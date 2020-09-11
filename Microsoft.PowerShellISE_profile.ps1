cd ~

Function ll($p){
  Get-ChildItem -Path $p | Sort-Object -Property LastWriteTime
}
set-alias l ll

function coldspa {cd c:\cast\proj\coldspa\v3}
function ahk { coldspa;  & 'C:\Program Files (x86)\AutoHotkey\AutoHotkey.exe' coldspa3.ahk }

Function vi($files){
  $files_str =@("--")
  if($files){ (Resolve-Path $files) | % { $files_str += ($_.Path -replace '^Microsoft.PowerShell.Core\\FileSystem::', '') }}
  Start-Process -FilePath "c:\cast\app\gvim64\gvim.exe" -ArgumentList $files_str;
  "["+$files_str+"]"
}
Set-Alias vim vi
Set-Alias gvim vi
Function vimdiff($files){
  $files_str = @("-d")
  if($files){ (Resolve-Path $files) | % { $files_str += ($_.Path -replace '^Microsoft.PowerShell.Core\\FileSystem::', '') }} else { $files_str = "--" }
  Start-Process -FilePath "c:\cast\app\gvim64\gvim.exe" -ArgumentList $files_str;
  "["+$files_str+"]"
}

function gzbvi(){
  
  
  if((Get-Location).Path -ne "C:\cast\gba"){
    Set-Location c:\cast\gba
    Write-Host -ForegroundColor Cyan (Get-Location)
  }
  c:\cast\app\bin\gzbvi.ps1 -file '.\MagicalVacation2.sgm' -format '.\MagicalVacation.b2t'
}

function gzb2b(){
  
  if((Get-Location).Path -ne "C:\cast\gba"){
    Set-Location c:\cast\gba
    Write-Host -ForegroundColor Cyan (Get-Location)
  }
  c:\cast\app\bin\gzb2b.ps1 -file '.\MagicalVacation2.sgm' -override '.\MagicalVacation.b2b'
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

function invCsCom([string] $member, [array] $args){
	$c = New-Object -Comobject ColdSpa.COM
	$ret = $c.getType().InvokeMember($member,
		[Reflection.BindingFlags]::InvokeMethod, $null, $c, $args)
	return $ret
}

Function tob64()
{
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]$in,
    [string]$opath = ""
  )

  $f = $null
  if(Test-Path $in){
    $f = (Resolve-Path $in)
  }
  if($f -ne $null -and $f.GetType().Name -eq "PathInfo"){
    $a = [System.IO.File]::ReadAllBytes($f.Path)
  }else{
    $a = $in
  }
  $b = [Convert]::ToBase64String([Byte[]][System.Text.Encoding]::Default.GetBytes($a))

  if($opath -ne ""){
    $ret = [System.IO.File]::WriteAllText($opath, $b, [System.Text.Encoding]::Default)
  }else{
    $ret = $b
  }
  return $ret
}

Function fromb64()
{
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]$in,
    [string]$opath = ""
  )

  $f = $null
  try{
    if(Test-Path $in){
        $f = (Resolve-Path $in)
        $b = [System.IO.File]::ReadAllText($f.Path)
    }else{
        $b = $in
    } 
  }catch [Exception]{
    $b = $in
  }
  $a = [Convert]::FromBase64String($b)
 

  if($opath -ne ""){
    <#
        $b = $a -split ' '
        $c = [byte[]]@()
        $b | % {
            $c += [byte]$_
        }
    #>
    $ret = [System.IO.File]::WriteAllBytes($opath, $a)
  }else{
    $ret =[System.Text.Encoding]::Default.GetString($a)
  }
  return $ret
}
