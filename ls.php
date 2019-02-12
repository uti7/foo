<?php
header("Expires: Mon, 26 Jul 1997 05:00:00 GMT");
header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
header("Cache-Control: no-store, no-cache, must-revalidate");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");
?><html><head><style>
.container {
  width: 80%;
  margin: 2rem auto;
}
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
.folder:before {
  margin: 0 10px 0 0;
  content: " ";
  display: inline-block;
  width: 1rem;
  height: 1rem;
  background: url("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAIAAADYYG7QAAAABnRSTlMAQABgAICTOhfYAAAAV0lEQVRYhe3OAQ2AMBAEwXrCAFKQUhvvFg2k1/QTZrMCZtzPbPU4LgACAjoJuj5WVb1AO0yroLgpAMqaMqDFgICAgICAgICAgICAgICAMqAOAwEB/Q70AjAur4we4qe8AAAAAElFTkSuQmCC");    
  background-size: contain;
  vertical-align: middle;
}
</style></head><body>
<?php
$myname = basename(__FILE__);
//$topdir = ".";
$topdir = "data";
?>
<div class="container">
<table><caption>Files</caption>
<!--<thead><tr><th>No.</th><th>Size</th><th colspan="3">Date</th><th>Name</th></tr></thead>-->
<tbody>
<?php
unset($outstr);
$cmd = <<< EOC
for d in `find $topdir -name .git -prune -o -type d -print`; do ls -lhd \$d && find \$d  -maxdepth 1 -mindepth 1 -type f -exec ls -lhd {} \; ;done \
| awk -v file_indent=4 -v file_ncols=5 'BEGIN{\
  #print "<tr><td>$topdir</td></tr>";\
}\
match(\$1,"^d")>0{\
  f = "";\
  for(i=9;i<=NF;i++){\
    if(f==""){ f=\$i; }else{ f = f " " \$i; }\
  }\
  print "<!--" NR "-->";\
  print "<tr>";\
  n = split(f, d, "/");\
	if(n > 1){\
		nofspan = n-1;\
		dir_indent_td = "<td colspan=\"" nofspan "\"></td>";
		print dir_indent_td;\
	}else{\
		nofspan = 0;\
	}\
  print "<td class=\"folder\">" d[n] "</td>";
  remain = file_indent + file_ncols - nofspan - 1;\
  print "<td colspan=\"" remain "\"></td>";\
  print "</tr>";
  next;\
}\
NF>=9{\
  print "<tr><td colspan=\"" file_indent "\"></td>";\
  f = "";\
  for(i=5;i<=NF;i++){\
    class_spec="";\
    if(i>=5&&i<=7){\
      class_spec=" class=\"text-right\"";\
    }\
    if(i < 9){\
      printf("<td%s>%s</td>",class_spec,\$i);\
    }else{\
      if(f==""){ f=\$i; }else{ f = f " " \$i; }\
      if(i==NF){\
        dsp_name=f;\
        sub(/.*\//,"",dsp_name);\
        if(match(f, /\.txt$/)>0){\
          getline target < f;\
          close(f);\
        }else{\
          target = f;\
        }\
        printf("<td><a href=\"%s\" download=\"%s\">%s</a></td>",target,dsp_name,dsp_name);\
      }\
    }\
  }\
  print "</tr>";
}'
EOC;

exec($cmd, $outstr, $status);
foreach($outstr as $s){
  print $s ."\n";
}
?>
</tbody></table>
<?php //print "<pre>".htmlspecialchars($cmd)."</pre>"; ?>
</div>
</body></html>
