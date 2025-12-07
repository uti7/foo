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
Function parseArray([string] $s, [string] $delim, [int] $max = 0, [switch]$absolute)
{
    $a = @()
    $s -split $delim, $max | % {
        $i = $_ -replace "^\s+", ""
        $i = $i -replace "\s+$", ""
        if(!$absolute -and $i -notmatch "^\*"){
          $i = ("*" + $i)
        }
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
  , [parameter(HelpMessage="list file-path what PATTERN matched, it's means no grep")]
  [switch] $list_path = $false
  , [parameter(HelpMessage="no list file-path what deny -list_path opt.")]
  [switch] $no_list = $false
  , [parameter(HelpMessage="open result-file by editor that no prompt")]
  [switch] $open_by_editor = $false
  , [parameter(HelpMessage="target files are directories")]
  [switch] $dir_only = $false
  , [parameter(HelpMessage='show result, also no prompt whether open')]
  [switch] $show_only = $false
  , [parameter(HelpMessage='files that comma separaited ("*.php,*.html")')]
  [string] $files = "*.ahk,*.pl,*.py,*.ps1,*.php,*.js,*.cs,*.c,*.vb,*.vbs,*.wsf,*.wsh,*.cpp,*.h,*.html,*.htm,*.inc,*.md,*.txt,*.json,*.csv,*.tsv,*,*.xml,*.yml,*.ini"
  , [parameter(HelpMessage='show usage')]
  [switch] $help = $false
  , [parameter(HelpMessage='show quick fix path info')]
  [switch] $qfinfo = $false
  )

  if($help){
    @"
 fj [-pattern .]
    [-root_dir .]
    [-editor c:\gvim64\gvim.exe]
    [ {-list_path | -no_list} ]
    [-open_by_editor]
    [-dir_only]
    [-show_only]
    [-qfinfo]
    [-files *.txt,*.ahk,*.???,...]

    -list_path  : no grep, To filter by file name as RE,
                  ex. of use:  -list_path -file "*.ps1,*.bat" -pattern "foo.*bar"
    -no_list    : cancel -list _path option
"@
    return [pscustomobject]@{"status"=2;"message"="done."}
  }

$org_dir = (Get-Location)
try{
  ""|Out-File -FilePath $org_dir/$outfile
}catch [Exception]{
  $org_dir = $env:Temp
  try{
    ""|Out-File -FilePath $org_dir/$outfile
  }catch [Exception]{
    $outfile = "errors.er1"
    try{
      ""|Out-File -FilePath $org_dir/$outfile
    }catch [Exception]{
      Write-Host -ForegroundColor Magenta ($_ + ", given up.")
      return @{"status"=1;"message"="done."}
    }
  }
}
if($qfinfo){
  Write-Host -ForegroundColor Green ("qf:" + "$org_dir\$outfile")
}

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
[array]$root_dir = parseArray $root_dir "," -absolute


[string]$outfile = "errors.err" # don't know why it's being overwritten here
#[string]$editor = "c:\cast\app\gvim64\gvim.exe"
[string]$editor_option_preset = "-q $org_dir/$outfile"

# directory exclusion  : 
# a)  $_.Directory -ne "tcpdf"  # "tcpdf" only, "tcpdf\conf" is not exclude  
# b)  $_.FullName -notmatch "\\tcpdf\\"  # "tcpdf and subdir effective

# FYI:
# console output :
# $_.DirectoryName    : C:\cast\proj\foo\bar
# $_.Directory(.Name) : bar
# dont kown what above two properties differnce

# for encode:
# Select-String -Encoding oem # cp932

if($no_list){
  $list_path = $false
}

if($dir_only){
    $files = "*"
    Get-ChildItem -Recurse -Include $files -Exclude (".git", ".svn", ".cpan", ".vscode") -Path $root_dir -ea SilentlyContinue | ? {
        $_.Mode -match "d" `
        -and $_.FullName -notmatch "\\\.git\\" `
        -and $_.FullName -notmatch "\\\.svn\\" `
        -and $_.FullName -notmatch "\\\.cpan\\" `
        -and $_.FullName -notmatch "\\\.vscode\\" `
        -and $_.FullName -match $pattern
    } | Set-Variable items
}elseif($list_path){
    Get-ChildItem -Recurse -Include $files -Exclude (".git", ".svn", ".cpan", ".vscode") -Path $root_dir -ea SilentlyContinue | ? {
        $_.Mode -notmatch "d" `
        -and $_.FullName -notmatch "\\\.git\\" `
        -and $_.FullName -notmatch "\\\.svn\\" `
        -and $_.FullName -notmatch "\\\.cpan\\" `
        -and $_.FullName -notmatch "\\\.vscode\\" `
        -and $_.FullName -match $pattern
    } | Set-Variable items
}else{
    Get-ChildItem -Recurse -Include $files -Exclude (".git", ".svn", ".cpan", ".vscode") -Path $root_dir -ea SilentlyContinue | ? {
        $_.Mode -notmatch "d" `
        -and $_.FullName -notmatch "\\\.git\\" `
        -and $_.FullName -notmatch "\\\.svn\\" `
        -and $_.FullName -notmatch "\\\.cpan\\" `
        -and $_.FullName -notmatch "\\\.vscode\\"
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

if(!(Test-Path $org_dir/$outfile)){
    Write-Host -ForegroundColor Magenta "no matched."
    return [pscustomobject]@{"status"=1;"message"="no matched."}
}

if((Get-ChildItem $org_dir/$outfile| % { $_.Length }) -eq 0 ){
    Write-Host -ForegroundColor Magenta "no matched."
    return [pscustomobject]@{"status"=1;"message"="no matched."}
}

Get-Content $org_dir/$outfile

if($show_only){
  return [pscustomobject]@{"status"=0;"message"="done."}
}

if(!$open_by_editor){
  $yn = Read-Host "will open by editor, ok? (y or else)"
  if($yn -eq "y"){
    $open_by_editor = $true
  }else{
    return [pscustomobject]@{"status"=0;"message"="done."}
  }
}
  
if($open_by_editor){
  $re4vi = $pattern -replace "([()|?+])", "\`$1"
  $editor_option = ($editor_option_preset + " '+/$re4vi/' ")
  $cmd = "$editor $editor_option"
  write-host -ForegroundColor green $cmd
  Invoke-Expression -Command $cmd
  Get-Variable LASTEXITCODE -ErrorAction SilentlyContinue | Out-Null
  if($? -eq $true){
    return [pscustomobject]@{"status"=$LASTEXITCODE;"message"="done."}
  }
  else{
    return [pscustomobject]@{"status"=3;"message"="it didn't work."}
  }
}
return [pscustomobject]@{"status"=0;"message"="done."}
}
