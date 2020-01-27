#persistent
#NoEnv

; CapsLock
/*
vkF0sc03A::
  Send, {Return}
  Return,
  */

;vk1Dsc07B & k::
!1::
  WinActivate , ahk_exe Slack.exe
  /*
  If(ErrorLevel != 1){
    TrayTip, ahk.ahk, Slack window does exists?, 10, 2
  }
  */
  Return,

#z::Send,{Enter}

