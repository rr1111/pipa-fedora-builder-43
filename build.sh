#!/bin/bash

set -e

mkosi_rootfs='mkosi.rootfs'
image_dir='images'
image_mnt='mnt_image'
date=$(date +%Y%m%d)
image_name=pipa-fedora43-${date}-1

# this has to match the volume_id in installer_data.json
ROOTFS_UUID=$(uuidgen)

if [ "$(whoami)" != 'root' ]; then
    echo "You must be root to run this script."
    exit 1
fi

mkdir -p "$image_mnt" "$mkosi_rootfs" "$image_dir/$image_name"

mkosi_create_rootfs() {
    umount_image
    mkosi clean
    rm -rf .mkosi*
    mkosi
    # not sure how/why this directory is being created by mkosi
    rm -rf $mkosi_rootfs/root/pipa-fedora-builder
}

mount_image() {
    # get last modified image
    image_path=$(find $image_dir -maxdepth 1 -type d | grep -E "/pipa-fedora43-[0-9]{8}-[0-9]" | sort | tail -1)

    [[ -z $image_path ]] && echo -n "image not found in $image_dir\nexiting..." && exit

    [[ -z "$(findmnt -n $image_mnt)" ]] && mount -o loop "$image_path"/root.img $image_mnt
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

make_image() {
    # if  $image_mnt is mounted, then unmount it
    umount_image
    echo "## Making image $image_name"
    echo '### Cleaning up'
    rm -rf $mkosi_rootfs/var/cache/dnf/*
    rm -rf "$image_dir/$image_name/*"

    ############# create root.img #############
    echo '### Calculating root image size'
    size=$(du -B M -s --exclude=$mkosi_rootfs/boot $mkosi_rootfs | cut -dM -f1)
    echo "### Root Image size: $size MiB"
    size=$(($size + ($size / 8) + 512))
    echo "### Root Padded size: $size MiB"
    truncate -s ${size}M "$image_dir/$image_name/root.img"

    ###### create rootfs filesystem on root.img ######
    echo '### Creating rootfs ext4 filesystem on root.img '
    MKE2FS_DEVICE_PHYS_SECTSIZE=4096 MKE2FS_DEVICE_SECTSIZE=4096 mkfs.ext4 -U "$ROOTFS_UUID" -L 'fedora_pipa' "$image_dir/$image_name/root.img"

    echo '### Loop mounting root.img'
    mount -o loop "$image_dir/$image_name/root.img" "$image_mnt"
    
    echo '### Copying files'
    rsync -aHAX --exclude '/tmp/*' --exclude '/boot/efi' --exclude '/efi' --exclude '/home/*' $mkosi_rootfs/ $image_mnt
    # this should be empty, but just in case
    rsync -aHAX $mkosi_rootfs/home/ $image_mnt/home
    umount $image_mnt
    echo '### Loop mounting rootfs root subvolume'
    mount -o loop "$image_dir/$image_name/root.img" "$image_mnt"

    # echo '### Setting uuid for rootfs partition in /etc/fstab'
    sed -i "s/ROOTFS_UUID_PLACEHOLDER/$ROOTFS_UUID/" "$image_mnt/etc/fstab"

    # echo '### Setting uuid for rootfs partition in /etc/cmdline'
    sed -i "s/ROOTFS_UUID_PLACEHOLDER/$ROOTFS_UUID/" "$image_mnt/etc/cmdline"

    # remove resolv.conf symlink -- this causes issues with arch-chroot
    rm -f $image_mnt/etc/resolv.conf
    echo "nameserver 1.1.1.1" > $image_mnt/etc/resolv.conf

    echo -e '\n### Generating Initramfs'
    arch-chroot $image_mnt dracut --force --regenerate-all --verbose

    # Dirty patch: reinstalling kernel
    echo '### Reinstalling kernel'
    local kernel_path="$(arch-chroot $image_mnt bash -c 'find /usr/lib/modules/* -maxdepth 0 -type d')"
    arch-chroot $image_mnt kernel-install add "$(basename "$kernel_path")" "${kernel_path}/vmlinuz" --verbose

    echo "### Enabling system services"
    arch-chroot $image_mnt systemctl enable NetworkManager.service sshd.service systemd-resolved.service
    arch-chroot $image_mnt systemctl enable qbootctl.service bootmac-bluetooth.service tuned.service tuned-ppd.service
    arch-chroot $image_mnt systemctl disable iio-sensor-proxy.service

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
    
    echo "### Version-locking bluez as newest version breaks bluetooth on pipa"
    arch-chroot $image_mnt dnf -y versionlock add bluez

    # echo "### SElinux labeling filesystem"
    # arch-chroot $image_mnt setfiles -F -p -c /etc/selinux/targeted/policy/policy.* -e /proc -e /sys -e /dev /etc/selinux/targeted/contexts/files/file_contexts /
    # arch-chroot $image_mnt setfiles -F -p -c /etc/selinux/targeted/policy/policy.* -e /proc -e /sys -e /dev /etc/selinux/targeted/contexts/files/file_contexts /boot

    ###### post-install cleanup ######
    echo -e '\n### Cleanup'
    rm -rf $image_mnt/boot/lost+found/
    rm -f  $image_mnt/etc/kernel/{entry-token,install.conf}
    rm -f  $image_mnt/etc/dracut.conf.d/initial-boot.conf
    rm -f  $image_mnt/etc/yum.repos.d/mkosi*.repo
    rm -f  $image_mnt/var/lib/systemd/random-seed
    rm -f $image_mnt/etc/resolv.conf
    chroot $image_mnt ln -s ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

    echo -e '\n### Copying boot image'
    #echo "### Debug: /boot contents"
    #ls -lah "$image_mnt/boot"

    cp $image_mnt/boot/boot*.img $image_dir/$image_name/boot.img

    echo -e '\n### Unmounting rootfs subvolumes'
    umount $image_mnt

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
