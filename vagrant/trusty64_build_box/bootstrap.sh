#!/usr/bin/env bash
#
# Bootstrap vagrant file, used to provision and initialize vagrant box
# 

# Script should fail once a command invocation itself fails.
set -e

#
# * Function to install locale
#   ex. install_locale "en_GB.UTF-8"
#

function install_locale() {
    local locale="$1"
    sudo locale-gen $locale
}


# General apt-sources

install_apt_main_sources() {

    echo "* Install apt_main_sources"

    if [ ! -e "/usr/bin/lsb_release" ]; then
        sudo apt-get install --yes lsb-release
    fi

    DISTRIB_CODENAME=$(lsb_release --codename --short)

    # Will be used to know if a apt-get update is needed
    local detected_changes=0

    if [ ! -e "/etc/apt/sources.list.d/canonical-partner.list" ]; then 
        sudo sh -c 'echo " deb http://archive.canonical.com/ubuntu '${DISTRIB_CODENAME}' partner" > /etc/apt/sources.list.d/canonical-partner.list';
        let "detected_changes+=1"
    fi

    # sudo apt-add-repository ppa:mc3man/trusty-media   # for ffmpeg
    # sudo apt-add-repository ppa:ansible/ansible

    if [ $detected_changes -gt 0 ]; then
        sudo apt-get update
        sudo apt-get --yes upgrade
    fi 
}


# Specific mariadb source


install_apt_mariadb_source() {

    echo "* Install apt_mariadb_source 10.0"

    if [ ! -e "/usr/bin/lsb_release" ]; then
        sudo apt-get install --yes lsb-release
    fi

    DISTRIB_CODENAME=$(lsb_release --codename --short)

    # Will be used to know if a apt-get update is needed
    local detected_changes=0

    if [ ! -e "/etc/apt/sources.list.d/mariadb.list" ]; then
        sudo sh -c 'echo "deb http://ftp.osuosl.org/pub/mariadb/repo/10.0/ubuntu '${DISTRIB_CODENAME}' main" > /etc/apt/sources.list.d/mariadb.list'
        sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
        let "detected_changes+=1"
    fi

    if [ $detected_changes -gt 0 ]; then
        sudo apt-get update
        sudo apt-get --yes upgrade
    fi 

}


#
# * Build environment
#

install_build_env() {
    echo "* Installing build environment"
    sudo apt-get --yes install build-essential clang autoconf gcc bison lemon g++ re2c flex shtool libtool pkg-config
}

#
# * Latest puppet release
#
install_puppet() {
    echo "* Install latest puppet"
    if [ ! -e "/usr/bin/lsb_release" ]; then
        sudo apt-get install --yes lsb-release
    fi

    DISTRIB_CODENAME=$(lsb_release --codename --short)

    if [ ! -e "/etc/apt/sources.list.d/puppetlabs.list" ]; then 
        sudo sh -c 'echo "deb http://apt.puppetlabs.com '${DISTRIB_CODENAME}' main" > /etc/apt/sources.list.d/puppetlabs.list';
        sudo apt-key adv --recv-keys --keyserver pgp.mit.edu 47B320EB4C7C375AA9DAE1A01054B7A24BD6EC30;
        sudo apt-get update
        sudo apt-get upgrade
    fi

    sudo apt-get --yes install puppet

}



#
# * Install latest Oracle Java
# 
install_oracle_java_env() {
    echo "* Install latest oracle java"
    if [ ! -e "/usr/bin/lsb_release" ]; then
        sudo apt-get install --yes lsb-release
    fi

    DISTRIB_CODENAME=$(lsb_release --codename --short)

    if [ ! -e "/etc/apt/sources.list.d/webupd8team-java-${DISTRIB_CODENAME}" ]; then
        sudo add-apt-repository ppa:webupd8team/java
        sudo apt-get update
    fi

    # pre accept licenses -> see http://askubuntu.com/questions/190582/installing-java-automatically-with-silent-option/190674#190674
    echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
    echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
    #sudo apt-get --yes install oracle-java7-installer oracle-java8-installer oracle-java8-set-default 2>&1
    sudo apt-get --yes install oracle-java8-installer oracle-java8-set-default 2>&1
}



