/*
FileEncoding, 
CP0		ANSI (デフォルト)
CP932		日本語シフトJIS。日本語Windowsではこれがデフォルト。
CP50220		日本語JIS。iso-2022-jp。電子メールでよく使われる形式。
CP51932		日本語EUC。Linux系でよく使われる形式(最近はUTF-8が多い)。
ただしこれを指定しても無効で読み書き出来ない
CP1200	UTF-16	UTF-16 LE
いわゆるUnicode。
メモ帳やIEでUnicodeと表記されているのはこれ。
CP1201		UTF-16 BE
CP65000		UTF-7
CP65001	UTF-8	UTF-8
UTF-8 RAW	UTF-8のBOMなし版。
新規作成時のみBOMなしのファイルが作られる。
UTF-16 RAW	UTF-16 LEのBOMなし版。
新規作成時のみBOMなしのファイルが作られる。
*/

isF(path)
{
	Return, % isExists(path)
}
isD(path)
{
	Return, % RegExMatch(getFileAttibutes(path), "^.*D.*$")
}

isR(path)
{
	Return, % RegExMatch(getFileAttibutes(path), "^.*R.*$")
}
isExists(path){
	Return, % (StrLen(getFileAttibutes(path)) > 0) ? 1 : 0
}
	
isS(path)
{
	If(!isF(path)){
		Return, 0
	}
	FileGetSize, o, % path
	Return, % o ; (o > 0)
}
getFileAttibutes(path){
	FileGetAttrib, o, % path
	Return, o
}

basename(path)
{
	SplitPath, path , OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
	Return, OutFileName
}

dirname(path)
{
	path := RegExReplace(path, "\\$", "")
	SplitPath, path , OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
	Return, OutDir
}

fput(path, buf, fenc = "UTF-8")
{
	FileDelete, % path
	FileAppend, %buf%, %path%, %fenc%
	Return, ErrorLevel
}

fappend(path, buf, fenc = "UTF-8")
{
	FileAppend, %buf%, %path%, %fenc%
	Return, ErrorLevel
}

fget(path, fenc = "UTF-8")
{
	FileRead, buf, %path%
	Return, % buf
}

filespec2re(specs)
{
  r:= "("
  Loop, % specs.MaxIndex()
  {
    a := specs[A_Index]
    ;OutputDebug, % RegExMatch(specs[A_Index], "\.")
    a := RegExReplace(a, "\.", "\.")
    a := RegExReplace(a, "\*", ".*")
    a := RegExReplace(a, "\?", ".")
    r.= a "|"
  }
  r:= RegExReplace(r, "\|$", ")$")
  Return, % r
}

filespec2findstrRe(specs)
{
  r:= ""
  Loop, % specs.MaxIndex()
  {
    a := "/c:""" specs[A_Index] "$"""
    ;OutputDebug, % RegExMatch(specs[A_Index], "\.")
    a := RegExReplace(a, "\.", "\.")
    a := RegExReplace(a, "\*", ".*")
    a := RegExReplace(a, "\?", ".")
    r.= a " "
  }
  
  Return, % r
}
