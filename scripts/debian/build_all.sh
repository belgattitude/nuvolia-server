#!/usr/bin/env bash
# 
# Build a php package 
# 

BASEDIR=$(dirname $(readlink -f $0))

set -e

$BASEDIR/build_libxl_package.sh;
$BASEDIR/build_php_package.sh;
$BASEDIR/build_php_ext_phpexcel_package.sh;