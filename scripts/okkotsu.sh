#!/bin/sh
# ============================================================
# okkotsu.sh - Klien Network 2 (Pool 2)
# Alokasi Target: 10.68.2.70 - 10.68.2.95
# Image: ardhptr21/alpinet:latest
# ============================================================

# Matikan instance udhcpc sebelumnya jika ada
killall udhcpc 2>/dev/null

# Hapus alamat IP lama di eth0
ip addr flush dev eth0

# Request DHCP:
# -i eth0 : interface
# -c okkotsu : Client ID (Option 61 - sesuai instruksi Soal 4)
# -H okkotsu : Hostname (Option 12)
# -s /usr/share/udhcpc/default.script : script default Alpine
udhcpc -i eth0 -c okkotsu -H okkotsu -s /usr/share/udhcpc/default.script

echo ""
echo "=== Verifikasi okkotsu ==="
ip addr show eth0
ip route show
cat /etc/resolv.conf
