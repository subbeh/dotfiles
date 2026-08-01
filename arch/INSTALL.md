# Arch Linux Install Guide

ThinkPad X1 Carbon Gen 11+ | systemd-boot | LUKS2 + FIDO2 | BTRFS | Dual-boot Windows

## Pre-install

Boot from archiso USB.

```bash
# Connect to wifi
iwctl
> station wlan0 scan
> station wlan0 connect-hidden <SSID>
> exit

# Set root password and start SSH
passwd
systemctl start sshd
ip a
```

SSH in from another machine for the remainder of the install.

```bash
ssh root@<ip>
```

## Variables

```bash
export DISK="/dev/nvme0n1"
export PART_EFI="${DISK}p1"
export PART_ROOT="${DISK}p4"
export PART_DATA="${DISK}p5"
```

## Partitioning

Preserve p1 (EFI, shared with Windows), p2 (Windows MSR), p3 (Windows BitLocker).
Delete p4, p5, p6. Create new root and data partitions.

```bash
# Delete old linux partitions (p4, p5, p6) and create new ones
sgdisk --delete=4 --delete=5 --delete=6 $DISK
sgdisk --new=4:0:+200GiB --typecode=4:8300 --change-name=4:root $DISK
sgdisk --new=5:0:0 --typecode=5:8300 --change-name=5:data $DISK
sgdisk --print $DISK
```

Expected layout:

| # | Label | Size   | Type |
|---|-------|--------|------|
| 1 | EFI   | 512M   | ef00 (keep) |
| 2 | (MSR) | —      | (keep) |
| 3 | (Win) | —      | (keep) |
| 4 | root  | 200G   | 8300 |
| 5 | data  | (rest) | 8300 |

```bash
partprobe -s $DISK
```

## Encryption

### Root partition

```bash
cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/root
cryptsetup open --allow-discards --persistent /dev/disk/by-partlabel/root root
```

The `--allow-discards --persistent` flags write the discard flag into the LUKS header so fstrim can pass through the encryption layer to the NVMe on every future open.

### Data partition

```bash
cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/data
cryptsetup open --allow-discards --persistent /dev/disk/by-partlabel/data data
```

## Filesystems

### Root BTRFS

```bash
mkfs.btrfs --label root /dev/mapper/root

mount /dev/mapper/root /mnt
cd /mnt

btrfs subvolume create @
btrfs subvolume create @home
btrfs subvolume create @var_log
btrfs subvolume create @var_cache
btrfs subvolume create @snapshots
btrfs subvolume create @home_snapshots

cd /
umount /mnt
```

### Data BTRFS

```bash
mkfs.btrfs --label data /dev/mapper/data

mount /dev/mapper/data /mnt
cd /mnt

btrfs subvolume create @data
btrfs subvolume create @data_snapshots

cd /
umount /mnt
```

### Disable CoW for log/cache subvolumes

```bash
mount /dev/mapper/root /mnt
chattr +C /mnt/@var_log
chattr +C /mnt/@var_cache
umount /mnt
```

## Mount

```bash
opts="defaults,ssd,noatime,compress=zstd,space_cache=v2"

mount -o $opts,subvol=@ /dev/mapper/root /mnt

mkdir -p /mnt/{boot,home,var/log,var/cache,.snapshots,home/.snapshots,data,data/.snapshots}

mount -o $opts,subvol=@home /dev/mapper/root /mnt/home
mount -o $opts,subvol=@var_log /dev/mapper/root /mnt/var/log
mount -o $opts,subvol=@var_cache /dev/mapper/root /mnt/var/cache
mount -o $opts,subvol=@snapshots /dev/mapper/root /mnt/.snapshots
mount -o $opts,subvol=@home_snapshots /dev/mapper/root /mnt/home/.snapshots

mount -o $opts,subvol=@data /dev/mapper/data /mnt/data
mount -o $opts,subvol=@data_snapshots /dev/mapper/data /mnt/data/.snapshots

mount $PART_EFI /mnt/boot
```

## Base Install

```bash
timedatectl set-ntp true

# Mirrors
reflector --country AU --age 24 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Install base system
pacstrap -K /mnt base base-devel linux linux-headers linux-firmware intel-ucode \
  git sudo vim openssh networkmanager reflector \
  btrfs-progs snapper snap-pac \
  sbctl efibootmgr dosfstools \
  libfido2 systemd-ukify zram-generator

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab
```

Verify fstab looks correct:

```bash
cat /mnt/etc/fstab
```

## System Configuration

```bash
arch-chroot /mnt
```

### Locale & Time

