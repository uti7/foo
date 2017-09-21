if [ -f /tmp/mintty.log ]; then
  mv -f /tmp/mintty.log /tmp/mintty-`date '+%Y%m%dT%H%M%S'`.log
fi
