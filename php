#!/usr/bin/bash
case `uname -sro` in
  Linux*-microsoft-standard*GNU/Linux)
    ;;
  *)
    echo  'this script only works on wsl.'
    exit 2
    ;;
esac
php="/mnt/c/pleiades/xampp/php/php.exe"
function php {
  TMP="$TEMP"
  files=
  opt=
  for f in $*
  do
    if [ -f "$f" ]; then
      files+=" `wp $f`"
    else
      opt+=" $f"
    fi
  done
  $php $opt $files
}
php $@
