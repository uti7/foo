#Requires -Version 3.0
if($PSVersionTable.PSVersion.Major -lt 3){
  $PSVersionTable
  Write-Host -ForegroundColor red "FATAL: no available."
  exit
}
Set-Location $PSScriptRoot

[void][System.Reflection.Assembly]::LoadFile("$pwd\TKMP.dll")
# DEBUG: message
$DebugPreference =  "Continue" # , then Write-Debug is available


function invoke_small($member, $argarray) {
  $small = New-Object -ComObject SmallLib.SmallObject
  $small.getType().InvokeMember($member,
       [Reflection.BindingFlags]::InvokeMethod, $null, $small, $argarray) 
  [void] [System.Runtime.Interopservices.Marshal]::ReleaseComObject($small)
  $small = $null
}

function decodePass($accdef) {
  if(!$Global:mail.passxml){
    $Global:mail.passxml = [xml] "<plist />"
  }
  $pn = $Global:mail.passxml.documentElement.selectSingleNode( `
      "./pass[@id='" + $accdef.id + "']")
  if(!$pn){
    $pn = $Global:mail.passxml.createElement("pass")
    $pn.setAttribute("id", $accdef.id)
    [void] $Global:mail.passxml.documentElement.appendChild($pn)

    $ret = invoke_small "DecodePass" ($accdef.pop, $accdef.user, $accdef.'#text')
    $ret = $ret -replace "[\r\n]*$", ""
    [void] $pn.appendChild($Global:mail.passxml.createTextNode($ret))
  }else{
    $ret = $pn.InnerText
  }
  return $ret
}

function init() {
  $Global:mail = @{
    config = @{
      acc_path = ".\account.xml";
    }
  }
  $Global:mail.config += @{
      tmpdir_ = $env:TEMP + "\coldspa\_tmp";
	    workdir_ = ".\m";
      paging_count = 10;
      paging_body = 20;
  };
  $Global:mail += @{
    js = New-Object -ComObject ScriptControl;
    accxml = [xml](Get-Content $Global:mail.config.acc_path);
    passxml = $null;
    imap = $null;
    mbox = $null;
    cia = $null;
    i = -1;
    deletion = @{};
  }
  $Global:mail.js.Language = "JScript"
  $Global:mail.js.AddCode("function encode(s){return encodeURIComponent(s);}")
  if(!(Test-Path $Global:mail.config.tmpdir_)){
    New-Item $Global:mail.config.tmpdir_ -ItemType Directory
  }
}

if($Global:mail -eq $null){
  init
}

function imapConnect($accdef, [ref] $resp) {
  # 正常時 $trueを返す. and set imap that instance of TKMP.Net.ImapClient
  # 異常時 $false を返し、resp にメッセージをセット
  try{
    $pass = decodePass ($accdef)
    $il = New-Object TKMP.Net.BasicImapLogon($accdef.addr, $pass)

    if($accdef.imap -match ":"){
      $server = $accdef.imap.Split(":")
    }else{
      $server = ($accdef.imap, 993)
    }

    $Global:mail.imap = New-Object TKMP.Net.ImapClient($il, $server[0], $server[1])
    if($accdef.ssl -eq "yes"){
      $Global:mail.imap.AuthenticationProtocol = [TKMP.Net.AuthenticationProtocols]::SSL
    }
    Write-Host ($accdef.addr + ": connecting...")
    if(!$Global:mail.imap.Connect()){        # imap接続
      throw $accdef.addr + ": connect failed."
    }
  }catch [Exception]{
    Write-Host -ForegroundColor Red $_.Exception.ErrorRecord
    $resp.Value =  $_.Exception
    return $false
  }
  $Global:mail.mbox = $Global:mail.imap.DefaultMailBox
  $Global:mail.list = $Global:mail.mbox.MailDatas

  Write-Host -ForegroundColor Green ($accdef.addr + ": connected, " `
      + $Global:mail.mbox.MailDatas.Count ` + " " `
      +"(new: " + $Global:mail.mbox.RecentCount + ") mail(s).")
  return $true
}

function imapDisconnect([switch] $is_quiet = $false) {
    if($Global:mail.imap -eq $null){
      if(!$is_quiet){
        Write-Host -ForegroundColor Yellow "not connected."
      }
    }elseif($Global:mail.imap.Connected){
      [void] $Global:mail.imap.Close
      $Global:mail.imap = $null
      Write-Host -ForegroundColor Green ($Global:mail.cia.id + ": disconnected.")
    }else{
      if(!$is_quiet){
        Write-Host -ForegroundColor Yellow "already disconnected."
      }
    }
    $Global:mail.cia = $null
    $Global:mail.i = -1
}

function seekMail($i)
{
  if(!(retrieve)){return}
  $i = _validate_ $i
  $Global:mail.i = $i
  if(!$Global:mail.list){
    $Global:mail.list = $Global:mail.mbox.MailDatas
  }
  outSummary $Global:mail.list[$i] $i
}

