JogarPartida()
{
    global BASE_DIR, IMAGENS

    CoordMode, Mouse, Screen
    CoordMode, Pixel, Screen

    ; helper local: se SleepComChecagem retornar algo diferente de OK, encerra e propaga
    ; (AHK v1 não tem função anônima boa, então vamos repetir o padrão)

    Send, 1
    PlaceTowerInArea(15, 500, 415, 550, 200, 50)

    Send, {d down}
    r := SleepComChecagem(300)
    if (r != "OK")
        return r
    Send, {d up}

    r := SleepComChecagem(700)
    if (r != "OK")
        return r

    Send, 1
    PlaceTowerInArea(15, 500, 415, 550, 200, 50)

    Send, {d down}
    r := SleepComChecagem(300)
    if (r != "OK")
        return r
    Send, {d up}

    r := SleepComChecagem(700)
    if (r != "OK")
        return r

    Send, 1
    PlaceTowerInArea(15, 500, 415, 550, 200, 50)
    r := SleepComChecagem(1000)
    if (r != "OK")
        return r

    Send, 3
    MoveMouseSeguro(310, 500)
    Click

    Send, {s down}
    r := SleepComChecagem(1450)
    if (r != "OK")
        return r
    Send, {s up}

    Send, 3
    MoveMouseSeguro(310, 500)
    Click

    Send, {s down}
    r := SleepComChecagem(1450)
    if (r != "OK")
        return r
    Send, {s up}

    r := SleepComChecagem(1000)
    if (r != "OK")
        return r

    Send, 3
    PlaceTowerInArea(390, 300, 410, 340, 20, 20)

    r := SleepComChecagem(100)
    if (r != "OK")
        return r

    if (!Farmers3Upgrade())
        return "STOP"  ; se você quiser diferenciar, pode retornar false mesmo

    if (!MelhorarTorreMaisRecente())
        return "STOP"

    Loop, 4
    {
        if (ShouldStop())
            return "STOP"

        Send, 2
        PlaceTowerInArea(25, 300, 375, 550, 175, 25)

        if (!MelhorarTorreMaisRecente())
            return "STOP"

        r := SleepComChecagem(50)
        if (r != "OK")
            return r
    }

    ; ============================
    ; ESPERA FINAL ATÉ ACABAR A PARTIDA
    ; Agora isso é OK, porque vai RETORNAR "RESTART_SOFT" quando PlayAgain aparecer
    ; ============================
    Loop
    {
        if (ShouldStop())
            return "STOP"

        r := SleepComChecagem(500)  ; checa de 0.5s em 0.5s
        if (r != "OK")
            return r
    }
}
