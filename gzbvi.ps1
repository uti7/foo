#Requires -Version 3.0

# purpose:
#   binary edit for gzip compressed file
#
# usage:
#   this.ps1 -file file.gz [-format "....."]
#
Param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})]
    $file,

    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})] 
    $editor = 'c:\Apps\vim\gvim.exe',

    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})] 
    $btta = "$HOME\bin\btta.exe",

    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})] 
    $ttba = "$HOME\bin\ttba.exe",

    [string] $format = '-v -c0x16 -k 97'
)
$path = $null
if(!($format -cmatch '-v')){
  $format = "$format -v"
}

try{
    $path = (Resolve-Path $file).Path
    $extracted = $env:TEMP + '\' + (Get-ChildItem $path).BaseName + '.x'
    $dumped = $env:TEMP + '\' + (Get-ChildItem $path).BaseName + '.txt'

    $i = New-Object System.IO.FileStream(($path),[System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
    $g = New-Object System.IO.Compression.GZipStream($i,[System.IO.Compression.CompressionMode]::Decompress)
    $o = New-Object System.IO.FileStream(($extracted),[System.IO.FileMode]::Create)
    $b = New-Object System.Byte[] 8192

    $n = $b.Length
    while($n -eq $b.Length){
        $n = $g.Read($b, 0, $b.Length)
        if($n){
            $o.Write($b,0,$n)
        }
    }
    $i.Dispose()
    $g.Dispose()
    $o.Dispose()

    $stderr = $env:TEMP + '\' + (Get-ChildItem $path).BaseName + ".stderr"

    $q = 'y'
    $proc = Start-Process -WindowStyle Minimized -Wait -PassThru -FilePath $btta -ArgumentList "$format `"$extracted`"" -RedirectStandardOutput $dumped -RedirectStandardError $stderr
    if((Test-Path $stderr) -and (Get-ChildItem $stderr).Length -gt 0){
      Get-Content $stderr
      if($proc.ExitCode -eq 2){
        $q = 'n'
      }
      Remove-Item $stderr
    }

    while($q -eq 'y'){
      (Get-Item $dumped).Attributes = 'Normal'
      Start-Process -Wait -FilePath $editor -ArgumentList "`"$dumped`""
      if(!((Get-Item $dumped).Attributes -contains 'Archive')){
        Write-Host -ForegroundColor Yellow "has no chenged."
        break
      }
      $proc = Start-Process -WindowStyle Minimized -Wait -PassThru -FilePath $ttba -ArgumentList "`"$dumped`" `"$extracted`"" -RedirectStandardError $stderr
      if((Test-Path $stderr) -and (Get-ChildItem $stderr).Length -gt 0){
        Write-Host -ForegroundColor Red (Get-Content $stderr)
        Write-Host -ForegroundColor Magenta "some error has occurred."
        Remove-Item $stderr
        $q = Read-Host "edit again? (y or else):"
        if($q -eq 'y'){
          continue
        }else{
          break
        }
      }
      if($proc.ExitCode -eq 0){
        $i = New-Object System.IO.FileStream(($extracted),[System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
        $o = New-Object System.IO.FileStream(($path),[System.IO.FileMode]::Create)
        $g = New-Object System.IO.Compression.GZipStream($o,[System.IO.Compression.CompressionMode]::Compress)
        $i.CopyTo($g)

        $i.Dispose()
        $g.Dispose()
        $o.Dispose()
        break
      }
    }
}catch [Exception]{
    $_.Exception
    $i.Dispose()
    $g.Dispose()
    $o.Dispose()
}
if(Test-Path $extracted){
  Remove-Item $extracted
}
if(Test-Path $dumped){
  Remove-Item $dumped
}
if(Test-Path $stderr){
  Remove-Item $stderr
}

