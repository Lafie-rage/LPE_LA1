#! /bin/bash


# Verifie si run en root
if [ $(id -u) -ne 0 ]
  then
    echo 1>&2 "Run this script as root"
    exit 1
fi

export WHERE_AM_I_RAN=$(pwd)
export ROOT_PATH="/mnt/root_rpi"

export SRC=$WHERE_AM_I_RAN/build/wiringPi
export TARGET=$WHERE_AM_I_RAN/build/compiled_wiringPi_rpi
export SAMPLE=$WHERE_AM_I_RAN/build/sample_wiringPi_rpi

install_sample() {
  echo "[Sample pi]"
  cd $SRC/examples
  if [ ! -d $SAMPLE ]
    then
      mkdir -p $SAMPLE
  fi
  make clean
  make cross
  chmod +x $SAMPLE/blink_pi
}

install() {
  cd $SRC/wiringPi
  echo "[WiringPi]"
  make clean
  make cross -j9
  make cross_install
  cd ../devLib
  echo "[DevLib]"
  make clean
  make cross -j9
  make cross_install
  cd ../gpio
  echo "[Gpio]"
  mkdir -p $TARGET/bin $TARGET/man
  make clean
  make cross -j9
  make cross_install
  if [ -d $SAMPLE ]
    then
        echo "Le dossiers des exemples de wiringPi existe déjà, voici son contenu :"
        ls $SAMPLE
        echo -n "Voulez-vous recompiler l'exemple wiringPi ? [Y/n] (Non par défaut)"
        read REP
        if [ "$REP" = "Y" -o "$REP" = "y" ]
          then
            install_sample
        fi
      else
        mkdir -p $TARGET
        install_sample
    fi
}



if [ -d $TARGET ]
  then
    echo "Le dossier des sources de wiringPi existe déjà, voici son contenu:"
    ls $TARGET
    echo -n "Voulez-vous recompiler wiringPi ? [Y/n] (Non par défaut)"
    read REP
    if [ "$REP" = "Y" -o "$REP" = "y" ]
      then
        install
    fi
  else
    mkdir -p $TARGET
    install
fi
