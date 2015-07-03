BASEDIR=$(dirname $(readlink -f $0))

# Includes
source $BASEDIR/lib/initializer
init_configuration "php"
init_configuration "libxl"


install_system_dependencies() { 

}

check_directories() {
    
}

download_libxl_archive() {
   echo "[+] Check for php_archive '$PHP_ARCHIVE' in build_path"
   if [ ! -f $PHP_BUILD_PATH/$PHP_ARCHIVE ]; then
      echo "  * Archive not found, downloading it...."
      wget -q http://$PHP_MIRROR/get/$PHP_ARCHIVE/from/this/mirror -O $PHP_BUILD_PATH/$PHP_ARCHIVE;
      if [ $? -ne 0 ]; then
            build_error_exit 3 "Download of archive failed"
      fi
   fi
   echo "[+] Extract archive in $PHP_BUILD_PATH"
   tar jxf $PHP_BUILD_PATH/$PHP_ARCHIVE --directory $PHP_BUILD_PATH
   if [ $? -ne 0 ]; then
        build_error_exit 4 "Cannot extract archive"
   fi
}



prepare_deb_source_directory() {
    
    if [ ! -d $PHP_PACKAGE_SRC_PATH ]; then
        mkdir $PHP_PACKAGE_SRC_PATH
    else
        rm -r $PHP_PACKAGE_SRC_PATH
    fi

    cp -r $PHP_INSTALL_PATH $PHP_PACKAGE_SRC_PATH

    #--after-upgrade scripts/rpm/after_upgrade.sh \
    #--after-install scripts/rpm/after_install.sh \
    #--before-remove scripts/rpm/before_remove.sh \
}

create_deb_archive() {
   PHP_PACKAGE_DEPS=""
   local IFS=" "
   for package in $PHP_SYSTEM_DEPS
   do 
     PHP_PACKAGE_DEPS="$PHP_PACKAGE_DEPS --depends $package"
   done 
   
   INITD_SCRIPT="$PHP_INSTALL_PATH/share/init.d/$PHP_INITD_SCRIPT_NAME"

   echo "#########################################################"
   echo " Packaging with: "
   echo "fpm -s dir -t deb -C $PHP_PACKAGE_SRC_PATH --prefix $PHP_PACKAGE_PREFIX --name $PHP_PACKAGE_NAME --version $PHP_PACKAGE_VERSION --url $PHP_PACKAGE_URL --description \"$PHP_PACKAGE_DESCRIPTION\" --maintainer \"$PHP_PACKAGE_MAINTAINER\" $PHP_PACKAGE_DEPS --verbose --force"
   fpm -s dir -t deb --deb-init $INITD_SCRIPT -C $PHP_PACKAGE_SRC_PATH --prefix $PHP_PACKAGE_PREFIX \
           --name $PHP_PACKAGE_NAME --version $PHP_PACKAGE_VERSION --url $PHP_PACKAGE_URL \
           --description "$PHP_PACKAGE_DESCRIPTION" \
           --maintainer "$PHP_PACKAGE_MAINTAINER" $PHP_PACKAGE_DEPS \
           --deb-init $INITD_SCRIPT \
           --verbose --force
   if [ $? -ne 0 ]; then
        build_error_exit 5 "Creation of deb archive failed"
   fi
}


###############################################
# Installation
###############################################

install_system_dependencies;
check_directories;
download_libxl_archive;
create_deb_archive;







