<?php
header("Expires: Mon, 26 Jul 1997 05:00:00 GMT");
header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
header("Cache-Control: no-store, no-cache, must-revalidate");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");
?><html><head><style>
table tr:nth-child(even) {
background: #F9F9F9;
}
table tr:nth-child(odd) {
background: #F0FAE2;
}
td.text-right {
	text-align: right;
}
td.item-no {
	color: #000000;
}
</style></head><body>
<?php
$myname = basename(__FILE__);
?>
<table><caption><?=$myname?></caption><thead><tr><th>No.</th><th>Size</th><th colspan="3">Date</th><th>Name</th></tr></thead>
<tbody>
<?php
unset($outstr);
$cmd = <<< EOC
find . -type f -print | xargs ls -lh | grep -v $myname | awk 'BEGIN{no=1}match(\$NF,/^\.\/\./)==0{printf("<tr><td class=\"text-right item-no\">%d</td>",no);for(i=5;i<=NF;i++){class_spec="";if(i>=5&&i<=7){class_spec=" class=\"text-right\"";}if(i==NF){dsp_name=\$i;sub(/^\.\//,"",dsp_name);printf("<td><a href=\"%s\">%s</a></td></tr>",\$i,dsp_name);}else{v=\$i;printf("<td%s>%s</td>",class_spec,v);}}no++}'
EOC;

exec($cmd, $outstr, $status);
foreach($outstr as $s){
  print $s;
}
?>
</tbody></table>
<?php //print "<pre>".htmlspecialchars($cmd)."</pre>"; ?>
</body></html>
