#!/usr/bin/bash
unset -f php
case `uname -sro` in
  Linux*-microsoft-standard*GNU/Linux)
    php_x="/mnt/d/pleiades/xampp/php/php.exe"
    ;;
  Linux*-generic*GNU/Linux)
    exec /usr/bin/php "$@"
    ;;
  MSYS_NT-*Msys)
    php_x="/d/pleiades/xampp/php/php.exe"
    ;;
  *)
    echo  'this script only works on msys2, wsl or native linux.'
    exit 2
    ;;
esac

function php {
  TMP="$TEMP"
  if [ "$1" = "-r" ]; then
    shift
    $php_x -r "$*"
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
  $php_x $opt $files
  return $?
}
php $*
exit $?
