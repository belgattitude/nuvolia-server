#!/usr/bin/env bash
#
# PHP 5.6 fpm compilation script for Ubuntu 14.04+ 64bits
# @author Sébastien Vanvelthem
#

BASEDIR=$(dirname $(readlink -f $0))
CONFIG_FILE=$BASEDIR/conf/config.ini

# Includes
source $BASEDIR/lib/bash_ini_parser

# Loading configuration options
cfg_parser $CONFIG_FILE
cfg_section_global
cfg_section_php

install_system_dependencies() { 
    # Propose to download dependencies
    echo "[Question] Would you like to install PHP dependencies* ?"
    echo " * requires sudo permissions"
    echo " * Process to installation of packages ? (y/n)";
    read resp
    if [ "$resp" = "y" ]; then
       #sudo apt-get build-dep php5;
       sudo apt-get install $PHP_SYSTEM_DEPS;
       sudo ln -s /usr/lib/libc-client.a /usr/lib/x86_64-linux-gnu/libc-client.a;
    else
       echo "[+] Warning: installation of system deps skipped"
    fi
}

check_directories() {
    # Ensure BUILD_PATH exists
    echo "[+] Ensure build_path '$BUILD_PATH' exists"
    if [ ! -d $BUILD_PATH ]; then
        mkdir -p $BUILD_PATH
        if [ $? -ne 0 ]; then
           echo "!!! Error, Cannot create build_path directory"
           exit 2 
        fi
    fi
}

download_php_archive() {
   echo "[+] Check for php_archive '$PHP_ARCHIVE' in build_path"
   if [ ! -f $BUILD_PATH/$PHP_ARCHIVE ]; then
      echo "  * Archive not found, downloading it...."
      wget -q http://$PHP_MIRROR/get/$PHP_ARCHIVE/from/this/mirror -O $BUILD_PATH/$PHP_ARCHIVE;
      if [ $? -ne 0 ]; then
          echo "!!! Error, download of archive failed"
          exit 3
      fi
   fi
   echo "[+] Extract archive"
   tar jxf $PHP_ARCHIVE
   if [ $? -ne 0 ]; then
     echo "!!! Error, cannot extract from archive"
     exit 4
   fi
}

configure_php() {
    cd $BUILD_PATH/php-$PHP_VERSION;
    echo "[+] Configure"
    make clean
    if [ "$PHP_EXTENSION_IMAP" = "true" ]; then
       PHP_CONFIGURE_EXTRAS="$PHP_CONFIGURE_EXTRAS --with-imap --with-imap-ssl"
    fi;
    CONFIGURE="--prefix=$INSTALL_PATH $PHP_CONFIGURE --enable-cli --enable-cgi --enable-fpm --with-fpm-user=$FPM_USER --with-fpm-group=$FPM_GROUP $PHP_CONFIGURE_EXTRAS"
    ./configure $CONFIGURE;
    if [ $? -ne 0 ]; then
      echo "!!! Error, configure failed"
      exit 5
    fi
}

make_and_install_php() {
    cd $BUILD_PATH/php-$PHP_VERSION;
    echo "[+] Make and install"
    make
    if [ $? -ne 0 ]; then
      echo "!!! Make error"
      exit 6
    fi

    if [ "$INSTALL_REQUIRES_SUDO" = "true" ]; then
       sudo make install
    else 
       make install
    fi
}

set_configuration_files() {
    sudo mkdir -v $INSTALL_PATH/etc/pool.d
    sudo mkdir -v $INSTALL_PATH/etc/conf.d
    sudo cp -v $BUILD_PATH/php-$PHP_VERSION/php.ini-production $PHP_CONFIG_FILE_PATH/php.ini
    sudo cp -v $PHP_CONFIG_FILE_PATH/php-fpm.conf.default $PHP_CONFIG_FILE_PATH/php-fpm.conf
    sudo cp -v $BUILD_PATH/php-$PHP_VERSION/sapi/fpm/init.d.php-fpm /etc/init.d/$INITD_SCRIPT_NAME
    sudo chmod 755 /etc/init.d/$INITD_SCRIPT_NAME
}

start_server_php_fpm() {
    sudo service $INITD_SCRIPT_NAME start
    sudo update-rc.d $INITD_SCRIPT_NAME defaults
}

create_deb_archive() {
   PHP_PACKAGE_DEPS=""
   local IFS=" "
   for package in $PHP_SYSTEM_DEPS
   do 
     PHP_PACKAGE_DEPS="$PHP_PACKAGE_DEPS --depends $package"
   done 
   NUVOLIA_PHP_BUILD_DIR="$(dirname $INSTALL_PATH)/php"
   echo "#########################################################"
   echo " Packaging with: "
   echo "fpm -s dir -t deb -C $NUVOLIA_PHP_BUILD_DIR --prefix $PHP_PACKAGE_PREFIX --name $PHP_PACKAGE_NAME --version $PHP_PACKAGE_VERSION --url $PHP_PACKAGE_URL --description \"$PHP_PACKAGE_DESCRIPTION\" --maintainer \"$PHP_PACKAGE_MAINTAINER\" $PHP_PACKAGE_DEPS --verbose --force"
   fpm -s dir -t deb -C $NUVOLIA_PHP_BUILD_DIR --prefix $PHP_PACKAGE_PREFIX --name $PHP_PACKAGE_NAME --version $PHP_PACKAGE_VERSION --url $PHP_PACKAGE_URL --description "$PHP_PACKAGE_DESCRIPTION" --maintainer "$PHP_PACKAGE_MAINTAINER" $PHP_PACKAGE_DEPS --verbose --force
   if [ $? -ne 0 ]; then
     echo "!!! Error, creation of deb package failed"
     exit 10
   fi
}


###############################################
# Installation
###############################################


create_deb_archive
exit

install_system_dependencies
check_directories
download_php_archive
configure_php
make_and_install_php
set_configuration_files
#start_server_php_fpm
create_deb_archive







