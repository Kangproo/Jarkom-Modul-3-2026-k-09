#!/bin/bash
# ============================================================
# jichi.sh - Router Utama & DHCP Relay
# Covers: Soal 1, 3, 9, 10
# Image: ardhptr21/debinet:latest
# ============================================================

echo 'nameserver 192.168.122.1' > /etc/resolv.conf

# === SOAL 1: Konfigurasi Interface Manual (Runtime) ===
ip addr flush dev eth1 2>/dev/null
ip addr flush dev eth2 2>/dev/null
ip addr flush dev eth3 2>/dev/null
ip addr flush dev eth4 2>/dev/null

ip addr add 10.68.1.1/24 dev eth1 && ip link set eth1 up
ip addr add 10.68.2.1/24 dev eth2 && ip link set eth2 up
ip addr add 10.68.3.1/24 dev eth3 && ip link set eth3 up
ip addr add 10.68.4.1/24 dev eth4 && ip link set eth4 up

# IPv4 Forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Source NAT (MASQUERADE) via eth0 (NAT WAN)
iptables -t nat -F POSTROUTING
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# === SOAL 10: Persistensi Konfigurasi Network & Forwarding (Tahan Reboot) ===
cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 10.68.1.1
    netmask 255.255.255.0

auto eth2
iface eth2 inet static
    address 10.68.2.1
    netmask 255.255.255.0

auto eth3
iface eth3 inet static
    address 10.68.3.1
    netmask 255.255.255.0

auto eth4
iface eth4 inet static
    address 10.68.4.1
    netmask 255.255.255.0
EOF

# Persistensi sysctl forwarding
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf

# Persistensi iptables via rc.local
cat > /etc/rc.local << 'EOF'
#!/bin/bash
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
service isc-dhcp-relay start
exit 0
EOF
chmod +x /etc/rc.local

# === SOAL 3: DHCP Relay ===
apt-get update
apt-get install -y isc-dhcp-relay

cat > /etc/default/isc-dhcp-relay << 'EOF'
SERVERS="10.68.4.10"
# eth2 untuk Net 2, eth3 untuk Net 3, eth4 untuk trunk ke server tengen
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
EOF

service isc-dhcp-relay restart

# === SOAL 10: Autostart Relay ===
systemctl enable isc-dhcp-relay 2>/dev/null || update-rc.d isc-dhcp-relay defaults 2>/dev/null

echo "=== jichi.sh selesai ==="
