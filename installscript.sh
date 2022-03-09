#!/bin/sh
which echo umount rm mkdir parted mkfs.fat mkfs.btrfs cp mount btrfs nixos-install rmdir >/dev/null || exit
targetdev=/dev/sda
echo this will wipe $targetdev. [Ctrl-C] to cancel or [Enter] to continue && read || exit


echo unmounting $targetdev1/2/3
while $(umount $targetdev'1'); do echo unmounting $targetdev'1'; done
while $(umount $targetdev'2'); do echo unmounting $targetdev'2'; done 
while $(umount $targetdev'3'); do echo unmounting $targetdev'3'; done 

echo cleaning /mnt
rm -rf /mnt
mkdir /mnt || exit

parted $targetdev -- mklabel gpt
parted $targetdev -- mkpart ESP fat32 1MiB 1GiB
parted $targetdev -- set 1 esp on
mkfs.fat -F 32 -n EFI $targetdev'1'
parted $targetdev -- mkpart primary 1GiB 100%
mkfs.btrfs -L btrfs -f $targetdev'2'

echo copy configuration to hard drive
mkdir /mnt/btrfs
mount $targetdev'2' /mnt/btrfs
btrfs subvolume create /mnt/btrfs/@nix
btrfs subvolume create /mnt/btrfs/home
btrfs subvolume create /mnt/btrfs/etc
cp -r dev/sda2/ETC/nixos /mnt/btrfs/etc/
cp -r dev/sda2/HOME/a /mnt/btrfs/home/
chown -R 1000:100 /mnt/btrfs/home/a

echo making configuration readonly
btrfs subvolume snapshot -r /mnt/btrfs/home /mnt/btrfs/HOME
btrfs subvolume snapshot -r /mnt/btrfs/etc /mnt/btrfs/ETC
btrfs subvolume delete /mnt/btrfs/home

echo preparing installation
mkdir /mnt/boot
mkdir /mnt/nix
mkdir /mnt/etc
mount $targetdev'1' /mnt/boot
mount $targetdev'2' -o subvol=@nix /mnt/nix
mount $targetdev'2' -o subvol=etc /mnt/etc

echo installing
nixos-install && btrfs subvolume delete /mnt/btrfs/etc

echo cleaning up
umount /mnt/btrfs && rmdir /mnt/btrfs
