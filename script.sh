#! /bin/bash

# Script pour boot sans EFI

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

export WHERE_AM_I_RUNED=$(pwd)
export LPE_PATH="/mnt/cle_lpe"
DEVICE="/dev/sdc"
PART_EFI="${DEVICE}2"

dmesg | grep sd | tail

echo -en "\nSélectionner device : [$DEVICE] ? > "
read REP
if [ -n "$REP" ]
then
	DEVICE="/dev/$REP"
fi

PART="${DEVICE}1"

echo "Utilisation de la partition : $PART"
enterToContinue

if [ ! -z "$(findmnt $PART)" ]
  then
		umount $PART
fi

if [ ! -z "$(findmnt $PART_EFI)" ]
  then
		umount $PART_EFI
fi


echo "Attention, si vous comptez booter vers un PC EFI, il faudra créer une deuxième partition de 100Mo"
enterToContinue

fdisk $DEVICE
clear
mkfs.ext4 $PART

echo "Clé partionnée et formatée"
enterToContinue

if [ ! -d $LPE_PATH ]
	then
	 	echo "Dossier $LPE_PATH créer pour monter la clef"
		mkdir $LPE_PATH
fi

mount $PART $LPE_PATH
echo "Clé montée"
enterToContinue

LINUX_VERSION=$(uname -r)
echo "Votre version de linux est $LINUX_VERSION"

echo "Copie du noyaux et de initrd"
cd $LPE_PATH
if [ ! -d boot/ ]
	then
	 	echo "Dossier $LPE_PATH créer pour monter la clef"
		mkdir boot/
fi
cp /boot/vmlinuz-$LINUX_VERSION ./boot/vmlinuz
cp /boot/initrd.img-$LINUX_VERSION ./boot/initrd.img
echo "Copie du noyaux et de initrd finie"
enterToContinue

# Installation grub
echo -en "\nInstallation de grub ? [Y/n] (Non par defaut) : "
read REP
if [ "$REP" = "Y" -o "$REP" = "y" ]
	then
		echo -e "\nSelectionner un mode d'installation :"
		echo "1 - Installation de grub depuis un pc EFI vers un pc EFI"
		echo "2 - Installation de grub depuis un pc EFI vers un pc non EFI"
		echo "3 - Installation de grub depuis un pc non EFI vers un pc non EFI"
		read REP

		while :
			do
				case $REP in
					1)
						echo  "Installation de grub depuis un pc EFI vers un pc EFI"
						EFI_PATH="/mnt/efi"
            echo "Formatage de la partition EFI"
						mkfs.vfat $PART_EFI
            if [ ! -d $EFI_PATH ]
              then
                echo "Création du dossier /mnt/efi pour monter la partition EFI"
                mkdir $EFI_PATH
            fi
            echo "Montage de la partition EFI"
						mount $PART_EFI $EFI_PATH
						grub-install $DEVICE --boot-directory=$LPE_PATH/boot --efi-directory=$EFI_PATH --removable
						break
						;;

					2)
						echo "Installation de grub depuis un pc EFI vers un pc non EFI"
						grub-install $DEVICE --target=i386-pc --boot-directory=$LPE_PATH/boot
						break
						;;

					3)
						echo "Installation de grub depuis un pc non EFI vers un pc non EFI"
						grub-install $DEVICE --boot-directory=$LPE_PATH/boot
						break
						;;

					*)
						echo -ne "Choix invalide...\nRessayez : "
						read REP
						;;

				esac
		done
fi

echo "Installation de grub terminée"
enterToContinue

echo -en "\nConfigurer grub ? [Y/n] (Non par défaut) :"
read REP
if [ $REP = "Y" -o $REP = "y" ]
	then
		cd ./boot/grub
		cat $WHERE_AM_I_RUNED/data/grub.cfg > grub.cfg
fi

echo "Configuration de grub terminée"
enterToContinue

echo -en "\nInstaller Busybox ? [Y/n] (Non par défaut ) : "
read REP
if [ "$REP" = "Y" -o "$REP" = "y" ]
	then
		cd $WHERE_AM_I_RUNED/src/
    if [ ! -d ../build ]
      then
        mkdir ../build
      else
        rm -rf ../build/*
    fi
		tar -jxvf busybox.tar.bz2 --directory=../build --one-top-level=busybox --strip-components=1
		cd ../build/busybox
    echo "Extraction de busybox finie"
    enterToContinue
    # Pour compilation statique
    #make menuconfig
    # Pour compilation dynamique
    make defconfig
		make -j9
		make CONFIG_PREFIX=$LPE_PATH install
		cd $LPE_PATH
    # Pour compilation dynamique
    if [ ! -d lib ]
      then
        mkdir lib
    fi
    mklibs -v -d lib bin/*
    if [ ! -d dev ]
      then
        mkdir dev
    fi
		if [ -z "$(apt-cache search makedev)" ]
			then
				apt-get install makedev
		fi
		cd dev
    /sbin/MAKEDEV generic console
    echo "MAKEDEV terminé"
    enterToContinue
    cd $LPE_PATH
    if [ ! -d etc/init.d ]
      then
        mkdir -p etc/init.d
    fi
    $LPE_PATH/bin/dumpkmap > etc/french.kmap
    cd etc/init.d
    cat $WHERE_AM_I_RUNED/data/rcS > rcS
    chmod +x rcS
    cd $LPE
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
fi

echo "Installation de busybox terminée"
enterToContinue

# Installation et configuration busybox
# make menuconfig
# make -j9
# cd $LPE_PATH
# mkdir dev
# Installation de makedev s'il ne l'était pas
# apt-get install makedev
# cd dev/
# /sbin/MAKEDEV generic console
# mkdir -p etc/init.d
#cd $LPE_PATH/etc/init.d
#./bin/dumpkmap > etc/french.kmap
#echo "#! /bin/sh
# Monte systeme fichier virtuel qui gere les processus
#mount -t proc /proc
# Monte en lecture ecriture le système de fichier racine
#mount -o remount,rw /
#loadkmap < /etc/french.kmap
#" > rcS
#chmod +x rcS
#cd $LPE
#mkdir proc
#mkdir -p ./sys ./root/run ./root/proc ./root/sys

# Check si ça marche
##
## Start an "askfirst" shell on the console (whatever that may be)
#::askfirst:-/bin/sh
## Start an "askfirst" shell on /dev/tty2-4
#tty2::askfirst:-/bin/sh
#tty3::askfirst:-/bin/sh
#tty4::askfirst:-/bin/sh
## /sbin/getty invocations for selected ttys
#tty4::respawn:/sbin/getty 38400 tty5
#tty5::respawn:/sbin/getty 38400 tty6
# A mettre dans etc/initab

#root::0:0:Super User:/:/bin/sh
# A mettre dans etc/passwd

#root:x:0:
# A mettre dans etc/group
