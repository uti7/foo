#Requires -Version 5.1
Param(
  [parameter(Mandatory=$true, HelpMessage="input file (.json)")]
  [ValidateScript({ Test-Path $_ -PathType Leaf })]
  [string]$inPath,
  [parameter(Mandatory=$true, HelpMessage="output file (.tsv)")]
  [string]$outPath
)

<#
# classes
#>
class MapDataReader {
  # GeoJson at GADM
  [string]$txt
  [string]$mark
  $cutTail = 3 # 1 if no parent key (FeatureCollection), otherwise 3
  $pos
  $len
  $n  # item counter (n features processed)

  MapDataReader([string]$path){
    $this.txt = (Get-Content -Encoding utf8 $path)

    if($this.txt.IndexOf('"type":"Feature"') -ne -1){
      # tightly
    }elseif('"type": "Feature"'){
      # politely
      $this.txt = $this.txt -replace "\{\s+", "{"
      $this.txt = $this.txt -replace "\[\s+", "["
      $this.txt = $this.txt -replace "\s+\}", "}"
      $this.txt = $this.txt -replace "\s+\]", "]"
      $this.txt = $this.txt -replace '":\s+"', '":"'
      $this.txt = $this.txt -replace '\s+\{', '{'
      $this.txt = $this.txt -replace ",\s+", ","
      $this.txt = $this.txt -replace "\}\{", "},{"
    }else{
      throw 'DOUBT: the mark key & value ["type": "Feature"] was not found.'
    }
    $this.mark = '"type":"Feature"'

    if($this.txt.IndexOf('"type":"FeatureCollection"') -ne -1){
      $this.cutTail = 3
    }else{
      $this.cutTail = 1
    }
    $this.pos = 0
    $this.len = 0
    $this.n = 0
  }

  [PSCustomObject]getFeature(){
    $i = $this.txt.IndexOf($this.mark)
    if($i -ne -1){
      $this.pos = $i - 1
      # to know the end position from the next beginning
      $j = $this.txt.Substring($i+1, $this.txt.Length-$i-1).IndexOf($this.mark)
      if($j -ne -1){
        $this.len = $j
      }else{
        # last one
        $this.len = $this.txt.Length - $this.cutTail
      }
      $ret = $this.txt.Substring($this.pos, $this.len)
      $this.txt = $this.txt.Substring($this.pos + $this.len, $this.txt.length - ($this.pos+$this.len))
      # prevent decimal point digit loss
      $ret = $ret -replace '\[([-0-9.]+),([-0-9.]+)\]',  '["$1","$2"]'
      $ret = ConvertFrom-Json -InputObject $ret
      $this.n++
    }else{
      # no more
      $ret = $null
    }
    return $ret
  }
}

class CSVMapDataReader { # no need to derive
  # exported by QGIS
  $csv
  $n  # item counter (n features processed)

  CSVMapDataReader([string]$path){
    $this.csv = New-Object System.Collections.ArrayList
    $this.csv.AddRange((Import-Csv -LiteralPath $path)) | Out-Null
    $this.n = 0
  }

  [PSCustomObject]getFeature(){
    if($this.csv.Count -gt 0){

      $ret = [PSCustomObject]@{"properties" = @{}; "geometry" = [PSCustomObject]@{"type" = "MultiPolygon"; "WKT" = ""}}
      $ret.properties = ($this.csv[0] | Select-Object -Property * -ExcludeProperty WKT)
      $ret.geometry.WKT = ("SRID=4326;" + $this.csv[0].WKT)

      $this.csv.RemoveAt(0)
      $this.n++
    }else{
      # no more
      $ret = $null
    }
    return $ret
  }
}

class TsvWriter {
  $path   # for write (finally)
  $tmppath   # for write (body output 1st)
  $n      # counter
  $header # the items that properties, geometry.type and coordinates
  $coordinatesHeadding  # 'coordinates' or 'KWT'
  $keys   # keys with only members under properties
  $nCellsMax # max number of cells required for coordinates

  TsvWriter([string]$path){
    $this.path = $path
    $this.tmppath = $env:TEMP + '\' + (New-Object -ComObject Scripting.FileSystemObject).GetTempName()
    if(Test-Path -Path $this.tmppath){
      Remove-Item -LiteralPath $this.tmppath
    }

    $this.header = @()
    $this.keys = @()
    $this.nCellsMax = 1
  }

  setupField([PSCustomObject]$j){
    $this.header += "EPSG"
    $j.properties.PSObject.Properties | ForEach-Object {
      #Write-Host "Key: $($_.Name)"
      $this.header += $($_.Name)
      $this.keys += $($_.Name)
    }
    $this.header += "type"
    #$this.header += "coordinates"
    #$this.header -join "`t" | Out-UTF8NoBOM -FilePath $this.path
    #Out-File -Encoding utf8 -FilePath $this.path
  }

