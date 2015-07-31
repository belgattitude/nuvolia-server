#!/usr/bin/env bash
# 
# Build a php package 
# 

BASEDIR=$(dirname $(readlink -f $0))

set -e

$BASEDIR/build_libxl_package.sh;
$BASEDIR/build_php_package.sh;
$BASEDIR/build_php_ext_phpexcel_package.sh;

# Start to test_all
#sudo add-apt-repository ppa:ondrej/apache2
#sudo apt-get --yes install apache2 apache2-utils apache2-dev