#!/usr/bin/env bash
# =============================================================================
# Hiren's Boot CD — Excelsior
# create-usb.sh — Flash ISO to USB drive
#
# Usage:
#   sudo bash excelsior/scripts/create-usb.sh <iso-file> <usb-device>
#
# Example:
#   sudo bash excelsior/scripts/create-usb.sh Excelsior.iso /dev/sdb
#
# WARNING: This ERASES the target device. Triple-check the device path!
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; RESET='\033[0m'

error()   { echo -e "${BOLD}${RED}[ERROR]${RESET} $*" >&2; exit 1; }
warn()    { echo -e "${BOLD}${YELLOW}[WARN ]${RESET} $*"; }
success() { echo -e "${BOLD}${GREEN}[ OK  ]${RESET} $*"; }
log()     { echo -e "${BOLD}[INFO ]${RESET} $*"; }

[[ $EUID -eq 0 ]] || error "Must be run as root: sudo bash $0 <iso> <device>"
[[ $# -ge 2 ]]    || { echo "Usage: sudo bash $0 <iso-file> <usb-device>"; exit 1; }

ISO="$1"
DEV="$2"

[[ -f "${ISO}" ]] || error "ISO not found: ${ISO}"
[[ -b "${DEV}" ]] || error "Not a block device: ${DEV}"

# Sanity check: refuse to write to a mounted filesystem
if mount | grep -q "^${DEV}"; then
  error "Device ${DEV} appears to be mounted! Unmount it first."
fi

# Get device info
DEV_SIZE=$(lsblk -bnd -o SIZE "${DEV}" 2>/dev/null || echo "unknown")
ISO_SIZE=$(stat -c%s "${ISO}")
ISO_SIZE_H=$(du -sh "${ISO}" | cut -f1)

echo ""
echo -e "${BOLD}${RED}══════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}${RED}  ⚠  WARNING — DATA DESTRUCTION AHEAD  ⚠${RESET}"
echo -e "${BOLD}${RED}══════════════════════════════════════════════════════${RESET}"
echo ""
echo -e "  ISO file  : ${BOLD}${ISO}${RESET} (${ISO_SIZE_H})"
echo -e "  USB device: ${BOLD}${DEV}${RESET}"
echo ""
lsblk "${DEV}" 2>/dev/null || true
echo ""
echo -e "${YELLOW}ALL DATA ON ${DEV} WILL BE PERMANENTLY ERASED!${RESET}"
echo ""
read -r -p "Type YES to confirm: " CONFIRM
[[ "${CONFIRM}" == "YES" ]] || { echo "Aborted."; exit 0; }

log "Unmounting any partitions on ${DEV}..."
umount "${DEV}"?* 2>/dev/null || true

log "Flashing ISO to USB — this may take several minutes..."
dd if="${ISO}" of="${DEV}" bs=4M status=progress oflag=sync conv=fsync

sync
echo ""
success "USB drive ready: ${DEV}"
echo -e "  Safely remove the drive and boot from it on your target machine."
echo ""
