# ==============================================================================
# GERENCIADOR DO BOT - TRAY + TELEGRAM
# - Auto relaunch em STA
# - Instancia unica via Mutex (sem lock zumbi)
# - Log em arquivo
# - Poll do Telegram em thread de background (UI nunca trava)
# ==============================================================================

# --- Auto-STA relaunch (CRITICO) ---
try {
    if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
        $ps = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
        Start-Process $ps -ArgumentList @(
            '-NoProfile','-Sta','-WindowStyle','Hidden','-ExecutionPolicy','Bypass',
            '-File',"`"$PSCommandPath`""
        )
        exit
    }
} catch { }

# --- Log ---
$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFile = Join-Path $baseDir "GerenciadorBot.log"
function Log([string]$t) {
    try { Add-Content -Path $logFile -Value ("[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $t) -Encoding UTF8 } catch {}
}

$ErrorActionPreference = "Continue"
trap {
    Log("ERRO FATAL: " + $_.Exception.Message)
    continue
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------------------------
# Instancia unica via Mutex
# ---------------------------
$createdNew = $false
$mutexName = "Global\GerenciadorBot_" + ([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($PSCommandPath)) -replace '[^a-zA-Z0-9]','').Substring(0,40)
$script:mutex = New-Object System.Threading.Mutex($true, $mutexName, [ref]$createdNew)
if (-not $createdNew) {
    Log("Outra instancia ja estava rodando. Saindo.")
    exit
}

$script:closing = $false
$script:pollTimer = $null

function Cleanup-And-Exit {
    if ($script:closing) { return }
    $script:closing = $true
    Log("Encerrando...")

    # Para o timer primeiro (evita callback rodando enquanto fecha)
    try {
        if ($script:pollTimer) {
            $script:pollTimer.Stop()
            $script:pollTimer.Dispose()
            $script:pollTimer = $null
        }
    } catch {}

    # Some com o ícone e dispose (evita ícone fantasma)
    try {
        if ($script:notifyIcon) {
            $script:notifyIcon.Visible = $false
            $script:notifyIcon.Dispose()
            $script:notifyIcon = $null
        }
    } catch {}

    # Libera mutex
    try {
        if ($script:mutex) {
            $script:mutex.ReleaseMutex() | Out-Null
            $script:mutex.Dispose()
            $script:mutex = $null
        }
    } catch {}

    # Encerra o loop WinForms do jeito certo
    try {
        if ($script:appContext) {
            $script:appContext.ExitThread()
        } else {
            [System.Windows.Forms.Application]::ExitThread()
        }
    } catch {}
}

# ---------------------------
# Paths
# ---------------------------
$configFile    = Join-Path $baseDir "Config.ini"
$msgFile       = Join-Path $baseDir "FilaMensagens.txt"
$launcherPath  = Join-Path $baseDir "Launcher.ahk"
$modoAtualPath = Join-Path $baseDir "ModoAtual.ahk"
$jogosDir      = Join-Path $baseDir "Jogos"
$lastModeFile  = Join-Path $baseDir "LastMode.txt"

$repoRoot = "C:\Users\Evan\Documents\AutoHotkey"
$repoUrl  = "https://github.com/ParasyteHiveMind/Auto-Farm.git"

$publisherPcName = "MeuComputadorPrincipal"  # <<< DEIXE IGUAL ao NomePC= do seu PC

# ---------------------------
# Config helpers
# ---------------------------
function Get-ConfigValue {
    param([string]$key)
    if (!(Test-Path $configFile)) { return $null }
    $line = (Select-String -Path $configFile -Pattern ("^{0}=" -f [regex]::Escape($key)) -ErrorAction SilentlyContinue | Select-Object -First 1).Line
    if (!$line) { return $null }
    return ($line.Split("=",2)[1]).Trim()
}

function Save-ConfigIni {
    param([string]$token,[string]$chatId,[string]$pcName)
@"
Token=$token
ChatID=$chatId
NomePC=$pcName
"@ | Set-Content -Path $configFile -Encoding UTF8
}

function Show-SetupForm {
    param([string]$defaultPcName)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Configurar Bot (primeira vez)"
    $form.Size = New-Object System.Drawing.Size(520, 260)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true

    $lbl1 = New-Object System.Windows.Forms.Label
    $lbl1.Text = "Token do Telegram Bot:"
    $lbl1.Location = New-Object System.Drawing.Point(12, 20)
    $lbl1.AutoSize = $true

    $tbToken = New-Object System.Windows.Forms.TextBox
    $tbToken.Location = New-Object System.Drawing.Point(170, 16)
    $tbToken.Size = New-Object System.Drawing.Size(320, 22)

    $lbl2 = New-Object System.Windows.Forms.Label
    $lbl2.Text = "ChatID:"
    $lbl2.Location = New-Object System.Drawing.Point(12, 60)
    $lbl2.AutoSize = $true

    $tbChat = New-Object System.Windows.Forms.TextBox
    $tbChat.Location = New-Object System.Drawing.Point(170, 56)
    $tbChat.Size = New-Object System.Drawing.Size(320, 22)

    $lbl3 = New-Object System.Windows.Forms.Label
    $lbl3.Text = "Nome do PC (para /setfor):"
    $lbl3.Location = New-Object System.Drawing.Point(12, 100)
    $lbl3.AutoSize = $true

    $tbPc = New-Object System.Windows.Forms.TextBox
    $tbPc.Location = New-Object System.Drawing.Point(170, 96)
    $tbPc.Size = New-Object System.Drawing.Size(320, 22)
    $tbPc.Text = $defaultPcName

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "Salvar"
    $btnOk.Location = New-Object System.Drawing.Point(170, 150)
    $btnOk.Size = New-Object System.Drawing.Size(120, 30)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancelar"
    $btnCancel.Location = New-Object System.Drawing.Point(310, 150)
    $btnCancel.Size = New-Object System.Drawing.Size(120, 30)

    $status = New-Object System.Windows.Forms.Label
    $status.Location = New-Object System.Drawing.Point(12, 190)
    $status.Size = New-Object System.Drawing.Size(480, 30)
    $status.Text = "Cole os valores e clique em Salvar."

    $btnOk.Add_Click({
        if ([string]::IsNullOrWhiteSpace($tbToken.Text) -or
            [string]::IsNullOrWhiteSpace($tbChat.Text) -or
            [string]::IsNullOrWhiteSpace($tbPc.Text)) {
            $status.Text = "Preencha todos os campos."
            return
        }
        $form.Tag = @{
            Token  = $tbToken.Text.Trim()
            ChatID = $tbChat.Text.Trim()
            NomePC = $tbPc.Text.Trim()
        }
        $form.Close()
    })

    $btnCancel.Add_Click({ $form.Tag = $null; $form.Close() })

    $form.Controls.AddRange(@($lbl1,$tbToken,$lbl2,$tbChat,$lbl3,$tbPc,$btnOk,$btnCancel,$status))
    $form.ShowDialog() | Out-Null
    return $form.Tag
}

# ---------------------------
# Load config
# ---------------------------
$script:token  = Get-ConfigValue "Token"
$script:chatId = Get-ConfigValue "ChatID"
$script:pcName = Get-ConfigValue "NomePC"

if ([string]::IsNullOrWhiteSpace($script:token) -or [string]::IsNullOrWhiteSpace($script:chatId) -or [string]::IsNullOrWhiteSpace($script:pcName)) {
    $setup = Show-SetupForm -defaultPcName $env:COMPUTERNAME
    if ($null -eq $setup) { Cleanup-And-Exit }
    $script:token  = $setup.Token
    $script:chatId = $setup.ChatID
    $script:pcName = $setup.NomePC
    Save-ConfigIni -token $script:token -chatId $script:chatId -pcName $script:pcName
}

$script:apiUrl = "https://api.telegram.org/bot$($script:token)"
$script:offset = 0

function Send-Telegram {
    param([string]$texto)
    try {
        $msg = "[{0}]`n{1}" -f $script:pcName, $texto
        Invoke-RestMethod -Uri "$($script:apiUrl)/sendMessage" -Method Post -Body @{
            chat_id    = $script:chatId
            text       = $msg
            parse_mode = "Markdown"
        } | Out-Null
    } catch {
        Log("Falha Send-Telegram: " + $_.Exception.Message)
    }
}

