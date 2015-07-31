#!/usr/bin/env bash
# 
# Build a php package 
# 

BASEDIR=$(dirname $(readlink -f $0))
INTERACTIVE=0

# Includes
source $BASEDIR/lib/initializer

init_configuration "tomcat"

# script should fail once a command invocation itself fails.
set -e

check_directories() {
    # Ensure BUILD_PATH exists
    echo "[+] Ensure build_path '$TOMCAT_BUILD_PATH' exists"
    if [ ! -d $TOMCAT_BUILD_PATH ]; then
        mkdir -p $TOMCAT_BUILD_PATH
        if [ $? -ne 0 ]; then
           build_error_exit 2 "!!! Error, Cannot create build_path directory"
        fi
    fi
   
    if [ ! -d "$BUILD_OUTPUT_DIR" ]; then
        mkdir -p "$BUILD_OUTPUT_DIR"
    fi
 
    echo "[+] Checking whether a previous install exists"
    if [ -d $TOMCAT_INSTALL_PATH ]; then
        echo "  * The TOMCAT_INSTALL_PATH already contain a build :"
        echo "  * -> $TOMCAT_INSTALL_PATH"
        echo "  * Do you want to delete all its content (Y/n) ? "
        if [ $INTERACTIVE -gt 0 ]; then
            read resp
        else
            resp="Y"
        fi
        if [ "$resp" = "Y" -o "$resp" = "" -o  "$resp" = "Y" ]; then
            if [ "$TOMCAT_INSTALL_REQUIRES_SUDO" = "true" ]; then
               sudo rm -rv $TOMCAT_INSTALL_PATH/
            else 
               rm -rv $TOMCAT_INSTALL_PATH/
            fi
        fi
    fi
    #if [ ! -e $TOMCAT_INSTALL_PATH ]; then
    #    echo "  * Creating TOMCAT_INSTALL_PATH : $TOMCAT_INSTALL_PATH"
    #    sudo mkdir $TOMCAT_INSTALL_PATH
    #fi 
}



download_tomcat_archive() {
   echo "[+] Check for php_archive '$TOMCAT_ARCHIVE' in build_path"
   if [ ! -f $TOMCAT_BUILD_PATH/$TOMCAT_ARCHIVE ]; then
      echo "  * Archive not found, downloading it...."
      cmd="wget $TOMCAT_URL/$TOMCAT_ARCHIVE -O $TOMCAT_BUILD_PATH/$TOMCAT_ARCHIVE"
      echo "Execute: $cmd"
      eval $cmd
      if [ $? -ne 0 ]; then
            build_error_exit 3 "Download of archive failed"
      fi
   fi
   echo "[+] Extract archive in $TOMCAT_BUILD_PATH"
   cmd="tar zxf $TOMCAT_BUILD_PATH/$TOMCAT_ARCHIVE --directory $TOMCAT_BUILD_PATH"
   echo "Execute: $cmd"
   eval $cmd
   if [ $? -ne 0 ]; then
        build_error_exit 4 "Cannot extract archive"
   fi

}

create_deb_archive() {

   
   cd $BUILD_OUTPUT_DIR

   echo "#########################################################"
   echo " Packaging with: "

   local tomcat_dir=$TOMCAT_BUILD_PATH/apache-tomcat-$TOMCAT_VERSION   
   

   cmd="fpm -s dir -t deb \
           --name $TOMCAT_PACKAGE_NAME -C $tomcat_dir --prefix=/opt/nuvolia/tomcat --version $TOMCAT_PACKAGE_VERSION --url $TOMCAT_PACKAGE_URL \
           --description \"$TOMCAT_PACKAGE_DESCRIPTION\" \
           --maintainer \"$TOMCAT_PACKAGE_MAINTAINER\" --verbose --force \
            ."
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
download_tomcat_archive;
create_deb_archive