#
# * Latest Ruby
# NOTE: puppet does not work with ruby-2.2, switch default to 1.9.1
#
install_ruby_env_2_2() {

    echo "* Install latest ruby environment"

    if [ ! -e "/usr/bin/lsb_release" ]; then
        sudo apt-get install --yes lsb-release
    fi

    DISTRIB_CODENAME=$(lsb_release --codename --short)

    if [ ! -e "/etc/apt/sources.list.d/brightbox-ruby-ng-${DISTRIB_CODEBASE}.list" ]; then
        sudo apt-add-repository ppa:brightbox/ruby-ng
        sudo apt-get update
    fi
    
    sudo apt-get --yes install ruby1.9.1 ruby1.9.1-dev ruby2.2 ruby2.2-dev ruby-switch
    #sudo ruby-switch --set ruby1.9.1
    sudo ruby-switch --set ruby2.2
}


#
# * Ruby env
#
install_ruby_env_1_9() {

    echo "* Install ruby environment"

    if [ ! -e "/usr/bin/lsb_release" ]; then
        sudo apt-get install --yes lsb-release
    fi

    DISTRIB_CODENAME=$(lsb_release --codename --short)

    if [ ! -e "/etc/apt/sources.list.d/brightbox-ruby-ng-${DISTRIB_CODEBASE}.list" ]; then
        sudo apt-get --yes install ruby ruby-dev
    else 
        sudo apt-get --yes install ruby1.9.1 ruby1.9.1-dev ruby-switch
        sudo ruby-switch --set ruby1.9.1
    fi
}



install_gem_fpm() {
    echo " * Install fpm packager with gem"
    if [ ! -e "/usr/local/bin/fpm" ]; then
        sudo gem install fpm
    fi
}

install_gem_webdev() {
    sudo gem install compass sass
}

#
# * Latest nodejs
#

install_nodejs_env() { 
    
    echo "* Install latest nodejs environment"

    if [ ! -e "/etc/apt/sources.list.d/nodesource.list" ]; then
        curl -sL https://deb.nodesource.com/setup_0.12 | sudo bash -
    fi
    sudo apt-get --yes install -y nodejs
    sudo npm install -g grunt-cli bower gulp less jspm
}

#
# * Webmin
#
install_webmin() {
    echo "* Install webmin"
    if [ ! -e "/etc/apt/sources.list.d/webmin.list" ]; then
        sudo sh -c 'echo "deb http://download.webmin.com/download/repository sarge contrib\ndeb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list';
        wget -q http://www.webmin.com/jcameron-key.asc -O- | sudo apt-key add -
        sudo apt-get update
    fi
    sudo apt-get --yes install webmin
}


#
# * Install php cli environment and deps
#
install_php_build_deps() {
    echo "* Install php deps minimal env"
    sudo apt-get --yes install libmariadbclient18 libmariadbclient-dev
    sudo apt-get --yes libmemcache-dev libmemcached-dev libevent-dev
    sudo apt-get --yes install php5-cli php5-mysqlnd libunistring0 libvpx-dev uuid-dev libmagic-dev libwrap0-dev libsystemd-daemon-dev libsasl2-dev unixodbc-dev libgd-dev libenchant-dev libpspell-dev libpq-dev libpng12-dev libbz2-dev libssl-dev libsqlite3-dev libmcrypt-dev libfreetype6-dev zlib1g-dev libgmp-dev libgmp3-dev libxml2 libxml2-dev libcurl4-openssl-dev libfreetype6-dev zlib1g-dev libldap2-dev libkrb5-dev libssh-dev libzip-dev libjpeg-progs libpcre++-dev libjpeg8-dev libtiff5-dev libmagick++-dev libmagick++5 libmagickwand-dev libc-client2007e-dev libt1-dev libicu-dev libc-client2007e-dev libxslt1-dev libmcrypt-dev pkg-config libfcgi0ldbl libfcgi-dev libreadline6-dev libevent-dev libmhash-dev libtinfo5 libtinfo-dev
    if [ ! -e "/usr/lib/x86_64-linux-gnu/libc-client.a" ]; then 
        sudo ln -s /usr/lib/libc-client.a /usr/lib/x86_64-linux-gnu/libc-client.a
    fi
    echo "* Install composer"
    if [ ! -e "/usr/local/bin/composer" ]; then 
        curl -sS https://getcomposer.org/installer | php; sudo mv composer.phar /usr/local/bin/composer
    fi
}


install_locale "en_GB.UTF-8"

install_apt_main_sources
install_apt_mariadb_source

install_build_env

install_ruby_env_1_9
install_puppet

# install_webmin 
# install_oracle_java_env
# install_nodejs_env

#install_latest_ruby_env

install_gem_fpm
#install_gem_webdev

install_php_build_deps

