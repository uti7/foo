#Requires -Version 3.0
<#
 Purpose:
 gvim colon line exection for external command 
   i.e (in gvim) :!start.ps <target>
   <target> : the same what ShellExecute(win32api), Process.Start(.net), start(cmd.exe) 
 Prepare:
   _gvimrc:
       set shell=poweshell
#>
<#
Param(
[string] $encoding = "oem",
[string] $target = ".\"
)
#>
$target = $args[0]

Set-PSDebug -strict

$myname = Split-Path $MyInvocation.MyCommand.Path -Leaf
#$mydir = Split-Path $MyInvocation.MyCommand.Path -Parent

# there's no need, use "set shell=poweshell" instead
<#
Function getParentProcessID([int] $_pid, [string]$pname = $false)
{
    $ret = $null
    Get-WmiObject Win32_Process| ?{
        ($pname -eq $false -and $_.ProcessID -eq $_pid) `
        -or ($_.ProcessName -eq $pname -and $_.ProcessId -eq $_pid)
     } `
    |%{
        [string]$_.ParentProcessId + ":" + [string]$_.ProcessName | Write-Host -ForegroundColor Yellow
        $ret = $_.ParentProcessId
        
    }
    return $ret
}


Function killParentCmdProcess()
{
 
    $ps1pid = getParentProcessID $PID 
    if($ps1pid -ne $null){
        $ppid = getParentProcessID $ps1pid "cmd.exe"
        
        if($ppid){
            write-host -ForegroundColor Magenta $ppid
            Stop-Process -id $ppid -Force
        }
    }
}
#>

# -------- main -------
try{
<#
    $targetStrSaved = ($env:TEMP + "\startpath.tmp")
    Write-Host -ForegroundColor Cyan $target
    $target |Out-File -FilePath $targetStrSaved -Encoding utf8
    Get-Content -Path $targetStrSaved  | Set-Variable utarget
#>
    $utarget = $target
    Write-Host -ForegroundColor Yellow $utarget
    [System.Diagnostics.Process]::Start($utarget)

}catch [Exception]{
    if($true){
        write $_.Exception
    }else{
        $e = $_.Exception
        [void](New-Object -ComObject wscript.shell).popup($e,30,$myname,48)
    }
    exit 1
}

Set-PSDebug -Off
exit 0
