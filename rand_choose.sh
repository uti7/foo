MAX=$1
LISTFILE=$2
LISTENTRY=`cat $2|wc -l`

while [ "${#KEPT_LINES[*]}" -lt $MAX ]
do
  R=$(( $RANDOM % $LISTENTRY + 1 ))
  I=0
  IS_DUP=0
  while [ $I -lt "${#KEPT_LINES[*]}" ]
  do
    if [ $R -eq "${KEPT_LINES[$I]}" ]; then
      IS_DUP=1
      break
    fi
    I=$(( I + 1 ))
  done
  if [ $IS_DUP -eq 0 ]; then
    KEPT_LINES+=($R)
  fi
done

for i in ${KEPT_LINES[@]}
do
   echo $i
done

