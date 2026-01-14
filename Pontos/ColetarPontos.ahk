#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 2
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
SetDefaultMouseSpeed, 0

; =============================
; CONFIGURAÇÕES E CAMINHOS
; =============================
EDGE_EXE      := "msedge.exe"
EDGE_PATH     := "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
EDGE_PARAMS   := " --no-first-run --no-default-browser-check"

BASE_DIR_PONTOS := "C:\Users\Evan\Documents\AutoHotkey\Pontos"
IMAGENS         := BASE_DIR_PONTOS . "\Imagens"
NEXT_FILE       := BASE_DIR_PONTOS . "\NextActivation.txt"
AVAIL_FILE      := BASE_DIR_PONTOS . "\AvailableTime.txt"

DIR_TTD         := "C:\Users\Evan\Documents\AutoHotkey\Toilet Tower Defense"
LAUNCHER_PATH   := DIR_TTD . "\Launcher.ahk"

LINK_PRINCIPAL := "https://rewards.bing.com/?form=dash_2"
LINK_QUESTOES  := "https://thestoryshack.com/pt/geradores/gerador-de-perguntas-aleatorias/#google_vignette"

; =============================
; FUNÇÕES AUXILIARES
; =============================

AjustarJanelaEdge() {
    global EDGE_EXE
    if !WinExist("ahk_exe " . EDGE_EXE)
        return

    WinActivate, ahk_exe %EDGE_EXE%
    WinWaitActive, ahk_exe %EDGE_EXE%,, 2

    WinRestore, ahk_exe %EDGE_EXE%
    Sleep, 200

    ; Detecta fullscreen real (quase do tamanho da tela)
    WinGetPos, X, Y, W, H, ahk_exe %EDGE_EXE%
    if (W >= A_ScreenWidth - 10 && H >= A_ScreenHeight - 10) {
        Send, {F11}
        Sleep, 700
        WinRestore, ahk_exe %EDGE_EXE%
        Sleep, 200
    }

    WinMove, ahk_exe %EDGE_EXE%,, 0, 0, 800, 600
    Sleep, 200

    WinGetPos, X, Y, W, H, ahk_exe %EDGE_EXE%
    if (W > 900 || H > 700) {
        WinRestore, ahk_exe %EDGE_EXE%
        Sleep, 200
        WinMove, ahk_exe %EDGE_EXE%,, 0, 0, 800, 600
        Sleep, 200
    }
}

ScrollDown(quantidade) {
    Loop, %quantidade% {
        Send, {WheelDown}
        Sleep, 120
    }
}

AbrirNovaAba(link) {
    Send, ^t
    Sleep, 350
    AjustarJanelaEdge()

    Send, ^l
    Sleep, 150

    Clipboard := link
    ClipWait, 1
    Send, ^v
    Sleep, 120
    Send, {Enter}
    Sleep, 300
}

ClicarEVerificarAba(x, y) {
    WinGetTitle, TituloAntes, A

    MouseMove, %x%, %y%, 10
    Sleep, 100
    Click

    Sleep, 1500

    WinGetTitle, TituloDepois, A
    if (TituloAntes != TituloDepois)
    {
        Sleep, 3000
        Send, ^w
        Sleep, 800
        AjustarJanelaEdge()
        return true
    }
    return false
}

LerHorariosDisponiveis(arquivo) {
    horarios := []
    if (!FileExist(arquivo))
        return horarios

    FileRead, txt, %arquivo%
    Loop, Parse, txt, `n, `r
    {
        linha := Trim(A_LoopField)
        if (linha = "")
            continue
        if RegExMatch(linha, "^\d{2}:\d{2}$")
            horarios.Push(linha)
    }
    return horarios
}

; Qualquer horário ENTRE o menor e o maior do arquivo
EscolherHorarioEntreMinMax(horarios) {
    if (horarios.Length() = 0)
        return "02:00"

    minM := 999999
    maxM := -1

    for i, h in horarios {
        hh := SubStr(h, 1, 2) + 0
        mm := SubStr(h, 4, 2) + 0
        total := hh*60 + mm
        if (total < minM)
            minM := total
        if (total > maxM)
            maxM := total
    }

    if (maxM <= minM) {
        hh := Floor(minM/60)
        mm := Mod(minM, 60)
        return SubStr("0" hh, -1) ":" SubStr("0" mm, -1)
    }

    Random, sorteado, %minM%, %maxM%
    hh := Floor(sorteado/60)
    mm := Mod(sorteado, 60)
    return SubStr("0" hh, -1) ":" SubStr("0" mm, -1)
}

