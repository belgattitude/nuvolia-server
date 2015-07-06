# == Class: baseconfig
#
# Performs initial configuration tasks for all Vagrant boxes.
#


class baseconfig {

    package { [
               'php5-cli' 
              ]:
      ensure => present;
    }

}


