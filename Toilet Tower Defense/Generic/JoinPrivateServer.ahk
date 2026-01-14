JoinPrivateServer()
{
    global IMAGENS, BASE_DIR
    global STOP_REQUESTED

    ROBLOX_EXE   := "RobloxPlayerBeta.exe"
    EDGE_EXE     := "msedge.exe"
    EDGE_PATH    := "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

    PRIVATE_LINK := "https://www.roblox.com/share?code=b30ea8752d022c4cb262dffa46a705b3&type=Server"
    IMAGE_PATH   := IMAGENS . "\GoingToLobby.png"
    TOLERANCIA   := 50
    TIMEOUT_LOBBY := 120000 ; 2 minutos

    ; --- CHECAGEM DE STOP IMEDIATA ---
    if (ShouldStop())
        return "STOP"

    ; --- (Opcional) legado do ReinicioRapido: mantém sem quebrar ---
    IniRead, ReinicioRapido, %A_ScriptDir%\EstadoBot.ini, Estado, ReinicioRapido, 0
    if (ReinicioRapido = 1)
    {
        IniWrite, 0, %A_ScriptDir%\EstadoBot.ini, Estado, ReinicioRapido
        if WinExist("ahk_exe " . ROBLOX_EXE)
            WinActivate, ahk_exe %ROBLOX_EXE%
        return "OK"
    }

    ; --- 1. Se Roblox já está aberto, tenta detectar lobby rápido ---
    if WinExist("ahk_exe " . ROBLOX_EXE)
    {
        WinActivate, ahk_exe %ROBLOX_EXE%

        Loop, 5
        {
            if (ShouldStop())
                return "STOP"

            ImageSearch, lx, ly, 0, 0, 800, 600, *%TOLERANCIA% %IMAGE_PATH%
            if (ErrorLevel = 0)
            {
                WinMove, ahk_exe %ROBLOX_EXE%, , 0, 0, 800, 600
                goto, EtapaTeleporte
            }
            Sleep, 250
        }
    }

    ; --- 2. Limpeza e início (sem Reload) ---
    Run, %ComSpec% /c taskkill /IM %ROBLOX_EXE% /F,, Hide
    Run, %ComSpec% /c taskkill /IM %EDGE_EXE% /F,, Hide

    ; espera curta com STOP
    startKill := A_TickCount
    while (A_TickCount - startKill < 1500)
    {
        if (ShouldStop())
            return "STOP"
        Sleep, 50
    }

    ; --- 3. Abre Edge ---
    Run, "%EDGE_PATH%"
    ; WinWait com checagem de STOP (não travar)
    startEdge := A_TickCount
    edgeOk := false
    while (A_TickCount - startEdge < 120000)
    {
        if (ShouldStop())
            return "STOP"

        if WinExist("ahk_exe " . EDGE_EXE)
        {
            edgeOk := true
            break
        }
        Sleep, 200
    }
    if (!edgeOk)
        return "RESTART"

    WinActivate, ahk_exe %EDGE_EXE%
    Sleep, 200

    ; abre link
    Send, ^t
    Sleep, 150
    Clipboard := PRIVATE_LINK
    Send, ^v
    Sleep, 150
    Send, {Enter}

    ; --- 4. Espera Roblox abrir ---
    startRoblox := A_TickCount
    robloxOk := false
    while (A_TickCount - startRoblox < 120000)
    {
        if (ShouldStop())
            return "STOP"

        if WinExist("ahk_exe " . ROBLOX_EXE)
        {
            robloxOk := true
            break
        }
        Sleep, 250
    }
    if (!robloxOk)
        return "RESTART"

    ; Fecha Edge
    if WinExist("ahk_exe " . EDGE_EXE)
    {
        WinActivate, ahk_exe %EDGE_EXE%
        Sleep, 150
        Send, ^w
        Sleep, 300
        Send, !{F4}
    }

    ; Foca Roblox
    WinActivate, ahk_exe %ROBLOX_EXE%

    ; aguarda ficar ativo (com STOP)
    startActive := A_TickCount
    while (A_TickCount - startActive < 30000)
    {
        if (ShouldStop())
            return "STOP"

        WinGet, isActive, MinMax, ahk_exe %ROBLOX_EXE%
        ; MinMax não diz ativo, então usamos WinActive
        if WinActive("ahk_exe " . ROBLOX_EXE)
            break

        Sleep, 200
    }

    ; estabiliza
    startStab := A_TickCount
    while (A_TickCount - startStab < 2000)
    {
        if (ShouldStop())
            return "STOP"
        Sleep, 50
    }

    WinMove, ahk_exe %ROBLOX_EXE%, , 0, 0, 800, 600

    ; --- 5. Espera o lobby carregar (COM STOP!) ---
    inicio := A_TickCount
    encontrou := false
    while (A_TickCount - inicio < TIMEOUT_LOBBY)
    {
        if (ShouldStop())
            return "STOP"

        ImageSearch, lx, ly, 0, 360, 70, 430, *%TOLERANCIA% %IMAGE_PATH%
        if (ErrorLevel = 0)
        {
            encontrou := true
            break
        }
        Sleep, 500
    }

    if (!encontrou)
        return "RESTART"

    ; --- 6. Teleporte ---
EtapaTeleporte:
    ; sleeps com STOP
    startTp := A_TickCount
    while (A_TickCount - startTp < 1000)
    {
        if (ShouldStop())
            return "STOP"
        Sleep, 50
    }

    MoveMouseSeguro(320, 62) ; ABRIR TELEPORTE
    Click

    startTp2 := A_TickCount
    while (A_TickCount - startTp2 < 500)
    {
        if (ShouldStop())
            return "STOP"
        Sleep, 50
    }

    MoveMouseSeguro(414, 104) ; FECHAR LEADERSTATS
    Click

    startTp3 := A_TickCount
    while (A_TickCount - startTp3 < 1000)
    {
        if (ShouldStop())
            return "STOP"
        Sleep, 50
    }

    ; Identifica o modo atual para retornar (mantive sua lógica, corrigindo globals)
    Modo := ""
    Loop, Files, % BASE_DIR "\*.txt"
    {
        SplitPath, A_LoopFileName,,,, NomeSemExt
        if (NomeSemExt != "GameMode")
        {
            Modo := NomeSemExt
            break
        }
    }

    if (Modo = "")
        return "OK"

    return Modo
}
