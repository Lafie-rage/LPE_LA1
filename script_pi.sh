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
export ROOT_PATh="/mnt/root_rpi"
DEVICE="/dev/sdc"
DATA_PATH=${WHERE_AM_I_RAN}/data
dmesg | grep -E (sd|mmc) | tail

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
