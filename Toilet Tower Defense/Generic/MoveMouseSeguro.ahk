MoveMouseSeguro(TargetX, TargetY) {
    ; Pega a posição atual do mouse
    MouseGetPos, CurrentX, CurrentY

    ; Calcula um ponto "perto" do destino (offset de 10 pixels)
    ; Isso garante que o mouse sempre faça um pequeno trajeto final lento
    PertoX := TargetX > CurrentX ? TargetX - 10 : TargetX + 10
    PertoY := TargetY > CurrentY ? TargetY - 10 : TargetY + 10

    ; Teleporta para perto
    MouseMove, %PertoX%, %PertoY%, 0

    MouseMove, %TargetX%, %TargetY%, 3
}