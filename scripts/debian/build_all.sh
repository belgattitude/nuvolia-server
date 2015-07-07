#!/usr/bin/env bash
# 
# Build a php package 
# 

BASEDIR=$(dirname $(readlink -f $0))

build_libxl_package.sh
build_php_package.sh
build_php_ext_phpexcel_package.sh