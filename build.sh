#!/bin/bash

set -e

mkosi_rootfs='mkosi.rootfs'
image_dir='images'
image_mnt='mnt_image'
date=$(date +%Y%m%d)
de_name="${1:-}"
mkosi_profile=""
os_release='fedora-44'
release_type='stable'

get_de_name() {
    echo "### Flavor:"
    case "$de_name" in
        tty)
            echo "### tty chosen"
            mkosi_profile=""
            ;;
        plasma)
            echo "### KDE Plasma chosen"
            mkosi_profile="plasma"
            ;;
        plasma-mobile)
            echo "### KDE Plasma mobile chosen"
            mkosi_profile="plasma-mobile"
            ;;
        gnome)
            echo "### Gnome chosen"
            mkosi_profile="gnome"
            ;;
        custom)
            echo "### Custom profile chosen"
            mkosi_profile="custom"
            ;;
        *)
            echo "### Invalid DE: $de_name, defaulting to KDE Plasma ..."
            mkosi_profile="plasma"
            ;;
    esac
}

get_de_name

image_name="pipa-${os_release}-${mkosi_profile}-${date}-${release_type}"

ROOT_IMG="$image_dir/$image_name/fedora_rootfs.raw"
BOOT_IMG="$image_dir/$image_name/fedora_boot.raw"
ESP_IMG="$image_dir/$image_name/fedora_esp.raw"

# this has to match the volume_id in installer_data.json
ROOTFS_UUID=$(cat /proc/sys/kernel/random/uuid)
BOOT_UUID=$(cat /proc/sys/kernel/random/uuid)
ESP_UUID=$(hexdump -n 4 -e '4/1 "%02X"' /dev/urandom)

GRUB_EFI_SOURCE="$image_dir/$image_name/grubaa64.efi"

if [ "$(whoami)" != 'root' ]; then
    echo "You must be root to run this script."
    exit 1
fi

mkdir -p "$image_mnt" "$image_mnt/bootimg" "$image_mnt/esp" "$image_mnt/tmp" "$mkosi_rootfs" "$image_dir/$image_name"

mkosi_create_rootfs() {
    umount_image
    mkosi clean
    rm -rf .mkosi*
    if [[ -n "$mkosi_profile" ]]; then
        mkosi --profile "$mkosi_profile"
    else
        mkosi
    fi
    # not sure how/why this directory is being created by mkosi
    rm -rf $mkosi_rootfs/root/pipa-fedora-builder
}

mount_image() {
    # get last modified image
    image_path=$(find $image_dir -maxdepth 1 -type d | grep -E "/pipa-${os_release}-${mkosi_profile}-[0-9]{8}-${release_type}" | sort | tail -1)

    [[ -z $image_path ]] && echo -n "image not found in $image_dir\nexiting..." && exit

    [[ -z "$(findmnt -n $image_mnt)" ]] && mount -o loop "$image_path"/fedora_rootfs.raw $image_mnt
}

umount_image() {
    if [ ! "$(findmnt -n $image_mnt)" ]; then
        return
    fi

    [[ -n "$(findmnt -n $image_mnt)" ]] && umount $image_mnt
}

# ./build.sh mount
#  or
# ./build.sh umount
#  to mount or unmount an image (that was previously created by this script) to/from mnt_image/
if [[ $1 == 'mount' ]]; then
    mount_image
    exit
elif [[ $1 == 'umount' ]] || [[ $1 == 'unmount' ]]; then
    umount_image
    exit
fi

mkdir -p "$image_mnt/check"

