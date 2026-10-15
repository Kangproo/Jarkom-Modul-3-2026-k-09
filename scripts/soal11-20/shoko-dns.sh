#!/bin/bash
# shoko - DNS Slave, soal 11 dan 12. Jalankan hanya pada node shoko.
# Script ini TIDAK mengubah IP atau konfigurasi jaringan.
set -euo pipefail
[ "$(hostname)" = "shoko" ] || { echo "ERROR: khusus node shoko"; exit 1; }

if ! command -v named-checkconf >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9-utils dnsutils
fi

backup="$(mktemp -d /root/k09-shoko-dns-XXXXXX)"
for f in /etc/bind/named.conf.local /etc/bind/named.conf.options /etc/bind/k09-zones.conf; do
    [ ! -f "$f" ] || cp -a "$f" "$backup/"
done

cat > /etc/bind/k09-zones.conf <<'CONF'
zone "jujutsu.k09.com" {
    type slave;
    masters { 10.68.1.2; };
    file "/var/cache/bind/db.jujutsu.k09.com";
    allow-notify { 10.68.1.2; };
};
zone "1.68.10.in-addr.arpa" {
    type slave;
    masters { 10.68.1.2; };
    file "/var/cache/bind/db.1.68.10.in-addr.arpa";
    allow-notify { 10.68.1.2; };
};
CONF

touch /etc/bind/named.conf.local
if ! grep -Fq 'include "/etc/bind/k09-zones.conf";' /etc/bind/named.conf.local; then
    if grep -Eq '^[[:space:]]*zone[[:space:]]+"(jujutsu\.k09\.com|1\.68\.10\.in-addr\.arpa)"' /etc/bind/named.conf.local; then
        echo "Zona K09 sudah dideklarasikan di named.conf.local; deklarasi lama dipertahankan."
    else
        printf '\ninclude "/etc/bind/k09-zones.conf";\n' >> /etc/bind/named.conf.local
    fi
fi

cat > /etc/bind/named.conf.options <<'CONF'
options {
    directory "/var/cache/bind";
    recursion yes;
    forwarders { 192.168.122.1; };
    forward only;
    allow-query { 10.68.0.0/16; localhost; };
    allow-recursion { 10.68.0.0/16; localhost; };
    allow-query-cache { 10.68.0.0/16; localhost; };
    listen-on { any; };
    listen-on-v6 { none; };
};
CONF

named-checkconf
service named restart
echo "DNS Slave shoko aktif. Backup konfigurasi: $backup"
echo "Jika zone transfer belum selesai, cek Master utahime dan tunggu beberapa detik."
dig @127.0.0.1 jujutsu.k09.com SOA +short
