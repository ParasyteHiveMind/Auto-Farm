Farmers3Upgrade()
{
    global IMAGENS

    ; =============================
    ; CONFIGURAÇÕES
    ; =============================
    CoordMode, Pixel, Screen
    CoordMode, Mouse, Screen

    IMG_UPGRADE_AVAILABLE := IMAGENS . "\UpgradeAvailable.png"

    SX1 := 500
    SY1 := 270
    SX2 := 760
    SY2 := 290

    ; =============================
    ; SEGURANÇA INICIAL
    ; =============================
    if (ShouldStop())
        return false

    Send, {w up}{a up}{s up}{d up}

    if (SleepComChecagem(80) != "OK")
        return false

    ; =============================
    ; LOOP PRINCIPAL
    ; =============================
    Loop
    {
        if (ShouldStop())
            return false

        ; =============================
        ; 3 FARMERS → 3 CICLOS
        ; =============================
        Loop, 3
        {
            if (ShouldStop())
                return false

            MoveMouseSeguro(530, 280)
            if (SleepComChecagem(1) != "OK")
                return false
            Click

            MoveMouseSeguro(620, 280)
            if (SleepComChecagem(1) != "OK")
                return false
            Click

            MoveMouseSeguro(710, 280)
            if (SleepComChecagem(1) != "OK")
                return false
            Click
        }

        ; =============================
        ; TIRA O MOUSE DO BOTÃO
        ; =============================
        MoveMouseSeguro(640, 250)
        if (SleepComChecagem(100) != "OK")
            return false

        ; =============================
        ; VERIFICA SE AINDA HÁ UPGRADE
        ; =============================
        inicio := A_TickCount
        achou  := false

        while (A_TickCount - inicio < 1000)
        {
            if (ShouldStop())
                return false

            ImageSearch, fx, fy, %SX1%, %SY1%, %SX2%, %SY2%, *20 %IMG_UPGRADE_AVAILABLE%
            if (ErrorLevel = 0)
            {
                achou := true
                break
            }

            if (SleepComChecagem(40) != "OK")
                return false
        }

        ; ❌ Não achou mais upgrade → encerra função
        if (!achou)
            break

        if (SleepComChecagem(120) != "OK")
            return false
    }

    ; ✅ Finalizou todos os upgrades possíveis
    return true
}
