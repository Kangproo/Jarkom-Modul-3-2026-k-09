#!/bin/bash
# ============================================================
# panda.sh - Worker Frontend
# IP: 10.68.4.4/24 | Gateway: 10.68.4.1
# Image: ardhptr21/debinet:latest
# ============================================================

# Resolver awal agar dapat mengunduh paket
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Pasang IP statis (idempotent, aman dijalankan berulang)
ip addr flush dev eth0 2>/dev/null
ip addr add 10.68.4.4/24 dev eth0
ip link set eth0 up
ip route replace default via 10.68.4.1

# Persistensi saat reboot kontainer
cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.68.4.4
    netmask 255.255.255.0
    gateway 10.68.4.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF

echo "=== panda.sh selesai (10.68.4.4) ==="
