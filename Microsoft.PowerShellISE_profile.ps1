#Requires -Version 3.0 
#C:\Users\__YOUR_ACCOUNT__\Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1

Function ll($p){
  Get-ChildItem -Path $p | Sort-Object LastWriteTime
}

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

Function tob64([string] $ipath, [string] $opath)
{
$b = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($ipath))
$ret = [System.IO.File]::WriteAllText($opath, $b, [System.Text.Encoding]::Default)
 return $ret
}
Function fromb64([string] $ipath, [string] $opath)
{
$b = [System.IO.File]::ReadAllText($ipath)
$ret = [System.IO.File]::WriteAllBytes($opath, [Convert]::FromBase64String($b))
}
