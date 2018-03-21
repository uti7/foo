#!/bin/bash

# 接続先情報
SSH_USER=user
SSH_HOST=host


# 後述のSSH_ASKPASSで設定したプログラム(本ファイル自身)が返す内容
if [ -n "$PASSWORD" ]; then
  echo $PASSWORD
  exit 0
fi

function init_sshpass
{
  if [ ! -n "$SSH_ASKPASS" ]; then
    read -sp "Password:" SSH_PASS
    echo
    export PASSWORD="$SSH_PASS"
  fi
  export SSH_ASKPASS=$0
  export DISPLAY=dummy:0
}

function do_remote_cmd
{
  target_host="$1"
  shift
  cmd_line="$*"
  [ ! -n "$target_host" ] && echo "ERROR: no target_host." && exit 1
  [ ! -n "$cmd_line" ] && echo "ERROR: no cmd_line." && exit 1

  setsid ssh $SSH_USER@$target_host $cmd_line
  return $?
}

init_sshpass

#cmd="ls -traF nai_file"
#echo $cmd
#do_remote_cmd "$SSH_HOST" "$cmd"
#echo $?

#cmd="ls -la"
#echo $cmd
#do_remote_cmd "$SSH_HOST" "$cmd"
#echo $?

uname -a | do_remote_cmd "$SSH_HOST" "dd of=/tmp/aaa" 2>/dev/null
do_remote_cmd "$SSH_HOST" "chmod 660 /tmp/aaa"
do_remote_cmd "$SSH_HOST" "ls -l /tmp/aaa"
do_remote_cmd "$SSH_HOST" "cat /tmp/aaa"
