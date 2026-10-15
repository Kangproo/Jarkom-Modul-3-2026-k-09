#!/bin/bash
# inumaki - MariaDB Slave soal 13. Tidak melakukan reset replikasi.
# Untuk bootstrap, butuh snapshot Master yang SEJAMAN dengan binlog position.
set -euo pipefail
[ "$(hostname)" = "inumaki" ] || { echo "ERROR: khusus node inumaki"; exit 1; }

if ! command -v mariadbd >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server mariadb-client
fi

conf=/etc/mysql/mariadb.conf.d/60-k09-slave.cnf
backup="$(mktemp -d /root/k09-inumaki-db-XXXXXX)"
[ ! -f "$conf" ] || cp -a "$conf" "$backup/"
cat > "$conf" <<'CONF'
[mysqld]
server-id = 2
relay-log = /var/lib/mysql/k09-relay
read_only = ON
bind-address = 10.68.4.9
CONF

service mariadb restart
echo "=== KONFIGURASI SLAVE ==="
mariadb -e "SHOW VARIABLES LIKE 'server_id'; SHOW VARIABLES LIKE 'read_only';"
echo "=== STATUS REPLIKASI ==="
mariadb -e "SHOW SLAVE STATUS\G" | grep -E 'Master_Host:|Slave_IO_Running:|Slave_SQL_Running:|Seconds_Behind_Master:|Last_IO_Error:|Last_SQL_Error:' || true

echo "Backup konfigurasi: $backup"
echo "Script ini sengaja tidak menjalankan CHANGE MASTER atau import SQL."
echo "Jika setup dari nol, ambil snapshot konsisten dari Yaga, salin,"
echo "import ke Inumaki, lalu pakai posisi log dari snapshot tersebut."
echo "Lihat soal/soal13.txt. Jangan gunakan MASTER_LOG_POS=1251 untuk snapshot baru."
