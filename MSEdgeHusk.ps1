<#
# husk of MSEdge (EddgeDriver, SeleniumWebDriver)
# 
# usage: . this.ps1 [-WithHead]
#
#   load this script as dot source in your script. there you can create classes derived from the MSEdgeHusk class.
#
# required:
#   .\WebDriver.dll
#   .\msedgedriver.exe
#
#   msedgedriver download link:
#     https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/
#     more directly:
#       https://msedgedriver.microsoft.com/115.0.1901.188/edgedriver_win64.zip
#
# sample:
#    . \path\to\this\MSEdgeHusk.ps1
#    $edge = [MSEdgeHusk]::new()
#
#    Set-Location $PSScriptRoot
#    $edge.navigate('https://foo.bar.com/')

#    $js = @'
#    let r = {};
#    r.foo = $("span.hoge").text();
#    r.bar = $("#baz").attr("src").replace(/^img\//,"");
#    return JSON.stringify(r);
#    '@
#    $r = $edge.evalScriptViaText($js)
#    $edge.dispose()
#    $r = (ConvertFrom-Json -InputObject $r)
#
#>
Param(
  [parameter(Mandatory=$false, HelpMessage="open browser window")]
  [switch] $WithHead
)

Set-Location $PSScriptRoot

[void][System.Reflection.Assembly]::LoadFile((Join-Path (Get-Location) "WebDriver.dll"))

Add-Type -A 'System.IO.Compression.FileSystem' # poweshell 5.1: .NetFramework4.7 required.

# driver auto update
function Download-EdgeDriver($version){
  Write-Host -ForegroundColor Yellow "EdgeDriver downloading..."

  $zippath = (Join-Path $pwd "edgedriver_win64.zip")
  $exefile = "msedgedriver.exe"
  Invoke-WebRequest -Method Get -Uri "https://msedgewebdriverstorage.z22.web.core.windows.net/?prefix=${version}/edgedriver_win64.zip" -OutFile $zippath

  if(Test-Path $zippath){
    if(Test-Path (Join-Path $pwd $exefile)){
      Remove-Item (Join-Path $pwd $exefile)
    }

    # (a) open ZIP archive, take only the target file
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zippath)
    $file = $zip.Entries | Where-Object { $_.Name -eq $exefile }
    <# .NetFramework4.5
    #$file.ExtractToFile((Join-path $pwd $file.Name))
    #>
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($file, (Join-path $pwd $file.Name), $true) # .NetFramework4.0
    $zip.Dispose()

    # (b) will be extract all files
    #[System.IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $pwd "edgedriver_win64.zip"), $pwd)

  }else{
    throw "FATAL: EdgeDriver download failed. ($version)"
  }
}

# show version
  $edgeVersion = (Get-ItemProperty "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe").VersionInfo.FileVersion
  if(Test-Path ".\msedgedriver.exe"){
    $edgedriverVersion = (Get-ItemProperty ".\msedgedriver.exe").VersionInfo.FileVersion
  }else{
    $edgedriverVersion = "none."
  }
  Write-Host -ForegroundColor Cyan ("MSEdge Version:       " + $edgeVersion)
  Write-Host -ForegroundColor Cyan ("MSEdgeDriver Version: " + $edgedriverVersion)
  Write-Host -ForegroundColor Cyan ("Selenium WebDriver Version: " + (Get-ItemProperty ".\WebDriver.dll").VersionInfo.FileVersion + " (4.9.1)")
  if($edgeVersion -ne $edgedriverVersion){
    $msg = @"
MSEdgedriver download link:
    https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/
    more directly:
        #https://msedgedriver.microsoft.com/{VERSION}/edgedriver_win64.zip
        https://msedgewebdriverstorage.z22.web.core.windows.net/?prefix={VERSION}/edgedriver_win64.zip
"@

    Write-Host -ForegroundColor Magenta $msg
    #throw "FATAL: MSEdge and EdgeDriver versions must be the same. ($edgeVersion <=> $edgedriverVersion)"

    Download-EdgeDriver -version $edgeVersion
  }

<#
# functions
#>
<#
# NOTE: The namespace used for the web driver is defined outside of the user class as functions, because it cannot be resolved in advance within the class.
#>
function D-ByTag([string] $name) {
  return [OpenQA.selenium.By]::TagName($name)
}

function D-ByClass([string] $name) {
  return [OpenQA.selenium.By]::ClassName($name)
}

function D-ById([string] $id) {
  return [OpenQA.selenium.By]::Id($id)
}

