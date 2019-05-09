#Persistent
#NoEnv
#SingleInstance force
; #InstallMouseHook
Menu, TRAY, Add, &view, RESTORE_GUI
Menu, TRAY, Default, &view
SysGet, SM_CXSCREEN, 0
SysGet, SM_CYSCREEN, 1
SysGet, SM_CXSIZEFRAME, 32
SysGet, SM_CYSIZEFRAME, 33
SysGet, SM_CYSMCAPTION, 51
x := SM_CXSCREEN - SM_CXSIZEFRAME - 200
y := SM_CYSCREEN - SM_CYSIZEFRAME - SM_CYSMCAPTION - 40

timer_interval := 1000
total := 0
max := 5 * timer_interval
Gui, Add, Progress, x0 y0 w200 h14 Range0-%max% -Smooth v_pbar , 0
Gui, Add, StatusBar, v_status_bar
SB_SetParts(30, 60)
Gui, +ToolWindow
Gui, Show, h40 w200 x%x% y%y%, %A_ScriptName%
Gui, Minimize

is_set_once := FALSE
SetTimer, onTimer, 1000

Return,

RESTORE_GUI:
	Gui, Restore
	Return,

onTimer(){
	global max, _pbar, is_set_once, timer_interval, total
	idle := A_TimeIdle
	s := idle "/" max ":" total
	cur := Mod(idle, max)
  If(max - cur <= timer_interval){
    cur := max
  }

	colorI := Round(Mod(A_TickCount / 1000, 768))
  s .= "   " colorI
  SB_SetText(idle , 1, 1)
  SB_SetText("/" max ":" total, 2, 1)
  SB_SetText(colorI, 3, 1)

	SetFormat, Integer, H
	If(colorI >= 768){
		cR := 255
		cG := 255
		cB := 255
	}Else If(colorI > 512){
		cR := 255
		cG := 255
		cB := Mod(colorI, 256)
	}Else If(colorI > 256){
		cR := 255
		cG := Mod(colorI, 256)
		cB := 0
	}Else{
		cR := Mod(colorI, 256)
		cG := 0
		cB := 0
	}
	SetFormat, Integer, D
	cR := "00" RegExReplace(cR, "^0x", "")
	cG := "00" RegExReplace(cG, "^0x", "")
	cB := "00" RegExReplace(cB, "^0x", "")
	StringRight, cR, cR, 2
	StringRight, cG, cG, 2
	StringRight, cB, cB, 2

OutputDebug, %A_ThisFunc%: C%cR%%cG%%cB%
	GuiControl, +C%cR%%cG%%cB%, _pbar
	GuiControl, Text, _pbar, %cur%
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

#IfWinActive, ahk_class AutoHotkeyGUI
#F9::
    ListVars
  	Return
#IfWinActive
