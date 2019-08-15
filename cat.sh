
# concat csv for all

# source: http://nlftp.mlit.go.jp/isj/index.html

outfile=${1:-mst_geocode_list.csv}
\ls -1 [0-9]*.csv | awk -v outfile=$outfile 'BEGIN{begin_line=1;print "rm -f " outfile;} $0!=outfile{\
  printf("w3m -I CP932 %s|tail --lines=+%d >> %s\n",$0,begin_line,outfile);\
  if(begin_line==1){ begin_line++; }\
}'