```bash
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

ln -sf /usr/share/zoneinfo/Australia/Sydney /etc/localtime
hwclock --systohc
```

### Hostname & Hosts

```bash
echo "x1" > /etc/hostname

cat << EOF > /etc/hosts
127.0.0.1 localhost
::1       localhost
127.0.1.1 x1.int.sbbh.cloud x1
EOF
```

### User

```bash
useradd -G wheel -g users -m sysadm
passwd sysadm

EDITOR=vim visudo
# Uncomment: %wheel ALL=(ALL:ALL) NOPASSWD: ALL
```

### Pacman

```bash
sed -i 's/^#Color/Color/' /etc/pacman.conf
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
```

### AUR helper

```bash
su sysadm -c "cd /tmp && git clone https://aur.archlinux.org/paru-bin.git && cd paru-bin && makepkg -sri --noconfirm"
```

## zram (swap)

```bash
cat << 'EOF' > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
```

## Initramfs

### crypttab.initramfs

sd-encrypt reads this file for early-boot LUKS unlock. It picks up FIDO2 token metadata directly from the LUKS2 header (after enrollment), so no `rd.luks.options` needed in cmdline.

```bash
ROOT_UUID=$(blkid -s UUID -o value /dev/disk/by-partlabel/root)

cat << EOF > /etc/crypttab.initramfs
root    UUID=${ROOT_UUID}    -    discard
EOF
```

### mkinitcpio

```bash
cat << 'EOF' > /etc/mkinitcpio.conf
MODULES=(i915 btrfs)
BINARIES=()
FILES=()
HOOKS=(base systemd autodetect modconf kms keyboard sd-vconsole sd-encrypt filesystems)
EOF

mkinitcpio -P
```

## Bootloader (systemd-boot)

```bash
bootctl install
systemctl enable systemd-boot-update.service
```

### Loader config

```bash
cat << 'EOF' > /boot/loader/loader.conf
default arch.conf
timeout 5
console-mode auto
editor  no
EOF
```

### Arch entry

```bash
cat << 'EOF' > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=/dev/mapper/root rootflags=subvol=@ rw
EOF
```

### Fallback entry

```bash
cat << 'EOF' > /boot/loader/entries/arch-fallback.conf
title   Arch Linux (fallback)
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux-fallback.img
options root=/dev/mapper/root rootflags=subvol=@ rw
EOF
```

## UKI Preparation (for future Secure Boot)

Set up Unified Kernel Image generation so enabling Secure Boot later is just key enrollment + signing.

```bash
mkdir -p /etc/kernel

cat << 'EOF' > /etc/kernel/cmdline
root=/dev/mapper/root rootflags=subvol=@ rw
EOF

cat << 'EOF' > /etc/mkinitcpio.d/linux.preset
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"
ALL_microcode=(/boot/*-ucode.img)

PRESETS=('default' 'fallback')

default_uki="/boot/EFI/Linux/arch-linux.efi"

fallback_uki="/boot/EFI/Linux/arch-linux-fallback.efi"
fallback_options="-S autodetect"
EOF

mkdir -p /boot/EFI/Linux
mkinitcpio -P
```

Add a loader entry for the UKI:

```bash
cat << 'EOF' > /boot/loader/entries/arch-uki.conf
title   Arch Linux (UKI)
efi     /EFI/Linux/arch-linux.efi
EOF
```

The traditional vmlinuz+initramfs entries remain as fallback. When ready for Secure Boot: `sbctl create-keys && sbctl enroll-keys && sbctl sign -s /boot/EFI/Linux/arch-linux.efi`.

## FIDO2 Enrollment (YubiKey)

Enroll both a passphrase (already done during luksFormat) and the YubiKey:

```bash
systemd-cryptenroll /dev/disk/by-partlabel/root --fido2-device=auto
```

Test that both unlock methods work:

```bash
systemd-cryptenroll /dev/disk/by-partlabel/root --fido2-device=auto --dry-run 2>/dev/null
cryptsetup luksDump /dev/disk/by-partlabel/root | grep -A2 "Tokens:"
```

## Data Partition Auto-unlock

### Generate keyfile

```bash
dd bs=512 count=4 iflag=fullblock if=/dev/urandom of=/etc/crypto_keyfile.bin
chmod 600 /etc/crypto_keyfile.bin
```

### Add keyfile to data LUKS

```bash
cryptsetup luksAddKey /dev/disk/by-partlabel/data /etc/crypto_keyfile.bin
```

### crypttab

