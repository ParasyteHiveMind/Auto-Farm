# ==============================================================================
# GERENCIADOR DO BOT - TRAY + TELEGRAM (COM SETUP) - SEM EMOJIS (ANTI-ENCODING)
# FIX: offset em $script:offset para nao reprocessar mensagens no Timer
# ==============================================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$baseDir       = Split-Path -Parent $MyInvocation.MyCommand.Path
$configFile    = Join-Path $baseDir "Config.ini"
$msgFile       = Join-Path $baseDir "FilaMensagens.txt"
$launcherPath  = Join-Path $baseDir "Launcher.ahk"
$modoAtualPath = Join-Path $baseDir "ModoAtual.ahk"
$jogosDir      = Join-Path $baseDir "Jogos"
$lastModeFile  = Join-Path $baseDir "LastMode.txt"   # opcional para lembrar modo

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

    $btnCancel.Add_Click({
        $form.Tag = $null
        $form.Close()
    })

    $form.Controls.AddRange(@($lbl1,$tbToken,$lbl2,$tbChat,$lbl3,$tbPc,$btnOk,$btnCancel,$status))
    $form.ShowDialog() | Out-Null
    return $form.Tag
}

# --- Carrega config ou faz setup ---
$script:token  = Get-ConfigValue "Token"
$script:chatId = Get-ConfigValue "ChatID"
$script:pcName = Get-ConfigValue "NomePC"

if ([string]::IsNullOrWhiteSpace($script:token) -or [string]::IsNullOrWhiteSpace($script:chatId) -or [string]::IsNullOrWhiteSpace($script:pcName)) {
    $setup = Show-SetupForm -defaultPcName $env:COMPUTERNAME
    if ($null -eq $setup) { exit }
    $script:token  = $setup.Token
    $script:chatId = $setup.ChatID
    $script:pcName = $setup.NomePC
    Save-ConfigIni -token $script:token -chatId $script:chatId -pcName $script:pcName
}

$script:apiUrl = "https://api.telegram.org/bot$($script:token)"

# IMPORTANTISSIMO: offset no escopo de script
$script:offset = 0
$script:lastMode = ""
if (Test-Path $lastModeFile) {
    try { $script:lastMode = (Get-Content $lastModeFile -Raw).Trim() } catch {}
}

function Send-Telegram {
    param([string]$texto)
    try {
        $msg = "[{0}]`n{1}" -f $script:pcName, $texto
        Invoke-RestMethod -Uri "$($script:apiUrl)/sendMessage" -Method Post -Body @{
            chat_id    = $script:chatId
            text       = $msg
            parse_mode = "Markdown"
        } | Out-Null
    } catch {}
}

function Get-LocalStatus {
    $ahk = Get-Process -Name "AutoHotkey" -ErrorAction SilentlyContinue
    $rbx = Get-Process -Name "RobloxPlayerBeta" -ErrorAction SilentlyContinue
    if ($ahk -and $rbx) { return "Rodando (AHK + Roblox)" }
    if ($ahk -and !$rbx) { return "AHK rodando, Roblox fechado" }
    return "Parado"
}

function Start-LauncherIfNeeded {
    if (!(Test-Path $launcherPath)) { return $false }
    # se já tiver AHK rodando, não inicia outro
    if (Get-Process -Name "AutoHotkey" -ErrorAction SilentlyContinue) { return $false }
    Start-Process $launcherPath -WorkingDirectory $baseDir
    return $true
}

function Set-GameMode {
    param([string]$modeName)

    # anti-loop: se já está no mesmo modo, não reinicia
    if ($script:lastMode -eq $modeName) {
        Send-Telegram "Modo ja estava definido: $modeName (ignorando repeticao)"
        return
    }

    $pathOrigem = Join-Path $jogosDir $modeName
    if (!(Test-Path $pathOrigem)) {
        Send-Telegram "Modo nao encontrado: $modeName"
        return
    }

    Stop-Process -Name "AutoHotkey" -ErrorAction SilentlyContinue

    $code = ""
    $ir = Join-Path $pathOrigem "IrAtePartida.ahk"
    $jp = Join-Path $pathOrigem "JogarPartida.ahk"

    if (Test-Path $ir) { $code += Get-Content $ir -Raw }
    $code += "`n; --- DIVISOR --- `n"
    if (Test-Path $jp) { $code += Get-Content $jp -Raw }

    Set-Content $modoAtualPath $code -Encoding UTF8

    $script:lastMode = $modeName
    try { Set-Content $lastModeFile $modeName -Encoding UTF8 } catch {}

    if (Test-Path $launcherPath) {
        Start-Process $launcherPath -WorkingDirectory $baseDir
        Send-Telegram "Modo definido: $modeName (Launcher iniciado)"
    } else {
        Send-Telegram "Launcher nao encontrado: $launcherPath"
    }
}

