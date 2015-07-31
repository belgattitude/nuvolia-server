#!/bin/sh
#

local_bindir="/usr/local/bin";
php_install_path=<%= php_install_path %>

php_binaries="php pear peardev phpize pecl phar phar.phar php-config"
for f in $php_binaries
do
  bin_file="$php_install_path/bin/$f"
  link_file="$local_bindir/$f"
  echo "Checking: $link_file"
  if [ -f $link_file ] && [ ! -h $link_file ]; then
      echo "Error, file '$f' already exists in '$local_bindir/$f'"
      echo "Please remove any existing PHP package that have been"
      echo "installed in $local_bindir"
      exit 1
  else
      if [ -f $link_file ]; then
         echo "* removing old link '$link_file'"
         rm $link_file
      fi
      echo "* Symlinking '$link_file' to '$bin_file'"
      ln -s $bin_file $link_file
  fi
done

