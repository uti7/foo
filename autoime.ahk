#Persistent
#NoEnv
#SingleInstance force
; #InstallMouseHook
Menu, TRAY, Add, &view, RESTORE_GUI
Menu, TRAY, Default, &view
max := 10 * 1000
Gui, Add, Progress, x0 y0 w240 h14 Range0-%max% CBlue v_pbar , 0
Gui, Add, StatusBar, v_status_bar
Gui, +ToolWindow
Gui, Show, h40 w240, %A_ScriptName%
Gui, Minimize

is_set_once := FALSE
SetTimer, showIdle, 1000

Return,

RESTORE_GUI:
	Gui, Restore
	Return,

showIdle(){
	global max, _pbar, is_set_once
	cur := A_TimeIdle
	s := cur "/" max
	GuiControl, Text, _pbar, %cur%
	SB_SetText(s)
	If(cur > max){
		If(!is_set_once){
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
