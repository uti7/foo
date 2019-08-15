
# extract csv for each zip what downloaded from:
# http://nlftp.mlit.go.jp/isj/index.html

\ls -1 *.zip | awk 'BEGIN{yyyy=2018;}{\
  basename=$0;\
  sub(/\.zip$/, "",basename);\
  prefecture_no = gensub(/^(..).*$/,"\\1", "g", basename);
  csvpath=basename "/" prefecture_no "_" yyyy ".csv";\
  print "unzip -p " $0 " " csvpath " >`basename " csvpath "`";\
}'
  #print "unzip -l " $0 " " csvpath;\

#Archive:  01000-12.0b.zip
#  Length      Date    Time    Name
#---------  ---------- -----   ----
#        0  2019-06-13 13:30   01000-12.0b/
#  2587261  2019-06-13 09:02   01000-12.0b/01_2018.csv
#     2740  2019-05-24 16:56   01000-12.0b/12.0b.html
#    13946  2019-01-25 19:54   01000-12.0b/META_01_2018.xml
#---------                     -------
#  2603947                     4 files
#
#Archive:  01000-12.0b.zip
#  Length      Date    Time    Name
#---------  ---------- -----   ----
#  2587261  2019-06-13 09:02   01000-12.0b/01_2018.csv
#---------                     -------
#  2587261                     1 file
