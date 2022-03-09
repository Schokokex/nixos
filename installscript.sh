#!/bin/sh
which nixos-install >/dev/null || exit
targetdev=/dev/sda
echo this will wipe $targetdev. [Ctrl-C] to cancel && read || exit

echo wiping $targetdev
sleep 3

parted $targetdev -- mklabel gpt
parted $targetdev -- mkpart ESP fat32 1MiB 1GiB
parted $targetdev -- set 1 esp on
mkfs.fat -F 32 -n EFI $targetdev'1'
parted $targetdev -- mkpart primary 1GiB 100%
mkfs.btrfs -L btrfs $targetdev'2'

echo copy configuration to hard drive
mkdir asd
mount $targetdev'2' asd
btrfs subvolume create asd/@nix
btrfs subvolume create asd/home
btrfs subvolume create asd/etc
cp -r dev/sda2/ETC/nixos asd/etc/
cp -r dev/sda2/HOME/a asd/home/

echo making configuration readonly
btrfs subvolume snapshot -r asd/home asd/HOME
btrfs subvolume snapshot -r asd/etc asd/ETC
btrfs subvolume delete asd/home

echo preparing installation
mkdir /mnt/boot
mkdir /mnt/nix
mkdir /mnt/etc
mount $targetdev'1' /mnt/boot
mount $targetdev'2' -o subvol=@nix /mnt/nix
mount $targetdev'2' -o subvol=etc /mnt/etc

echo installing
nixos-install && btrfs subvolume delete asd/etc

echo cleaning up
umount asd && rmdir asd
