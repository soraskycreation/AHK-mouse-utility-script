#Requires AutoHotkey v2.0
#SingleInstance Force
ProcessSetPriority "High"

; Global flag to block native mouse clicks during Layer 2
global Layer2Active := false

; =========================================================================
; 🔍 DYNAMIC ZOOM LAYER
; While holding the Forward Button (XButton2), your Delete button acts as Ctrl.
; This allows you to hold both down and use the normal scroll wheel to zoom!
; =========================================================================
#HotIf GetKeyState("XButton2", "P")

*Delete::Send "{Blind}{Ctrl DownR}"
*Delete Up::Send "{Blind}{Ctrl Up}"

#HotIf ; Reset context sensitivity


; 🚫 SUPPRESS & REMAP CLICKS DURING LAYER 2
; This handles remapping while you are actively inside the Tap-Hold Arrow layer.
#HotIf Layer2Active

; 1. Left Click -> Acts strictly as Shift for highlighting (blocks native click)
*LButton:: {
    if !GetKeyState("Shift")
        Send "{Shift Down}"
}
*LButton Up:: {
    Send "{Shift Up}"
}

; 2. Right Click -> Acts strictly as Ctrl+Z Undo (blocks native right click)
*RButton:: {
    Send "^z"
}
#HotIf


XButton2::
{
    global Layer2Active

    ; Check if this is the SECOND click of a tap-dance sequence
    ; (Waiting 200ms for a second click to start)
    if (A_PriorHotkey = "XButton2" && A_TimeSincePriorHotkey < 200)
    {
        ; 🏹 LAYER 2: TAP -> HOLD -> ARROW KEYS (With Left-Click Shift and Right-Click Undo)
        Layer2Active := true ; Activate the click override blocks
        CoordMode "Mouse", "Screen"
        MouseGetPos &OriginalX, &OriginalY
        
        While GetKeyState("XButton2", "P")
        {
            ; Safety fallback loop state verification for shift selection
            if GetKeyState("LButton", "P") {
                if !GetKeyState("Shift")
                    Send "{Shift Down}"
            } else {
                if GetKeyState("Shift")
                    Send "{Shift Up}"
            }

            MouseGetPos &CurrentX, &CurrentY
            DeltaX := CurrentX - OriginalX
            DeltaY := CurrentY - OriginalY
            
            ; Only handle movement if we cross the baseline threshold
            if (Abs(DeltaX) > 15 || Abs(DeltaY) > 15)
            {
                ; 📐 ANGLE TEST: Check if movement is distinctly VERTICAL
                if (Abs(DeltaY) > Abs(DeltaX)) 
                {
                    ; ↕️ Vertical Arrow Keys
                    If (DeltaY > 25) {
                        Send "{Down}"
                        DllCall("SetCursorPos", "int", OriginalX, "int", OriginalY)
                        Sleep 80 ; Repeat rate for holding down
                    } Else If (DeltaY < -25) {
                        Send "{Up}"
                        DllCall("SetCursorPos", "int", OriginalX, "int", OriginalY)
                        Sleep 80
                    }
                } 
                ; 📐 ANGLE TEST: Movement is distinctly HORIZONTAL (Safe from vertical wobble)
                else 
                {
                    ; ↔️ Horizontal Arrow Keys
                    If (DeltaX > 25) {
                        Send "{Right}"
                        DllCall("SetCursorPos", "int", OriginalX, "int", OriginalY)
                        Sleep 80
                    } Else If (DeltaX < -15) {
                        Send "{Left}"
                        DllCall("SetCursorPos", "int", OriginalX, "int", OriginalY)
                        Sleep 80
                    }
                }
            }
            Sleep 10
        }
        
        ; 🧼 CLEANUP: Reset variables and release modifiers when exiting Layer 2
        Layer2Active := false
        if GetKeyState("Shift")
            Send "{Shift Up}"
        return
    }

    ; 📜 LAYER 1: FIRST PRESS / STRAIGHT HOLD -> SCROLL (Balanced Speed)
    ; Wait 180ms to see if you release it (testing for a tap vs hold)
    if !KeyWait("XButton2", "T0.180")
    {
        CoordMode "Mouse", "Screen"
        MouseGetPos &OriginalX, &OriginalY
        
        While GetKeyState("XButton2", "P")
        {
            MouseGetPos &CurrentX, &CurrentY
            DeltaX := CurrentX - OriginalX
            DeltaY := CurrentY - OriginalY
            
            ; ↕️ Vertical Continuous Scrolling (Accelerated 3x)
            If (DeltaY > 15) {
                Loop 3
                    Click "WheelDown"
                DllCall("SetCursorPos", "int", OriginalX, "int", OriginalY)
            } Else If (DeltaY < -15) {
                Loop 3
                    Click "WheelUp"
                DllCall("SetCursorPos", "int", OriginalX, "int", OriginalY)
            }
            
            ; ↔️ Horizontal Continuous Scrolling (Precision Controlled)
            If (DeltaX > 15) {
                Click "WheelRight"
                DllCall("SetCursorPos", "int", OriginalX, "int", OriginalY)
                Sleep 30 ; Throttles horizontal speed down
            } Else If (DeltaX < -15) {
                Click "WheelLeft"
                DllCall("SetCursorPos", "int", OriginalX, "int", OriginalY)
                Sleep 30 ; Throttles horizontal speed down
            }
            Sleep 15
        }
        return
    }
}

; --- Keyboard Layout & System Mappings ---

global lastSpaceTime := 0
global isLayerActive := false

sc070::Send("{vkF3}")       ; sc070 (Katakana/Hiragana) -> vkF3 (Hankaku/Zenkaku)

; --- Notepad Launcher ---
<#+F23::
{
    if WinExist("ahk_exe notepad.exe")
        WinActivate "ahk_exe notepad.exe"
    else
        Run "notepad.exe"
}
