#!/usr/bin/env bash
# 
# Build a php package 
# 


#
# Configuration 
#

BASEDIR=$(dirname $(readlink -f $0))
CONFIG_FILE=$BASEDIR/conf/config.global.ini


# Includes
source $BASEDIR/lib/bash_ini_parser
source $BASEDIR/lib/common

# Loading configuration options

cfg_parser $CONFIG_FILE
cfg_section_global
cfg_section_php
IFS=" "
LOG_PATH=$PHP_LOG_FILE

# script should fail once a command invocation itself fails.
set -e

# Set the `PHP_BUILD_DEBUG` environment variable to `yes` to trigger the
# `set -x` call, which in turn outputs every issued shell command to `STDOUT`.
if [ -n "$PHP_BUILD_DEBUG" ]; then
    set -x
fi

# Preserve STDERR on FD3, so we can easily log build errors on FD2 to a file and
# use FD3 for php-build's visible error messages.
exec 3<&2

# Redirect everything logged to STDERR (except messages by php-build itself)
# to the Log file.
exec 4<> "$LOG_PATH"


install_system_dependencies() { 
    # Propose to download dependencies
    echo "[Question] Would you like to install PHP dependencies* ?"
    echo " * requires sudo permissions"
    echo " * Process to installation of packages ? (Y/n)";
    read resp
    if [ "$resp" = "Y" -o "$resp" = "" -o  "$resp" = "Y" ]; then
       #sudo apt-get build-dep php5;
       local IFS=" "
       sudo apt-get install $PHP_SYSTEM_DEPS
       if [ ! -f /usr/lib/x86_64-linux-gnu/libc-client.a ]; then
            sudo ln -s /usr/lib/libc-client.a /usr/lib/x86_64-linux-gnu/libc-client.a;
       fi
       if [ ! -f /usr/include/gmp.h  ]; then
            sudo ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h 
       fi
    else
       echo "[+] Warning: installation of system deps skipped"
    fi
}

check_directories() {
    # Ensure BUILD_PATH exists
    echo "[+] Ensure build_path '$PHP_BUILD_PATH' exists"
    if [ ! -d $PHP_BUILD_PATH ]; then
        mkdir -p $PHP_BUILD_PATH
        if [ $? -ne 0 ]; then
           build_error_exit 2 "!!! Error, Cannot create build_path directory"
        fi
    fi
    
    echo "[+] Checking for previous extracted source archive"
    if [ -d $PHP_BUILD_PATH/php-$PHP_VERSION ]; then
        echo "  * The PHP_BUILD_PATH already contains "
        echo "  * the php sources ".
        echo "  * -> $PHP_BUILD_PATH/php-$PHP_VERSION"
        echo "  * Do you want to delete all its content (Y/n) ? "
        read resp
        if [ "$resp" = "Y" -o  "$resp" = "" -o "$resp" = "Y" ]; then
            rm -r $PHP_BUILD_PATH/php-$PHP_VERSION
        fi
    fi
    
    echo "[+] Checking whether a previous install exists"
    if [ -d $PHP_INSTALL_PATH ]; then
        echo "  * The PHP_INSTALL_PATH already contain a build :"
        echo "  * -> $PHP_INSTALL_PATH"
        echo "  * Do you want to delete all its content (y/N) ? "
        read resp
        if [ "$resp" = "Y" -o  "$resp" = "Y" ]; then
            rm -rv $PHP_INSTALL_PATH
        fi
    fi
}

download_php_archive() {
   echo "[+] Check for php_archive '$PHP_ARCHIVE' in build_path"
   if [ ! -f $PHP_BUILD_PATH/$PHP_ARCHIVE ]; then
      echo "  * Archive not found, downloading it...."
      wget -q http://$PHP_MIRROR/get/$PHP_ARCHIVE/from/this/mirror -O $PHP_BUILD_PATH/$PHP_ARCHIVE;
      if [ $? -ne 0 ]; then
            build_error_exit 3 "Download of archive failed"
      fi
   fi
   echo "[+] Extract archive in $PHP_BUILD_PATH"
   tar jxf $PHP_BUILD_PATH/$PHP_ARCHIVE --directory $PHP_BUILD_PATH
   if [ $? -ne 0 ]; then
        build_error_exit 4 "Cannot extract archive"
   fi
}

