IrAtePartida()
{
    global IMAGENS
    CoordMode, Mouse, Screen

    MoveMouseSeguro(380, 130) ; Aqui teleporta até as raids
    Click
    Sleep, 1000

    Send, {a down}
    Sleep, 1500
    Send, {a up}

    Sleep, 25000
    return true
}