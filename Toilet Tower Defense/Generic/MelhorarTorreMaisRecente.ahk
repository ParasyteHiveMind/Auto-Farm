MelhorarTorreMaisRecente()
{
    global IMAGENS

    CoordMode, Pixel, Screen
    CoordMode, Mouse, Screen

    IMG_UP1 := IMAGENS . "\UpgradeOnLeft.png"
    IMG_UP2 := IMAGENS . "\UpgradeOnLeftDark.png"

    SX1 := 15
    SY1 := 355
    SX2 := 95
    SY2 := 390

    ; =============================
    ; SEGURANÇA INICIAL
    ; =============================
    if (ShouldStop())
        return false

    ; =============================
    ; ABRIR INTERFACE
    ; =============================
    MoveMouseSeguro(551, 221)
    Click
    if (SleepComChecagem(120) != "OK")
        return false

    MoveMouseSeguro(35, 440)
    Click
    if (SleepComChecagem(150) != "OK")
        return false

    ; =============================
    ; LOOP DE UPGRADE
    ; =============================
    Loop
    {
        if (ShouldStop())
            return false

        MoveMouseSeguro(35, 375)
        Click

        inicio := A_TickCount
        achou  := false

        ; =============================
        ; VERIFICA BOTÃO DE UPGRADE
        ; =============================
        while (A_TickCount - inicio < 1000)
        {
            if (ShouldStop())
                return false

            ImageSearch, fx, fy, %SX1%, %SY1%, %SX2%, %SY2%, %IMG_UP1%
            if (ErrorLevel = 0)
            {
                achou := true
                break
            }

            ImageSearch, fx, fy, %SX1%, %SY1%, %SX2%, %SY2%, %IMG_UP2%
            if (ErrorLevel = 0)
            {
                achou := true
                break
            }

            if (SleepComChecagem(30) != "OK")
                return false
        }

        ; ❌ Torre no máximo
        if (!achou)
            break

        if (SleepComChecagem(80) != "OK")
            return false
    }

    ; ✅ Finalizou upgrades
    return true
}
