#! /bin/bash

# Verifie si run en root
if [ $(id -u) -ne 0 ]
  then
    echo 1>&2 "Run this script as root"
    exit 1
fi

enterToContinue() {
 	echo "Appuyez sur ENTRER pour continuer"
	read REP
	clear
}

WHERE_AM_I_RAN=$(pwd)
export BOOT_PATH="/mnt/boot_rpi"
export ROOT_PATH="/mnt/root_rpi"
CROSS_COMPILER=${WHERE_AM_I_RAN}/build/rpi_gcc/bin/arm-linux-gnueabihf-
DEVICE="/dev/sdc"
DATA_PATH=${WHERE_AM_I_RAN}/data
dmesg | grep -E "(sd|mmc|hd)" | tail

echo -en "\nSélectionner device : [$DEVICE] ? > "
read REP
if [ -n "$REP" ]
then
	DEVICE="/dev/$REP"
fi

PART_BOOT="${DEVICE}1"
PART_ROOT="${DEVICE}2"

echo "Utilisation du device : $DEVICE"
enterToContinue

if [ ! -z "$(findmnt $PART_BOOT)" ]
  then
		umount $PART_BOOT
fi

if [ ! -z "$(findmnt $PART_ROOT)" ]
  then
		umount $PART_ROOT
fi

echo "Il vous faudra créer 2 partition : boot de 100Mo et rootfs"
echo "Pensez à activer l'indicateur d'amorçage sur la partition boot à l'aide de a dans fdisk et appliquer le type e à cette partition..."
echo "Important : boot devra être la partition 1 !"
enterToContinue

fdisk $DEVICE
clear
mkfs.vfat $PART_BOOT
mkfs.ext4 $PART_ROOT
echo "Partitionnement et formatage des partitions terminé"
enterToContinue

echo "Montage des partitions"
if [ ! -d $BOOT_PATH ]
	then
	 	echo "Dossier $BOOT_PATH créer pour monter la partition boot"
		mkdir $BOOT_PATH
fi
if [ ! -d $ROOT_PATH ]
	then
	 	echo "Dossier $ROOT_PATH créer pour monter la partition root"
		mkdir $ROOT_PATH
fi

mount $PART_BOOT $BOOT_PATH
mount $PART_ROOT $ROOT_PATH

cp -r $DATA_PATH/boot_rpi/* $BOOT_PATH

cd $WHERE_AM_I_RAN/build/busybox
echo "Voulez-vous forcer le désarchivage de busybox ? [Y/n] (Non par défaut)"
read $REP
if [ "$REP" = "Y" -o "$REP" = "y" ]
  then
    tar -jxvf busybox.tar.bz2 --directory=../build --one-top-level=busybox --strip-components=1
fi

cat $DATA_PATH/busybox_config_rpi > .config

make -j9 CROSS_COMPILE=$CROSS_COMPILER
make CROSS_COMPILE=$CROSS_COMPILER CONFIG_PREFIX=$ROOT_PATH install
chmod +s $ROOT_PATH/bin/busybox

cd $ROOT_PATH
if [ ! -d lib ]
  then
    mkdir lib
fi
cp $WHERE_AM_I_RAN/build/rpi_gcc/my_libs/lib/* lib
if [ ! -d dev ]
  then
    mkdir dev
fi
if [ ! -d dev/pts ]
  then
    mkdir dev/pts
fi
if [ ! -d etc/init.d ]
  then
    mkdir -p etc/init.d
fi
cat $DATA_PATH/french.kmap > etc/french.kmap
cd etc/init.d
cat $DATA_PATH/rcS_rpi > rcS
cat $DATA_PATH/rc.network > rc.network
cat $DATA_PATH/rc.services > rc.services
chmod +x ./*
cd ../
mkdir ifplugd
cat $DATA_PATH/ifplugd.action > ifplugd/ifplugd.action
chmod +x ifplugd/ifplugd.action
mkdir udhcpc
cat $DATA_PATH/udhcpc.action > udhcpc/udhcpc.action
chmod +x udhcpc/udhcpc.action
cat $DATA_PATH/hostname > hostname
cat $DATA_PATH/profile > profile
cd $ROOT_PATH
mkdir -p home/httpd home/root
cat $DATA_PATH/index.html > home/httpd/index.html
cp $DATA_PATH/test_png.png home/root/test_png.png
if [ ! -d run ]
  then
    mkdir -p run
fi
if [ ! -d proc ]
  then
    mkdir proc
fi
if [ ! -d sys ]
  then
    mkdir sys
fi
if [ ! -d root/run ]
  then
    mkdir -p root/run
fi
if [ ! -d root/proc ]
  then
    mkdir -p root/proc
fi
if [ ! -d root/sys ]
  then
    mkdir -p root/sys
fi
cd etc
cat $DATA_PATH/inittab_rpi > inittab
cat $DATA_PATH/"passwd" > "passwd"
cat $DATA_PATH/group > group

echo "Installation de busybox terminée"
enterToContinue

echo -n "Voulez-vous installer dropbear pour configurer SSH ? [Y/n] (Non par défaut)"
read REP
if [ ! "$REP" = "Y" -a ! "$REP" = "y" ]
  then
    exit 0
fi
cd $WHERE_AM_I_RAN/src
tar -jxvf dropbear.tar.bz2 --directory=../build --one-top-level=dropbear --strip-components=1
cd $WHERE_AM_I_RAN/build/dropbear
CC=${CROSS_COMPILER}gcc
CXX=${CROSS_COMPILER}g++
SRC_DEST=$WHERE_AM_I_RAN/build/compiled_dropbear_rpi

install_dropbear() {
  ./configure --host=arm-linux --disable-zlib --prefix=../$SRC_DEST
  make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" -j9
  make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" install 
}

if [ -d $SRC_DEST ]
  then
    echo "Le dossier contenant dropbear existe déjà, voici son contenu."
    ls $SRC_DEST
    echo -n "Voulez-vous l'installer quand même ? [Y/n] (Non défaut)"
    read REP
    if [ "$REP" = "Y" -o "$REP" = "y" ]
      then
        install_dropbear
    fi
  else
    mkdir $SRC_DEST
    install_dropbear
fi

cp -r $SRC_DEST/* $ROOT_PATH
for f in $(ls $SRC_DEST/bin); do
  chmod +s $ROOT_PATH/bin/$f
done
