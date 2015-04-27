Option Explicit
If WScript.Arguments.Count < 1 Then
	WScript.Echo "usage:" & vbCrLf _
	& "  コマンドプロンプトで:" & vbCrlf _
	& "  > cscript.exe ExcelReplace.vbs file.tsv" & vbCrLf _
	& "  または" & vbCrLf _
	& "  ファイルエクスプローラで この vbs に file.tsv をドロップします."
	WScript.Quit 2
End If

Dim fso, excel, ret, file
Set fso = CreateObject("Scripting.FileSystemObject")
Set file = fso.OpenTextFile(WScript.Arguments(0), 1, False)
file.SkipLine
Set excel = CreateObject("Excel.Application")
excel.Visible = True
excel.DisplayAlerts = False

Dim buf, isItemEnd, xlsname, sheetname, row, column, key, val, currentxls, wbs

Do While Not file.AtEndOfStream
	Dim s, f
	s = file.ReadLine
	If(s <> "") Then
		f = Split(s, vbTab)
		If UBound(f) = 5 Then
			xlsname = f(0)
			sheetname = f(1)
			row = f(2)
			column = f(3)
			key= f(4)
			val = f(5)
		Else
			val = s
		End If
	Else
		val = s
	End If

	If Left(val, 1) = """" And Right(val, 1) = """" Then
		buf = val
		isItemEnd = True
	ElseIf Right(val, 1) = """" Then
		buf = buf & val & vbCrLf
		isItemEnd = True
	Else
		isItemEnd = False
		buf = buf & val & vbCrLf
	End If

	If isItemEnd Then
		Dim i
		i = InStrRev(buf, vbCrLf)
		If i > 0 Then
			buf = Mid(buf, 1, i - 1)
		End If
		WScript.Echo xlsname & ":" & sheetname & ":" & row & "," & column & key & ":" & buf ' & ": instrrev=" & InStrRev(buf, vbCrLf) & "? len=" & Len(buf) & vbCrlf
Stop
		If currentxls <> xlsname Then
			If currentxls <> "" And TypeName(wbs) = "Workbook" Then
				wbs.Save
				wbs.Close
			End If
			Set wbs = excel.Workbooks.Open(xlsname)
			currentxls = xlsname
		End If
		Dim ws
		Set ws = wbs.Worksheets(sheetname)
		ws.Cells(row, column).Value = buf
		buf = ""
	End If
Loop

If TypeName(wbs) = "Workbook" Then
	wbs.Save
	wbs.Close
	Set wbs = Nothing
End If
file.Close
Set fso = Nothing
excel.Quit
Set excel = Nothing
WScript.Echo "done."
