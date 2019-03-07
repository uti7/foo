#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Recommended for catching common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
;SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include %A_ScriptDir%
#Include getopt.ahk

initial_dir := A_WorkingDir

_EDITOR := "c:\cast\app\gvim64\gvim.exe RE4EDITOR"
_FINALY_QF := "-q"
_FINALY_GF := "OUTFILE"

EnvGet, TEMP, TEMP

If(_argc_ < 1){
	show_usage()
	Return
}

tmgrProgress(0, 100)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; set option as default value
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

If(!_named_.HasKey("d")){
	;_named_["d"] := []
	;_named_["d"].Insert(initial_dir)
	_named_["d"] := [ initial_dir ]
}

If(!_unnamed_.MaxIndex()){
	_unnamed_.Insert("*.*")
}

If(!_named_.HasKey("a")){
	;_named_["a"].Insert(_unnamed_[1])
	If(_unnamed_.MaxIndex() > 1){
		_named_["a"] := [ _unnamed_[1] ]
		_unnamed_.Remove(1)
	}Else If(!_named_.HasKey("L") && _unnamed_[1] != "*.*"){
		show_usage("PATTERN nothing, guessed that filespec is " _unnamed_[1])
		Exit,
	}
}

If(!_named_.HasKey("fenc")){
	_named_["fenc"] := [ "UTF-8" ]
}
FileEncoding, % _named_["fenc"][1]

If(!_named_.HasKey("cf")){
	_named_["cf"] := [ "errors.err" ]
}
outfile := _named_["cf"][1]
FileDelete, % TEMP "\" outfile
FileDelete, % initial_dir "\" outfile

/*
stdout := FileOpen(DllCall("GetStdHandle", "int", -11, "ptr"), "h `n")
If(!IsObject(stdout)){
	Msgbox, cannot open stdout
}
*/

; make ignore path RE
ignore_path_re =
_named_["p"].Insert("\.svn\\")
_named_["p"].Insert("\.xlsx?$")
_named_["p"].Insert("\.dll$")
_named_["p"].Insert("\.exe$")
_named_["p"].Insert("\\obj\\")
_named_["p"].Insert("\\bin\\")
Loop, % _named_["p"].MaxIndex()
{
	ignore_path_re .= _named_["p"][A_Index] "|"
}
ignore_path_re := RegExReplace(ignore_path_re, "\|$", "")

OutputDebug, % "ignore_path_re: " ignore_path_re

include_path_re =
Loop, % _named_["q"].MaxIndex()
{
	include_path_re .= _named_["q"][A_Index] "|"
}
include_path_re := RegExReplace(include_path_re, "\|$", "")

OutputDebug, % "include_path_re: " include_path_re

total := getFileCount(_named_["d"], _unnamed_)
current := 0
OutputDebug, % "total: " total
/*
Try
	{
	*/
;;;;;;;;;;;;;;;;;;;;
; for each dirspec
;;;;;;;;;;;;;;;;;;;;
Loop, % _named_["d"].MaxIndex()
{
	SetWorkingDir, % initial_dir	; reset for the next relative path
	SetWorkingDir, % _named_["d"][A_Index]
	If(ErrorLevel){
		Msgbox, %  _named_["d"][A_Index] ":  cd failed."
		Continue
	}

	OutputDebug, % "dirspec: " A_Index ": " A_WorkingDir
	;;;;;;;;;;;;;;;;;;;;
	; for each filespec
	;;;;;;;;;;;;;;;;;;;;
	Loop, % _unnamed_.MaxIndex()
	{
		OutputDebug, % "filespec: " A_Index ": " _unnamed_[A_Index]
		;;;;;;;;;;;;;;;;;;;;
		; for each file
		;;;;;;;;;;;;;;;;;;;;
		Loop, % _unnamed_[A_Index],, 1
		{
			current++
			tmgrProgress(current, total)
			OutputDebug, % "TRYING: " current ": " A_LoopFileFullPath
			If(ignore_path_re != "" && RegExMatch(A_LoopFileFullPath, "i)" ignore_path_re)){
				Continue
			}
			If(include_path_re != "" && !RegExMatch(A_LoopFileFullPath, "i)" include_path_re)){
				Continue
			}
			If(_named_.HasKey("L")){
				; no grep
				OutputDebug, no grep for %A_LoopFileFullPath%
				;msgbox, % _named_["a"][1] "---" _unnamed_[1]

				OutputDebug, % "MATCHED(no grep): " A_LoopFileName " @ " _named_["a"][A_Index]
				outcf(A_LoopFileFullPath, 1 , A_LoopFileFullPath)
				Continue
			}
			;;;;;;;;;;;;;;;;;;;;
			; for each line
			;;;;;;;;;;;;;;;;;;;;
			isMatched := do_grep2(A_LoopFileFullPath)
		}
	}
}
/*
	}
Catch e
{
	MsgBox, % e
	stdout.Close()
	Return
}
*/
	;stdout.Close()
