IrAtePartida()
{
    global IMAGENS
    CoordMode, Mouse, Screen

    if (ShouldStop())
        return "STOP"

    ; teleportar até posição do jogo
    MoveMouseSeguro(250, 240)
    Click

    ; Sleep 1000 com checagem de STOP
    start := A_TickCount
    while (A_TickCount - start < 1000) {
        if (ShouldStop())
            return "STOP"
        Sleep, 50
    }

    ; Movimentação física (Segurar teclas) com STOP
    Send, {s down}
    Send, {d down}

    start := A_TickCount
    while (A_TickCount - start < 1000) {
        if (ShouldStop()) {
            Send, {s up}{d up}
            return "STOP"
        }
        Sleep, 50
    }

    Send, {s up}

    start := A_TickCount
    while (A_TickCount - start < 600) {
        if (ShouldStop()) {
            Send, {d up}
            return "STOP"
        }
        Sleep, 50
    }

    Send, {d up}

    ; Aguardar teleporte (25s) com STOP
    start := A_TickCount
    while (A_TickCount - start < 25000) {
        if (ShouldStop())
            return "STOP"
        Sleep, 100
    }

    return "OK"
}
