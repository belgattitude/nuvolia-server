#!/usr/bin/env bash
# 
# Scripts to execute after to nuvolia-server-php upgrade
# 


BASEDIR=$(dirname $(readlink -f $0))
source "$BASEDIR/deb_scripts_vars.sh"



set_default_php_ini() {
    if [ ! -e "$php_ini_file" ]; then 
        cp $prefix/share/ $php_ini_file
        echo "* default php.ini copied to $conf_dir"
    fi
}

set_default_extensions_ini() {
    if [ ! -e "$extension_conf_file" ]; then
        cp $share_dir/conf.d.extensions.ini.default $extension_conf_file
    fi
}

set_default_phpfpm_conf() {
    if [ ! -e "$extension_conf_file" ]; then
        cp $share_dir/conf.d.extensions.ini.default $extension_conf_file
    fi
}



start_phpfpm() {
    if [ -e $INITD_SCRIPT ]; then
        $INITD_SCRIPT start
        echo "* php-fpm started"
    fi
)

stop_phpfpm() {
    if [ -e $INITD_SCRIPT ]; then
        $INITD_SCRIPT stop
        echo "* php-fpm stopped"
    fi
)