SetWorkingDir, % initial_dir	; reset for the next relative path
path_filtering()

tmgrProgress(2, 1)

If(isS(initial_dir "\" outfile)){
	If(_named_.HasKey("a")){
		_EDITOR := RegExReplace(_EDITOR, "RE4EDITOR", """+/" re4editor() "/""")
	}Else{
		_EDITOR := RegExReplace(_EDITOR, "RE4EDITOR", "")
	}
	If(_named_.HasKey("g")){
		_FINALY_GF := RegExReplace(_FINALY_GF, "OUTFILE", initial_dir "\" outfile)
		cmd = %_EDITOR% %_FINALY_GF%
	}Else{
		cmd = %_EDITOR% %_FINALY_QF%
	}

	native := TEMP "\" A_ScriptName ".bat"
	FileDelete, % native
	FileEncoding, UTF-8-RAW ;CP932

	FileAppend, cd /d %initial_dir%`r`n%cmd%, %native%
	RunWait, %native%,, Min
}Else{
	Msgbox, no matched.
}
Return
; end of main

;;;;;;;;;;;;;;;;;;;;;;
; functions and labels
;;;;;;;;;;;;;;;;;;;;;;

do_grep2(file)
{
	global TEMP, outfile, _named_
	FileRead, a, %file%
	StringSplit, b, a, `n, `r
	qf =
	is_matched_flags := []
	;;;;;;;;;;;;;;;;;;;;
	; for each lines
	;;;;;;;;;;;;;;;;;;;;
	Loop, % b0
	{
		;;;;;;;;;;;;;;;;;;;;
		; for each patterns
		;;;;;;;;;;;;;;;;;;;;
		lno := A_Index
		s := b%A_Index%
		Loop, % _named_["a"].MaxIndex()
		{
			re := _named_["a"][A_Index]
			If(!re){
				show_usage(A_Index "th PATTERN empty.")
				Exit,
			}
			;OutputDebug, % A_ThisFunc ":" re ":" A_Index
			If(is_matched(s, re)){
				is_matched_flags[A_Index] := TRUE
				qf .= outcf(file, lno, s, TRUE)
			}
		}
	}
	Loop, % _named_["a"].MaxIndex()
	{
		If(!is_matched_flags[A_Index]){
			Return, FALSE
		}
	}

	FileAppend, %qf%, %TEMP%\%outfile%
	Return, TRUE
}

is_matched(str, re)
{
	global _named_
	If(_named_.HasKey("i")){
		re := "i)" re
	}
	Return, % RegExMatch(str, re)
}

outcf(path, line, content, isReturned = FALSE)
{
	global TEMP, initial_dir, _named_
	global outfile
	If(_named_.HasKey("g")){
		s := A_WorkingDir "\" path "`r`n"
	}Else{
		s := A_WorkingDir "\" path "(" line ") : " content "`r`n"
	}

	If(isReturned){
		Return, % s
	}Else{
		FileAppend, %s%, %TEMP%\%outfile%
	}
	Return
}

path_filtering()
{
	global _named_, TEMP, initial_dir, outfile

	If(!_named_.HasKey("v")){
		FileMove, %TEMP%\%outfile%, %initial_dir%\%outfile%
		Return
	}

	Loop, Read, %TEMP%\%outfile%
	{
		path := RegExReplace(A_LoopReadLine, "^(.*):.*$", "$1")
		path := RegExReplace(path, "^(.*)\(\d+\)\s.*$", "$1")
		content :=RegExReplace(A_LoopReadLine, "^.*\(\d+\):(.*)$", "$1")
		OutputDebug, % A_ThisFunc ":" content
		is_skip := FALSE

		Loop, % _named_["v"].MaxIndex()
		{
			If(RegExMatch(content, _named_["v"][A_Index])){
				is_skip := TRUE
				Break
			}
		}
		if(is_skip){
			Continue
		}
		FileAppend, %A_LoopReadLine%`r`n, %initial_dir%\%outfile%
	}
	FileMove, %TEMP%\%outfile%, %initial_dir%\%outfile%
}

show_usage(appendix = "")
{
helpstr =
(
 %A_ScriptName% - file traverser
 
  Usage:
   %A_ScriptName% [OPTION] PATTERN [FILE...]
   %A_ScriptName% [OPTION] /a:PATTERN [/a:PATTERN...] [FILE...]
   %A_ScriptName% [OPTION] /L [FILE...]
 
  PATTERN`t: a regular expression
  FILE`t`t: file spec (e.g. *.txt)
 
  Option:
   /a:PATTERN`t`t: AND condition of them, do not matter whether there's in the same line.
   /i`t`t: ignore case
   /L`t`t: never grep (like find(1),  with /p /q )
   /g`t`t: output the file-list (usable gf jump, also use with /L)
   /p:PATTERN`t: exclude path by PATTERN (stronger than /q)
   /q:PATTERN`t: include path by PATTERN
   /v:PATTERN`t: invert filtering as PATTERN for content
   /cf:PATH`t: output quick fix (default: errors.err)
   /fenc:ENCODING`t : file encoding (default: UTF-8)

  Note:
    option char case ignored

)
	MsgBox, % helpstr "`r`n" appendix
}

re4editor()
{
	global _named_, TEMP
	r4e =
	Loop, % _named_["a"].MaxIndex()
	{
		; not escaped, then insert `n whitch instead of \
		a := RegExReplace(_named_["a"][A_Index], "^([)(+?|])",  "`n$1")
		a := RegExReplace(_named_["a"][A_Index], "([^\\])([)(+?|])",  "$1`n$2")
		; escaped, remove `\'
		a := RegExReplace(a,"\\([)(+?|])",  "$1")
		; cause inserted `n no escaped, replace it 
		a := RegExReplace(a,"\n([)(+?|])",  "\$1")
		r4e .= a
		If(A_Index < _named_["a"].MaxIndex()){
			r4e .= "\|"
		}
	}
	;msgbox, % r4e
	Return, r4e
}

getFileCount(dirs, filespecs)
{
  global TEMP
  dirspec_str =
  Loop, % dirs.MaxIndex()
  {
    dirspec_str .= dirs[A_Index] " "
  }
	findstr_re_str := filespec2findstrRe(filespecs)

  tmpfile := TEMP "\" A_ScriptName ".tmp"
  FileDelete, % tmpfile
  Run, cmd /c dir /s /b /a-d  %dirspec_str% | findstr /r %findstr_re_str% | find /c /v "" > %tmpfile% ,, Hide, pid

	tick := 0
	Process, Exist, %pid%
	While(ErrorLevel)
	{
		tick := (tick != 6) ? 3 : 6
		tmgrProgress(tick, 11)
		Sleep, 250
		Process, Exist, %pid%
	}
  FileRead, a, %tmpfile%
OutputDebug, % ErrorLevel ":" A_LastError
	a := RegExReplace(a, "\r?\n$", "")
  Return, %a%
}

tmgrProgress(current, total)
{
	;global
	n := Ceil((current / total) * 10)
  n += 3    
	OutputDebug, % A_ThisFunc ": " current "/" total " = " n
	If(n < 3 || n > 14){
		n := 1
	}
  Menu, TRAY, Icon, %A_WinDir%\system32\taskmgr.exe, %n%
  Return
}


#Include %A_ScriptDir%
#Include filetester.ahk
