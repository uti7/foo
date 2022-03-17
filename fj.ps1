#Requires -Version 3.0 

<#
    usage: powershell -f .\fj.ps1 -pattern PATTERN -files FILES [-list_path] [-root_dir ROOT_DIR] [-no_list] [-open_by_editor | -show_only]

    ex.)
      similar to:

        $ find ... \( -name FILE -o -name FILE -o ... \) ... -print | xargs grep PATTERN
            > powershell -f .\fj.ps1 -p[attern] PATTERN -f[iles] "*.php,*.html,*.txt"

        $ find ... -name PATTERN \( -name FILE -o -name FILE \) -print
            > powershell -f .\fj.ps1 -l -p foo.*bar -f "*.xlsx,*.xls" 
#>        
$mydir = (Split-Path $MyInvocation.MyCommand.Path -Resolve -Parent)
. $mydir\fj_source.ps1
$cmd = ("fj " + "-root_dir " + (Get-Location).Path + " " + ($args -join " ") + " -editor c:\cast\app\gvim64\gvim.exe")
Write-host -foregroundcolor green $cmd
Invoke-Expression -Command $cmd