verify_images() {
    echo '### Verifying generated images'

    [[ -f "$ROOT_IMG" ]] || { echo "ERROR: missing $ROOT_IMG"; exit 1; }
    [[ -f "$BOOT_IMG" ]] || { echo "ERROR: missing $BOOT_IMG"; exit 1; }
    [[ -f "$ESP_IMG" ]] || { echo "ERROR: missing $ESP_IMG"; exit 1; }
    [[ -f "$GRUB_EFI_SOURCE" ]] || { echo "ERROR: missing $GRUB_EFI_SOURCE"; exit 1; }

    mount -o loop "$BOOT_IMG" "$image_mnt/check"
    [[ -f "$image_mnt/check/grub2/grub.cfg" ]] || { echo "ERROR: missing /grub2/grub.cfg in boot image"; umount "$image_mnt/check"; exit 1; }
    umount "$image_mnt/check"

    mount -o loop "$ESP_IMG" "$image_mnt/check"
    [[ -f "$image_mnt/check/EFI/BOOT/BOOTAA64.EFI" ]] || { echo "ERROR: missing /EFI/BOOT/BOOTAA64.EFI in ESP"; umount "$image_mnt/check"; exit 1; }
    umount "$image_mnt/check"
}

make_boot_image() {
    echo '### Calculating boot image size'
    local boot_size
    boot_size=$(du -BM -s "$mkosi_rootfs/boot" | cut -dM -f1)
    echo "### Boot Image size: $boot_size MiB"
    boot_size=$((boot_size + (boot_size / 4) + 512))
    echo "### Boot Padded size: $boot_size MiB"

    truncate -s "${boot_size}M" "$BOOT_IMG"

    echo '### Creating boot ext4 filesystem on fedora_boot.raw'
    MKE2FS_DEVICE_PHYS_SECTSIZE=4096 MKE2FS_DEVICE_SECTSIZE=4096 mkfs.ext4 -U "$BOOT_UUID" -L 'fedora_boot' "$BOOT_IMG"

    echo '### Loop mounting boot image'
    mount -o loop "$BOOT_IMG" "$image_mnt/bootimg"

    echo '### Copying /boot contents from root image'
    mount -o loop "$ROOT_IMG" "$image_mnt/tmp"
    rsync -aHAX --exclude '/efi/*' "$image_mnt/tmp/boot/" "$image_mnt/bootimg/"
    umount "$image_mnt/tmp"

    echo '### Cleaning boot image'
    rm -rf "$image_mnt/bootimg/lost+found"
    rm -f "$image_mnt/bootimg/.keep"

    umount "$image_mnt/bootimg"
}

make_esp_image() {
    echo '### Creating FAT16 ESP image'
    local esp_size=64

    truncate -s "${esp_size}M" "$ESP_IMG"

    mkfs.vfat -F 16 -n 'PIPAESP' -i "$ESP_UUID" "$ESP_IMG"

    echo '### Loop mounting ESP image'
    mount -o loop "$ESP_IMG" "$image_mnt/esp"

    mkdir -p "$image_mnt/esp/EFI/BOOT"
    mkdir -p "$image_mnt/esp/EFI/fedora"

    echo '### Copying GRUB binary'
    cp "$GRUB_EFI_SOURCE" "$image_mnt/esp/EFI/BOOT/BOOTAA64.EFI"
    cp "$GRUB_EFI_SOURCE" "$image_mnt/esp/EFI/fedora/grubaa64.efi"

    echo '### Copying ESP GRUB stub config'
    mount -o loop "$ROOT_IMG" "$image_mnt/tmp"
    cp "$image_mnt/tmp/boot/efi/EFI/fedora/grub.cfg" "$image_mnt/esp/EFI/fedora/grub.cfg"
    cp "$image_mnt/tmp/boot/efi/EFI/BOOT/grub.cfg" "$image_mnt/esp/EFI/BOOT/grub.cfg"
    umount "$image_mnt/tmp"

    umount "$image_mnt/esp"
}


