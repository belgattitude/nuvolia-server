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
init_configuration "php_ext_phpexcel"

# script should fail once a command invocation itself fails.
set -e


PHP_BASE=$PHP_INSTALL_PATH
PHP_CONFIG="$PHP_INSTALL_PATH/bin/php-config"
PHP_EXT_DIR=$($PHP_CONFIG --extension-dir)
PHPIZE="$PHP_INSTALL_PATH/bin/phpize"
EXT_FILE="$PHP_EXT_DIR/excel.so"


check_directories() {
    if [ ! -e $PHP_CONFIG ]; then
        build_error_exit 10 "PHP component must be installed prior to building extensions, missing php-config"
    fi

    if [ ! -e $PHPIZE ]; then
        build_error_exit 10 "PHP component must be installed prior to building extensions, missing phpize"
    fi


    if [ ! -d $PHP_EXT_DIR ]; then
        build_error_exit 11 "PHP extension dir does not exists '$PHP_EXT_DIR'"
    fi

    if [ -d "$PHPEXCEL_BUILD_PATH/$PHPEXCEL_ARCHIVE_DIRECTORY" ]; then
        rm -r "$PHPEXCEL_BUILD_PATH/$PHPEXCEL_ARCHIVE_DIRECTORY"
    fi

    if [ -e "$EXT_FILE" ]; then
        sudo rm "$EXT_FILE"
    fi

}

# Download ilia php_excel
download_phpexcel() {
    local archive="$PHPEXCEL_BUILD_PATH/$PHPEXCEL_ARCHIVE"
    if [ ! -e "$archive" ]; then 
        wget "$PHPEXCEL_URL/$PHPEXCEL_ARCHIVE" -O "$archive"
    fi
    cmd="tar zvxf $archive --directory $PHPEXCEL_BUILD_PATH"
    echo "Execute: $cmd"
    eval $cmd
    if [ $? -ne 0 ]; then
         build_error_exit 4 "Cannot extract archive"
    fi
}


make_extension() {



    local libxl_dir=$LIBXL_INSTALL_PATH
    local libxl_lib_dir="$libxl_dir/lib64"

    cd "$PHPEXCEL_BUILD_PATH/$PHPEXCEL_ARCHIVE_DIRECTORY"

    eval "$PHPIZE"

    local cmd="./configure --with-excel=$libxl_dir --with-php-config=$PHP_CONFIG --with-libxl-libdir=$libxl_lib_dir --with-libxl-incdir=$libxl_dir/include_c"
    echo "Executing: $cmd"
    eval $cmd
    make 
    #make test
    sudo make install


    if [ ! -e $EXT_FILE ]; then
        build_error_exit 12 "Cannot find extenstion '$EXT_FILE'"
    fi
    
    # $env = array('LDFLAGS' => "-L$libxl_lib_dir",
    # 'CPPFLAGS' => "-I$libxl_dir/include_c");

    
}


create_deb_archive() {

   cd $BUILD_OUTPUT_DIR
   echo "#########################################################"
   echo " Packaging with: "

   local CONF_FILE="$PHP_CONFIG_FILE_PATH/conf.d/extension.phpexcel.ini"
   sudo cp -i $PHPEXCEL_INI_EXT_TPL $CONF_FILE

   cmd="fpm -s dir -t deb \
           --name $PHPEXCEL_PACKAGE_NAME --version $PHPEXCEL_PACKAGE_VERSION --url $PHPEXCEL_PACKAGE_URL \
           --description \"$PHPEXCEL_PACKAGE_DESCRIPTION\" \
           --depends=\"$LIBXL_PACKAGE_NAME (=$LIBXL_PACKAGE_VERSION)\" \
           --depends=\"$PHP_PACKAGE_NAME (=$PHP_PACKAGE_VERSION)\" \
           --maintainer \"$PHPEXCEL_PACKAGE_MAINTAINER\" --verbose --force \
            $EXT_FILE $CONF_FILE"
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
download_phpexcel;
make_extension;
create_deb_archive;