function exproreMail($i)
{
  if(!(retrieve)){return}
  $i = _validate_ $i
  if(!$Global:mail.list){
    $Global:mail.list = $Global:mail.mbox.MailDatas
  }
  $ismd5 = 0
  $extdir = ""
  $parent = ""
  $folName = ""
  $id = extractMail3 $Global:mail.list[$i] $parent $folName $mime ([ref] $extdir) ([ref]$ismd5) $is_forcibly
  if($id -eq $false){
    Write-Host -ForegroundColor ("ERROR: "+ $i + ": extract failure.")
    return
  }
  $Global:mail.i = $i
  Invoke-Item $extdir
}

function deleteMail([array]$iii)
{
  if(!(retrieve)){return}
  if(!$Global:mail.list){
    Write-Host -ForegroundColor Yellow "has no mail-list yet."
    return
  }
  $iii | % {
    $i = _validate_ $_
    $uid = $Global:mail.list[$i].UID
    $Global:mail.deletion[$uid] = !($Global:mail.deletion[$uid] -eq $true)
  }
}

function doDelete
{
  if(!$Global:mail.list){
    Write-Host -ForegroundColor Yellow "has no mail-list yet."
    return
  }
  $Global:mail.deletion.Keys | ? {
    $uid = $_
    $Global:mail.deletion[$uid] -eq $true } | % {
      $Global:mail.list | ? {
        $_.UID -eq $uid } | % {
          try{
            $ret = $_.Delete()
          }catch [Exception]{
            $ret =$false
            Write-Host -ForegroundColor Magenta ([string]$uid + ": delete failed.`n" + $_.Exception)
          }
          if($ret){
            Write-Host -ForegroundColor Cyan ([string]$uid + ": deleted.")
          }
        }
    }
    $Global:mail.deletion = @{}
}

function searchMail($key){
    if(!(retrieve)){return}
    $mails = $Global:mail.mbox.SearchMailData($key)
    if($mails.Count -gt 0){
      $Global:mail.i = -1
      _pagenateMails $mails
    }else{
      Write-Host -ForegroundColor Yellow "no matched."
    }
}

function listMail()
{
    if(!(retrieve)){return}
    _pagenateMails $Global:mail.mbox.MailDatas
}

function _pagenateMails($mails)
{
    $Global:mail.list = $mails
    $count = $Global:mail.list.Count * -1
    if($count -eq 0){
      Write-Host -ForegroundColor Yellow "no mail."
      break
    }elseif($Global:mail.i -lt $count){
      $Global:mail.i = -1
    }
    $n = $Global:mail.config.paging_count
    for(; ; $Global:mail.i--){
      if($Global:mail.i -lt $count){
        $Global:mail.i = -1
        break
      }
      outSummary $Global:mail.list[$Global:mail.i] $Global:mail.i
      $n--
      if($Global:mail.i -lt -1 -and $n -eq 0){

        $is_end_pager = $false
        while(!$is_end_pager){
          $cmd = Pause "Cyan" (($Global:mail.i * -1).ToString() + "/" + ($count * -1) + ": press ENTER, or [q]uit, [h]elp")
          if($cmd -eq "q"){
            $is_end_pager = $true
            break
          }elseif($cmd -eq ""){
            break # next page
          }elseif($cmd -match "^s\s*(-?\d+)$"){
            $i = $cmd -replace "^s\s*(-?\d+)$", '$1'
            try{
              $i = (Invoke-Expression -Command $i)
            }catch [Exception]{
              Write-Host -ForegroundColor DarkRed $_.Exception
              continue
            }
            seekMail $i
          }elseif($cmd -match "^x\s*(-?\d+)$"){
            $i = $cmd -replace "^x\s*(-?\d+)$", '$1'
            try{
              $i = (Invoke-Expression -Command $i)
            }catch [Exception]{
              Write-Host -ForegroundColor DarkRed $_.Exception
              continue
            }
            exproreMail $i
          }elseif($cmd -match "^-?\d+$"){
            $i = $cmd -replace "^(-?\d+)$", '$1'
            try{
              $i = (Invoke-Expression -Command $i)
            }catch [Exception]{
              Write-Host -ForegroundColor DarkRed $_.Exception
              continue
            }
            viewMail $i
          }elseif($cmd -ceq "b"){
            $Global:mail.i += ($Global:mail.config.paging_count * 2)
            if($Global:mail.i -gt 0){ $Global:mail.i = 0 }
          }elseif($cmd -ceq "r"){
            $Global:mail.i += ($Global:mail.config.paging_count)
            if($Global:mail.i -ge 0){ $Global:mail.i = -1 }
          }elseif($cmd -ceq "g"){
            # 1st page
            $Global:mail.i = 0
          }elseif($cmd -ceq "G"){
            # last page
            $Global:mail.i = $count + $Global:mail.config.paging_count
          }elseif($cmd -match "^d\s*([\d,().+]+)$"){
            $iii = $cmd -replace "^d\s*([\d,().+]+)$", '$1'
            try{
              $iii = (Invoke-Expression -Command $iii)
            }catch [Exception]{
              Write-Host -ForegroundColor DarkRed $_.Exception
              continue
            }
            deleteMail $iii
          }elseif($cmd -ceq "h"){
            Write-Host -ForegroundColor DarkCyan ("command as follows:`n`tENTER:`tto next page.`n`t[q]uit`n`t[h]elp`n`t[s]eek (N)`n`t[d]elete (N)`n`te[x]prore`n`tpage [b]ack`n`t[r]edraw`n`t[g]o to 1st page`n`t[G]o to last page`n`t[N]:`tview mail for N")
            continue
          }else{
            Write-Host -ForegroundColor Magenta "${cmd}: unknown command."
            continue
          }
          break
        }
        $n = $Global:mail.config.paging_count
        if(($Global:mail.i - 1) -lt $count){ $Global:mail.i = 0 }
        if($is_end_pager){
          break
        }
      }
    }
}

