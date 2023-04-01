#!/usr/bin/bash
case `uname -sro` in
  Linux*-microsoft-standard*GNU/Linux)
    ;;
  Linux*-generic*GNU/Linux)
    exec /usr/bin/php $*
    ;;
  MSYS_NT-*Msys)
    ;;
  *)
    echo  'this script only works on msys2, wsl or native linux.'
    exit 2
    ;;
esac

php="/mnt/c/pleiades/xampp/php/php.exe"
function php {
  TMP="$TEMP"
  if [ "$1" = "-r" ]; then
    shift
    $php -r "$*"
    return $?
  fi
  files=
  opt=
  is_optend=0
  for f in $*
  do
    if [ "$f" = "--" ]; then
      is_optend=1
    elif [ -f "$f" ]; then
      files+=" `wp $f`"
    elif [ "$is_optend" -eq 1 ]; then
      files+=" $f"
    else
      opt+=" $f"
    fi
  done
  $php $opt $files
  return $?
}
php $*
exit $?
