#!/bin/bash
# yaga - MariaDB Master soal 13. Tidak mengubah alamat IP.
# Password tidak disimpan dalam GitHub. Gunakan file rahasia lokal.
set -euo pipefail
[ "$(hostname)" = "yaga" ] || { echo "ERROR: khusus node yaga"; exit 1; }

if ! command -v mariadbd >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server mariadb-client
fi

conf=/etc/mysql/mariadb.conf.d/60-k09-master.cnf
backup="$(mktemp -d /root/k09-yaga-db-XXXXXX)"
[ ! -f "$conf" ] || cp -a "$conf" "$backup/"
cat > "$conf" <<'CONF'
[mysqld]
server-id = 1
log_bin = /var/lib/mysql/k09-bin
binlog_format = ROW
bind-address = 10.68.4.8
CONF

service mariadb restart
mariadb <<'SQL'
CREATE DATABASE IF NOT EXISTS db_shibuya_k09;
CREATE TABLE IF NOT EXISTS db_shibuya_k09.request_logs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    worker_name VARCHAR(64) NOT NULL,
    client_ip VARCHAR(45) NOT NULL,
    requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
SQL

# Membuat user hanya jika berkas password lokal tersedia. Jangan
# membuat password baru sembarangan: worker lama bisa kehilangan akses.
# Password harus alfanumerik/._- supaya aman disisipkan ke SQL.
make_user() {
    local file="$1" user="$2" host="$3" grant="$4" pass
    if [ ! -f "$file" ]; then
        echo "CATATAN: $file belum ada, pembuatan user $user dilewati."
        return
    fi
    chmod 600 "$file"
    pass="$(tr -d '\r\n' < "$file")"
    if ! printf '%s' "$pass" | LC_ALL=C grep -Eq '^[A-Za-z0-9._-]{16,128}$'; then
        echo "ERROR: karakter password $user tidak sesuai aturan script, tidak diubah." >&2
        return 1
    fi
    mariadb <<SQL
CREATE USER IF NOT EXISTS '$user'@'$host' IDENTIFIED BY '$pass';
$grant
SQL
    echo "Hak user $user diperiksa."
}

make_user /root/k09-repl-secret.txt repl_k09 10.68.4.9 \
    "GRANT REPLICATION SLAVE ON *.* TO 'repl_k09'@'10.68.4.9';"
make_user /root/k09-app-secret.txt app_k09 10.68.4.% \
    "GRANT SELECT, INSERT ON db_shibuya_k09.request_logs TO 'app_k09'@'10.68.4.%';"

mariadb -e "SHOW VARIABLES LIKE 'log_bin'; SHOW VARIABLES LIKE 'binlog_format';"
mariadb -e "SHOW MASTER STATUS\G"
echo "MariaDB Master yaga siap. Backup konfigurasi: $backup"
echo "Snapshot untuk Slave harus diambil secara konsisten; jangan memakai log position lama."
