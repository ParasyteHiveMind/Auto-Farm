#NoEnv
#SingleInstance Force
#InstallMouseHook
#InstallKeybdHook
SetWorkingDir %A_ScriptDir%

global BASE_DIR := A_ScriptDir
global IMAGENS  := BASE_DIR . "\Imagens"
global GENERIC  := BASE_DIR . "\Generic"

global STOP_REQUESTED := false
global Estado := "VIGILIA"      ; VIGILIA | JOGANDO
global BotRodando := false

; =========================
; LÊ CONFIG.INI (AFK)
; =========================
global CONFIG_FILE := BASE_DIR . "\Config.ini"
global TempoAFK_MS := 600000 ; padrão 10 min

CarregarConfigAFK()

; =========================
; INCLUDES
; =========================
#Include Generic\FuncoesCentrais.ahk
#Include Generic\EsperandoPartidaIniciar.ahk
#Include Generic\ResetCharacter.ahk
#Include Generic\JoinPrivateServer.ahk
#Include Generic\MelhorarTorreMaisRecente.ahk
#Include Generic\PlaceTowerInArea.ahk
#Include Generic\Farmers3Upgrade.ahk
#Include %A_ScriptDir%\ModoAtual.ahk

; Timer APENAS para vigília/pause
SetTimer, VigiaAFK, 500
return

; ==========================================================
; Lê AfkMinutes do ini
; ==========================================================
CarregarConfigAFK() {
    global CONFIG_FILE, TempoAFK_MS

    if (!FileExist(CONFIG_FILE)) {
        TempoAFK_MS := 600000
        return
    }

    IniRead, afkMin, %CONFIG_FILE%, Bot, AfkMinutes, 10

    ; sanitiza
    afkMin := Trim(afkMin)
    if (afkMin = "" || afkMin <= 0)
        afkMin := 10

    TempoAFK_MS := afkMin * 60000
}

; ==========================================================
; VIGIA: decide iniciar ou pausar
; ==========================================================
VigiaAFK:
    ; Se usuário mexeu e bot estava jogando -> pausa
    if (A_TimeIdlePhysical < 1000) {
        if (Estado = "JOGANDO") {
            FazerPausa("Usuário mexeu no PC")
        }
        return
    }

    ; Se está em vigília e AFK atingiu -> inicia
    if (Estado = "VIGILIA") {
        if (A_TimeIdlePhysical >= TempoAFK_MS) {
            IniciarModoJogo()
        }
        return
    }
return

; ==========================================================
; INICIA BOT
; ==========================================================
IniciarModoJogo() {
    global Estado, STOP_REQUESTED, BotRodando
    Estado := "JOGANDO"
    STOP_REQUESTED := false

    if (BotRodando)
        return

    BotRodando := true
    SetTimer, BotLoopKick, -10
}

BotLoopKick:
    BotLoop()
return

; ==========================================================
; LOOP SERIAL DO BOT
; ==========================================================
BotLoop() {
    global Estado, BotRodando, RESTART_SOFT

    etapa := "JOIN"  ; JOIN -> IR -> WAIT -> PLAY

    Loop {
        if (Estado != "JOGANDO")
            break
        if (ShouldStop())
            break

        if (etapa = "JOIN") {
            r := JoinPrivateServer()
            if (r = "STOP")
                break
            if (r = "RESTART") {
                etapa := "JOIN"
                continue
            }
            etapa := "IR"
        }

        if (etapa = "IR") {
            r := IrAtePartida()
            if (r = "STOP")
                break
            if (r = "RESTART") {
                etapa := "JOIN"
                continue
            }
            etapa := "WAIT"
        }

        if (etapa = "WAIT") {
            r := EsperandoPartidaIniciar()
            if (r = "STOP")
                break
            if (r = "RESTART") {
                etapa := "JOIN"
                continue
            }
            RESTART_SOFT := false
            etapa := "PLAY"
        }

        if (etapa = "PLAY") {
            r := JogarPartida()

            if (r = "RESTART_SOFT") {
                RESTART_SOFT := false
                etapa := "WAIT"
                continue
            }
            if (r = "RESTART") {
                etapa := "JOIN"
                continue
            }
            if (r = "STOP")
                break

            ; OK/vazio: por segurança, espera próxima
            etapa := "WAIT"
        }
    }

    BotRodando := false
    return
}

; ==========================================================
; PAUSA
; ==========================================================
FazerPausa(Motivo) {
    global Estado, STOP_REQUESTED
    Estado := "VIGILIA"
    STOP_REQUESTED := true
    Process, Close, RobloxPlayerBeta.exe
}

; ==========================================================
; HOTKEY
; ==========================================================
F12::
    global STOP_REQUESTED
    STOP_REQUESTED := true
    Process, Close, RobloxPlayerBeta.exe
return
