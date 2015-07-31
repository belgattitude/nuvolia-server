#!/bin/sh
#

local_bindir="/usr/local/bin";

php_binaries="php pear phpize pecl phar php-config"
for f in $php_binaries
do
  #bin_file="$nuvolia_bin_dir/$f"
  link_file="$local_bindir/$f"
  echo "Checking: $link_file"
  if [ -h $link_file ]; then
      echo " * Removing link file $link_file"
      rm $link_file
  fi
done

