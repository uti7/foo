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
#       https://msedgedriver.azureedge.net/115.0.1901.188/edgedriver_win64.zip
#
# sample:
#    . \path\to\this\MSEdgeHusk.ps1
#    Set-Location $PSScriptRoot
#    $edge = [MSEdgeHusk]::new()
#    $edge.navigate('https://foo.bar.com/')
#    Start-Sleep -milliseconds 1000
#
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

# show version
  $edgeVersion = (Get-ItemProperty "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe").VersionInfo.FileVersion
  $edgedriverVersion = (Get-ItemProperty ".\msedgedriver.exe").VersionInfo.FileVersion
  Write-Host -ForegroundColor Cyan ("MSEdge Version:       " + $edgeVersion)
  Write-Host -ForegroundColor Cyan ("MSEdgeDriver Version: " + $edgedriverVersion)
  Write-Host -ForegroundColor Cyan ("Selenium WebDriver Version: " + (Get-ItemProperty ".\WebDriver.dll").VersionInfo.FileVersion + " (4.9.1)")
  if($edgedriverVersion -ne $edgedriverVersion){
    throw "FATAL: MSEdge and EdgeDriver versions must be the same. ($edgeVersion <=> $edgedriverVersion)"
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

    $service = [OpenQA.Selenium.Edge.EdgeDriverService]::CreateDefaultService((Get-Location))
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
    Write-Host "GET:  $address"
    $this.edgeDriver.Navigate().GoToUrl($address)
    Write-Host -ForegroundColor Magenta "navigating..."

    $ready = $false
    for ($i = 0; $i -lt 40; $i++) {
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
