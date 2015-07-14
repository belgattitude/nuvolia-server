#!/usr/bin/env bash
# 
# Scripts to execute after to nuvolia-server-php upgrade
# 

# ===================== CUT FROM HERE ================

#
# CONFIGURATION
# 

PHP_PREFIX={{php_prefix}}
INITD_SCRIPT_NAME={{init_d_name}}
SHARE_DIR=$PHP_PREFIX/share
CONF_DIR=$PHP_PREFIX/etc
PHP_INI_FILE=$CONF_DIR/php.ini
PHP_FPM_CONF_FILE=$CONF_DIR/php-fpm.conf
EXT_CONF_FILE=$CONF_DIR/conf.d/loaded_extensions.ini
OPCACHE_INI_FILE=$CONF_DIR/conf.d/ext-opcache.ini
INITD_SCRIPT=/etc/init.d/$INITD_SCRIPT_NAME



#################
# Functions
#################

uprc="/usr/sbin/update-rc.d"

######################################
# Install files
######################################


set_default_php_ini() {
    echo "[+] Setting default php.ini file"    
    if [ ! -e "$PHP_INI_FILE" ]; then 
        cp -v $SHARE_DIR/php.ini.default $PHP_INI_FILE
        echo "* default php.ini copied to $conf_dir"
    else
        echo "* Skipping, php.ini default already exists"
    fi
}

set_default_extensions_ini() {
    echo "[+] Setting extensions ini file"    
    if [ ! -e "$EXT_CONF_FILE" ]; then
        cp -v $SHARE_DIR/conf.d.extensions.ini.default $EXT_CONF_FILE
        echo "* PHP loaded extensions file have been copied '$EXT_CONF_FILE'"
    else
        echo "* Skipping, php extension file already exists"
    fi
}



set_default_phpfpm_conf() {
    echo "[+] Setting php-fpm conf file"    
    if [ ! -e "$PHP_FPM_CONF_FILE" ]; then
        cp -v $SHARE_DIR/php-fpm.conf.default $PHP_FPM_CONF_FILE
        echo "* php-fpm conf file copied '$PHP_FPM_CONF_FILE'"
    else 
        echo "* Skipping, php-fpm conf file already exists"
    fi
}

set_default_opcache_ini() {
    echo "[+] Setting opcache ini file"
    if [ ! -e "$OPCACHE_INI_FILE" ]; then
        cp -v $SHARE_DIR/extension.opcache.ini.default $OPCACHE_INI_FILE
        echo "* opcache ini file copied '$OPCACHE_INI_FILE'"
    else 
        echo "* Skipping, opcache ini file already exists"
    fi
}

install_apache2_config() {
    echo "[+] Installing apache2 configuration"
    local apache_dir="/etc/apache2/conf-available"
    if [ -d "$apache_dir" ]; then
        cp $SHARE_DIR/apache2/*.conf $apache_dir || "Warning, cannot create apache conf files"
    else 
        echo "Apache2 conf avaible already exists"
    fi
}

set_all_default_config_files() {
    set_default_php_ini;
    set_default_extensions_ini;
    set_default_opcache_ini;
    set_default_phpfpm_conf;
}

######################################
# Daemon
######################################


ensure_init_d() {
    #if [ ! -e $INITD_SCRIPT ]; then 
        cp -v $SHARE_DIR/init.d/$INITD_SCRIPT_NAME $INITD_SCRIPT
        chmod +x $INITD_SCRIPT
    #else
    #    echo "* Skipping init.d, it already exists '$INITD_SCRIPT'"
    #fi
}

start_phpfpm() {
    echo "[+] Staring php-fpm"
    if [ -e $INITD_SCRIPT ]; then
        $INITD_SCRIPT start || echo "Error cannot start"
        echo "* php-fpm started"
    else 
        echo "* Error cannot start php-fpm, init.d script does not exists '$INITD_SCRIPT'"
    fi
}

restart_phpfpm() {
    echo "[+] Re-starting php-fpm "
    if [ -e $INITD_SCRIPT ]; then
        $INITD_SCRIPT restart || echo "Error, cannot restart"
        echo "* php-fpm restarted"
    else 
        echo "* Error cannot restart php-fpm, init.d script does not exists '$INITD_SCRIPT'"
    fi
}


stop_phpfpm() {
    echo "[+] Stopping php fpm"
    if [ -e $INITD_SCRIPT ]; then
        $INITD_SCRIPT stop || echo "Error, cannot stop, not running ?"
        echo "* php-fpm stopped"
    else 
        echo "* Error cannot stop php-fpm, init.d script does not exists '$INITD_SCRIPT'"
    fi

}

ensure_always_start() {
    
    if [ -e $uprc ]; then 
        $uprc $INITD_SCRIPT_NAME defaults
    else 
        echo " Skipping, update-rc.d does not exists"
        echo " Error, you may need to add '$INITD_SCRIPT_NAME' in your startup scripts manually"
    fi

}



######################################
# Uninstall
######################################

remove_init_d() {
    echo "[+] Remove $INITD_SCRIPT file"
    if [ -e $INITD_SCRIPT ]; then 
        rm  $INITD_SCRIPT
    fi
}


remove_from_startup() {
    echo "[+] Removing from startup sequence"
    if [ -e $uprc ]; then 
        $uprc $INITD_SCRIPT_NAME disable || echo "Warning, not enabled"
        $uprc -f $INITD_SCRIPT_NAME remove || echo "Warning, already removed"
    else 
        echo " Skipping, update-rc.d does not exists"
        echo " Error, you may need to remove '$INITD_SCRIPT_NAME' in your startup scripts manually"
    fi

}


purge_php_ini() {
    echo "[+] Purging php.ini"
    if [ -e "$php_ini_file" ]; then 
        rm $SHARE_DIR/php.ini.default $php_ini_file
        echo "* php.ini removed"
    fi
}


purge_extensions_ini() {
    echo "[+] Purging extension file"
    if [ -e "$extension_conf_file" ]; then
        rm $extension_conf_file
        echo "* '$extension_conf_file' removed"
    fi
}

purge_phpfpm_conf() {
    echo "[+] Purging phpfpm config "
    if [ -e "$PHP_FPM_CONF_FILE" ]; then
        rm $PHP_FPM_CONF_FILE
        echo "* '$PHP_FPM_CONF_FILE' removed"
    fi
}


purge_opcache_ini() {
    echo "[+] Purging opcache ini"
    if [ -e "$OPCACHE_INI_FILE" ]; then
        rm $OPCACHE_INI_FILE
        echo "* opcache ini file '$OPCACHE_INI_FILE' removed"
    fi
}


purge_all_config_files() {
    echo "[+] Purging all config files"
    purge_php_ini;
    purge_extensions_ini;
    purge_opcache_ini;
    purge_phpfpm_conf;
}


# ===================== TO HERE ================

########################################
# Running
########################################