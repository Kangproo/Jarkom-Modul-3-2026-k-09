#!/bin/bash
# kirara - API PHP/MariaDB (soal 14 & 17). Tidak mengubah IP/gateway.
# API hanya dapat diakses dari Geto (10.68.4.2) atau localhost.
set -euo pipefail
[ "$(hostname)" = "kirara" ] || { echo "ERROR: script khusus kirara"; exit 1; }

if ! command -v php >/dev/null 2>&1 || ! command -v nginx >/dev/null 2>&1 || ! php -m 2>/dev/null | grep -q '^mysqli$'; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx php-fpm php-cli php-mysql curl
fi

if [ -f /etc/k09-app-secret ]; then
    chown root:www-data /etc/k09-app-secret
    chmod 640 /etc/k09-app-secret
elif [ -f /root/k09-app-secret.txt ]; then
    install -o root -g www-data -m 640 /root/k09-app-secret.txt /etc/k09-app-secret
else
    echo "ERROR: /etc/k09-app-secret atau /root/k09-app-secret.txt belum tersedia." >&2
    echo "Salin password aplikasi dari Yaga secara aman sebelum menjalankan ulang." >&2
    exit 1
fi

backup="$(mktemp -d /root/k09-kirara-api-XXXXXX)"
for f in /var/www/k09-api/index.php /etc/nginx/sites-available/default /etc/nginx/k09-fastcgi-params; do
    [ ! -f "$f" ] || cp -a "$f" "$backup/"
done

mkdir -p /var/www/k09-api
cat > /var/www/k09-api/index.php <<'PHP'
<?php
header('Content-Type: application/json');
$worker = gethostname() ?: 'unknown';
$peer = $_SERVER['REMOTE_ADDR'] ?? '';
$ip = $peer;

// IP forwarding hanya dipercaya saat koneksi berasal dari Geto.
if ($peer === '10.68.4.2') {
    $ip = $_SERVER['HTTP_X_REAL_IP'] ?? $peer;
}
if (!filter_var($ip, FILTER_VALIDATE_IP)) {
    http_response_code(400);
    echo json_encode(['error' => 'invalid client IP']);
    exit;
}

try {
    mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
    $password = trim(file_get_contents('/etc/k09-app-secret'));
    $db = new mysqli('10.68.4.8', 'app_k09', $password, 'db_shibuya_k09', 3306);
    $stmt = $db->prepare(
        'INSERT INTO request_logs (worker_name, client_ip) VALUES (?, ?)'
    );
    $stmt->bind_param('ss', $worker, $ip);
    $stmt->execute();
    $stmt->close();
    $db->close();
    echo json_encode(['status' => 'ok', 'worker' => $worker, 'client_ip' => $ip]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['error' => 'database request failed']);
}
PHP
chmod 755 /var/www/k09-api
chmod 644 /var/www/k09-api/index.php

# Debian fastcgi_params bisa mendefinisikan SCRIPT_FILENAME.
# Buang parameter ganda agar /api tidak menghasilkan "File not found".
grep -vE '^[[:space:]]*fastcgi_param[[:space:]]+SCRIPT_FILENAME[[:space:]]' \
    /etc/nginx/fastcgi_params > /etc/nginx/k09-fastcgi-params

cat > /etc/nginx/sites-available/default <<'CONF'
server {
    listen 80 default_server;
    server_name _;

    location ~ ^/api/?$ {
        allow 10.68.4.2;
        allow 127.0.0.1;
        deny all;

        include /etc/nginx/k09-fastcgi-params;
        fastcgi_param SCRIPT_FILENAME /var/www/k09-api/index.php;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }

    location / {
        return 404;
    }
}
CONF

[ -e /etc/nginx/sites-enabled/default ] || ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
php -l /var/www/k09-api/index.php
nginx -t
service php8.4-fpm start
if service nginx status >/dev/null 2>&1; then
    service nginx reload
else
    service nginx start
fi
echo "API kirara terpasang. Backup: $backup"
echo "Uji HTTP dari Geto: curl -i http://10.68.4.7/api"
