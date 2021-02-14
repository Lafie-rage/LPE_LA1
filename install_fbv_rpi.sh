#! /bin/bash

install() {
  ./configure --prefix=$TARGET --without-libjpeg --libs="-lpng -lz"
  make cross
  make cross_install
}

# Verifie si run en root
if [ $(id -u) -ne 0 ]
  then
    echo 1>&2 "Run this script as root"
    exit 1
fi


export WHERE_AM_I_RAN=$(pwd)
export ROOT_PATH="/mnt/root_rpi"

export SRC=$WHERE_AM_I_RAN/build/fbv-master
export CROSS_COMPILER=${WHERE_AM_I_RAN}/build/rpi_gcc/bin/arm-linux-gnueabihf-
export TARGET=${WHERE_AM_I_RAN}/build/compiled_fbv_rpi
export LIBPNG_PATH=$WHERE_AM_I_RAN/build/compiled_libpng_rpi

export CC=${CROSS_COMPILER}g++

cd $SRC
mkdir -p $TARGET

if [ -e $TARGET/bin ]
  then
    echo -n "L'executable fbv existe déjà. Voulez-vous le recompiler tout de même ? [Y/n] (Non par défaut)"
    read REP
    if [ "$REP" = "Y" -o "$REP" = "y" ]
      then
        install
    fi
  else
    install
fi

cp -r $TARGET/bin $ROOT_PATH/bin/fbv
