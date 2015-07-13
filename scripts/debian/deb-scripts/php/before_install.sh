#!/usr/bin/env bash
# 
# Scripts to execute on install 
# 

BASEDIR=$(dirname $(readlink -f $0))

set -e

source "$BASEDIR/common.sh"

echo "COOL"
exit 10