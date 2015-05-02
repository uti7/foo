Option Explicit

Dim dir, patterns, file
dir = "C:\cast\proj\nipmms"
patterns = Array("加工","所有者")
file = ".\file.tsv"

Const UpdateLinksNone = 0

' usage : cscript.exe this.vbs [/d:dir] [/o:file] [pattern...]
Dim args, i
Set args = WScript.Arguments
If args.Named.Exists("d") Then
	dir = args.Named.Item("d")
End If
If args.Named.Exists("o") Then
	file = args.Named.Item("o")
End If
If args.Unnamed.Count > 0 Then
	ReDim patterns(args.Unnamed.Count - 1)
	For i = 0 To  args.Unnamed.Count - 1
		patterns(i) = args.Unnamed.Item(i)
	Next
End If

''''''''''
Function searchByExcel(path)
	Dim ret, wbs, wss, ws, key, ur, hit, hit1stAddr
	Set wbs = excel.Workbooks.Open(path, UpdateLinksNone)
	'WScript.Echo wbs.Name & ":"
	Set wss = wbs.Worksheets
	For Each ws In wss
		'WScript.Echo ws.Name
		Set ur = ws.usedRange
		For Each key In patterns

			Set hit = ur.find(key)
			If Not hit Is Nothing Then
				hit1stAddr = hit.Address
				Do
					Dim v
					v = Replace(hit, vbLf, vbCrLf)
					'WScript.Echo "hit:" & hit
					Set outfile = fso.OpenTextFile(file, 8, True)
					outfile.WriteLine path _
					&  vbTab & ws.Name _
					&  vbTab & hit.Row _
					&  vbTab & hit.Column _
					&  vbTab & key _
					&  vbTab & """" & v & """"
					outfile.Close
					Set hit = ur.FindNext(hit)
				Loop While Not hit Is Nothing And hit1stAddr <> hit.Address
			End If
		Next
	Next
	wbs.Close
	searchByExcel = ret
End Function

Function process(folder)
	Dim fc, f, sfc, sf, ret
	Set fc = folder.Files
	For Each f In fc
		If ( fso.GetExtensionName(f.Name) = "xls" _
		Or fso.GetExtensionName(f.Name) = "xlsx" ) _
		And InStr(1, f.Name, "~$") <> 1 Then
			ret = ret & searchByExcel(f.Path)
		End If
	Next

	Set sfc = folder.SubFolders
	For Each sf In sfc
		ret = ret & process(sf)
	Next
	process = ret
End Function

''''''''''
Dim fso, outfile, excel, ret
Set fso = CreateObject("Scripting.FileSystemObject")
Set outfile = fso.OpenTextFile(file, 2, True)
Set excel = CreateObject("Excel.Application")
excel.Visible = True
excel.DisplayAlerts = False

outfile.WriteLine "ファイル名" _
	&  vbTab & "シート" _
	&  vbTab & "行" _
	&  vbTab & "列" _
	&  vbTab & "検索文字列" _
	&  vbTab & "セルの値"
outfile.Close

ret = process(fso.GetFolder(dir))

outfile.Close
Set fso = Nothing
excel.Quit
Set excel = Nothing
WScript.Echo "done."
