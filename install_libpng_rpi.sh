#! /bin/bash

install() {
  ./configure --prefix=$TARGET --host=arm-linux-gnueabihf
  make -j9
  make install
}

# Verifie si run en root
if [ $(id -u) -ne 0 ]
  then
    echo 1>&2 "Run this script as root"
    exit 1
fi

export WHERE_AM_I_RAN=$(pwd)
export ROOT_PATH="/mnt/root_rpi"

export SRC=$WHERE_AM_I_RAN/build/libpng-1.6.37
export CROSS_COMPILER=${WHERE_AM_I_RAN}/build/rpi_gcc/bin/arm-linux-gnueabihf-
export TARGET=${WHERE_AM_I_RAN}/build/compiled_libpng_rpi

export CC=${CROSS_COMPILER}gcc
export BUILD_CC=gcc
export ZLIBLIB=$ROOT_PATH/lib
export ZLIBINC=$ROOT_PATH/include
export CPPFLAGS="-I$ZLIBINC"
export LDFLAGS="-L$ZLIBLIB"
export LD_LIBRARY_PATH="$ZLIBLIB:$LD_LIBRARY_PATH"

cd $SRC

if [ -d $TARGET ]
  then
    echo "Le dossier des sources de libpng existe déjà, voici son contenu:"
    ls $TARGET
    echo -n "Voulez-vous recompiler libpng ? [Y/n] (Non par défaut)"
    read REP
    if [ "$REP" = "Y" -o "$REP" = "y" ]
      then
        install
    fi
  else
    mkdir -p $TARGET
    install
fi

cp -r $TARGET/* $ROOT_PATH
