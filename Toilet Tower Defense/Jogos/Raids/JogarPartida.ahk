JogarPartida()
{
    ; Puxa as variáveis de diretório se necessário
    global BASE_DIR, IMAGENS
    IMG_UPGRADE_AVAILABLE := IMAGENS . "\UpgradeAvailable.png"
    
    CoordMode, Mouse, Screen
    CoordMode, Pixel, Screen

        achou := false

    Loop ; Aqui coloca os 3 VIPs Octopus
    {
        ; ===== AÇÕES =====
        Send, 1
        MoveMouseSeguro(50, 430)
        PlaceTowerInArea(50, 430, 450, 530, 100, 500)
        MoveMouseSeguro(45, 65)
        Click
        SleepComChecagem(1000)
        MoveMouseSeguro(415, 537)
        Click
        SleepComChecagem(1000)
        MoveMouseSeguro(297, 392)
        Click
        SleepComChecagem(1000)

        ; ===== BUSCA DA IMAGEM (ATÉ 1s) =====
        inicio := A_TickCount
        achou := false

        while (A_TickCount - inicio < 1000)
        {
            ImageSearch, fx, fy, 680, 260, 740, 300, *20 %IMG_UPGRADE_AVAILABLE%
            if (ErrorLevel = 0)
            {
                achou := true
                break
            }
            Sleep, 40
        }

        ; Se encontrou, sai do loop principal
        if (achou)
            break

        ; Caso contrário, repete tudo
        SleepComChecagem(120)
    }
    Farmers3Upgrade()

    Loop, 12 ; Aqui coloca 12 palhaços
    {
        MoveMouseSeguro(45, 65)
        Click
        SleepComChecagem(1000)
        MoveMouseSeguro(415, 537)
        Click
        SleepComChecagem(1000)
        MoveMouseSeguro(297, 392)
        Click
        SleepComChecagem(1000)

        Send, 3
        MoveMouseSeguro(50, 430)
        PlaceTowerInArea(50, 430, 400, 530, 50, 50)
        SleepComChecagem(200)
        MelhorarTorreMaisRecente()

        SleepComChecagem(500)
    }
    SleepComChecagem(999999)
}