make_image() {
    # if  $image_mnt is mounted, then unmount it
    umount_image
    echo "## Making image $image_name"
    echo '### Cleaning up'
    rm -rf $mkosi_rootfs/var/cache/dnf/*
    rm -rf "$image_dir/$image_name"/*

    ############# create root.img #############
    echo '### Calculating root image size'
    size=$(du -BM -s --exclude='boot' $mkosi_rootfs | cut -dM -f1)
    echo "### Root Image size: $size MiB"
    size=$(($size + ($size / 8) + 512))
    echo "### Root Padded size: $size MiB"
    truncate -s ${size}M "$ROOT_IMG"

    ###### create rootfs filesystem on root.img ######
    echo '### Creating rootfs ext4 filesystem on root.img '
    MKE2FS_DEVICE_PHYS_SECTSIZE=4096 MKE2FS_DEVICE_SECTSIZE=4096 mkfs.ext4 -U "$ROOTFS_UUID" -L 'fedora_pipa' "$ROOT_IMG"

    echo '### Loop mounting root.img'
    mount -o loop "$ROOT_IMG" "$image_mnt"
    
    echo '### Copying files'
    rsync -aHAX --exclude '/tmp/*' --exclude '/efi/*' --exclude '/home/*' $mkosi_rootfs/ $image_mnt
    # this should be empty, but just in case
    rsync -aHAX $mkosi_rootfs/home/ $image_mnt/home
    umount $image_mnt
    echo '### Loop mounting rootfs root subvolume'
    mount -o loop "$ROOT_IMG" "$image_mnt"

    # echo '### Setting uuid for partitions in /etc/fstab'
    sed -i "s/ROOTFS_UUID_PLACEHOLDER/$ROOTFS_UUID/" "$image_mnt/etc/fstab"
    sed -i "s/BOOT_UUID_PLACEHOLDER/$BOOT_UUID/g" "$image_mnt/etc/fstab"
    sed -i "s/ESP_UUID_PLACEHOLDER/$ESP_UUID/g" "$image_mnt/etc/fstab"

    # echo '### Setting uuid for partitions in /etc/cmdline'
    sed -i "s/ROOTFS_UUID_PLACEHOLDER/$ROOTFS_UUID/" "$image_mnt/etc/cmdline"
    CMDLINE=$(tr -d '\n' < "$image_mnt/etc/cmdline")
    sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"$CMDLINE\"|" "$image_mnt/etc/default/grub"

    # remove resolv.conf symlink -- this causes issues with arch-chroot
    rm -f $image_mnt/etc/resolv.conf
    echo "nameserver 1.1.1.1" > $image_mnt/etc/resolv.conf

    echo -e '\n### Generating Initramfs'
    arch-chroot $image_mnt dracut --force --regenerate-all --verbose

    # Remove Kernel flasher hook
    rm -f "$image_mnt"/usr/lib/kernel/install.d/99-android-boot.install


    # Dirty patch: reinstalling kernel
    echo '### Reinstalling kernel'
    local kernel_path="$(arch-chroot $image_mnt bash -c 'find /usr/lib/modules/* -maxdepth 0 -type d')"
    arch-chroot $image_mnt kernel-install add "$(basename "$kernel_path")" "${kernel_path}/vmlinuz" --verbose

    echo "### Generating GRUB config"
    arch-chroot "$image_mnt" grub2-mkconfig -o /boot/grub2/grub.cfg

    echo "### Building monolithic GRUB EFI binary"
    mkdir -p "$image_mnt/usr/lib/grub/arm64-efi/monolithic"

    arch-chroot "$image_mnt" grub2-mkimage -O arm64-efi -o /usr/lib/grub/arm64-efi/monolithic/grubaa64.efi -p /EFI/fedora part_gpt fat ext2 normal linux search search_fs_uuid search_label configfile echo test probe regexp minicmd

    cp "$image_mnt/usr/lib/grub/arm64-efi/monolithic/grubaa64.efi" "$GRUB_EFI_SOURCE"

    echo "### Enabling system services"
    # echo "### DEBUG: NetworkManager.service"
    arch-chroot $image_mnt systemctl enable NetworkManager.service
    # echo "### DEBUG: sshd.service"
    arch-chroot $image_mnt systemctl enable sshd.service
    # echo "### DEBUG: systemd-resolved.service"
    arch-chroot $image_mnt systemctl enable systemd-resolved.service
    # echo "### DEBUG: qbootctl.service"
    arch-chroot $image_mnt systemctl enable qbootctl.service
    # echo "### DEBUG: bootmac-bluetooth.service"
    arch-chroot $image_mnt systemctl enable bootmac-bluetooth.service
    # echo "### DEBUG: tuned.service"
    arch-chroot $image_mnt systemctl enable tuned.service
    # echo "### DEBUG: tuned-ppd.service"
    arch-chroot $image_mnt systemctl enable tuned-ppd.service
    echo "### Setting default systemd target"
    if [[ -n "$mkosi_profile" ]]; then
        arch-chroot "$image_mnt" systemctl set-default graphical.target
    else
        arch-chroot "$image_mnt" systemctl set-default multi-user.target
    fi
    echo "### Enabling Desktop services"
    if [[ "$mkosi_profile" == "plasma" ]]; then
        arch-chroot $image_mnt systemctl enable --force plasmalogin.service
    elif [[ "$mkosi_profile" == "plasma-mobile" ]]; then
        arch-chroot $image_mnt systemctl enable --force plasmalogin.service
    elif [[ "$mkosi_profile" == "gnome" ]]; then
        arch-chroot $image_mnt systemctl enable gdm.service
    fi

    echo "### Disabling systemd-firstboot"
    arch-chroot $image_mnt rm -f /usr/lib/systemd/system/sysinit.target.wants/systemd-firstboot.service

    echo "### Setting permission"
    arch-chroot $image_mnt find /etc/skel -type d -exec chmod 755 {} \;
    arch-chroot $image_mnt find /etc/skel -type f -exec chmod 644 {} \;
    arch-chroot $image_mnt find /var/lib/gdm -type d -exec chmod 744 {} \;
    arch-chroot $image_mnt find /var/lib/gdm -type f -exec chmod 644 {} \;

    echo "### Creating default user and setting fish as their shell"
    arch-chroot $image_mnt useradd -m -G audio,video,wheel user
    echo 'user:147147' | arch-chroot $image_mnt chpasswd
    arch-chroot $image_mnt chsh -s /bin/fish user
    arch-chroot $image_mnt chmod +x /home/user/post-install
    arch-chroot $image_mnt chmod +x /home/user/niri-install

    # echo "### SElinux labeling filesystem"
    # arch-chroot $image_mnt setfiles -F -p -c /etc/selinux/targeted/policy/policy.* -e /proc -e /sys -e /dev /etc/selinux/targeted/contexts/files/file_contexts /
    # arch-chroot $image_mnt setfiles -F -p -c /etc/selinux/targeted/policy/policy.* -e /proc -e /sys -e /dev /etc/selinux/targeted/contexts/files/file_contexts /boot

    ###### post-install cleanup ######
    echo -e '\n### Cleanup'
    rm -rf $image_mnt/boot/lost+found/
    rm -f $image_mnt/boot/boot*.img
    rm -f $image_mnt/boot/*-dtb
    rm -f $image_mnt/etc/kernel/{entry-token,install.conf}
    rm -f $image_mnt/etc/dracut.conf.d/initial-boot.conf
    rm -f $image_mnt/etc/yum.repos.d/mkosi*.repo
    rm -f $image_mnt/var/lib/systemd/random-seed
    rm -f $image_mnt/etc/resolv.conf
    arch-chroot $image_mnt ln -s ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

    echo -e '\n### Unmounting rootfs subvolumes'
    umount $image_mnt

    echo -e '\n### Creating ESP image'
    make_esp_image

    echo -e '\n### Creating boot image'
    make_boot_image

    echo -e '\n### Removing /boot from root image'
    mount -o loop "$ROOT_IMG" "$image_mnt"
    rm -rf "$image_mnt/boot"/*
    umount "$image_mnt"


    echo -e '\n### Verifying images'
    verify_images

    echo -e '\n### Compressing'
    rm -f $image_dir/"$image_name".zip
    pushd $image_dir/"$image_name" > /dev/null
    zip -r ../"$image_name".zip .
    popd > /dev/null

    echo '### Done'
}

[[ $(command -v getenforce) ]] && setenforce 0 || echo "Selinux Disabled"
mkosi_create_rootfs
make_image
