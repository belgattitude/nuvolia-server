#!/usr/bin/env bash
# 
# Scripts to execute prior to nuvolia-server-php upgrade
# 

INITD_SCRIPT=/etc/init.d/nuvolia-server-php

function stop_phpfpm() {

    if [ -e $INITD_SCRIPT ]; then
        echo "Stopping php-fpm before upgrade"
        $INITD_SCRIPT stop
    fi
)

# stop_phpfpm