#!/bin/bash

echo -n "Did you plug the USB drive or SD card? [y/N] "
read scelta

if [[ ! "$scelta" =~ ^([y-Y][e-E][s-S]|[y-Y])$ ]]; then
    echo "Installation arrested."
    exit
fi

userRun=$(whoami)
echo "Preliminary checks."
if [ "$userRun" != "root" ]; then
    userRoot="n"
else
    userRoot="y"
fi

echo -e "$(lsblk | sed "s/^├─.*$//g" | sed "s/^└─.*//g" | sed "s/$/\n/g" | sed "/^$/d" | sed "s/ MOUNTPOINT//g" | nl -v0)" > /tmp/diskList
lastDisk=$(cat /tmp/diskList | tail -n 1 | awk '{print $1}')
lastDisk=$(( lastDisk + 1))

echo "Select where to flash the Raspbian OS image:"
echo -e "$(cat /tmp/diskList)"
echo "     "$lastDisk " None of above. [exit]"
until [[ $chooseDisk =~ ^([1-$lastDisk])$ ]]; do
    read -rp "Select [1-"$lastDisk"]: " -e -i $lastDisk chooseDisk
done
if [ "$chooseDisk" == "$lastDisk" ]; then
    exit
fi
chooseDisk=$(( chooseDisk + 1))
dkusb="/dev/"$(cat /tmp/diskList | awk -v i=$chooseDisk 'FNR == i {print $2}')

echo "The installation will be done on "$dkusb
echo -n "Continue? [y/N] "
read scelta

if [[ ! "$scelta" =~ ^([y-Y][e-E][s-S]|[y-Y])$ ]]; then
    echo "Installation arrested."
    exit
fi

echo "Wich version of Raspbian OS you want install? "
echo "	1. Raspbian full [with desktop and recommended software]"
echo "	2. Raspbian desktop [with desktop]"
echo "	3. Raspbian server [CLI]"
until [[ $version =~ ^([1-3])$ ]]; do
    read -rp"Select [1-3]: " -e -i 2 version
done
case $version in
    1)
        echo "Raspbian OS full installation"
        osversion=raspbian_full_latest
    ;;
    2)
        echo "Raspbian OS desktop installation"
        osversion=raspbian_latest
    ;;
    3)
        echo "Raspbian OS server installation"
        osversion=raspbian_lite_latest
    ;;
esac

echo -n "Set the ammount of GPU memory (in MB): "
read qgpu

echo -n "Would you like enable SSH? [y/N] "
read sshen

echo -n "Would you like set the official 7 inch LCD [y/N] "
read lcd7inch

echo -n "Would you like to set the WiFi parameters? [y/N] "
read parWiFi

if [[ ! "$parWiFi" =~ ^([y-Y][e-E][s-S]|[y-Y])$ ]]; then
    echo -n "insert the SSID name: "
    read nSSID

    echo -n "Insert WiFi passphrase: "
    read pwwifi
fi

dirDest=~/Downloads
if [ ! -d "$dirDest" ]; then
    mkdir ~/Downloads
fi
filename=~/Downloads/$osversion

if [ -f "$filename" ]; then
    echo -n "In the destination folder is already present "$osversion". Would you like to download it again? [y/N] "
    read ifdownos
else
    ifdownos="y"
fi

if [ "$userRoot" == "n" ]; then
    sudo -k # make sure to ask for password on next sudo
    if sudo true; then
        echo "Correct password"
    else
        echo "Wrong password"
        exit
    fi
fi

if [ "$ifdownos" == "y" -o "$ifdownos" == "Y" ]; then
    wget -P ~/Downloads https://downloads.raspberrypi.org/$osversion
fi

echo "Extracting img. Wait..."
dirDest=~/Downloads/rpiimg
if [ ! -d "$dirDest" ]; then
    mkdir ~/Downloads/rpiimg
