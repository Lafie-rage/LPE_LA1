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
export LPE_PATH="/mnt/cle_lpe"
DEVICE="/dev/sdc"
PART_EFI="${DEVICE}2"
DATA_PATH=${WHERE_AM_I_RAN}/data
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

cd $LPE_PATH
if [ ! -d boot/ ]
	then
	 	echo "Dossier $LPE_PATH créer pour monter la clef"
		mkdir boot/
fi

# Clear build folder
if [ ! -d ../build ]
  then
    mkdir ../build
  else
    rm -rf ../build/*
fi

echo -e "\nQuel noyau utiliser :"
echo "1 - Votre noyau et initrd"
echo "2 - Le noyau se trouvant dans $WHERE_AM_I_RAN/src"
read REP
while :
  do
    case $REP in
      1)
        LINUX_VERSION=$(uname -r)
        echo "Votre version de linux est $LINUX_VERSION"

        echo "Copie du noyaux et de initrd"

        cp /boot/vmlinuz-$LINUX_VERSION ./boot/vmlinuz
        cp /boot/initrd.img-$LINUX_VERSION ./boot/initrd.img
        echo "Copie du noyaux et de initrd finie"
        break
        ;;
      2)
        cd $WHERE_AM_I_RAN/src
        tar -Jxvf linux_kernel.tar.xz --directory=../build --one-top-level=linux_kernel --strip-components=1
        cd $WHERE_AM_I_RAN/build/linux_kernel
        cat $DATA_PATH/kernel_config > .config
        # Installation des paquets si nécessaire...
        apt-get install libncurses-dev flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf
        make -j9
        cp arch/x86/boot/bzImage $LPE_PATH/boot/bzImage
        echo "Noyau linux installé avec succés"
        break
        ;;
      *)
        echo -ne "Choix invalide...\nRessayez : "
        read REP
        ;;
    esac
done
enterToContinue

# Installation grub
echo -n "Installation de grub ? [Y/n] (Non par defaut) : "
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

echo -n "Configurer grub ? [Y/n] (Non par défaut) :"
read REP
if [ $REP = "Y" -o $REP = "y" ]
	then
    cd $LPE_PATH
		cd ./boot/grub
		cat $DATA_PATH/grub.cfg > grub.cfg
fi

echo "Configuration de grub terminée"
enterToContinue

echo -en "\nInstaller Busybox ? [Y/n] (Non par défaut ) : "
read REP
if [ "$REP" = "Y" -o "$REP" = "y" ]
	then
		cd $WHERE_AM_I_RAN/src/
		tar -jxvf busybox.tar.bz2 --directory=../build --one-top-level=busybox --strip-components=1
		cd ../build/busybox
    echo "Extraction de busybox finie"
    enterToContinue
    cat $DATA_PATH/busybox_config > .config
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
    cat $DATA_PATH/rcS > rcS
    chmod +x rcS
    cd $LPE_PATH
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
    cat $DATA_PATH/inittab > inittab
    cat $DATA_PATH/"passwd" > "passwd"
    cat $DATA_PATH/group > group
fi

echo "Installation de busybox terminée"
enterToContinue
