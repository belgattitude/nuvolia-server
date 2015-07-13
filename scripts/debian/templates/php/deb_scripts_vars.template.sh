#!/usr/bin/env bash
# 
# Standard variables for deb install
#
 
PHP_PREFIX={{php_prefix}}
SHARE_DIR=$PHP_PREFIX/share
CONF_DIR=$prefix/etc
PHP_INI_FILE=$CONF_DIR/php.ini
EXT_CONF_FILE=$CONF_DIR/conf.d/loaded_extensions.ini
