#SingleInstance Force
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

IMAGE_PATH := "C:\Users\Evan\Documents\AutoHotkey\Toilet Tower Defense\Imagens\EndlessSpot.png"

; Área de busca
X1 := 340
Y1 := 80
X2 := 470
Y2 := 180

Loop
{
    ImageSearch, FoundX, FoundY, X1, Y1, X2, Y2, %IMAGE_PATH%

    if (ErrorLevel = 0)
    {
        ToolTip, Imagem encontrada!
        break
    }
    else if (ErrorLevel = 1)
    {
        ToolTip, Imagem não encontrada tentando novamente...

        Send, {Esc}
        Sleep, 1000
        Send, r
        Sleep, 1000
        Send, {Enter}
        Sleep, 1000
    }
    else
    {
        ToolTip, Erro ao procurar a imagem!
        break
    }
}

; Mantém o tooltip visível por 2 segundos e limpa
Sleep, 2000
ToolTip
Esc::ExitApp