configure_php() {
    if [ ! -d $PHP_BUILD_PATH/php-$PHP_VERSION ]; then
       build_error_exit 10 "Extracted sources not present in $PHP_BUILD_PATH/php-$PHP_VERSION"
    fi 
    cd $PHP_BUILD_PATH/php-$PHP_VERSION;
    echo "[+] Configure"
    make clean || echo "All clean"
    local IFS=" "
    CONFIGURE="--prefix=$PHP_INSTALL_PATH $PHP_CONFIGURE --enable-cli --enable-cgi --enable-fpm --with-fpm-user=$PHP_FPM_USER --with-fpm-group=$PHP_FPM_GROUP $PHP_CONFIGURE_EXTRAS"
    echo " * Configure options: $CONFIGURE";
    if [ "$PHP_BUILD_USE_CLANG" = "true" ]; then
       ./configure $CONFIGURE CC=clang CFLAGS="-O3 -march=native"
    else 
       ./configure $CONFIGURE CFLAGS="-O3"
    fi
    if [ $? -ne 0 ]; then
        build_error_exit 5 "PHP configure failed"
    fi
    cd $BASEDIR
}

make_and_install_php() {
    cd $PHP_BUILD_PATH/php-$PHP_VERSION;
    echo "[+] Make and install"

    # Optimize make for cpu_cores from 4 cores...
    # keep 2 free
    local CPU_CORES=$(grep "cpu cores" /proc/cpuinfo | wc -l)
    make clean
    if [ $CPU_CORES -gt 3 ]; then
       local CORES=$((CPU_CORES-2))
       make -j$CORES
    else
       make
    fi
    
    if [ $? -ne 0 ]; then
      echo "!!! Make error"
      build_error_exit 6 "Make failed"
    fi

    if [ "$PHP_INSTALL_REQUIRES_SUDO" = "true" ]; then
       sudo make install
    else 
       make install
    fi
    cd $BASEDIR
}

