#! /bin/bash


# Verifie si run en root
if [ $(id -u) -ne 0 ]
  then
    echo 1>&2 "Run this script as root"
    exit 1
fi

enterToContinue() {
  ./configure --prefix=$TARGET --zprefix
  make -j9
  make install
}

export WHERE_AM_I_RAN=$(pwd)
export ROOT_PATH="/mnt/root_rpi"

export SRC=$WHERE_AM_I_RAN/build/zlib-1.2.11
export CROSS_COMPILER=${WHERE_AM_I_RAN}/build/rpi_gcc/bin/arm-linux-gnueabihf-
export TARGET=${WHERE_AM_I_RAN}/build/compiled_zlib_rpi

export CC=${CROSS_COMPILER}gcc

cd $SRC

if [ -d $TARGET ]
  then
    echo "Le dossier des sources de zlib existe déjà, voici son contenu:"
    ls $TARGET
    echo -n "Voulez-vous recompiler zlib ? [Y/n] (Non par défaut)"
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