function viewMail
{
  Param(
    [int]     $i,
    [string]  $mime = "",
    [switch]  $is_forcibly = $true,
    [switch]  $is_silent = $false
  )
  if(!(retrieve)){return}
  if(!$Global:mail.list){
      Write-Host -ForegroundColor Yellow ("set the list to MailDatas[]")
      $Global:mail.list = $Global:mail.mbox.MailDatas
  }
  $i = _validate_ $i
  $ismd5 = 0
  $extdir = ""
  $parent = ""
  $folName = ""
  $id = extractMail3 $Global:mail.list[$i] $parent $folName $mime ([ref] $extdir) ([ref]$ismd5) $is_forcibly
  if($id -eq $false){
    Write-Host -ForegroundColor ("ERROR: "+ $i + ": extract failure.")
    return
  }
  $Global:mail.i = $i
  if($is_silent){
    Get-Content ($extdir + "\body.txt") |Set-Variable b
    return $b
  }else{
    Get-Content ($extdir + "\header.txt")|Select-String "^(Subject|From|Date):"|Write-Host -BackgroundColor DarkGreen -ForegroundColor Yellow
    Get-Content ($extdir + "\body.txt") |Set-Variable b
    #$b -split "\r\n" |Set-Variable bb
    _more_ $b
  }
}

function invokeURL
{
  Param(
    [array]   $list,
    [int]     $i
  )
	$uri = $list[$i] -replace '^.*?([a-z]+://[^\s<>|,;:"]*).*?$', '$1'
	if($uri -ne ''){
    Write-Host -ForegroundColor Magenta $uri
    [System.Diagnostics.Process]::Start($uri)
	}
}

function showAccounts()
{
  $Global:mail.accxml.selectNodes("/accounts/account-def")|?{$_.imap -ne $null}|%{
    if($_.id -eq $Global:mail.cia.id){
      Write-Host -NoNewLine "*"
    }
    "`t" + $_.id
  }
}
function showTemplate {
	$accdef = '<account-def id="IDENT" imap="imap.gmail.com:993" pop="pop.gmail.com:995" user="recent:USER" smtp="smtp.gmail.com:465" addr="USER@gmail.com" smtpauth_user="USER" smtpauth_pwd="" popbeforesmtp="no" ssl="yes" ></account-def>'
	$accdef
}

