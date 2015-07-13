#!/usr/bin/env bash
# 
# Scripts to execute on install 
# 

BASEDIR=$(dirname $(readlink -f $0))

set -e

source "$BASEDIR/common.sh"

set_default_php_ini;
set_default_extensions_ini;
set_default_phpfpm_conf;