; =============================
; 1) PREPARAÇÃO DO NAVEGADOR
; =============================
if WinExist("ahk_exe " . EDGE_EXE)
{
    WinActivate, ahk_exe %EDGE_EXE%
    WinWaitActive, ahk_exe %EDGE_EXE%,, 5
}
else
{
    Run, "%EDGE_PATH%" %EDGE_PARAMS% --new-window --window-position=0,0 --window-size=800,600
    WinWait, ahk_exe %EDGE_EXE%,, 10
}

AjustarJanelaEdge()

; =============================
; 2) ETAPA 1: LINK PRINCIPAL
; =============================
AbrirNovaAba(LINK_PRINCIPAL)
Sleep, 5000
MouseMove, 400, 300, 0

coords := [[155, 222], [385, 222], [615, 222]]

ScrollDown(5)
Sleep, 1000
for i, pos in coords {
    MouseMove, % pos[1], % pos[2], 10
    Click
    Sleep, 3500
    Send, ^w
    Sleep, 800
    AjustarJanelaEdge()
}

ScrollDown(7)
Sleep, 1000
for i, pos in coords {
    ClicarEVerificarAba(pos[1], pos[2])
}

ScrollDown(4)
Sleep, 1000
for i, pos in coords {
    ClicarEVerificarAba(pos[1], pos[2])
}

ScrollDown(4)
Sleep, 1000
for i, pos in coords {
    ClicarEVerificarAba(pos[1], pos[2])
}

Send, ^w
Sleep, 500

; =============================
; 3) ETAPA 2: LINK QUESTÕES
; =============================
AbrirNovaAba(LINK_QUESTOES)

inicioWait := A_TickCount
Loop
{
    ImageSearch, x, y, 0, 0, 800, 600, *40 %IMAGENS%\QuestionsLoaded.png
    if (ErrorLevel = 0)
        break

    if (A_TickCount - inicioWait > 120000)
        Reload

    Sleep, 500
}

MouseMove, 400, 300, 0
ScrollDown(6)
Sleep, 1000

Loop, 35
{
    ImageSearch, cx, cy, 0, 0, 800, 600, *40 %IMAGENS%\CopyQuestion.png
    if (ErrorLevel = 0)
    {
        Click, %cx%, %cy%
        Sleep, 200
    }
    else
    {
        Send, {WheelDown}
        Sleep, 500
        continue
    }

    ImageSearch, gx, gy, 0, 0, 800, 600, *40 %IMAGENS%\GenerateQuestion.png
    if (ErrorLevel = 0)
    {
        Click, %gx%, %gy%
        Sleep, 200
    }

    Send, ^t
    Sleep, 500
    Send, ^v
    Sleep, 100
    Send, {Enter}
    Sleep, 6000
    Send, ^w
    Sleep, 500
    AjustarJanelaEdge()
}

; =============================
; 4) FINALIZAÇÃO
; =============================
Send, ^w
Sleep, 1000
Send, !{F4}
Sleep, 2000

; Atualiza NextActivation para amanhã, horário aleatório no intervalo
horarios := LerHorariosDisponiveis(AVAIL_FILE)
horarioEscolhido := EscolherHorarioEntreMinMax(horarios)

FormatTime, dataAmanha,, yyyyMMdd
EnvAdd, dataAmanha, 1, Days
novaData := SubStr(dataAmanha,1,4) "-" SubStr(dataAmanha,5,2) "-" SubStr(dataAmanha,7,2)

FileDelete, %NEXT_FILE%
FileAppend, % novaData " " horarioEscolhido, %NEXT_FILE%

; Volta ao TTD
if FileExist(LAUNCHER_PATH)
    Run, "%LAUNCHER_PATH%", %DIR_TTD%
else
    MsgBox, 16, Erro, Launcher não encontrado!`n%LAUNCHER_PATH%

ExitApp

Esc::ExitApp