set_configuration_files() {
    if [ ! -d $PHP_INSTALL_PATH/etc/pool.d ]; then 
        sudo mkdir -v $PHP_INSTALL_PATH/etc/pool.d 
    fi
    if [ ! -d $PHP_INSTALL_PATH/tmp ]; then 
        sudo mkdir -v $PHP_INSTALL_PATH/tmp
    fi
    if [ ! -d $PHP_INSTALL_PATH/share ]; then 
        sudo mkdir -v $PHP_INSTALL_PATH/share
    fi
    if [ ! -d $PHP_INSTALL_PATH/etc/conf.d ]; then 
        sudo mkdir -v $PHP_INSTALL_PATH/etc/conf.d
    fi

    local SHARE_DIRECTORY=$PHP_INSTALL_PATH/share

    #
    # Preparing default php.ini file
    #

    local FINAL_PATH="$PHP_PACKAGE_PATH"
    local FINAL_LIB_PATH="$FINAL_PATH/lib"
    local FINAL_INC_PATH="$FINAL_LIB_PATH/php"
    local FINAL_EXT_PATH="$FINAL_LIB_PATH/php/extensions/no-debug-non-zts-20131226"

    local TEMP_CONFIG_PATH="$PHP_INSTALL_CONFIG_FILE_PATH"
    sed 's|'{{php_include_path}}'|'$FINAL_INC_PATH'|g; s|'{{php_extension_dir}}'|'$FINAL_EXT_PATH'|g' $PHP_DEFAULT_INI_TPL \
         > $SHARE_DIRECTORY/php.ini.default
    cp -i $SHARE_DIRECTORY/php.ini.default $TEMP_CONFIG_PATH/php.ini

    #
    # Preparing default phpfpm init.d file
    #

    sed 's|'{{php_include_path}}'|'$FINAL_INC_PATH'|g; s|'{{php_extension_dir}}'|'$FINAL_EXT_PATH'|g' $PHP_DEFAULT_INI_TPL \
         > $SHARE_DIRECTORY/php.ini.default
    cp -i $SHARE_DIRECTORY/php.ini.default $TEMP_CONFIG_PATH/php.ini



    #PHP_DEFAULT_FPM_TPL=$PHP_TEMPLATE_PATH/php-fpm.conf.tpl
    #PHP_DEFAULT_INITD_TPL=$PHP_TEMPLATE_PATH/init.d.php-fpm.tpl

exit
    cat /web/nuvolia-server/templates/php_config/php.ini-production.tpl | sed 's|'{{php_include_path}}'|'$FINAL_INC_PATH'|g; s|'{{php_extension_dir}}'|'$FINAL_EXT_PATH'|g'

    
exit

    echo cat $PHP_DEFAULT_INI_TPL | sed 's/$INSTALL_DIR/$PACKAGE_DIR/g'
exit
echo $PHP_INSTALL_CONFIG_FILE_PATH/php.ini

exit;

    echo $PHP_TEMPLATE_PATH;
exit;

    # REPLACE ALL links to temp install directory
    local INSTALL_DIR=$PHP_INSTALL_PATH
    local PACKAGE_DIR=$PHP_PACKAGE_PREFIX;
    local PHP_DEFAULT_INI_FILE=$PHP_BUILD_PATH/php-$PHP_VERSION/php.ini-production
    local PHP_DEFAULT_FPM_FILE=$PHP_INSTALL_PATH/etc/php-fpm.conf.default
    local PHP_DEFAULT_INITD_FILE=$PHP_BUILD_PATH/php-$PHP_VERSION/sapi/fpm/init.d.php-fpm


    sudo cat $PHP_DEFAULT_INI_FILE | sed 's/$INSTALL_DIR/$PACKAGE_DIR/g' > $PHP_CONFIG_FILE_PATH/php.ini.default
    echo cat $PHP_DEFAULT_sudo sed -i 's|'$INSTALL_DIR'|'$PACKAGE_DIR'|g' $PHP_DEFAULT_FPM_FILE
exit 
    sudo cat $PHP_DEFAULT_INITD_FILE | sed 's/$INSTALL_DIR/$PACKAGE_DIR/g' > /etc/init.d/$PHP_INITD_SCRIPT_NAME
    
    exit
    # sudo cp -v $PHP_DEFAULT_INI_FILE $PHP_CONFIG_FILE_PATH/php.ini
    

    sudo cp -v $PHP_CONFIG_FILE_PATH/php-fpm.conf.default $PHP_CONFIG_FILE_PATH/php-fpm.conf
    sudo cp -v $PHP_BUILD_PATH/php-$PHP_VERSION/sapi/fpm/init.d.php-fpm /etc/init.d/$PHP_INITD_SCRIPT_NAME
    sudo chmod 755 /etc/init.d/$PHP_INITD_SCRIPT_NAME
    

    

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
   NUVOLIA_PHP_BUILD_DIR="$(dirname $PHP_INSTALL_PATH)/php"
   echo "#########################################################"
   echo " Packaging with: "
   echo "fpm -s dir -t deb -C $NUVOLIA_PHP_BUILD_DIR --prefix $PHP_PACKAGE_PREFIX --name $PHP_PACKAGE_NAME --version $PHP_PACKAGE_VERSION --url $PHP_PACKAGE_URL --description \"$PHP_PACKAGE_DESCRIPTION\" --maintainer \"$PHP_PACKAGE_MAINTAINER\" $PHP_PACKAGE_DEPS --verbose --force"
   fpm -s dir -t deb -C $NUVOLIA_PHP_BUILD_DIR --prefix $PHP_PACKAGE_PREFIX --name $PHP_PACKAGE_NAME --version $PHP_PACKAGE_VERSION --url $PHP_PACKAGE_URL --description "$PHP_PACKAGE_DESCRIPTION" --maintainer "$PHP_PACKAGE_MAINTAINER" $PHP_PACKAGE_DEPS --verbose --force
   if [ $? -ne 0 ]; then
        build_error_exit 5 "Creation of deb archive failed"
   fi
}


###############################################
# Installation
###############################################

set_configuration_files;
exit


install_system_dependencies;
check_directories;
download_php_archive;
configure_php;
make_and_install_php;
set_configuration_files;
#start_server_php_fpm
create_deb_archive;






