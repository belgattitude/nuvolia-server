#!/usr/bin/env bash
# 
# Build a php libxl php extension
# 

BASEDIR=$(dirname $(readlink -f $0))
INTERACTIVE=0

# Includes
source $BASEDIR/lib/initializer

init_configuration "php"
init_configuration "libxl"

# script should fail once a command invocation itself fails.
set -e

check_directories() {
    # Ensure BUILD_PATH exists
    echo "[+] Ensure build_path '$LIBXL_BUILD_PATH' exists"
    if [ ! -d $LIBXL_BUILD_PATH ]; then
        mkdir -p $LIBXL_BUILD_PATH
        if [ $? -ne 0 ]; then
           build_error_exit 2 "!!! Error, Cannot create build_path directory"
        fi
    fi
    
    echo "[+] Checking whether a previous install exists"
    if [ -d $LIBXL_INSTALL_PATH ]; then
        echo "  * The LIBXL_INSTALL_PATH already contain a build :"
        echo "  * -> $LIBXL_INSTALL_PATH"
        echo "  * Do you want to delete all its content (Y/n) ? "
        if [ $INTERACTIVE -gt 0 ]; then
            read resp
        else
            resp="Y"
        fi
        if [ "$resp" = "Y" -o "$resp" = "" -o  "$resp" = "Y" ]; then
            if [ "$LIBXL_INSTALL_REQUIRES_SUDO" = "true" ]; then
               sudo rm -rv $LIBXL_INSTALL_PATH/
            else 
               rm -rv $LIBXL_INSTALL_PATH/
            fi
        fi
    fi
    #if [ ! -e $LIBXL_INSTALL_PATH ]; then
    #    echo "  * Creating LIBXL_INSTALL_PATH : $LIBXL_INSTALL_PATH"
    #    sudo mkdir $LIBXL_INSTALL_PATH
    #fi 
}



download_libxl_archive() {
   echo "[+] Check for php_archive '$LIBXL_ARCHIVE' in build_path"
   if [ ! -f $LIBXL_BUILD_PATH/$LIBXL_ARCHIVE ]; then
      echo "  * Archive not found, downloading it...."
      cmd="wget $LIBXL_URL/$LIBXL_ARCHIVE -O $LIBXL_BUILD_PATH/$LIBXL_ARCHIVE"
      echo "Execute: $cmd"
      eval $cmd
      if [ $? -ne 0 ]; then
            build_error_exit 3 "Download of archive failed"
      fi
   fi
   echo "[+] Extract archive in $LIBXL_BUILD_PATH"
   cmd="tar zxf $LIBXL_BUILD_PATH/$LIBXL_ARCHIVE --directory $LIBXL_BUILD_PATH"
   echo "Execute: $cmd"
   eval $cmd
   if [ $? -ne 0 ]; then
        build_error_exit 4 "Cannot extract archive"
   fi

   # COPY to destination
   cmd="sudo cp -r $LIBXL_BUILD_PATH/libxl-$LIBXL_ARCHIVE_VERSION $LIBXL_INSTALL_PATH"
   eval $cmd
}

create_deb_archive() {

   cd $BUILD_OUTPUT_DIR
   echo "#########################################################"
   echo " Packaging with: "
   

   cmd="fpm -s dir -t deb -C $LIBXL_INSTALL_PATH --prefix $LIBXL_INSTALL_PATH \
           --name $LIBXL_PACKAGE_NAME --version $LIBXL_PACKAGE_VERSION --url $LIBXL_PACKAGE_URL \
           --description \"$LIBXL_PACKAGE_DESCRIPTION\" \
           --maintainer \"$LIBXL_PACKAGE_MAINTAINER\" --verbose --force"
   echo $cmd
   eval $cmd
   local ret="$?"
   cd $BASEDIR
   echo "Return code: $ret";
   if [ $ret -ne 0 ]; then 
       build_error_exit 5 "Creation of deb archive failed"
   fi
   
}



check_directories;
download_libxl_archive;
create_deb_archive






