#!/bin/bash

#
# Retry Script
#
# ./wait-for.sh "<command>"
#
set -o nounset

RETRY_MAX_ATTEMPTS=${RETRY_MAX_ATTEMPTS:-30}
RETRY_DELAY_SECONDS=${RETRY_DELAY_SECONDS:-2}

function fail {
    echo $1 >&2
    exit 1
}

function retry {
  echo "[+] $(timestamp) - trying to execute command: $@"
  local attempts=0
  local max=$RETRY_MAX_ATTEMPTS
  local delay=$RETRY_DELAY_SECONDS

  while [ true ]; do
    "$@" && break || {
      if [[ $attempts -lt $max ]]; then
        ((attempts++))
        echo "[+] $(timestamp) - Attempt failed $attempts/$max. retry in $delay seconds"
        sleep $delay;
      else
        fail "[+] $(timestamp) - Command failed after $attempts attempts"
      fi
    }
    done
}

function timestamp(){
 date +"%Y-%m-%d %T"
}
retry $1

echo ""
echo "Finished"
