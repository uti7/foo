cd ~

$env:Path = "c:\Program Files\PostgreSQL\12\bin;$env:Path"
$env:PSQL_EDITOR = "C:\cast\app\gvim64\vim.exe"
$env:PSQLRC="${env:HOMEDRIVE}${env:HOMEPATH}\.psqlrc"
$env:WSLROOT="\\wsl$\Ubuntu-20.04"

. c:\cast\app\bin\fj_source.ps1

Function ll($p){
  Get-ChildItem -Path $p | Sort-Object -Property LastWriteTime
}
set-alias l ll

function coldspa {cd c:\cast\proj\coldspa\v3}
function ahk { coldspa;  & 'C:\Program Files (x86)\AutoHotkey\AutoHotkey.exe' coldspa3.ahk }

Function gvim {
  $files_str =@("--")
  $args|%{Resolve-Path $_ -ea SilentlyContinue |Out-Null; $files_str += if(!$?){ $_ } else{ (Resolve-Path $_).Path -replace '^Microsoft.PowerShell.Core\\FileSystem::', '' }}
  Start-Process -FilePath "c:\cast\app\gvim64\gvim.exe" -ArgumentList $files_str
  "["+$files_str+"]"
}
Function vim {
  $files_str =@("--")
  $args|%{Resolve-Path $_ -ea SilentlyContinue |Out-Null; $files_str += if(!$?){ $_ } else{ (Resolve-Path $_).Path -replace '^Microsoft.PowerShell.Core\\FileSystem::', '' }}
  & "c:\cast\app\gvim64\vim.exe" $files_str
  "["+$files_str+"]"
}
Set-Alias vi vim

Function gvimdiff {
  $files_str = @("-c `":se columns=160`" -d")
  $args|%{Resolve-Path $_ -ea SilentlyContinue |Out-Null; $files_str += if(!$?){ $_ } else{ (Resolve-Path $_).Path -replace '^Microsoft.PowerShell.Core\\FileSystem::', '' }}
  Start-Process -FilePath "c:\cast\app\gvim64\gvim.exe" -ArgumentList $files_str
  "["+$files_str+"]"
}

Function vimdiff {
  $files_str = @("-d")
  $args|%{Resolve-Path $_ -ea SilentlyContinue |Out-Null; $files_str += if(!$?){ $_ } else{ (Resolve-Path $_).Path -replace '^Microsoft.PowerShell.Core\\FileSystem::', '' }}
  & "c:\cast\app\gvim64\vim.exe" $files_str
  "["+$files_str+"]"
}

Function git {
  # used for reference
  & "c:\msys64\usr\bin\git.exe" $args
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
    $b = [Convert]::ToBase64String($a)
  }else{
    $a = $in
    $b = [Convert]::ToBase64String([Byte[]][System.Text.Encoding]::Default.GetBytes($a))
  }

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

Function hh()
{
  Param(
    [string] $pattern = ".",
    [switch] $run_latest = $false
  )
  $id = $null; $cl = $null
  Get-History | ? { !($_.CommandLine -match '^hh') -and $_.CommandLine -match $pattern } | % { $id = $_.Id; $cl = $_.CommandLine; $_ }
  if($run_latest){
    if($id -ne $null){
      Write-Host -ForegroundColor Yellow "$id`t$cl"
      Invoke-History -Id $id
    }
  }
}

Function msys-bash
{
  # One or both of the following arguments must be provided.
  Param(
    [Parameter(Mandatory=$false, HelpMessage="the Windows path notation for the script file that will be executed.")]
    [string]$run_script = $null,
    [Parameter(Mandatory=$false, HelpMessage="command line in bash")]
    [string]$command_line = $null
  )
  ($PWD -replace "^([a-z]):\\", '/$1/') -replace "\\", '/' | Set-Variable swd
  if($run_script -ne $null){
    $no_sepa = $run_script -split '\\'
    if($no_sepa[0] -match "^[A-Z]:$"){
      $no_sepa[0] = ("/mnt/" + ($no_sepa[0].ToLower() -replace ":", ''))
    }
    $msys_path = $no_sepa -join '/'
    $do_this = ($msys_path + ' ')
  }
  elseif($command_line -eq $null){ # -and $run_script -eq $null
    Write-Error "usage: msys-path WIN_PATH_SPEC_SCRIPT_FILE [ARGS...]`n       msys-path BASH_COMMAND_LINE"
    return
  }
  $do_this += $command_line
  & C:\msys64\usr\bin\env.exe -C "$PWD" -- MSYS=enable_pcon MSYSTEM=MSYS _SWD="$swd" /bin/bash --login -c "pushd $swd 1>/dev/null; $do_this"
  # see $LASTEXITCODE
}

Function wsl-bash
{
  # One or both of the following arguments must be provided.
  Param(
    [Parameter(Mandatory=$false, HelpMessage="the Windows path notation for the script file that will be executed.")]
    [string]$run_script = $null,
    [Parameter(Mandatory=$false, HelpMessage="command line in bash")]
    [string]$command_line = $null
  )
  if($run_script -ne $null){
    $no_sepa = $run_script -split '\\'
    if($no_sepa[0] -match "^[A-Z]:$"){
      $no_sepa[0] = ("/mnt/" + ($no_sepa[0].ToLower() -replace ":", ''))
    }
    $msys_path = $no_sepa -join '/'
    $do_this = ($msys_path + ' ')
  }
  elseif($command_line -eq $null){ # -and $run_script -eq $null
    Write-Error "usage: msys-path WIN_PATH_SPEC_SCRIPT_FILE [ARGS...]`n       msys-path BASH_COMMAND_LINE"
    return
  }
  $do_this += $command_line
  & wsl.exe --distribution Ubuntu-20.04 --user wsl2u --cd $PWD --exec bash -c "$do_this"
  # see $LASTEXITCODE
}
