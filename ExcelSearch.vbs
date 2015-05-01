Option Explicit

Dim dir, patterns, file
dir = "C:\cast\proj\nipmms"
patterns = Array("フロー", "加工")
file = ".\file.tsv"

''''''''''
Function searchByExcel(path)
	Dim ret, wbs, wss, ws, key, ur, hit, hit1stAddr
	Set wbs = excel.Workbooks.Open(path)
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
					v = Replace(hit, vbLF, vbCrLf)
					'WScript.Echo "hit:" & hit
					outfile.WriteLine path _
					&  vbTab & ws.Name _
					&  vbTab & hit.Row _
					&  vbTab & hit.Column _
					&  vbTab & key _
					&  vbTab & """" & v & """"
					Set hit = ur.FindNext(hit)
				Loop While Not hit Is Nothing And hit1stAddr <> hit.Address
			End If
		Next
	Next
	searchByExcel = ret
End Function

Function process(folder)
	Dim fc, f, sfc, sf, ret
	Set fc = folder.Files
	For Each f In fc
		If fso.GetExtensionName(f.Name) = "xls" _
		Or fso.GetExtensionName(f.Name) = "xlsx" Then
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
excel.Visible = False
excel.DisplayAlerts = False

outfile.WriteLine "ファイル名" _
	&  vbTab & "シート" _
	&  vbTab & "行" _
	&  vbTab & "列" _
	&  vbTab & "検索文字列" _
	&  vbTab & "セルの値"

ret = process(fso.GetFolder(dir))

outfile.Close
Set fso = Nothing
excel.Quit
Set excel = Nothing
WScript.Echo "done."
