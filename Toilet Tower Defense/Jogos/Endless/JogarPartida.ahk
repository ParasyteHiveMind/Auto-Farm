JogarPartida()
{
    ; Puxa as variáveis de diretório se necessário
    global BASE_DIR, IMAGENS
    IMG_UPGRADE_AVAILABLE := IMAGENS . "\UpgradeAvailable.png"
    
    CoordMode, Mouse, Screen
    CoordMode, Pixel, Screen

        achou := false
    MoveMouseSeguro(620, 600) ; Abrir livro 7 slots
    Click

    Loop ; Aqui coloca 3 VIPs Octopus
    {
        ; ===== AÇÕES =====
        Send, 1
        PlaceTowerInArea(50, 430, 450, 530, 100, 500)
        ResetCharacter()

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
        SleepComChecagem(100)
    }
    Farmers3Upgrade()

    Loop, 21 ; Aqui coloca até 21 Plungers
    {
        ResetCharacter()

        Send, 4
        PlaceTowerInArea(50, 430, 400, 530, 50, 50)
        SleepComChecagem(100)
        MelhorarTorreMaisRecente()
        SleepComChecagem(100)
    }
    SleepComChecagem(9999999)
}