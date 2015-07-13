#!/usr/bin/env bash
# 
# Scripts to execute after to nuvolia-server-php upgrade
# 

INITD_SCRIPT=/etc/init.d/nuvolia-server-php

function start_phpfpm() {
    if [ -e $INITD_SCRIPT ]; then
        echo "Start php-fpm after upgrade"
        $INITD_SCRIPT start
    fi
)

start_phpfpm