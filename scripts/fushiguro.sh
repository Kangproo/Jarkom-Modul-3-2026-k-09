#!/bin/sh
# ============================================================
# fushiguro.sh - Klien Network 2 (Pool 1)
# Alokasi Target: 10.68.2.10 - 10.68.2.35
# Image: ardhptr21/alpinet:latest
# ============================================================

# Matikan instance udhcpc sebelumnya jika ada
killall udhcpc 2>/dev/null

# Hapus alamat IP lama di eth0
ip addr flush dev eth0

# Request DHCP:
# -i eth0 : interface
# -c fushiguro : Client ID (Option 61 - sesuai instruksi Soal 4)
# -H fushiguro : Hostname (Option 12)
# -s /usr/share/udhcpc/default.script : script default Alpine
udhcpc -i eth0 -H fushiguro -s /usr/share/udhcpc/default.script

echo ""
echo "=== Verifikasi fushiguro ==="
ip addr show eth0
ip route show
cat /etc/resolv.conf
