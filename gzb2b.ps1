
#Requires -Version 3.0

# purpose:
#   binary edit for gzip compressed file whitch like a sed
#
# usage:
#   this.ps1 -file file.gz -override file.b2b
#
# requirements:
#   ttba
#
Param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})]
    $file,

    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})] 
    $override,

    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})] 
    $ttba = "C:\msys64\usr\local\bin\ttba.exe",

    [string] $format = ''
)
$path = $null

try{
    $path = (Resolve-Path $file).Path
    $override = (Resolve-Path $override).Path
    $extracted = $env:TEMP + '\' + (Get-ChildItem $path).BaseName + '.x'
    $edited = $env:TEMP + '\' + (Get-ChildItem $path).BaseName + '.o'

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

    <# t2b #>
    $proc = Start-Process -WindowStyle Minimized -Wait -PassThru `
      -FilePath $ttba `
      -ArgumentList "-m `"$extracted`" `"$override`" `"$edited`"" `
      -RedirectStandardError $stderr
    if((Test-Path $stderr) -and (Get-ChildItem $stderr).Length -gt 0){
      Write-Host -ForegroundColor Red (Get-Content $stderr)
      Write-Host -ForegroundColor Magenta "some error has occurred."
      Remove-Item $stderr
    }
    if($proc.ExitCode -eq 0){
      $i = New-Object System.IO.FileStream(($edited),[System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
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
}catch [Exception]{
    $_.Exception
    $i.Dispose()
    $g.Dispose()
    $o.Dispose()
}
if(Test-Path $extracted){
  Remove-Item $extracted
}
if(Test-Path $edited){
  Remove-Item $edited
}
if(Test-Path $stderr){
  Remove-Item $stderr
}
