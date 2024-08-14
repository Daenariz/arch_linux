#!/bin/sh

### Minimal Arch Linux install ###
### 01: Base Install ###


COUNTRY='DE' # Your country code for reflector. List all codes with: $ reflector --list-countries
DISK='/dev/disk/by-id/nvme-Micron_MTFDHBA512TDV_21212F5AAB85' # '/dev/disk/by-id/ID'. List all IDs with: $ ls -lAh /dev/disk/by-id
HOSTNAME='16ach6'
KEYMAP='de-latin1' # list all options with: $ localectl list-keymaps
LANGUAGE='en_US.UTF-8' # list all options with: $ locale -a
LOCALES=('de_DE.UTF-8 UTF-8' 'de_DE ISO-8859-1' 'de_DE@euro ISO-8859-15' 'en_US.UTF-8 UTF-8') # list all options with: $ cat /usr/share/i18n/SUPPORTED
SWAP_GB=8 # Positive integer. Set to machine's RAM size in GB
TIMEZONE='Europe/Berlin' # list all options with: $ timedatectl list-timezones
UCODE='intel-ucode' # 'intel-ucode' for Intel systems
USERNAME='sid'


# Options
NOVERIFY=0
FORMAT=0
while getopts 'fn' flag; do
  case "${flag}" in
    f) FORMAT=1 ;;
    n) NOVERIFY=1 ;;
    *) echo "Unexpected option ${flag}" ;;
  esac
done

# Sync system clock
timedatectl

# Ensure swap parts are off
swapoff --all

# Clear part tables
sgdisk --zap-all $DISK

# Wipe filesystem
# [ $FORMAT -eq 1 ] && dd status=progress if=/dev/random of=$DISK

# Partition disk
sgdisk -n1:1M:+1G         -t1:EF00 -c1:EFI  $DISK
sgdisk -n2:0:+${SWAP_GB}G -t2:8200 -c2:SWAP $DISK
sgdisk -n3:0:0            -t3:8300 -c3:ROOT $DISK
partprobe -s $DISK

# Verify partitions
lsblk -f
[ $NOVERIFY -eq 1 ] || read -p "Verify partitions. Press Ctrl+c to cancel or Enter to continue..."

# Format partitions
mkfs.vfat -F 32 -n EFI $DISK-part1
mkswap -L SWAP $DISK-part2
mkfs.ext4 -fL ROOT $DISK-part3

# Mount partitions
mount -L ROOT /mnt
mkdir -p /mnt/efi
mount -L EFI /mnt/efi

# Activate swap
swapon -L SWAP

# Verify mounts
lsblk -f
[ $NOVERIFY -eq 1 ] || read -p "Verify mount points. Press Ctrl+c to cancel or Enter to continue..."

# Configure and optimize pacman
sed -ie '/^#Color/s/^#//' /etc/pacman.conf
sed -ie '/^#ParallelDownloads/s/^#//' /etc/pacman.conf
reflector --country $COUNTRY --age 24 --protocol http,https --sort rate --save /etc/pacman.d/mirrorlist

# Install base system
pacman -Syy
pacstrap -K /mnt base base-devel linux linux-firmware linux-headers util-linux networkmanager vim wpa_supplicant openssh git zsh zsh-completions $UCODE

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Verify fstab
cat /mnt/etc/fstab
[ $NOVERIFY -eq 1 ] || read -p "Verify the file system table. Press Ctrl+c to cancel or Enter to continue..."

# Configure and optimize pacman
sed -ie '/^#Color/s/^#//' /mnt/etc/pacman.conf
sed -ie '/^#ParallelDownloads/s/^#//' /mnt/etc/pacman.conf
reflector --country $COUNTRY --age 24 --protocol http,https --sort rate --save /mnt/etc/pacman.d/mirrorlist

# Set time zone
arch-chroot /mnt ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime

# Enable internet time synchronisation
arch-chroot /mnt hwclock --systohc
arch-chroot /mnt systemctl enable systemd-timesyncd

# Set and generate locales
for i in "${LOCALES[@]}"; do
  arch-chroot /mnt sed -ie "/^#$i/s/^#//" /etc/locale.gen
done
arch-chroot /mnt locale-gen

# Set language
echo "LANG=$LANGUAGE" > /mnt/etc/locale.conf

# Set keymap
echo "KEYMAP=$KEYMAP" > /mnt/etc/vconsole.conf

# Set hostname
echo $HOSTNAME > /mnt/etc/hostname

# Set hosts
echo "127.0.0.1  localhost.localdomain localhost" > /mnt/etc/hosts
echo "::1        localhost.localdomain localhost" >> /mnt/etc/hosts
echo >> /mnt/etc/hosts
echo "127.0.0.1  $HOSTNAME.localdomain $HOSTNAME" >> /mnt/etc/hosts

# Disable PC speaker
echo "blacklist pcspkr" >> /mnt/etc/modprobe.d/nobeep.conf
echo "blacklist snd_pcsp" >> /mnt/etc/modprobe.d/nobeep.conf

# Create user
arch-chroot /mnt useradd -U -m -s /bin/zsh -G adm,audio,floppy,log,lp,optical,rfkill,scanner,storage,sys,video,wheel $USERNAME
echo Set a password for your user:
arch-chroot /mnt passwd $USERNAME
sed -ie '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /mnt/etc/sudoers

# Configure mkinitcpio
arch-chroot /mnt mkinitcpio -P

# Verify mkinitcpio
ls -lR /mnt/efi
[ $NOVERIFY -eq 1 ] || read -p "Verify the initramfs image. Press Ctrl+c to cancel or Enter to continue..."

# Enable services to start at next boot
systemctl --root /mnt systemd-resolved systemd-timesyncd enable NetworkManager reflector.timer
systemctl --root /mnt mask systemd-networkd

# Boot loader
mkdir -p /mnt/efi/EFI/Linux # I am not sure if you need this
arch-chroot /mnt bootctl install --esp-path=/efi
sync
systemctl reboot --firmware-setup