```bash
DATA_UUID=$(blkid -s UUID -o value /dev/disk/by-partlabel/data)

cat << EOF >> /etc/crypttab
data    UUID=${DATA_UUID}    /etc/crypto_keyfile.bin    luks
EOF
```

## Snapper

### Root config

```bash
snapper -c root create-config /

# Replace default subvolume with our pre-created one
btrfs subvolume delete /.snapshots
mkdir /.snapshots
mount -a

cat << 'EOF' > /etc/snapper/configs/root
SUBVOLUME="/"
FSTYPE="btrfs"
QGROUP=""
SPACE_LIMIT="0.5"
FREE_LIMIT="0.2"
ALLOW_USERS=""
ALLOW_GROUPS="wheel"
SYNC_ACL="no"
BACKGROUND_COMPARISON="yes"
NUMBER_CLEANUP="yes"
NUMBER_MIN_AGE="1800"
NUMBER_LIMIT="50"
NUMBER_LIMIT_IMPORTANT="10"
TIMELINE_CREATE="yes"
TIMELINE_CLEANUP="yes"
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="0"
TIMELINE_LIMIT_DAILY="7"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="0"
TIMELINE_LIMIT_YEARLY="0"
EMPTY_PRE_POST_CLEANUP="yes"
EMPTY_PRE_POST_MIN_AGE="1800"
EOF
```

### Home config

```bash
snapper -c home create-config /home

btrfs subvolume delete /home/.snapshots
mkdir /home/.snapshots
mount -a

cp /etc/snapper/configs/root /etc/snapper/configs/home
sed -i 's|SUBVOLUME="/"|SUBVOLUME="/home"|' /etc/snapper/configs/home
```

### Data config

```bash
snapper -c data create-config /data

btrfs subvolume delete /data/.snapshots
mkdir /data/.snapshots
mount -a

cp /etc/snapper/configs/root /etc/snapper/configs/data
sed -i 's|SUBVOLUME="/"|SUBVOLUME="/data"|' /etc/snapper/configs/data
```

### Register configs

```bash
echo 'SNAPPER_CONFIGS="root home data"' > /etc/conf.d/snapper
```

## Services

```bash
systemctl enable NetworkManager
systemctl enable systemd-resolved
systemctl enable systemd-timesyncd
systemctl enable sshd
systemctl enable fstrim.timer
systemctl enable reflector.timer
systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer
```

### Reflector config

```bash
cat << 'EOF' > /etc/xdg/reflector/reflector.conf
--country AU
--protocol https
--age 24
--sort rate
--save /etc/pacman.d/mirrorlist
EOF
```

## Dual Boot — Verify Windows

systemd-boot auto-detects Windows Boot Manager on the shared EFI partition.

```bash
bootctl list
```

If Windows does not appear, create a manual entry:

```bash
cat << 'EOF' > /boot/loader/entries/windows.conf
title   Windows
efi     /EFI/Microsoft/Boot/bootmgfw.efi
EOF
```

## Finalize

```bash
# Create initial snapshot
snapper -c root create -d "Base install"

# Exit chroot
exit

# Unmount
umount -R /mnt

# Reboot
reboot
```

## Post-reboot Verification

1. systemd-boot menu appears with Arch + Windows entries
2. YubiKey prompt appears — touch to unlock root
3. System boots to login prompt
4. Log in as sysadm
5. Verify data partition mounted: `lsblk -f | grep data`
6. Verify snapper: `snapper -c root list`
7. Verify networking: `nmcli device wifi list`
8. Connect wifi: `nmcli device wifi connect <SSID> password <pass> hidden yes`
9. Verify TRIM: `sudo fstrim -v /` (should report bytes trimmed)
10. Verify zram: `swapon --show` (should show /dev/zram0)

---

## Appendix: Snapshot Rollback

If the system is broken, boot from archiso (or a working snapshot) and roll back.

### From archiso

```bash
cryptsetup open /dev/disk/by-partlabel/root root
mount /dev/mapper/root /mnt

# List subvolumes — find the @ subvolume ID
btrfs subvolume list /mnt

# Move broken root aside
mv /mnt/@ /mnt/@.broken

# Create writable snapshot from a known-good snapshot
# (list snapshots under /mnt/@snapshots/<number>/snapshot)
ls /mnt/@snapshots/
btrfs subvolume snapshot /mnt/@snapshots/<number>/snapshot /mnt/@

umount /mnt
reboot
```

### Cleanup after successful rollback

```bash
# Mount top-level subvolume
sudo mount -o subvolid=5 /dev/mapper/root /mnt
sudo btrfs subvolume delete /mnt/@.broken
sudo umount /mnt
```
