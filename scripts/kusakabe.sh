#!/bin/sh
# ============================================================
# kusakabe.sh - Klien Network 3 (Short Lease 1800s)
# Alokasi Target: 10.68.3.10 - 10.68.3.89
# Image: ardhptr21/alpinet:latest
# ============================================================

# Matikan instance udhcpc sebelumnya jika ada
killall udhcpc 2>/dev/null

# Hapus alamat IP lama di eth0
ip addr flush dev eth0

# Request DHCP:
# -i eth0 : interface
# -c kusakabe : Client ID (Option 61 - sesuai instruksi Soal 4)
# -H kusakabe : Hostname (Option 12)
# -s /usr/share/udhcpc/default.script : script default Alpine
udhcpc -i eth0 -c kusakabe -H kusakabe -s /usr/share/udhcpc/default.script

echo ""
echo "=== Verifikasi kusakabe ==="
ip addr show eth0
ip route show
cat /etc/resolv.conf
