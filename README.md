# Documentation for Running the Minimal Arch Linux Installation Script

This document explains how to use the provided shell script to install Arch Linux. The script automates a minimal installation of Arch Linux and can be customized for specific system configurations.

## Prerequisites
- An Arch Linux ISO booted on the system.
- An active internet connection.
- Basic knowledge of shell usage.
- Backup of all data on the target disk, as the script will erase it completely.

## Script Overview
The script is divided into several sections and accepts basic configuration parameters:

### Key Parameters
1. **Country Code for Mirror Servers**: `COUNTRY='DE'`
2. **Target Disk**: `DISK='/dev/disk/by-id/...'` (uses the disk ID; can be listed using `ls -lAh /dev/disk/by-id`).
3. **Hostname**: `HOSTNAME='16ach6'`
4. **Keyboard Layout**: `KEYMAP='de-latin1'`
5. **Language**: `LANGUAGE='en_US.UTF-8'`
6. **Timezone**: `TIMEZONE='Europe/Berlin'`
7. **Username**: `USERNAME='sid'`
8. **Swap Size**: `SWAP_GB=8` (swap partition size in GB).

### Script Features
- Disk partitioning with GPT.
- Formatting and mounting partitions.
- Installing a minimal system with essential packages.
- Setting up timezone, language, hostname, and user.
- Installing and configuring a bootloader.
- Activating necessary system services.

## Execution Steps

### 1. Download and Prepare the Script
Save the script as a file, e.g., `install.sh`:
```bash
nano install.sh
```
Paste the script content and make it executable:
```bash
chmod +x install.sh
```

### 2. Adjust Script Parameters
Modify parameters like `DISK`, `COUNTRY`, `USERNAME`, etc., according to your hardware and requirements. Open the file in an editor:
```bash
nano install.sh
```

### 3. Run the Script
Execute the script with root privileges:
```bash
sudo ./install.sh
```

The script supports two optional flags:
- `-f`: Forces disk formatting with `dd`.
- `-n`: Skips all verification prompts.

Example:
```bash
sudo ./install.sh -f -n
```

### 4. Verification Steps
The script pauses at certain points to allow verification (unless the `-n` flag is used). For example, it displays the partitions and the `fstab` file for confirmation.

### 5. Reboot
After a successful installation and configuration, reboot the system. Remove the installation media:
```bash
sync
reboot
```

## Important Notes
- **Data Loss**: All data on the specified disk will be erased.
- **Hardware Compatibility**: Ensure your hardware (e.g., UEFI or BIOS) is compatible with Arch Linux.
- **Network**: The script requires an active internet connection to download packages and optimize mirrors.

## Troubleshooting
If an error occurs:
1. Check the console output for detailed error messages.
2. Ensure all parameters are correctly configured.
3. Run the script with debugging by adding `set -x` before the commands in the script.

## Extension
The script can be customized to include additional packages or specific configurations (e.g., desktop environments).

---

With this script, you can quickly and efficiently set up a minimal Arch Linux system.