function Set-GameModeFor {
    param([string]$modeName, [string]$targetPc)
    if ($targetPc -ne $script:pcName) { return }
    Set-GameMode $modeName
}

function Update-Bot {
    Send-Telegram "Atualizando do GitHub..."
    Stop-Process -Name "AutoHotkey" -ErrorAction SilentlyContinue

    $batFile = "$env:TEMP\update_full.bat"
    $zipUrl = "https://github.com/ParasyteHiveMind/Auto-Farm/archive/refs/heads/main.zip"
    $zipFile = "$env:TEMP\AutoFarm.zip"
    $extractPath = "$env:TEMP\AutoFarm_Extracted"

$batContent = @"
@echo off
timeout /t 3 /nobreak >nul
powershell -Command "Invoke-WebRequest -Uri '$zipUrl' -OutFile '$zipFile'"
powershell -Command "Expand-Archive -Path '$zipFile' -DestinationPath '$extractPath' -Force"
xcopy /E /Y "$extractPath\Auto-Farm-main\Toilet Tower Defense\*" "$baseDir\"
del "$zipFile"
rmdir /s /q "$extractPath"
start "" "powershell.exe" -Sta -WindowStyle Hidden -ExecutionPolicy Bypass -File "$baseDir\GerenciadorBot.ps1"
del "%~f0"
"@

    Set-Content $batFile $batContent -Encoding ASCII
    Start-Process $batFile

    $notifyIcon.Visible = $false
    $appContext.ExitThread()
    Exit
}

# --- TRAY ---
$appContext = New-Object System.Windows.Forms.ApplicationContext
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = [System.Drawing.SystemIcons]::Application
$notifyIcon.Text = "Gerenciador Bot Roblox ($($script:pcName))"
$notifyIcon.Visible = $true

$contextMenu = New-Object System.Windows.Forms.ContextMenu
$itemExit = $contextMenu.MenuItems.Add("Sair e Fechar Tudo")
$itemExit.add_Click({
    Stop-Process -Name "AutoHotkey" -ErrorAction SilentlyContinue
    Stop-Process -Name "RobloxPlayerBeta" -ErrorAction SilentlyContinue
    $notifyIcon.Visible = $false
    $appContext.ExitThread()
})
$notifyIcon.ContextMenu = $contextMenu

$notifyIcon.add_Click({
   Send-Telegram ("Estou vivo. Status: {0}" -f (Get-LocalStatus))
})

# --- LIMPA backlog antigo de updates (muito importante) ---
try {
    $res0 = Invoke-RestMethod -Uri "$($script:apiUrl)/getUpdates?timeout=0" -Method Get -ErrorAction SilentlyContinue
    if ($res0 -and $res0.ok -eq $true -and $res0.result.Count -gt 0) {
        $last = $res0.result[-1]
        $script:offset = [int]$last.update_id + 1
    }
} catch {}

# --- AUTO START DO LAUNCHER (sem precisar /set) ---
if (Start-LauncherIfNeeded) {
    Send-Telegram "Launcher iniciado automaticamente."
} else {
    # se já estava rodando ou faltou arquivo, só informa status
    Send-Telegram ("Gerenciador iniciado. Status: {0}" -f (Get-LocalStatus))
}

# --- LOOP ---
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 2000
$timer.add_Tick({

    # 1) Mensagens do AHK -> Telegram
    if (Test-Path $msgFile) {
        try {
            $txt = Get-Content $msgFile -Raw
            if ($txt) { Send-Telegram $txt }
            Remove-Item $msgFile -Force
        } catch {}
    }

    # 2) Comandos do Telegram
    try {
        $uri = "$($script:apiUrl)/getUpdates?offset=$($script:offset)&timeout=1"
        $res = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction SilentlyContinue

        if ($res -and $res.ok -eq $true -and $res.result.Count -gt 0) {
            foreach ($upd in $res.result) {
                $script:offset = [int]$upd.update_id + 1

                $msg = $upd.message.text
                $fromChat = $upd.message.chat.id

                if ($fromChat -ne $script:chatId) { continue }

                if ($msg -match "^/set\s+(.+)$") {
                    Set-GameMode $Matches[1].Trim()
                }
                elseif ($msg -match "^/setfor\s+(\S+)\s+(.+)$") {
                    $modo = $Matches[1].Trim()
                    $pcTarget = $Matches[2].Trim()
                    Set-GameModeFor $modo $pcTarget
                }
                elseif ($msg -eq "/update") {
                    Update-Bot
                }
                elseif ($msg -eq "/status") {
                    Send-Telegram (Get-LocalStatus)
                }
            }
        }
    } catch {}
})

$timer.Start()
[System.Windows.Forms.Application]::Run($appContext)
