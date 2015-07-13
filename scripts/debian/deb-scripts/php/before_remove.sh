#!/usr/bin/env bash
# 
# 

PREFIX=/opt/nuvolia/php
INITD_SCRIPT=/etc/init.d/nuvolia-php


function stop_phpfpm() {
    if [ -e $INITD_SCRIPT ]; then
        echo "Stopping php-fpm after upgrade"
        $INITD_SCRIPT stop
    fi
)


stop_phpfpm;