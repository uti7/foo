#Requires -Version 3.0 

$mydir = (Split-Path $MyInvocation.MyCommand.Path -Resolve -Parent)
. $mydir\fj_source.ps1
$cmd = ("fj " + "-root_dir " + (Get-Location).Path + " " + ($args -join " ") + " -editor c:\cast\app\gvim64\gvim.exe")
Write-host -foregroundcolor green $cmd
Invoke-Expression -Command $cmd
