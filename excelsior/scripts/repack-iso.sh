#!/usr/bin/env bash
# repack-iso.sh — Re-assemble Excelsior.iso from an already-populated iso_root.
# Writes to /tmp first to avoid WSL2 DrvFs libburn Permission Denied, then
# removes the old ISO (owned by the WSL user) and copies the new one in place.
set -euo pipefail

WORKDIR="${WORKDIR:-/mnt/c/excelsior-build}"
DEST="${DEST:-/mnt/c/Users/gerla/OneDrive/Desktop/Hiren-s-Boot-CD-reborn/Excelsior.iso}"
TMPISO="/tmp/Excelsior-repack-$$.iso"
LABEL="EXCELSIOR"

echo "[BUILD] Re-packing ISO from ${WORKDIR}/iso_root..."
echo "[BUILD] Writing to tmpfs: ${TMPISO}"

xorriso -as mkisofs \
  -iso-level 3 \
  -full-iso9660-filenames \
  -volid "${LABEL}" \
  -appid "Hirens Boot CD Excelsior" \
  -publisher "HBCD Excelsior Project" \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -b boot/isolinux/isolinux.bin \
  -c boot/isolinux/boot.cat \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -eltorito-alt-boot \
  -e boot/grub/efiboot.img \
  -no-emul-boot \
  -isohybrid-gpt-basdat \
  -output "${TMPISO}" \
  "${WORKDIR}/iso_root"

echo "[ OK ] ISO written to tmpfs ($(du -sh ${TMPISO} | cut -f1))"
echo "[BUILD] Removing old ISO and installing new one..."
rm -f "${DEST}"
cp "${TMPISO}" "${DEST}"
rm -f "${TMPISO}"

echo "[ OK ] ISO installed: ${DEST}"
ls -lh "${DEST}"
sha256sum "${DEST}" | tee "${DEST}.sha256"
echo "[ OK ] Done."
