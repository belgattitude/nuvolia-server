#!/usr/bin/env bash
# 
# Scripts to execute on install 
# 

BASEDIR=$(dirname $(readlink -f $0))

set -e

source "$BASEDIR/common.sh"

set_all_default_config_files
ensure_init_d

start_phpfpm

ensure_always_start

echo "Success"