function Create-EdgeDriver {
    $option = New-Object OpenQA.Selenium.Edge.EdgeOptions
    $option.BinaryLocation = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    if(!$Script:WithHead){
      $option.AddArgument("headless")
      #$option.AddArgument("disable-gpu")
    }
    $option.AddArguments("--disable-extensions", "--no-sandbox", "--disable-dev-shm-usage")

    # create a profile to exclude sign-in information and block images, among other things.
    $edgeUserProfilePath = "$env:Temp\EdgeProfile"
    $option.AddArgument("--user-data-dir=$edgeUserProfilePath")
    $option.AddArgument("--profile-directory=Default")

    $service = [OpenQA.Selenium.Edge.EdgeDriverService]::CreateDefaultService((Get-Location), "msedgedriver.exe")
    $driver= New-Object OpenQA.Selenium.Edge.EdgeDriver($service, $option)
    $driver.Manage().Timeouts().ImplicitWait = [System.TimeSpan]::FromSeconds(10)
    return $driver
}

<#
# class that can be base
#>
class MSEdgeHusk {
  $edgeDriver
  $jqueryURL

  MSEdgeHusk(){
    $this.edgeDriver = Create-EdgeDriver
    $this.jqueryURL = 'https://ajax.googleapis.com/ajax/libs/jquery/3.4.1/jquery.min.js';
  }

  [bool] navigate($address){
    # no jquery equipped by own
    return $this.navigate($address, 1)
  }
  [bool] navigate($address, $jqueryUnnecessary){
    Write-Host "GET:  $address"
    $this.edgeDriver.Navigate().GoToUrl($address)
    Write-Host -ForegroundColor Magenta "navigating..."
    Write-Host -ForegroundColor Yellow "is NO jquery requied: $jqueryUnnecessary"

    $ready = $jqueryUnnecessary
    for ($i = 0; $i -lt 40 -and !$ready; $i++) {
      try {
        $ready = $this.evalScriptViaAttr('((window.hasOwnProperty("$") && window.$.hasOwnProperty("fn") && (window.$.fn.hasOwnProperty("jquery"))) ? window.$.fn.jquery : 0)')
        if($ready -ne 0) {
          Write-Host -ForegroundColor Cyan ("jquery is already available: " + $ready)
          break
        }
      } catch [Exception] {
        Write-Host -ForegroundColor DarkRed $_.Exception
        Write-Host -ForegroundColor DarkYellow "to be continued."
      }
      Write-Host -ForegroundColor Yellow ("check whether jquery is available from the beginning...:" + $ready)
      Start-Sleep -milliseconds 250
    }

    if($ready -eq 0){
      Write-Host -ForegroundColor Magenta ("jquery adding...")
      $ecma = @"
        const s = document.createElement("script");
        s.id = 'jquery-cdn';
        s.type = 'text/javascript';
        s.src = '{0}';
        document.body.appendChild(s);
"@
      [void] $this.evalScriptViaText($ecma -f $this.jqueryURL)

      for ($i = 0; $i -lt 40; $i++) {
        $ready = $this.evalScriptViaAttr('((window.hasOwnProperty("$") && window.$.hasOwnProperty("fn") && (window.$.fn.hasOwnProperty("jquery"))) ? window.$.fn.jquery : 0)')
        if($ready -ne 0){
          break
        }
        Write-Host -ForegroundColor Yellow ("waintng for jquery available...:" + $ready)
        Start-Sleep -milliseconds 250
      }
      Write-Host -ForegroundColor Green ("jQuery is ready? :" + $ready)
    }
    if($ready -eq 0){
        throw "FATAL: process timeout, jquery no available."
        return $false
    }

    $waitms = 1500
    Write-Host -ForegroundColor Magenta "wait $waitms [ms]"
    Start-Sleep -milliseconds $waitms
    return $true
  }

  [void] dispose(){
    if(!$Script:WithHead){
      $this.edgeDriver.Quit()
      Stop-Process -name msedgedriver -ea SilentlyContinue
    }
  }

  [object] evalScriptViaAttr([string] $ecma){
    # like giving an expression for a return statement
    $this.edgeDriver.ExecuteScript('document.body.setAttribute("res-out", (function(){return (' + $ecma + ');})())')
    return $this.edgeDriver.FindElement((D-ByTag 'body')).GetAttribute('res-out') 
  }

  [object] evalScriptViaText([string] $ecma){
    # please do what you need to do and then return on your own
    $this.edgeDriver.ExecuteScript('let __wk__ = document.querySelector("#feedback");if(__wk__==null){__wk__=document.createElement("div");__wk__.id="feedback";document.body.appendChild(__wk__);}__wk__.innerText=(function(){' + $ecma + '})()')
    return $this.edgeDriver.FindElement((D-ById 'feedback')).Text 
  }
}