function Get-LocalStatus {
    $ahk = Get-Process -Name "AutoHotkey" -ErrorAction SilentlyContinue
    $rbx = Get-Process -Name "RobloxPlayerBeta" -ErrorAction SilentlyContinue
    $mode = "(desconhecido)"
    if (Test-Path $lastModeFile) { try { $mode = (Get-Content $lastModeFile -Raw).Trim() } catch {} }
    if ($ahk -and $rbx) { return "Rodando (AHK + Roblox) | Modo: $mode" }
    if ($ahk -and !$rbx) { return "AHK rodando, Roblox fechado | Modo: $mode" }
    return "Parado | Modo: $mode"
}

function Set-GameMode {
    param([string]$modeName)

    $pathOrigem = Join-Path $jogosDir $modeName
    if (!(Test-Path $pathOrigem)) { Send-Telegram "Modo nao encontrado: $modeName"; return }

    Stop-Process -Name "AutoHotkey" -ErrorAction SilentlyContinue

    $code = ""
    $ir = Join-Path $pathOrigem "IrAtePartida.ahk"
    $jp = Join-Path $pathOrigem "JogarPartida.ahk"
    if (Test-Path $ir) { $code += Get-Content $ir -Raw }
    $code += "`n; --- DIVISOR --- `n"
    if (Test-Path $jp) { $code += Get-Content $jp -Raw }

    Set-Content $modoAtualPath $code -Encoding UTF8
    try { Set-Content $lastModeFile $modeName -Encoding UTF8 } catch {}

    if (Test-Path $launcherPath) {
        Start-Process $launcherPath -WorkingDirectory $baseDir
        Send-Telegram "Modo definido: $modeName (Launcher iniciado)"
    } else {
        Send-Telegram "Launcher nao encontrado."
    }
}

