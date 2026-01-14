; =====================================================================
; FUNÇÕES CENTRAIS (TTD)
; =====================================================================

global UltimaVezConectado := A_TickCount
global STOP_REQUESTED := false
global RESTART_SOFT := false

; Caminhos do sistema de pontos
global PONTOS_DIR      := "C:\Users\Evan\Documents\AutoHotkey\Pontos"
global NEXT_FILE       := PONTOS_DIR . "\NextActivation.txt"
global COLETAR_SCRIPT  := PONTOS_DIR . "\ColetarPontos.ahk"

ShouldStop() {
    global STOP_REQUESTED
    return STOP_REQUESTED
}

; Retornos: OK | STOP | RESTART_SOFT | RESTART
SleepComChecagem(TempoMs) {
    global RESTART_SOFT

    Inicio := A_TickCount
    Loop {
        if (ShouldStop())
            return "STOP"

        if (RESTART_SOFT)
            return "RESTART_SOFT"

        if (A_TickCount - Inicio >= TempoMs)
            return "OK"

        r := VerificarGameOver()
        if (r != "OK")
            return r

        Sleep, 100
    }
}

; =====================================================================
; GAME OVER / PLAY AGAIN
; =====================================================================
VerificarGameOver() {
    global IMAGENS

    if (ShouldStop())
        return "STOP"

    ImagensPlayAgain := ["PlayAgain.png", "PlayAgainDark.png", "JogarNovamente.png", "JogarNovamenteDark.png"]

    For index, imgName in ImagensPlayAgain {
        ImageSearch, , , 400, 445, 625, 490, % IMAGENS "\" imgName
        if (ErrorLevel = 0) {
            ClicarPlayAgainEReiniciar()
            return "RESTART_SOFT"
        }
    }
    return "OK"
}

; =====================================================================
; Converte "YYYY-MM-DD HH:MM" para "YYYYMMDDHHMISS" (segundos = 00)
; Retorna "" se inválido
; =====================================================================
ParseNextActivationToAHDatetime(txt) {
    txt := Trim(txt)
    if !RegExMatch(txt, "^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}$")
        return ""

    y := SubStr(txt, 1, 4)
    m := SubStr(txt, 6, 2)
    d := SubStr(txt, 9, 2)
    hh := SubStr(txt, 12, 2)
    mm := SubStr(txt, 15, 2)

    return y . m . d . hh . mm . "00"
}

; =====================================================================
; Se já passou do horário do NextActivation, roda ColetarPontos.ahk
; Retorna true se disparou a coleta (e então este script deve sair)
; =====================================================================
ChecarEExecutarColetarPontosSeDevido() {
    global NEXT_FILE, COLETAR_SCRIPT

    if (!FileExist(NEXT_FILE))
        return false

    FileRead, raw, %NEXT_FILE%
    alvo := ParseNextActivationToAHDatetime(raw)
    if (alvo = "")
        return false

    agora := A_Now  ; YYYYMMDDHHMISS

    ; Se agora >= alvo: rodar coleta
    if (agora >= alvo)
    {
        ; Fecha Roblox por segurança (evita conflito de mouse/teclas)
        Process, Close, RobloxPlayerBeta.exe
        Sleep, 500

        ; Roda o script de coletar pontos (ele relança o Launcher no final)
        if (FileExist(COLETAR_SCRIPT))
            Run, "%COLETAR_SCRIPT%", %PONTOS_DIR%

        return true
    }

    return false
}

; =====================================================================
; PLAY AGAIN (com gancho para ColetarPontos)
; =====================================================================
ClicarPlayAgainEReiniciar() {
    global RESTART_SOFT

    if (ShouldStop())
        return

    ; ✅ Antes de clicar PlayAgain: se está na hora, roda ColetarPontos e encerra este bot
    if (ChecarEExecutarColetarPontosSeDevido()) {
        ExitApp
    }

    ; Caso normal: clica PlayAgain e segue
    MoveMouseSeguro(512, 467)
    Click

    RESTART_SOFT := true

    ; dá tempo da tela de loading aparecer
    start := A_TickCount
    while (A_TickCount - start < 5000) {
        if (ShouldStop())
            return
        Sleep, 50
    }
}

MoveMouseSeguro(x, y) {
    MouseMove, x, y
}
