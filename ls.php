<?php
header("Expires: Mon, 26 Jul 1997 05:00:00 GMT");
header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
header("Cache-Control: no-store, no-cache, must-revalidate");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");
?><html><body>
<?php
print "<table><tbody>";
unset($outstr);
$cmd = "find . -type f -exec ls -l {} \; | awk '{for(i=1;i<=NF;i++){ if(i==1){ printf(\"<tr>\"); } if(i==NF){ printf(\"<td><a href='%s'>%s</a></td></tr>\",\$i,\$i); }else{ printf(\"<td>%s</td>\",\$i);}}}'";

//print $cmd;
exec($cmd, $outstr, $status);
foreach($outstr as $s){
  print $s;
}
print "</tbody></table>";
?></body></html>
