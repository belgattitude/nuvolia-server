#!/usr/bin/env bash
# 
# Build a php package 
# 

BASEDIR=$(dirname $(readlink -f $0))
INTERACTIVE=0

# Includes
source $BASEDIR/lib/initializer
init_configuration "php"

# script should fail once a command invocation itself fails.
set -e

install_system_dependencies() { 

    # Propose to download dependencies
    echo "[Question] Would you like to install PHP dependencies* ?"
    echo " * requires sudo permissions"
    echo " * Process to installation of packages ? (Y/n)";
    if [ $INTERACTIVE -gt 0 ]; then
        read resp
    else
        resp="Y"
    fi
    if [ "$resp" = "Y" -o "$resp" = "" -o  "$resp" = "Y" ]; then
        #sudo apt-get build-dep php5;
        local IFS=" "
        sudo apt-get --yes install $PHP_SYSTEM_DEPS
        sudo apt-get --yes install $PHP_SYSTEM_DEPS_MYSQL
        if [ ! -f /usr/lib/x86_64-linux-gnu/libc-client.a ]; then
             sudo ln -s /usr/lib/libc-client.a /usr/lib/x86_64-linux-gnu/libc-client.a;
        fi
        if [ ! -f /usr/include/gmp.h  ]; then
             sudo ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h 
        fi

        if [ ! -e "/usr/lib/libmysqlclient.so.18" ]; then
            build_error_exit 2 "!!! Error, missing libmysqlclient.so.18, ensure mariadb 10+ installed"
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
        if [ $INTERACTIVE -gt 0 ]; then
            read resp
        else
            resp="Y"
        fi
        if [ "$resp" = "Y" -o "$resp" = "" -o  "$resp" = "Y" ]; then
            rm -r $PHP_BUILD_PATH/php-$PHP_VERSION
        fi
    fi
    
    echo "[+] Checking whether a previous install exists"
    if [ -d $PHP_INSTALL_PATH ]; then
        echo "  * The PHP_INSTALL_PATH already contain a build :"
        echo "  * -> $PHP_INSTALL_PATH"
        echo "  * Do you want to delete all its content (Y/n) ? "
        if [ $INTERACTIVE -gt 0 ]; then
            read resp
        else
            resp="Y"
        fi
        if [ "$resp" = "Y" -o "$resp" = "" -o  "$resp" = "Y" ]; then
            if [ "$PHP_INSTALL_REQUIRES_SUDO" = "true" ]; then
               sudo rm -rv $PHP_INSTALL_PATH
            else 
               rm -rv $PHP_INSTALL_PATH
            fi
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

    if [ ! -e "/usr/lib/libmysqlclient.so.18" ]; then
       build_error_exit 10 "Missing /usr/lib/libmysqlclient.so.18, consider install mariadb 10"
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

add_directory_to_installed() {
    
    local DIRECTORY="$1"
    log notice "Creating directory: $DIRECTORY"
    if [ ! -d $DIRECTORY ]; then
        if [ "$PHP_INSTALL_REQUIRES_SUDO" = "true" ]; then
            sudo mkdir -v $DIRECTORY
        else 
            mkdir -v $DIRECTORY
        fi
        log debug " * Directory: $DIRECTORY created"
    else 
        log notice " * Skipped, directory: $DIRECTORY already exists"
    fi
}

set_directory_phpfpm_ownership()
{
    local DIRECTORY="$1"
    log notice "Setting FPMUSER ownership to $DIRECTORY"
    sudo chown $PHP_FPM_USER $DIRECTORY
    sudo chgrp $PHP_FPM_GROUP $DIRECTORY
}

create_config_extensions() {

    local php_config_bin=$PHP_INSTALL_PATH/bin/php-config;

    if [ ! -f $php_config_bin ]; then
        build_error_exit 11 "Cannot find php-config file '$php_config_bin'"
    fi

    local php_ext_dir=$($php_config_bin --extension-dir)
    if [ ! -d $php_ext_dir ]; then
        build_error_exit 12 "PHP extension dir'$php_ext_dir' does not exist"
    fi

    enabled_exts=(${PHP_DEFAULT_ENABLED_EXTS// / })


    local tf=$PHP_BUILD_PATH/extensions.ini

    echo "; Common extension configuration file " > $tf;
    echo " " >> $tf;

    for f in $php_ext_dir/*.so; do

        ext_file=${f##*/}
        ext=${ext_file%.so}

        echo "; PHP '$ext' extension" >> $tf;
        if [ $(contains "${enabled_exts[@]}" "$ext") == "y" ]; then
            echo "extension=$ext_file"  >> $tf;
        else
            echo ";extension=$ext_file"  >> $tf;
        fi
        echo " " >> $tf;
    done

    local SHARE_DIRECTORY=$PHP_INSTALL_PATH/share
    sudo cp $tf $SHARE_DIRECTORY/conf.d.extensions.ini.default

}


set_configuration_files() {
    add_directory_to_installed "$PHP_INSTALL_PATH/etc/pool.d"
    add_directory_to_installed "$PHP_INSTALL_PATH/etc/conf.d"
    add_directory_to_installed "$PHP_INSTALL_PATH/tmp"
    set_directory_phpfpm_ownership "$PHP_INSTALL_PATH/tmp"
    sudo chmod 775 "$PHP_INSTALL_PATH/tmp"
    add_directory_to_installed "$PHP_INSTALL_PATH/share"
    add_directory_to_installed "$PHP_INSTALL_PATH/share/init.d"

    local SHARE_DIRECTORY="$PHP_INSTALL_PATH/share"

    #
    # Preparing default php.ini file
    #
    local FINAL_PREFIX_PATH="$PHP_INSTALL_PATH"
    local FINAL_LIB_PATH="$FINAL_PREFIX_PATH/lib"
    local FINAL_INC_PATH="$FINAL_LIB_PATH/php"
    local FINAL_EXT_PATH="$FINAL_LIB_PATH/php/extensions/no-debug-non-zts-20131226"

    sed 's|'{{php_include_path}}'|'$FINAL_INC_PATH'|g; s|'{{php_extension_dir}}'|'$FINAL_EXT_PATH'|g; s|'{{tz}}'|'$PHP_INI_TIMEZONE'|g' $PHP_DEFAULT_INI_TPL \
        > $TEMP_DIRECTORY/php.ini.default
    sudo cp $TEMP_DIRECTORY/php.ini.default $SHARE_DIRECTORY/php.ini.default
    sudo cp -i $SHARE_DIRECTORY/php.ini.default $PHP_CONFIG_FILE_PATH/php.ini


    #
    # Additional default extension
    #
    sudo cp -i "$PHP_DEFAULT_INI_EXT_TPL" "$SHARE_DIRECTORY/extension.main.ini.default"
    
    #
    # Preparing default phpfpm conf file
    #
    
    sed 's|'{{php_prefix}}'|'$FINAL_PREFIX_PATH'|g; s|'{{fpm_user}}'|'$PHP_FPM_USER'|g; s|'{{fpm_group}}'|'$PHP_FPM_GROUP'|g; s|'{{fpm_listen}}'|'$PHP_FPM_LISTEN'|g' $PHP_DEFAULT_FPM_TPL \
         > $TEMP_DIRECTORY/php-fpm.conf.default
    sudo cp $TEMP_DIRECTORY/php-fpm.conf.default $SHARE_DIRECTORY/php-fpm.conf.default
    sudo cp -i $SHARE_DIRECTORY/php-fpm.conf.default $PHP_CONFIG_FILE_PATH/php-fpm.conf

    #
    # Preparing default phpfpm init.d file
    #

    sed 's|'{{php_prefix}}'|'$FINAL_PREFIX_PATH'|g; s|'{{provides}}'|'$PHP_INITD_SCRIPT_NAME'|g; s|'{{name}}'|'$PHP_PACKAGE_NAME'|g' $PHP_DEFAULT_INITD_TPL \
         > $TEMP_DIRECTORY/$PHP_INITD_SCRIPT_NAME
    sudo cp $TEMP_DIRECTORY/$PHP_INITD_SCRIPT_NAME $SHARE_DIRECTORY/init.d/$PHP_INITD_SCRIPT_NAME
    
    # sudo cp -vi $SHARE_DIRECTORY/init.d/$PHP_INITD_SCRIPT_NAME /etc/init.d/$PHP_INITD_SCRIPT_NAME
    # sudo chmod 755 /etc/init.d/$PHP_INITD_SCRIPT_NAME

    create_config_extensions
    
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
     PHP_PACKAGE_DEPS="$PHP_PACKAGE_DEPS -d $package"
   done 
   # Special case

   PHP_PACKAGE_DEPS=$PHP_PACKAGE_DEPS' -d "libmariadbclient-dev (>=10.0.20)" -d "libmariadbclient18 (>=10.0.20)"'
   
   INITD_SCRIPT="$PHP_INSTALL_PATH/share/init.d/$PHP_INITD_SCRIPT_NAME"

   echo "#########################################################"
   echo " Packaging with: "
   
   cd $BUILD_OUTPUT_DIR

   cmd="fpm -s dir -t deb --deb-init $INITD_SCRIPT -C $PHP_PACKAGE_PATH --prefix $PHP_PACKAGE_PREFIX \
           --name $PHP_PACKAGE_NAME --version $PHP_PACKAGE_VERSION --url $PHP_PACKAGE_URL \
           --description \"$PHP_PACKAGE_DESCRIPTION\" \
           --maintainer \"$PHP_PACKAGE_MAINTAINER\" $PHP_PACKAGE_DEPS \
           --deb-init $INITD_SCRIPT \
           --verbose --force"
   echo $cmd
   eval $cmd
   local ret="$?"
   cd $BASEDIR
   echo "Return code: $ret";
   if [ $ret -ne 0 ]; then 
       build_error_exit 5 "Creation of deb archive failed"
   fi
    #--after-upgrade scripts/rpm/after_upgrade.sh \
    #--after-install scripts/rpm/after_install.sh \
    #--before-remove scripts/rpm/before_remove.sh \
   #sudo cp -i $SHARE_DIRECTORY/extension.main.ini.default $PHP_CONFIG_FILE_PATH/config.d/extension.main.ini
}


###############################################
# Installation
###############################################



install_system_dependencies;

check_directories;

download_php_archive;

configure_php;

make_and_install_php;

set_configuration_files;

####start_server_php_fpm

create_deb_archive;