function Set-GameModeFor {
    param([string]$modeName, [string]$targetPc)
    if ($targetPc -ne $script:pcName) { return }
    Set-GameMode $modeName
}

function Update-Bot {
    Send-Telegram "Update: baixando do GitHub..."
    Stop-Process -Name "AutoHotkey" -ErrorAction SilentlyContinue

    $batFile = "$env:TEMP\update_full.bat"
    $zipUrl = "https://github.com/ParasyteHiveMind/Auto-Farm/archive/refs/heads/main.zip"
    $zipFile = "$env:TEMP\AutoFarm.zip"
    $extractPath = "$env:TEMP\AutoFarm_Extracted"

$batContent = @"
@echo off
timeout /t 2 /nobreak >nul
powershell -Command "Invoke-WebRequest -Uri '$zipUrl' -OutFile '$zipFile'"
powershell -Command "Expand-Archive -Path '$zipFile' -DestinationPath '$extractPath' -Force"
xcopy /E /Y "$extractPath\Auto-Farm-main\*" "$repoRoot\"
del "$zipFile"
rmdir /s /q "$extractPath"
start "" "powershell.exe" -NoProfile -Sta -WindowStyle Hidden -ExecutionPolicy Bypass -File "$baseDir\GerenciadorBot.ps1"
del "%~f0"
"@

    Set-Content $batFile $batContent -Encoding ASCII
    Start-Process $batFile
    Cleanup-And-Exit
}

function Publish-Bot {
    if ($script:pcName -ne $publisherPcName) { Send-Telegram "Publish bloqueado (nao publicador)."; return }
    if (!(Test-Path (Join-Path $repoRoot ".git"))) { Send-Telegram "Publish erro: repoRoot sem .git"; return }

    try {
        Push-Location $repoRoot

        $rem = & git remote get-url origin 2>$null
        if (!$rem) { & git remote add origin $repoUrl | Out-Null }
        elseif ($rem -ne $repoUrl) { & git remote set-url origin $repoUrl | Out-Null }

        & git add -A | Out-Null
        $status = & git status --porcelain
        if ([string]::IsNullOrWhiteSpace($status)) { Send-Telegram "Publish: sem mudancas."; return }

        $msg = "Auto publish " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        & git commit -m $msg | Out-Null
        & git push origin main --force | Out-Null

        Send-Telegram "Publish OK: $msg"
    }
    catch {
        Send-Telegram ("Publish falhou: {0}" -f $_.Exception.Message)
        Log("Publish falhou: " + $_.Exception.Message)
    }
    finally {
        Pop-Location
    }
}

