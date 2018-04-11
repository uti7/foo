#Requires -Version 3.0 
#C:\Users\__YOUR_ACCOUNT__\Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1

Set-Alias -Name ll -Value Get-ChildItem | Sort-Object LastWriteTime

function foo {cd c:\foo}
function multiline { foo;  & 'C:\Program Files (x86)\AutoHotkey\AutoHotkey.exe' bar.ahk }
function vi($files){
c:\cast\app\gvim64\gvim.exe $files
} 

# same as operator that -split
# to use .ps1 file command line args who other shell (e.g. .bat file, bash prompt)
# > powershell.exe -f aaa.ps1 -f "*.html *.php"
Function str2arr([string] $s, [string] $delim = "\s+", [int] $max = 0)
{
    $a = @()
    $s -split $delim, $max | % {
        $i = $_ -replace "^\s+", ""
        $i = $i -replace "\s+$", ""
        if($i.length){
            $a += $i
        }
    }

    return $a
}

function invokeCom([string] $member, [array] $args){
	$c = New-Object -Comobject Fubar.COM
	$ret = $c.getType().InvokeMember($member,
		[Reflection.BindingFlags]::InvokeMethod, $null, $c, $args)
	return $ret
}