  writeFeature([PSCustomObject]$j){
    $rec = @()
    $rec += $null # add EPSG column as empty
    # properties, and coordinates-type
    foreach($key in $this.keys){
      $rec += $j.properties.$key
    }
    $rec += $j.geometry.type

    if($j.geometry.PSObject.Properties.Name -contains 'coordinates'){
      # coordinates belonging to GeoJson
      $this.coordinatesHeadding = 'coordinates'
      $s = "SRID=4326;MULTIPOLYGON("  # it has been decided, whatever it is.
        $j.geometry.coordinates | % {
          $s += "("
        $_ | % {
          $s += "("
          $_ | % {
              $s += (($_[0], $_[1]) -join ' ')
              $s += ","
          }
          $s += ")"
          $s += ","
        }
        $s += ")"
        $s += ","
      }
      $s += ")"
      $s = $s -replace ",\)", ")"

    }elseif($j.geometry.PSObject.Properties.Name -contains 'WKT'){
      # WKT belonging to QGIS-csv
      $this.coordinatesHeadding = 'WKT'
      $s = $j.geometry.WKT
    }else{
      $this.coordinatesHeadding = 'UNKNOWN'
      $s = "data missing?"
    }

    if($s.length -gt 30000){
      $s -split "(.{30000})" | ? {$_} | Set-Variable s
      if($s -is [array] -and $this.nCellsMax -lt $s.length){
        # keep max that n of cells required for coordinates
        $this.nCellsMax = $s.length
      }
    }
    $rec += $s

    $rec -join "`t" | Out-UTF8NoBOM -Append -FilePath $this.tmppath
    #Out-File -Encoding utf8 -Append -FilePath $this.tmppath
    $this.n++
  }
  
  writeFinally(){
    # write header to the final file
    (1..$this.nCellsMax) | % {
      $this.header += ("{0}[{1}/{2}]" -f $this.coordinatesHeadding, $_, $this.nCellsMax)
    }
    $this.header -join "`t" | Out-UTF8NoBOM -FilePath $this.path

    # concatinate the data bodies
    #Get-Content -Encoding utf8 -LiteralPath $this.tmppath | Out-UTF8NoBOM -Append -FilePath $this.path
    Concat-File_CustomMade -FileA $this.path -FileB $this.tmppath

    try{
      Remove-Item -LiteralPath $this.tmppath
    }catch [Exception]{ }
  }
}

<#
# functions
#>
# for PS ver.5.x
$UTF8NoBOM = New-Object System.Text.UTF8Encoding $false

function Out-UTF8NoBOM([string]$FilePath, [switch]$Append){
  # blank line won't be output
  [string]$s = $null
  $input | ? { $_.Length -gt 0 } | % { $s += ($_ + "`r`n") }
  $s = $s -replace '(\r\n)+$', ""
  if($Append){
    [System.IO.File]::AppendAllLines($FilePath, [string[]]@($s), $UTF8NoBOM)
  }else{
    [System.IO.File]::WriteAllLines($FilePath, $s, $UTF8NoBOM)
  }
}

# Concatenate the contents of file-B to the end of file-A
# Read and write line by line for large files
function Concat-File_CustomMade([string]$FileA, [string]$FileB){

  # ファイルパスを指定します
  $fullpathA = (Resolve-Path $FileA).Path
  $fullpathB = (Resolve-Path $FileB).Path

  # StreamWriterを作成します。既存の内容に追記するため、appendパラメータを$trueに設定します
  $writer = New-Object System.IO.StreamWriter($fullpathA, $true, [System.Text.Encoding]::UTF8)

  # StreamReaderを作成します
  $reader = New-Object System.IO.StreamReader($fullpathB, [System.Text.Encoding]::UTF8)

  # ファイルBの内容を1行ずつ読み込み、ファイルAに書き込みます
  while (($line = $reader.ReadLine()) -ne $null) {
      $writer.WriteLine($line)
  }

  # StreamReaderとStreamWriterを閉じます
  $reader.Close()
  $writer.Close()

}

function New-Reader([string]$FilePath){
  $fullpath = (Resolve-Path $FilePath).Path
  $buf = New-Object char[] 80

  $sr = New-Object System.IO.StreamReader($fullpath)
  $sr.Read($buf, 0, 80) | Out-Null
  $sr.Close()

  $s = -join $buf
  if($s -match '{\s*\"?type\"?\s*:'){
    # geojson
    return [MapDataReader]::new($FilePath)
  }elseif($s -match '^WKT,featurecla,'){
    # csv from ne.shp
    return [CSVMapDataReader]::new($FilePath)
  }elseif($s -match '^WKT,GID_2,'){
    # csv from gadm.shp
    return [CSVMapDataReader]::new($FilePath)
  }else{
    throw "ERROR: path ($FilePath): unknown file type ."
  }

}

<#
# start of main
#>
$x = 0

$reader = $null
$writer = $null

try {
  $reader = New-Reader -FilePath $inPath
  $writer = [TsvWriter]::new($outPath)

  while($j = $reader.getFeature()){
    if($reader.n -eq 1){
      $writer.setupField($j)
    }
    $writer.writeFeature($j)
  }
  $writer.writeFinally()

  Write-Host -ForegroundColor Green 'done.'
  Write-Host -ForegroundColor Green ('{0} processed.' -f $reader.n)
} catch [Exception] {
  Write-Error $_.Exception.Message
  Write-Error $_.ScriptStackTrace
  $x = 1
} finally {
  $reader = $null
  $writer = $null
}

exit $x