function Kill-Local {
    Cleanup-And-Exit
}

# ---------------------------
# Tray
# ---------------------------
$script:appContext = New-Object System.Windows.Forms.ApplicationContext
$script:notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$script:notifyIcon.Icon = [System.Drawing.SystemIcons]::Application
$script:notifyIcon.Text = "Gerenciador Bot ($($script:pcName))"
$script:notifyIcon.Visible = $true

$contextMenu = New-Object System.Windows.Forms.ContextMenu
$itemStatus = $contextMenu.MenuItems.Add("Status")
$itemStatus.add_Click({ Send-Telegram ("Status: " + (Get-LocalStatus)) })

$itemExit = $contextMenu.MenuItems.Add("Sair")
$itemExit.add_Click({
    Stop-Process -Name "AutoHotkey" -ErrorAction SilentlyContinue
    Stop-Process -Name "RobloxPlayerBeta" -ErrorAction SilentlyContinue
    Cleanup-And-Exit
})

$script:notifyIcon.ContextMenu = $contextMenu
$script:notifyIcon.add_Click({ Send-Telegram ("Estou vivo. " + (Get-LocalStatus)) })

# Limpa backlog
try {
    $res0 = Invoke-RestMethod -Uri "$($script:apiUrl)/getUpdates?timeout=0" -Method Get -ErrorAction SilentlyContinue
    if ($res0 -and $res0.ok -eq $true -and $res0.result.Count -gt 0) {
        $script:offset = [int]$res0.result[-1].update_id + 1
    }
} catch {}

# Auto-start Launcher (se quiser)
if (Test-Path $launcherPath) {
    if (!(Get-Process -Name "AutoHotkey" -ErrorAction SilentlyContinue)) {
        Start-Process $launcherPath -WorkingDirectory $baseDir
    }
}

Send-Telegram ("Gerenciador iniciado. " + (Get-LocalStatus))
Log("Gerenciador iniciado. " + (Get-LocalStatus))

# ---------------------------
# Poll no thread STA (estável) - WinForms Timer
# ---------------------------
$script:polling = $false

$script:pollTimer = New-Object System.Windows.Forms.Timer
$script:pollTimer.Interval = 2000  # 2s

$script:pollTimer.Add_Tick({
    if ($script:closing) { return }
    if ($script:polling) { return }
    $script:polling = $true
    try {
        # arquivo msg
        if (Test-Path $msgFile) {
            try {
                $txt = Get-Content $msgFile -Raw
                if ($txt) { Send-Telegram $txt }
                Remove-Item $msgFile -Force
            } catch {}
        }

        # Dica: timeout=0 evita travada; você já roda a cada 2s
        $uri = "$($script:apiUrl)/getUpdates?offset=$($script:offset)&timeout=0"
        $res = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction SilentlyContinue

        if ($res -and $res.ok -eq $true -and $res.result.Count -gt 0) {
            foreach ($upd in $res.result) {
                $script:offset = [int]$upd.update_id + 1
                $msg = $upd.message.text
                if ($upd.message.chat.id -ne $script:chatId) { continue }
                if ([string]::IsNullOrWhiteSpace($msg)) { continue }

                if ($msg -match "^/set\s+(.+)$") { Set-GameMode $Matches[1].Trim() }
                elseif ($msg -match "^/setfor\s+(\S+)\s+(.+)$") { Set-GameModeFor $Matches[1].Trim() $Matches[2].Trim() }
                elseif ($msg -eq "/status") { Send-Telegram (Get-LocalStatus) }
                elseif ($msg -eq "/publish") { Publish-Bot }
                elseif ($msg -eq "/update" -or $msg -eq "/updateall") { Update-Bot }
                elseif ($msg -eq "/killlocal") { Cleanup-And-Exit }
            }
        }
    }
    catch {
        Log("Erro no poll: " + $_.Exception.Message)
    }
    finally {
        $script:polling = $false
    }
})

$script:pollTimer.Start()

[System.Windows.Forms.Application]::Run($script:appContext)

# Se saiu do Run(), garante limpeza (sem reentrância)
if (-not $script:closing) { Cleanup-And-Exit }
