#Persistent
#NoEnv
#SingleInstance force
; #InstallMouseHook
max := 10 * 1000
Gui, Add, Progress, x0 y0 w240 h14 Range0-%max% CBlue v_pbar , 0
Gui, Add, StatusBar, v_status_bar
Gui, Show, h40 w240

SetTimer, showIdle, 1000

Return,

showIdle(){
	global max, _pbar
	cur := A_TimeIdle
	s := cur "/" max
	GuiControl,, _pbar, cur
	SB_SetText(s)
	If(_cur > max){
		IME_SET(0)
	}
}

IME_SET(setSts, WinTitle="")
;-----------------------------------------------------------
; IMEの状態をセット
;    対象： AHK v1.0.34以降
;   SetSts  : 1:ON 0:OFF
;   WinTitle: 対象Window (省略時:アクティブウィンドウ)
;   戻り値  1:ON 0:OFF
;-----------------------------------------------------------
{
    ifEqual WinTitle,,  SetEnv,WinTitle,A
    WinGet,hWnd,ID,%WinTitle%
    DefaultIMEWnd := DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hWnd, Uint)

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
