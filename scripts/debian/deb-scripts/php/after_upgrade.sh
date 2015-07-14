#!/usr/bin/env bash
# 
# Scripts to execute after to nuvolia-server-php upgrade
# 

BASEDIR=$(dirname $(readlink -f $0))

set -e

source "$BASEDIR/common.sh"

set_all_default_config_files
ensure_init_d

restart_phpfpm

ensure_always_start

echo "Success"
