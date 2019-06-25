#Requires -Version 3.0

# purpose:
#   binary pattern search
#
# usage:
#   this.ps1 -pattern @(.....) [-in file]
#
# pattern and result:
#   e.g.) > "123" | this.ps1 -pattern @(.....)
#
#   @(0x31,50)
#       -> 00000000:  49(0x31) 50(0x32)
#
#   @(@('x','^3'),@('d','^5'))
#       -> 00000000:  0x31 50
#          00000001:  0x32 51
#
#   @('n',@('d', '^5'))
#       -> 00000001:  50
#          00000002:  51
#
#   @('n',@('.', 2))  # /.{2}/
#       -> 00000000:  49(0x31) 50(0x32)
#          00000001:  50(0x32) 51(0x33)
#
Param(
  [Parameter(Mandatory=$true)]$pattern,
  [Parameter(Mandatory=$true, ValueFromPipeline=$true)]$in
)$myname = Split-Path $MyInvocation.MyCommand.Path -Leaf


Set-PSDebug -strict
$f = $null
if(Test-Path $in){
  $f = (Resolve-Path $in)
}
if($f -ne $null -and $f.GetType().Name -eq "PathInfo"){
  $a = [System.IO.File]::ReadAllBytes($f.Path)
}else{
  $a = [System.Text.Encoding]::ASCII.GetBytes($in)
}

$i = 0
$ms = @()
while($i -le $a.Length){
  $is_unmatched = $false
  $m = @()
  $m += ("{0:x8}" -f $i)  # offset for print
  $j = $i + 1 # next test position
  $c = 0 # number of pattern item
  switch($pattern){
    {$_ -is [int]}  # 
    {
      $c++
      if($a[$i] -eq $_){
        $m += [string]$a[$i] + ('(0x' + ("{0:x2}" -f $a[$i]) + ')')
        $i++
        continue
      }else{
        $is_unmatched = $true
        break
      }
    }
    {$_ -is [array] -and $_[0] -eq 'x'} #
    {
      $c++
      if(("{0:x2}" -f $a[$i]) -match $_[1]){
        $m += '0x' + ("{0:x2}" -f $a[$i])
        $i++
        continue
      }else{
        $is_unmatched = $true
        break
      }
    }
    {$_ -is [array] -and $_[0] -eq 'd'} #
    {
      $c++
      if(("{0}" -f $a[$i]) -match $_[1]){
        $m += ("{0}" -f $a[$i])
        $i++
        continue
      }else{
        $is_unmatched = $true
        break
      }
    }
    {$_ -is [array] -and $_[0] -eq '.' -and $_[1] -is [int]} #
    {
      $n = $i + $_[1] - 1
      $c += $_[1]
      $a[$i..$n]| % {
        $m += [string]$a[$i] + ('(0x' + ("{0:x2}" -f $a[$i]) + ')')
        $i++
      }
      continue
    }
    default {
      if($_ -eq 'n'){
        #  no operation
        continue
      }
      throw ($_ + ": pattern unexpected.")
    }
  }
  if(!$is_unmatched -and ($m.Length - 1) -eq $c){
    $ms += ,$m
  }
  $i = $j
}
$ms | % {
  $m = $_
  Write-Host -ForegroundColor Yellow -NoNewline ($m[0] + ':')
  $m[0] = $null
  $m | % {
    Write-Host -NoNewline (' ' + $_)
  }
  Write-Host
}
