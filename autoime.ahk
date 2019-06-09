#Persistent
#NoEnv
#SingleInstance force
; #InstallMouseHook

/*
; capslock pressed, then enter
vkF0sc03A::
  Send, {Return}
  Return,
*/

timer_interval := 1000
max := 3 * timer_interval

Menu, TRAY, Add, &view, RESTORE_GUI
Menu, TRAY, Default, &view
SysGet, SM_CXSCREEN, 0
SysGet, SM_CYSCREEN, 1
SysGet, SM_CYCAPTION, 4
SysGet, SM_CXSIZEFRAME, 32
SysGet, SM_CYSIZEFRAME, 33
SysGet, SM_CYSMCAPTION, 51
x := SM_CXSCREEN - SM_CXSIZEFRAME - 200
y := SM_CYSCREEN - SM_CYSIZEFRAME - SM_CYSMCAPTION - 40 - 36

total := 0
is_not_reset := FALSE
start_tick := 0

Gui, Add, Progress, x0 y0 w200 h14 Range0-%max% -Smooth v_pbar , 0
Gui, Add, StatusBar, v_status_bar g_SB_CLICK
SB_SetParts(60, 60)
Gui, +ToolWindow
Gui, Show, h40 w200 x%x% y%y%, %A_ScriptName%
Gui, Minimize

is_set_once := FALSE
SetTimer, ON_TIMER, %timer_interval%

Return,

#z::
  Gosub, RESTORE_GUI
  Gosub, _SB_CLICK
  Return,

_SB_CLICK:
  If(is_not_reset){
    ; stop
    SetTimer, ON_TIMER, Off
    is_not_reset := FALSE
    timer_interval := 1000
    max := 3 * timer_interval
    Gosub, ON_TIMER
    SetTimer, ON_TIMER, %timer_interval%
    WinActivate ahk_exe chrome.exe
  }Else{
    ; start
    reach_times := 0
    SetTimer, ON_TIMER, Off
    WinActivate ahk_class ConsoleWindowClass
    is_not_reset := TRUE
    start_tick := A_TickCount
    SB_SetText(0.000 , 1, 1)
    SB_SetText("timer mode", 3, 1)
    timer_interval := 100
    max := 600 * timer_interval
    SetTimer, ON_TIMER, %timer_interval%
  }
  Return,

RESTORE_GUI:
	Gui, Restore
  WinActivate, ahk_class AutoHotkeyGUI
	Return,

ON_TIMER:
  onTimer()
  Return,

onTimer(){
	global max, _pbar, is_set_once, timer_interval, total, is_not_reset, start_tick, reach_times
  If(!is_not_reset){
    idle := A_TimeIdle
    cur := Mod(idle, max)
  }Else{
    cur := Mod((A_TickCount - start_tick), max)
  }
  If(max - cur <= timer_interval){
    cur := max
    reach_times++
  }

	SetFormat, Integer, H
	colorI :="000000" regexreplace(Mod(Round(A_TickCount/1000),0xffffff),"^0x","")
	StringRight, colorI, colorI, 6
	SetFormat, Integer, D

  If(!is_not_reset){
    display_sec := idle/1000
  }Else{
    display_sec := cur / 1000
  }
  display_sec := RegExReplace(display_sec, "\d{3}$", "")

  SB_SetText(display_sec , 1, 1)
  If(!is_not_reset){
    SB_SetText(colorI, 3, 1)
    SB_SetText("/" max ":" total, 2, 1)
  }Else{
    SB_SetText("timer mode", 3, 1)
    SB_SetText("/" max ":" reach_times, 2, 1)
  }

	GuiControl, +C%colorI% Range0-%max%, _pbar
	GuiControl, Text, _pbar, %cur%
	If(!is_not_reset){
    If(idle > max){
      If(!is_set_once){
        total++
        WinGet, wh, List, , , A_ScriptName,
        OutputDebug, % A_ThisFunc ":" wh
        Loop, %wh%
        {
          hWnd := wh%A_Index%
          IME_SET(0, "", hWnd)
        }
        is_set_once := TRUE
      }
    }Else{
      is_set_once := FALSE
    }
	}
}

IME_SET(setSts, WinTitle="", hWnd = 0)
;-----------------------------------------------------------
; IMEの状態をセット
;    対象： AHK v1.0.34以降
;   SetSts  : 1:ON 0:OFF
;   WinTitle: 対象Window (どちらも省略時:アクティブウィンドウ)
;   hWnd: 対象Window (どちらも省略時:アクティブウィンドウ)
;   戻り値  1:ON 0:OFF
;-----------------------------------------------------------
{
		If(!hWnd){
			ifEqual WinTitle,,  SetEnv,WinTitle,A
			WinGet,hWnd,ID,%WinTitle%
		}
    DefaultIMEWnd := DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hWnd, Uint)
;OutputDebug, % A_ThisFunc ":hwnd=" hWnd ", imeWnd=" DefaultIMEWnd

    ;Message : WM_IME_CONTROL  wParam:IMC_SETOPENSTATUS
    DetectSave := A_DetectHiddenWindows
    DetectHiddenWindows,ON
    SendMessage 0x283, 0x006,setSts,,ahk_id %DefaultIMEWnd%
    DetectHiddenWindows,%DetectSave%
    Return ErrorLevel
}

GuiEscape:
GuiClose:
  ExitApp, 0

NumLock::
  Send, {BS}
  Return,

#IfWinActive, ahk_class AutoHotkeyGUI
#F9::
    ListVars
  	Return
#IfWinActive
