#Requires -Version 3.0 
<#
    usage:
      ex. 1) on powershell console
        PS> . .\this.ps1
        PS> fj -pattern PATTERN -files FILES [-list_path] [-root_dir ROOT_DIR] [-no_list] [-open_by_editor | -show_only]

      ex. 2) on cmd prompt
        CMD> powershell.exe -F .\fj.ps1 -pattern ...

    similar to:
        $ find ... \( -name FILE -o -name FILE -o ... \) ... -print | xargs grep PATTERN
            > powershell -f .\fj.ps1 -p[attern] PATTERN -f[iles] "*.php,*.html,*.txt"

        $ find ... -name PATTERN \( -name FILE -o -name FILE \) -print
            > powershell -f .\fj.ps1 -l -p foo.*bar -f "*.xlsx,*.xls" 
#>        
<#
$profile:
C:\Users\__YOUR_ACCOUNT__\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
#>

Set-PSDebug -strict

# sub function
Function parseArray([string] $s, [string] $delim, [int] $max = 0)
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

<#
  main function
#>
Function fj {
  Param(
  [parameter(HelpMessage="EDITOR")]
  [string] $editor = "c:\cast\app\gvim64\vim.exe"
  , [parameter(HelpMessage="PATTERN")]
  [string] $pattern = "."
  , [parameter(HelpMessage="root DIR")]
  [string] $root_dir = "$PWD\"
  , [parameter(HelpMessage="list file-path what PATTERN matched")]
  [switch] $list_path = $false
  , [parameter(HelpMessage="no list file-path what deny -l opt.")]
  [switch] $no_list = $false
  , [parameter(HelpMessage="open result-file by editor that no prompt")]
  [switch] $open_by_editor = $false
  , [parameter(HelpMessage="target files are directories")]
  [switch] $dir_only = $false
  , [parameter(HelpMessage='show result, also no prompt whether open')]
  [switch] $show_only = $false
  , [parameter(HelpMessage='files that comma separaited ("*.php,*.html")')]
  [string] $files = "*.ahk,*.pl,*.py,*.ps1,*.php,*.js,*.cs,*.c,*.vb,*.vbs,*.wsf,*.wsh,*.cpp,*.h,*.html,*.htm,*.inc,*.md,*.txt"
  )

$org_dir = (Get-Location)
#Set-Location $root_dir

# read preferences as json. at 2015-03-29, regex "SingleLine" using due to replace operator useless
# specified __DUMMY__ because i don't wanna match anything
<#
(New-Object regex "__DUMMY__", "SingleLine").Replace(
    (Get-Content -Encoding UTF8 "$pwd\fj.json"), "`$1") `
    | ConvertFrom-Json | Set-Variable myPreferences
#>
# DEBUG: message
$DebugPreference =  "Continue" # , then Write-Debug is available


[array]$files = parseArray $files ","
[array]$root_dir = parseArray $root_dir ","


[string]$outfile = "errors.err"
#[string]$editor = "c:\cast\app\gvim64\gvim.exe"
[string]$editor_option_ini = "-c :cf"

# directory exclusion  : 
# a)  $_.Directory -ne "tcpdf"  # "tcpdf" only, "tcpdf\conf" is not exclude  
# b)  $_.FullName -notmatch "\\tcpdf\\"  # "tcpdf and subdir effective

# FYI:
# console output :
# $_.DirectoryName    : C:\cast\proj\foo\bar
# $_.Directory(.Name) : bar
# dont kown what above two properties differnce

# for encode:
# Select-String -Encoding Default # cp932

if($no_list){
  $list_path = $false
}

if($dir_only){
    Get-ChildItem -Recurse -Include $files $root_dir | ? {
        $_.Mode -match "d" `
        -and $_.FullName -notmatch "\\.git\\" `
        -and $_.FullName -notmatch "\\.svn\\" `
        -and $_.FullName -notmatch "\\.cpan\\" `
        -and $_.FullName -match $pattern
    } | Set-Variable items
}elseif($list_path){
    Get-ChildItem -Recurse -Include $files $root_dir | ? {
        $_.FullName -notmatch "\\.git\\" `
        -and $_.FullName -notmatch "\\.svn\\" `
        -and $_.FullName -notmatch "\\.cpan\\" `
        -and $_.FullName -match $pattern
    } | Set-Variable items
}else{
    Get-ChildItem -Recurse -Include $files $root_dir | ? {
        $_.FullName -notmatch "\\.git\\" `
        -and $_.FullName -notmatch "\\.svn\\" `
        -and $_.FullName -notmatch "\\.cpan\\"
    } | Set-Variable items
}

if(!$list_path -and !$dir_only){
 $items | Select-String -Exclude "fubar_hoge_dummy" -Pattern $pattern `
    | %{ $_.Path + ":" + $_.LineNumber + ":" + $_.Line } `
    | Out-File -Width 8192 -FilePath "$org_dir\$outfile" -Encoding oem
}else{
 $items | % { [string]$_.FullName + ":1:`t" + $_.Length + "`t" + $_.LastWriteTime } | Out-File -Width 8192 -FilePath "$org_dir\$outfile" -Encoding oem
}

#Set-Location $org_dir

if(!(Test-Path $outfile)){
    Write-Host -ForegroundColor Magenta "no matched."
    return "done: 1"
}

if((Get-ChildItem $outfile| % { $_.Length }) -eq 0 ){
    Write-Host -ForegroundColor Magenta "no matched."
    return "done: 1"
}

Get-Content $outfile

if($show_only){
  return "done: 0"
}

if(!$open_by_editor){
  $yn = Read-Host "will open by editor, ok? (y or else)"
  if($yn -eq "y"){
    $open_by_editor = $true
  }else{
    return "done: 0"
  }
}
  
if($open_by_editor){
  $re4vi = $pattern -replace "([()|?+])", "\`$1"
  $editor_option = ($editor_option_ini + " '+/$re4vi/' ")
  $cmd = "$editor $editor_option"
  write-host -ForegroundColor green $cmd
  Invoke-Expression -Command $cmd
  Get-Variable LASTEXITCODE -ErrorAction SilentlyContinue | Out-Null
  if($? -eq $true){
    return "done: $LASTEXITCODE"
  }
  else{
    return "done: 3"
  }
}
return "done: 0"
}
