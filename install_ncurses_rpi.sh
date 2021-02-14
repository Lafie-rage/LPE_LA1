#! /bin/bash


# Verifie si run en root
if [ $(id -u) -ne 0 ]
  then
    echo 1>&2 "Run this script as root"
    exit 1
fi

export WHERE_AM_I_RAN=$(pwd)
export ROOT_PATH="/mnt/root_rpi"


export SRC=$WHERE_AM_I_RAN/build/ncurses-6.2
export CROSS_COMPILER=${WHERE_AM_I_RAN}/build/rpi_gcc/bin/arm-linux-gnueabihf-
export TARGET=${WHERE_AM_I_RAN}/build/compiled_ncurses_pi/
export NC_PC=${WHERE_AM_I_RAN}/build/compiled_ncurses/

export CC=${CROSS_COMPILER}gcc
export CXX=${CROSS_COMPILER}g++
export TIC=${NC_PC}/bin/tic
export LD_LIBRARY_PATH=${NC_PC}/lib
export BUILD_CC=gcc

install() {
  ./configure --prefix=$TARGET --with-shared --host=x86_64-build_unknown-linux-gnu --target=arm-linux-gnueabihf --disable-stripping
  make -j9
  make install
}

cd $SRC

if [ -d $TARGET ]
  then
    echo "Le dossier des sources de ncurses existe déjà, voici son contenu:"
    ls $TARGET
    echo -n "Voulez-vous recompiler ncurses ? [Y/n] (Non par défaut)"
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


mkdir -p $ROOT_PATH/home/root/ncurses_programs
cd $WHERE_AM_I_RAN/src
make sample_ncurses_pi

echo -e "export TERMINFO=/share/terminfo\nexport TERM=linux" > $ROOT_PATH/etc/profile
