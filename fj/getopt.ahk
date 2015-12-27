;;;;;;;;;;;;;;;;;;;;
;;; get opt generic
;;;
;;; command line usage:
;;; (its windows typical command style)
;;;  your_script.ahk /foo /bar:hoge /bar:hoge\hoge file1 file2 ...

_named_ := Object()		 ;; array of key value
_unnamed_ := Object()  ;; array

;;; to access:
;;; - check whether specified:
;;;    If(_named_.HasKey("opt")) { ... }
;;; - get value:
;;;   Loop, _named_["opt"].MaxIndex()
;;;   {
;;;       foo := _named_["opt"][A_Index]
;;;	  }
;;;;;;;;;;;;;;;;;;;;

_argc_ = %0%
Loop, % _argc_
{
	_argv_ := %A_Index%
	If(RegExMatch(_argv_, "^/(\w+)(:.*)?", $)){

		If(!_named_.HasKey($1)){
			_named_[$1] := []
		}

		If(StrLen($2)){
			_named_[$1].Insert(RegExReplace($2, "^:", ""))
		}Else{
			_named_[$1].Insert(TRUE)
		}
		;OutputDebug, % "stored opt: " $1 ": pos=" _named_[$1].MaxIndex() " val=" _named_[$1][_named_[$1].MaxIndex()]
	}Else{
		_unnamed_.Insert(_argv_)
	}
}

