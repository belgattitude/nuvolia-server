#!/usr/bin/env bash
# 
# Standard variables for deb install
#

# Directories
 
PHP_PREFIX={{php_prefix}}
SHARE_DIR=$PHP_PREFIX/share
CONF_DIR=$prefix/etc

# Files

PHP_INI_FILE=$CONF_DIR/php.ini
PHP_FPM_CONF_FILE=$CONF_DIR/php-fpm.conf
EXT_CONF_FILE=$CONF_DIR/conf.d/loaded_extensions.ini
OPCACHE_INI_FILE=$CONF_DIR/conf.d/ext-opcache.ini

# INIT.D


INITD_SCRIPT_NAME={{init_d_name}}
INITD_SCRIPT=/etc/init.d/$INITD_SCRIPT_NAME

