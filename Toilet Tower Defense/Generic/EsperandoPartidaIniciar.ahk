EsperandoPartidaIniciar() {
    global IMAGENS

    CoordMode, Pixel, Screen
    CoordMode, Mouse, Screen

    IMAGE_PATH := IMAGENS . "\MatchStarted.png"

    StartTime := A_TickCount
    TIMEOUT_MS := 120000  ; 2 minutos

    ; Espera até aparecer o Auto Skip vermelho (MatchStarted)
    Loop
    {
        if (ShouldStop())
            return "STOP"

        ImageSearch, FoundX, FoundY, 420, 70, 440, 90, %IMAGE_PATH%
        if (ErrorLevel = 0)
            break

        if (A_TickCount - StartTime > TIMEOUT_MS)
            return "RESTART"   ; Launcher volta pro JoinPrivateServer

        Sleep, 200
    }

    ; Achou o Auto Skip (vermelho) => clica e prepara UI
    if (ShouldStop())
        return "STOP"

    ; clique no Auto Skip
    MoveMouseSeguro(436, 76)
    Click
    Sleep, 200

    if (ShouldStop())
        return "STOP"

    ; abrir livro
    MoveMouseSeguro(560, 600)
    Click
    Sleep, 200

    return "OK"
}
