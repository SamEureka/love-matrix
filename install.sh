#!/usr/bin/env bash

## (c) 2023 // Sam Dennon

set -u

danger_will() {
  printf "%s\n" "$@" >2&2
  exit 1337
}

check_and_install_you_some_bash(){
    local TIMEOUT_COUNT=0
    while [ ! -f "/bin/bash" ] && [ "$TIMEOUT_COUNT" -lt 3 ]; do
        echo "get you some bash!"
        apt add bash
        let "TIMEOUT_COUNT++"
    done
    
    if [ -f "/bin/bash" ]; then
        echo "We have positive bashage!"
        exec bash
    else
        danger_will "We tried a few times.... no bash for you."
        
    fi
}

check_and_install_you_some_bash
danger_will "Danger, Will Robinson! DANGER!!"