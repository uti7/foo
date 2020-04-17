#Requires -Version 3.0

# purpose:
#   binary edit for gzip compressed file whitch vim used
#
# usage:
#   this.ps1 -file file.gz [-format "....."]
#
# requirements:
#   vim, ttba, btta
#
Param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})]
    $file,

    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})] 
    $editor = "C:\cast\app\gvim64\gvim.exe",

    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})] 
    $btta = "C:\msys64\usr\local\bin\btta.exe",
    #$btta = "C:\cast\app\bin\btta.exe",

    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})] 
    $ttba = "C:\msys64\usr\local\bin\ttba.exe",
    #$ttba = "C:\cast\app\bin\ttba.exe",
    #$ttba = "D:\cygwin\home\ga\tb\x64\Release\ttba.exe",

    [string] $format = ''
)
$path = $null

try{
    if($format -eq ''){
      $format = '-v -c0x16 -k 97'
      $format_path = "no format file"
    }else{
      $format_path = (Resolve-Path $format).Path
      $format = "-f $format_path"
    }
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

    <# b2t #>
    Measure-Command { $proc = Start-Process `
      -WindowStyle Minimized -Wait -PassThru `
      -FilePath $btta -ArgumentList "$format `"$extracted`"" `
      -RedirectStandardOutput $dumped -RedirectStandardError $stderr }
    if((Test-Path $stderr) -and (Get-ChildItem $stderr).Length -gt 0){
      Get-Content $stderr
      if($proc.ExitCode -eq 2 -or $proc.ExitCode -eq 3){
        $q = 'n'
      }
      Remove-Item $stderr
    }

    while($q -eq 'y'){

      <# vim #>
      (Get-Item $dumped).Attributes = 'Normal'
      Start-Process -Wait -FilePath $editor `
        -ArgumentList "-c `"set columns=160 nowrap|vertical ba`" `"$dumped`" `"$format_path`""
      if(!((Get-Item $dumped).Attributes -contains 'Archive')){
        Write-Host -ForegroundColor Yellow "has no chenged."
        break
      }

      <# t2b #>
      $proc = Start-Process -WindowStyle Minimized -Wait -PassThru `
        -FilePath $ttba -ArgumentList "`"$dumped`" `"$extracted`"" `
        -RedirectStandardError $stderr
      if((Test-Path $stderr) -and (Get-ChildItem $stderr).Length -gt 0){
        Write-Host -ForegroundColor Red (Get-Content $stderr)
        Write-Host -ForegroundColor Magenta "some error has occurred."
        Remove-Item $stderr
        $q = Read-Host "edit again? ([y]es, [i]gnore or else(process no continued))"
        if($q -eq 'y'){
          continue
        }elseif($q -eq 'i'){
          # fall 
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
        Write-Host -ForegroundColor Green "gz done."
        break
      }else{
        Write-Host -ForegroundColor Yellow "gz skipped."
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

