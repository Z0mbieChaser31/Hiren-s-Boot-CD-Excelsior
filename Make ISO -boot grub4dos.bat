@echo off
echo.
echo ============================================================
echo  DEPRECATED — Hiren's Boot CD Excelsior
echo ============================================================
echo  This script builds the LEGACY Hiren's BootCD 15.2 ISO.
echo  It uses grub4dos (Legacy BIOS only, no UEFI support).
echo.
echo  For a modern USB rescue drive that works on any computer,
echo  use setup.py / setup.ps1 instead:
echo.
echo    python setup.py         (interactive wizard)
echo    .\setup.ps1             (Windows PowerShell)
echo.
echo  See README.md for full instructions.
echo ============================================================
echo.
echo Building legacy HBCD 15.2 ISO with grub4dos bootloader...
echo (This will only boot on Legacy BIOS systems, NOT on UEFI)
echo.
pause
"mkisofs.exe" -R -D -J -l -joliet-long -duplicates-once -o MyHBCD.iso -b HBCD/grldr -c HBCD/boot.cat -hide-joliet HBCD/boot.cat -hide HBCD/boot.cat -no-emul-boot -N -boot-info-table -V HirensBootCD  -boot-load-size 4 CD
echo.
echo Done. Output: MyHBCD.iso
echo To use on a Ventoy USB: copy to ISOs\Legacy\hbcd-15.2.iso on your USB drive.
pause
