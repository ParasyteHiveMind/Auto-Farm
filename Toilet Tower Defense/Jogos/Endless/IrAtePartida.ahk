IrAtePartida()
{
    global IMAGENS
    CoordMode, Mouse, Screen

    ; teleportar até posição do jogo
    MoveMouseSeguro(100, 185)
    Click
    Sleep, 1000

    ; Passo 2: Movimentação física (Segurar teclas)
    ; Se a conexão cair aqui, o Reload do SleepComChecagem limpa o buffer do teclado
    Send, {w down}
    Send, {a down}
    Sleep, 100
    Send, {a up}
    Sleep, 2400
    Send, {w up}

    ; Passo 3: Aguardar o Teleporte (25 segundos)
    ; Aqui é onde a maioria dos scripts "morre". Usando o SleepComChecagem,
    ; ficamos vigiando a tela enquanto o Roblox carrega.
    Sleep, 25000

    ; Em vez de Run Generic, agora apenas retornamos para o Launcher
    ; O Launcher então chamará o EsperandoPartidaIniciar()
    return true

}