fi
rm -rf ~/Downloads/rpiimg/*
bsdtar -xpf $filename -C ~/Downloads/rpiimg
echo "Extraction Done."

for fileimg in ~/Downloads/rpiimg/*img;
do
    echo "Flashing "$fileimg". Wait..."
    if [ "$userRoot" == "y" ]; then
       dd if=$fileimg of=$dkusb bs=4M conv=fsync status=progress
    else
        sudo dd if=$fileimg of=$dkusb bs=4M conv=fsync status=progress
    fi
    echo "Flashing done."
    rm -v $fileimg
done

#boot partition mount
mkdir -p ~/tmpboot
tipousb=$(echo $dkusb | grep mmc)
if [ "$tipousb" == "" ]; then
    bootpart=$dkusb"1"
else
    bootpart=$dkusb"p1"
fi

#mount boot partition
if [ "$userRoot" == "y" ]; then
    mount $bootpart ~/tmpboot
else
    sudo mount $bootpart ~/tmpboot
fi

sleep 1

#SSH
if [[ "$sshen" =~ ^([y-Y][e-E][s-S]|[y-Y])$ ]]; then
    sudo touch ~/tmpboot/SSH
fi

#WiFI
if [[ "$parWiFi" =~ ^([y-Y][e-E][s-S]|[y-Y])$ ]]; then
    echo "ctrl_interface=/var/run/wpa_supplicant" >> /tmp/wpa_supplicant.conf
    echo "update_config=1" >> /tmp/wpa_supplicant.conf
    echo "network={" >> /tmp/wpa_supplicant.conf
    echo '    ssid="'$nSSID'"' >> /tmp/wpa_supplicant.conf
    echo '    psk="'$pwwifi'"' >> /tmp/wpa_supplicant.conf
    echo '    key_mgmt=WPA-PSK' >> /tmp/wpa_supplicant.conf
    echo "}" >> /tmp/wpa_supplicant.conf

    if [ "$userRoot" == "y" ]; then
        cp /tmp/wpa_supplicant.conf ~/tmpboot/wpa_supplicant.conf
    else
        sudo cp /tmp/wpa_supplicant.conf ~/tmpboot/wpa_supplicant.conf
    fi
    rm /tmp/wpa_supplicant.conf
fi

cp ~/tmpboot/config.txt /tmp/configtemp.tmp
echo "" >> /tmp/configtemp.tmp
echo "[all]" >> /tmp/configtemp.tmp
echo "" >> /tmp/configtemp.tmp
echo "dtparam=audio=on" >> /tmp/configtemp.tmp
echo "" >> /tmp/configtemp.tmp
echo "gpu_mem="$qgpu >> /tmp/configtemp.tmp
#Official LCD
if [[ "$lcd7inch" =~ ^([y-Y][e-E][s-S]|[y-Y])$ ]]; then
    echo "" >> /tmp/configtemp.tmp
    echo "#LCD official 7 inch" >> /tmp/configtemp.tmp
    echo "lcd_rotate=2" >> /tmp/configtemp.tmp
    echo "framebuffer_height=614" >> /tmp/configtemp.tmp
    echo "framebuffer_width=1024" >> /tmp/configtemp.tmp
else
    echo "" >> /tmp/configtemp.tmp
    echo "#LCD official 7 inch" >> /tmp/configtemp.tmp
    echo "#lcd_rotate=2" >> /tmp/configtemp.tmp
    echo "#framebuffer_width=1024" >> /tmp/configtemp.tmp
    echo "#framebuffer_height=614" >> /tmp/configtemp.tmp
fi

if [ "$userRoot" == "y" ]; then
    cp /tmp/configtemp.tmp ~/tmpboot/config.txt
else
    sudo cp /tmp/configtemp.tmp ~/tmpboot/config.txt
fi

# umount boot partition
if [ "$userRoot" == "y" ]; then
    umount ~/tmpboot
else
    sudo umount ~/tmpboot
fi

rmdir ~/tmpboot
rm -rf ~/Downloads/rpiimg

echo "Done!"

exit