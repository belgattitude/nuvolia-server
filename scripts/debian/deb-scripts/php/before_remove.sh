#!/usr/bin/env bash
# 
# 

BASEDIR=$(dirname $(readlink -f $0))

set -e

source "$BASEDIR/common.sh"


stop_phpfpm

remove_from_startup
remove_init_d

echo "Success"