function retrieve($is_viewbody = $false){
    $ret = $true
    $is_reconnect = $false
    while($true){
      if(!$Global:mail.mbox `
      -or $Global:mail.mbox.GetType().Name -ne "MailBox"){
        $is_reconnect = $true
        break
      }
      if($Global:mail.mbox.MailDatas.Count -gt 0){
        try{
            [void]$Global:mail.mbox.MailDatas[$Global:mail.i].ReadBody();
            [void]$Global:mail.mbox.MailDatas[$Global:mail.i].ReadHeader()
        }catch [Exception]{
          if($_.Exception -match "I/O.*エラー"){
            Write-Host -ForegroundColor Yellow $_.Exception
            $is_reconnect = $true
            break
          }else{
            throw $_
          }
        }
      }else{
        $is_reconnect = $true
        break
      }
      break # 1 time
    }
    if($is_reconnect){
        Write-Host -ForegroundColor Yellow "retrive connection..."
        if(!$Global:mail.cia){
          Write-Host -ForegroundColor Magenta "unknown account for connection, do connect 1st."
          return $false
        }
        $resp = ""
        try{
          $ret = imapConnect $Global:mail.cia ([ref] $resp)
        }catch [Exception]{
          throw $_.Exception
        }
    }
    return $ret
}

function _validate_([int]$i){
  if($i -gt 0){
    $i *= -1
  }elseif($i -eq 0){
    $i = -1
  }
  if($i -gt -1 -or ( $i * -1) -gt $Global:mail.mbox.MailDatas.Count){
      throw $i + ": out of range."
  }
  return $i
}

function outSummary{
  Param(
    $m,
    [parameter(Mandatory=$true, HelpMessage="minus index")]
    [int]   $i
    )

  [void] $m.ReadHeader()
  $h = New-Object TKMP.Reader.MailReader($m.HeaderStream, $false)
  $hdate = $h.HeaderCollection["Date"] -replace "\([A-Z]{3}\)$", ""
  $hdate =(Get-Date -Date $hdate)
  $mark = ""
  if($Global:mail.deletion[$m.UID]){
    $mark += "D"
  }
  if($Global:mail.list.Count * -1 -eq $i){
    $mark += "E"
  }
  $ii = $i * -1
  Write-Host ($mark + "`t" + $ii.toString() + ":`t" + (_left_ $h.HeaderCollection["Subject"]  20) `
  + "`t" + (_left_ $h.HeaderCollection["From"] 20) `
  + "`t" + $hdate)
}

function _left_($datum, $max){
  $l = $datum.toString().length
  return $datum.toString().SubString(0, ([int]($max - $l -lt 0) * $max) + ([int]($max - $l -ge 0) * $l))
}

function _more_([array]$list, $fg = "White"){
  #more does not works also `Out-Host -Paging', dammit!
  $i = 0
  $n = $Global:mail.config.paging_body
  while($i -lt $list.Count){
      Write-Host -ForegroundColor $fg (("{0,3}: " -f $i) + ($list[$i]))
      $n--
      $i++
      $is_no_more = $false
      while(!$is_no_more){
        if($i -lt $list.Count -and $n -eq 0){
          $cmd = Pause "Green" (($i).ToString() + "/" + ($list.Count-1) + ": press ENTER, or [q]uit, [h]elp")
          if($cmd -eq "q"){
            $is_no_more = $true
          }elseif($cmd -eq ""){
          }elseif($cmd -match "^s*\s*(-?\d+)$"){
            $quant = $cmd -replace "^s*\s*(-?\d+)$", '$1'
            try{
              $quant = (Invoke-Expression -Command $quant)
            }catch [Exception]{
              Write-Host -ForegroundColor DarkRed $_.Exception
              continue
            }
            if($quant -lt 0){
              $i += $quant
            }else{
              $i = $quant
            }
          }elseif($cmd -match "^x$"){
            exproreMail $Global:mail.i
          }elseif($cmd -ceq "b"){
            $i -= ($Global:mail.config.paging_body * 2)
            if($i -lt 0){
              Write-Host -ForegroundColor Yellow "can't back."
              $i = 0
              continue
            }
          }elseif($cmd -ceq "r"){
            # redraw
            $i -= ($Global:mail.config.paging_body)
            if($i -lt 0){ $i = 0 }
          }elseif($cmd -ceq "g"){
            # 1st page
            $i = 0
          }elseif($cmd -ceq "G"){
            # last page
            $i = $list.Count - $Global:mail.config.paging_body
            if($i -lt 0){ $i = 0 }
          }elseif($cmd -match "^[iu]\s*([\d,().+]+)*$"){
            $iii = $cmd -replace "^[iu]\s*([\d,().+]+)*$", '$1'
            if($iii -eq ""){
              $iii = $i
            }
            try{
              $iii = (Invoke-Expression -Command $iii)
            }catch [Exception]{
              Write-Host -ForegroundColor DarkRed $_.Exception
              continue
            }
            invokeURL $list $iii
						continue
          }elseif($cmd -ceq "h"){
            Write-Host -ForegroundColor DarkGreen ("command as follows:`n`tENTER:`tto next page.`n`t[q]uit`n`t[h]elp`n`t[s]eek (N)`n`t[i]nvoke [u]rl (N)`n`te[x]prore`n`tpage [b]ack`n`t[r]edraw`n`t[g]o to 1st page`n`t[G]o to last page")
            continue
          }else{
            Write-Host -ForegroundColor Magenta "${cmd}: unknown command."
            continue
          }
          $n = $Global:mail.config.paging_body
        }
        break
      }
      if($is_no_more){
        break
      }
  }
  Write-Host -BackgroundColor DarkGreen -ForegroundColor Yellow "-- "
}

function Pause {
  Param(
    [string] $fg = "White",
    [string] $prompt = "続行するにはENTERを押してください(q で終了)"
    )
    if($ExecutionContext.Host.name -match "console"){
        Write-Host "続行するには何かキーを押してください . . ." -NoNewLine
        [Console]::ReadKey($true) | Out-Null
        Write-Host
    }elseif($ExecutionContext.Host.name -match "Windows PowerShell"){
        Write-Host -NoNewLine -ForegroundColor $fg $prompt
        return Read-Host -Prompt " "
    }else{    
        #Add-Type -AssemblyName System.Windows.Forms
        [WIndows.Forms.MessageBox]::Show("続行するにはOKを押してください") | Out-Null
    }
}

<#
  mail extraction {
#>
function extractMail3($src, $parent, $folName, $mime,
    [ref] $extdir, [ref] $ismd5, $is_forcibly)
{
<#
  'メールヘッダ部、本文と添付ファイルを規定フォルダへ抽出
  Dim tmpd, h, dest, ots, i
  ahkからの時は$srcはフルパス
  戻り：id＝$srcから (#Logなど展開不要時は 空文字) 異常時は"NG"文字←現在ない
        rfc822を展開した場合はMD5化した疑似id
        $extidに持っている
  返却：$extdir展開先フォルダパス、$ismd5添付メール用疑似ID化したフラグ
#>


  # get uidx and full path
  if([string]$src.GetType() -eq "TKMP.Net.MailData_Imap"){
    # ahkからのときはこっちはありえない
    $id = $Global:mail.js.CodeObject.encode($src.UID)
    $path = ($Global:mail.config.workdir_ + "\$id")
  }elseif($src -like '*\*'){
    # 2009-11-30 LVイベントによってはLog、_resultsでfileが渡される、何もしない
    if($src -like "*\#Log\*" -or $src -like "*\_results\*"){
      return ""  # 展開不要
    }
    $path = $src
    $id = (Split-Path -Leaf $src)
  }

  $tmpd = $Global:mail.config.tmpdir_
  $ismd5.Value = 0  # 返しバッファinit

  # decide extract destfolder
  #$dest = $id
  if($id -like "*rfc822*"){
    # 受信メール内添付メール
    $extid = invoke_small "MD5" @($path)
    $ismd5.Value = 1  # 返しバッファへ
    $dest = "$tmpd\$extid" # 添付メールネスト対策
  }else{
    if($mime -like  "*rfc822*"){
      # 草稿内添付メール
      $extid = invoke_small "MD5" @($path)
      $dest = "$tmpd\$extid" # 添付メールネスト対策
      $ismd5.Value = 1  # 返しバッファへ
    }else{
      # 通常
      $extid = $id
      $dest = "$tmpd\$id"
    }
  }

  $extdir.Value = $dest  # 返しバッファへ

  if(Test-Path $dest){
    if($is_forcibly){
      # 放置 cleaning で消されても再展開すればOK
      # senderで開いたとき(port:5)とsenderで内包転送メール(port:6)を開いたとき
      Remove-Item -Recurse -Path $dest
    }else{
      # viewer表示などは再展開しない
      return $extid
    }
  }
  New-Item $dest -ItemType Directory | Out-Null

  # 全フィールド列挙、本文添付も
  $resp = $dest  # 添付ファイル出力フォルダの指示
  $m = readMail ($src) ('*', 'body', 'file') ([ref] $resp)
    if(!$m){
        throw $resp
    }

  $hbuf = ""
  $bbuf = ""
  $fbuf = ""
  if($m -is [hashtable]){ # 純粋下書きの場合
    $m.Keys | % {
      $n = $_
      switch($n){
        'body' { $bbuf += $m.$n }
        default {
          $hbuf += $n + ": " + $m.$n + "`r`n"
        }
      }
    }
  }else{
    if($m.GetType().Name -eq "PSCustomObject"){
      $mm = $m
    }else{
      $mm = $m.Item(2)
    }
    Get-Member -InputObject $mm | ? {
        $_.MemberType -eq "NoteProperty" } | % {
      $n = $_.Name
      switch($n){
        'body' {
          # 2014-04-05
          # $mimeにある値で強制デコード
          if($mime -eq  "shift_jis"){
            $bbuf += [System.Text.Encoding]::GetEncoding(932).GetString($m.body_byte)
          }else{
            $bbuf += $m.$n
          }
        }
        'body_byte' {
          # 2014-04-08 ヘッダに入らないように特に何もせず
        }
        'file' {
          foreach($f in $m.$n){
            $fbuf += "File: " + $dest + "\" + $f + "`r`n"
          }
        }
        default {
          $hbuf += $n + ": " + $m.$n + "`r`n"
        }
      }
    }
  }
  # ファイルへ保存
  saveByStreamWriter $hbuf "$dest\header.txt"
  saveByStreamWriter $bbuf "$dest\body.txt"
  saveByStreamWriter $fbuf "$dest\files.txt"

<# mandokuse
  # 隠し属性にして
  Set-ItemProperty "$dest\header.txt" -Name Attributes -Value 'Hidden'
  Set-ItemProperty "$dest\body.txt" -Name Attributes -Value 'Hidden'
  Set-ItemProperty "$dest\files.txt" -Name Attributes -Value 'Hidden'
#>

  return $extid
}

function readMail($src, $field, [ref]$resp){
# $src: TKMP.Net.MailData_Imap ならそれを読む（オンライン用）
#       String ならメールファイルパス＝DL済みを読む
# $field "読むヘッダフィールド(大文字小文字区別なし）,
#       や、'body', 'file' を配列で指定する
#       また、'ipaddr'で 最初のグローバルIPアドレスをReceivedから取得する
#       'file'の場合 戻り($ret.file)の値はファイル名の配列
#       この時$respにフォルダパスが指定されていればそこに実ファイルが置かれる
#       '*' なら存在するすべてのヘッダ
#         ('body','file'などは読まないため必要なら同時に指定するkoto)
#
#       'file'の場合 multipart/alternative;の text/htmlパートを添付ファイル扱い
#       で抽出する
#
# 戻り $retは Object,（$ret.Subject, $ret.body (=$src.MainText)など
#       bodyが要求された場合、$ret.body_byte に $src.MainData (本文の生バイト)
#       も格納される。文字化け対策として上位に変換処理を委ねる
#       $ret.file[0] 添付ファイルは配列で
#       multipart は 添付ファイル化？
#       異常時は $false を返し $respへメッセージ設定する
# 注意： Receivedのように複数あるものは全部連結されてstringになる
#       そのためｎ個目というアクセスはできない
#
#       Date:はヘッダになければReceivedから取得する。それでも取得できなければ
#       現在日時を設定する
#
# 下書きの場合： X-Accountヘッダを含んでいれば下書きと判断して
#        _readDraft を呼び出す   
  try{
    if([System.Boolean]($field | ? { $_ -eq "body" -or $_ -eq "file" })){
      $isNoBody = $false
    }else{
      $isNoBody = $true
    }

    if([string]$src.GetType() -eq "TKMP.Net.MailData_Imap"){
      if($src.HeaderLoadedLength -eq 0){
        [void]$src.ReadHeader();
      }
      if($src.BodyLoadedLength -eq 0){
        [void]$src.ReadBody();
      }
      $m = New-Object TKMP.Reader.MailReader($src.DataStream, $isNoBody)
    }else{
      $src = (Resolve-Path $src).Path
 
      $m = New-Object TKMP.Reader.MailReader($src, $isNoBody)
    }

    # 純粋な下書きなら別処理で読んですぐ戻る
    # (draftにコピーされた普通のメールはTKMPで読む必要がある)
    if($m.HeaderCollection["X-Account"]){  # 純粋な下書き
      return _readDraft ($src) ($isNoBody) ([ref]$resp)
    }


    $ret = "{"
    $attfiles = "["
    foreach($f in $field){
      switch($f.toLower()){
        'body' {
          # 2017-07-21 srcがファイルの場合cp932でsaveされているので、
          # text/plain の charset が何であっても、iso-2022-jp以外は結局ここで化ける
          # utf-8 直書きなどのケースも。
          # よってデコードしなおす 
          if([string]$src.GetType() -ne "TKMP.Net.MailData_Imap"){
            if($m.ContentType.Types -eq "Text"-and
              $m.ContentType.SubType -eq "plain" -and
              (-not ($m.ContentType.Charset -like "iso-2022-jp" -or $m.ContentType.Charset -like "utf-8"))){
              $txt = [System.Text.Encoding]::GetEncoding(932).GetString($m.MainData)
            }elseif($m.FirstTextPart.ContentType.Types -eq "Text"-and
              $m.FirstTextPart.ContentType.SubType -eq "plain" -and
              (-not ($m.FirstTextPart.ContentType.Charset -like "iso-2022-jp")) -and
             (-not ($m.FirstTextPart.ContentType.Encoding.ToLower() -eq "quoted-printable")) -and
             (-not ($m.FirstTextPart.ContentType.Encoding.ToLower() -eq "base64"))){
              $txt = [System.Text.Encoding]::GetEncoding(932).GetString($m.FirstTextPart.MainData)
            }else{
              $txt = $m.MainText
            }
          }else{
            $txt = $m.MainText
          }
          $ret += "body:" + (ConvertTo-Json $txt) + ","
          # 2014-04-05 byte arrayでも保管しておき上位で文字化け対策に使用
          if($m.MainData.Length -gt 0){
            $ret += "body_byte:" + (ConvertTo-Json $m.MainData) + ","
          }elseif($m.partCollection[0].MainData.Length -gt 0){
            # 2017-06-16 以下をすべて満たす場合bodyが化ける対策
            # （Apple Mailがこの典型）
            # * 親content-typeにcharsetがない（multipart/altなど）
            # * 先頭パートのcontent-type: charsetがiso-2022-jp以外
            # （tkmldllがiso-2022-jp扱いしてしまう模様）
            # ↑この場合 $m.MainDataが空になっている。
            # ↓こうすれば先頭パートのcp932指定が生かされる
            $ret += "body_byte:" + (ConvertTo-Json $m.partCollection[0].MainData) + ","
          }
        }
        'file' {
          # 展開先が実存ディレクトリならそこへ出力する
          $save_dest = $false
          if($resp.Value -and (Test-Path $resp.Value)){
            $save_dest = (Get-ItemProperty $resp.Value | % { $_.Attributes })
            if($save_dest -like '*Directory*'){
              $save_dest = $resp.Value
            }
          }

          $ret += "file:"
          $m.FileCollection | % {
            $attfiles += (ConvertTo-Json $_.FileName) + ","
            if($save_dest){
              $_.FileSave($save_dest)
            }
          }

          # 出力する場合htmlパートなども添付ファイル扱いで出力
          if($save_dest){
            $attfiles +=  _findAlternativePart $m.PartCollection $save_dest
          }

          $attfiles = $attfiles -replace ",$", "]," #ファイルがあったときだけ有効
          $attfiles = $attfiles -replace "\[$", "[]," #ファイルがなかったときだけ有効

          $ret += $attfiles

        }
        'ipaddr' {
          $re = [regex]"[[\s(]([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})[])\s]"
          $re.Matches($m.HeaderCollection["Received"]) | % {
            $ip = $_.Value -replace "^[^\d]*([\d.]+)[^\d]*$", "`$1"
            If (!($ip -match "^(" `
              + "^(127\.0\.0\.\d+)|" `
              + "(10\.[0-9]+\.[0-9]+\.[0-9]+)|" `
              + "(172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]+\.[0-9]+)|" `
              + "(192\.168\.[0-9]+\.[0-9]+)|" `
              + "(0\.[0-9]+\.[0-9]+\.[0-9]+))$")){
              # no private
              $ret += $f + ":" + (ConvertTo-Json $ip) + ","

                # FIXME: 最初のip(＝最後に現れるもの)を取る
								break  # 残りのipは見ない
            }
          }
        }
        'date' {
          if(!$m.HeaderCollection[$f]){
            # not exists in header
            if($m.HeaderCollection["Received"] -match "(Sun|Mon|Tue|Wed|Thu|Fri|Sat),\s+(\d+)\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d+)\s(\d+):(\d+):(\d+)\s+\+\d{4}"){
              $ret += $f + ":" + (ConvertTo-Json $Matches[0]) + ","
            }else{
              # not in received header too
              $ret += $f + ":" + (ConvertTo-Json (dateStrFixedDigits (Get-Date))) + ","
            }
          }else{
            $ret += $f + ":" + (ConvertTo-Json (dateStrFixedDigits ($m.HeaderCollection[$f]))) + ","
          }
        }
        'path' {
          if([string]$src.GetType() -eq "TKMP.Net.MailData_Imap"){
            # オンラインなら受信フォルダのパス
            $path = $Global:mail.config.workdir_ + "\"
            $path += $Global:mail.js.CodeObject.encode($src.UID)
            
          }else{
            # オフラインならそのパス
            $path = $src
          }
          $ret += "path:" + (ConvertTo-Json $path) + ","
        }
        '*' {
          foreach($h in $m.HeaderCollection){
            $ret += $h.Name + ":" + (ConvertTo-Json $h.Data) + ","
          }
        }
        default {
          if(!$m.HeaderCollection[$f]){
            $ret += $f + ":" + '""' + ","
          }else{
            $ret += $f + ":" + (ConvertTo-Json $m.HeaderCollection[$f]) + ","
          }
        }
      }
    }
    $ret = (ConvertFrom-Json ($ret -replace ",$", "}"))

  }catch [Exception]{
    Write-host -ForegroundColor Red $_.Exception
    $resp.Value =  $_.Exception
    return $false
  }
  return $ret
}

function _findAlternativePart($parts, $save_dest){
  # PartCollectionをくだりaltテキストを$save_destへ出力
  # htmlメールなどを添付ファイル化する
  $ret = ""
  foreach($p in $parts){
#Write-Host ($p.ContentType.SubType)
    if($p.ContentType.Types -eq [TKMP.Reader.Header.ContentType+MIMETypes]::Text){
      if($p.ContentType.SubType -eq "html"){
        $ext = "html"
        $base = "mail"
        $i = 0
        for(; $i -lt 256 ; $i++){
          if($i){
            $path = "$save_dest\$base($i).$ext"
          }else{
            $path = "$save_dest\$base.$ext"
          }
          if(!(Test-Path $path)){
            break
          }
        }
        $enc = charset2enc $p.ContentType.Charset
        saveByStreamWriter $p.MainText $path $false $enc
        $ret += (ConvertTo-Json (Split-Path -Leaf $path)) + ","
      }
    }
    $ret += _findAlternativePart $p.PartCollection $save_dest
  }
  return $ret
}

function charset2enc($charset){
	# charset 表記を .netエンコーディング表記に変換する（一致しないものある）
	# メールのcharset指定と.Net名が異なる場合例外になる
	# c.f.）http://www.atmarkit.co.jp/ait/articles/0304/11/news004.html
	# その場合はメールの指定を使用せず.Netで使える名でencodeする
	if($charset -like "cp-850"){
		$enc = [System.Text.Encoding]::GetEncoding("ibm850")
	}else{
		$enc =  [System.Text.Encoding]::GetEncoding($charset)
	}
	return $enc
}

function saveByStreamWriter($str, $path, $isAppend = $false,
    $enc = [System.Text.Encoding]::Default ){
  $sw = New-Object System.IO.StreamWriter($path, $isAppend, $enc)
  $sw.Write($str)
  $sw.Close()
}

<#
	} mail extraction
#>
<#
  search conditions
#>
function _AND{
  Param([parameter(Mandatory=$true)] [object]  $cond1,
        [parameter(Mandatory=$true)] [object] $cond2)
  $r =  New-Object TKMP.Net.SearchKey.AND($cond1, $cond2)
  return $r
}
function _BEFORE{
  Param([parameter(Mandatory=$true)] [datetime] $date)
  $r =  New-Object TKMP.Net.SearchKey.BEFORE($date)
  return $r
}
function _BODY{
  Param([parameter(Mandatory=$true)] [string] $text)
  $r =  New-Object TKMP.Net.SearchKey.BODY($text)
  return $r
}
function _HEADER{
  Param(
    [parameter(Mandatory=$true)] [string] $field,
    [parameter(Mandatory=$true)] [string] $value)
  $r =  New-Object TKMP.Net.SearchKey.HEADER($field, $value)
  return $r
}
function _FROM{
  Param(
    [parameter(Mandatory=$true)] [string] $value)
  $r =  New-Object TKMP.Net.SearchKey.HEADER('From', $value)
  return $r
}
function _KEYWORD{
  Param([parameter(Mandatory=$true)] [string] $value)
  $r =  New-Object TKMP.Net.SearchKey.HEADER($value)
  return $r
}
function _NOT{
  Param([parameter(Mandatory=$true)] [object] $cond)
  $r =  New-Object TKMP.Net.SearchKey.NOT($cond)
  return $r
}
function _OR{
  Param([parameter(Mandatory=$true)] [object] $cond1,
        [parameter(Mandatory=$true)] [object] $cond2)
  $r =  New-Object TKMP.Net.SearchKey.OR($cond1, $cond2)
  return $r
}
function _SINCE{
  Param([parameter(Mandatory=$true)] [datetime] $date)
  $r =  New-Object TKMP.Net.SearchKey.SINCE($date)
  return $r
}
function _SUBJECT{
  Param([parameter(Mandatory=$true)] [string] $text)
  $r =  New-Object TKMP.Net.SearchKey.SUBJECT($text)
  return $r
}
function _TEXT{
  Param([parameter(Mandatory=$true)] [string] $text)
  $r =  New-Object TKMP.Net.SearchKey.TEXT($text)
  return $r
}

<#
  the main command
#>
function mail
{
  Param(
    [string]  $connect,
    [switch]  $disconnect,
    [array]   $deleteToggle,
    [switch]  $length,
    [switch]  $list,
    [switch]  $header,
    [switch]  $_delete,
    [switch]  $info,
    [int]     $invoke,
    [int]     $seek,
    [switch]  $deleteReset,
    [int]     $view = $Global:mail.i,
    [int]     $exprore,
    [object]  $search,
    [switch]  $show_accounts,
    [switch]  $show_template,
    [switch]  $clean,
    [switch]  $init
  )

  try{
    if($connect -ne ""){
      imapDisconnect -is_quiet
      $Global:mail.cia = $Global:mail.accxml.selectSingleNode( `
          "/accounts/account-def[@id='$connect']")
      if(!$Global:mail.cia){
          throw "cold spa cli: $connect : no such account."
      }
      $resp = ""
      $ret = imapConnect  $Global:mail.cia ([ref] $resp)
    }elseif($deleteToggle.Count -gt 0){
      deleteMail $deleteToggle
    }elseif($deleteReset){
      $Global:mail.deletion = @{}
    }elseif($disconnect){
      if($_delete){
        doDelete
      }
      imapDisconnect
    }elseif($init){
      init
    }elseif($clean){
      if($_delete){
        doDelete
      }
      imapDisconnect
      $Global:mail = $null
    }elseif($length){
      if(!(retrieve)){return}
      $Global:mail.mbox.MailDatas.Count
    }elseif($info){
      if(!$Global:mail){
        retrieve
        return
      }
      Write-Host -ForegroundColor Green ($Global:mail.cia.addr + ": new " + $Global:mail.mbox.RecentCount + " mail(s).")
    }elseif($invoke){
      $b = (viewMail -i $Global:mail.i -mime "" -is_silent)
      invokeURL $b $invoke
    }elseif($list){
      listMail
    }elseif($seek){
      seekMail $seek
    }elseif($exprore){
     exproreMail $exprore
    }elseif($search){
      searchMail $search
    }elseif($show_accounts){
      showAccounts
    }elseif($show_template){
      showTemplate

    # last
    }elseif($view){
      viewMail $view
    }
  }catch [Exception]{
      if($_.Exception -match "I/O.*エラー"){
        Write-Host -ForegroundColor Yellow $_.Exception
        $Global:mail.list = $null
        if(retrieve){
          Write-Host -ForegroundColor Yellow 'try again.' 
          return
        }
      }
      Write-Host -ForegroundColor Red $_.Exception
  }
}
