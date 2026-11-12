#!/bin/bash
# ====================================================================
# IRULTUN Auto Update Script via GitHub Repository
# Repo: https://github.com/irulgood/vpnit
# ====================================================================

clear
echo -e "\033[1;36m====================================================\033[0m"
echo -e "\033[1;33m       IRULTUN TUNNELING - SINKRONISASI UPDATE      \033[0m"
echo -e "\033[1;36m====================================================\033[0m"
echo -e "Menghubungkan ke GitHub: \033[1;32mirulgood/vpnit\033[0m ..."
echo ""

REPO_URL="https://raw.githubusercontent.com/irulgood/vpnit/main"
TEMP_DIR="/tmp/irultun_update"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

echo -e "Mengunduh pembaruan master package..."
if curl -sL "${REPO_URL}/irultun.zip" -o "$TEMP_DIR/irultun.zip"; then
  echo -e "\033[1;32m[OK]\033[0m Paket update berhasil diunduh!"
else
  echo -e "\033[1;31m[GAGAL]\033[0m Gagal mengunduh paket dari GitHub. Periksa koneksi internet VPS."
  exit 1
fi

echo -e "Mengekstrak paket..."
unzip -q -o "$TEMP_DIR/irultun.zip" -d "$TEMP_DIR/extracted"

echo -e "Memperbarui binary dan script sistem..."
# Amankan database akun vpn dan file sertifikat agar tidak tertimpa
mkdir -p "$TEMP_DIR/backup_db"
[ -f /usr/sbin/potatonc/potato.db ] && cp -a /usr/sbin/potatonc/potato.db "$TEMP_DIR/backup_db/"
[ -f /usr/sbin/envslowdns ] && cp -a /usr/sbin/envslowdns "$TEMP_DIR/backup_db/"
[ -d /usr/sbin/potatonc/slowdns ] && cp -a /usr/sbin/potatonc/slowdns "$TEMP_DIR/backup_db/"
[ -d /usr/sbin/potatonc/cert ] && cp -a /usr/sbin/potatonc/cert "$TEMP_DIR/backup_db/"

# Update binaries & scripts
SRC_DIR="$TEMP_DIR/extracted"
if [ -d "$SRC_DIR/bin" ]; then
  cp -a "$SRC_DIR/bin/"* /usr/sbin/ 2>/dev/null || true
  chmod +x /usr/sbin/* 2>/dev/null || true
  ln -sf /usr/sbin/menu /usr/bin/menu 2>/dev/null || true
  ln -sf /usr/sbin/menu /usr/bin/irultun 2>/dev/null || true
  ln -sf /usr/sbin/menu /usr/sbin/irultun 2>/dev/null || true
  ln -sf /usr/sbin/apimanage /usr/bin/apimanage 2>/dev/null || true
  ln -sf /usr/sbin/adblock /usr/bin/adblock 2>/dev/null || true
  ln -sf /usr/sbin/update-irultun /usr/bin/update-irultun 2>/dev/null || true
  ln -sf /usr/sbin/update-irultun /usr/bin/update 2>/dev/null || true
fi

if [ -d "$SRC_DIR/usr/bin" ]; then
  cp -a "$SRC_DIR/usr/bin/"* /usr/bin/ 2>/dev/null || true
  chmod +x /usr/bin/* 2>/dev/null || true
fi

if [ -d "$SRC_DIR/lib" ]; then
  cp -a "$SRC_DIR/lib/"* /usr/lib/x86_64-linux-gnu/ 2>/dev/null || true
  cp -a "$SRC_DIR/lib/"* /lib/x86_64-linux-gnu/ 2>/dev/null || true
  ldconfig 2>/dev/null || true
fi

# ====================================================================
# SUNTIKKAN OVERPOWER HIGH PERFORMANCE TUNING (BBR, Buffer, Nginx, Ulimit, Swap)
# ====================================================================
echo -e "Menerapkan Optimasi Overpower Kernel & Network..."

# 1. Sysctl limits & Overpower Kernel Network Tuning (TCP BBR, Buffer 16MB, Conntrack)
cat << 'SYSEOF' > /etc/sysctl.d/99-irultun-overpower.conf
fs.file-max = 10000000
fs.nr_open = 10000000
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.ip_local_port_range = 10000 65000
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_mtu_probing = 1
vm.swappiness = 10
vm.vfs_cache_pressure = 50
SYSEOF
sysctl --system 2>/dev/null || sysctl -p /etc/sysctl.d/99-irultun-overpower.conf 2>/dev/null || true

# 2. Overpower Ulimit limits (1.048.576 open files)
cat << 'LIMEOF' > /etc/security/limits.d/99-irultun-limits.conf
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 1048576
* hard nproc 1048576
root soft nofile 1048576
root hard nofile 1048576
root soft nproc 1048576
root hard nproc 1048576
LIMEOF
ulimit -n 1048576 2>/dev/null || true

# 3. Overpower Auto Swap RAM (2GB jika belum ada swap)
if [ $(free -m | awk '/Swap:/ {print $2}') -eq 0 ]; then
  echo -e "Menyiapkan Swap RAM 2GB untuk stabilitas server..."
  fallocate -l 2G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=2048 2>/dev/null || true
  if [ -f /swapfile ]; then
    chmod 600 /swapfile
    mkswap /swapfile >/dev/null 2>&1 || true
    swapon /swapfile >/dev/null 2>&1 || true
    grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab
  fi
fi

# 4. Overpower Nginx Multi-core Auto Configuration
cat << 'NGXEOF' > /etc/nginx/nginx.conf
user www-data;
worker_processes auto;
worker_cpu_affinity auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

worker_rlimit_nofile 1048576;

events {
    worker_connections 65535;
    use epoll;
    multi_accept on;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    types_hash_max_size 2048;
    server_tokens off;

    default_type application/octet-stream;
    include /etc/nginx/mime.types;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    access_log off;
    error_log /var/log/nginx/error.log crit;

    gzip off;
    open_file_cache max=200000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;

    include /etc/nginx/conf.d/*.conf;
}
NGXEOF
nginx -t && systemctl restart nginx 2>/dev/null || true

# Kembalikan database dan sertifikat aktif
if [ -f "$TEMP_DIR/backup_db/potato.db" ]; then
  cp -a "$TEMP_DIR/backup_db/potato.db" /usr/sbin/potatonc/
fi
if [ -f "$TEMP_DIR/backup_db/envslowdns" ]; then
  cp -a "$TEMP_DIR/backup_db/envslowdns" /usr/sbin/
fi
if [ -d "$TEMP_DIR/backup_db/slowdns" ]; then
  cp -a "$TEMP_DIR/backup_db/slowdns" /usr/sbin/potatonc/
fi
if [ -d "$TEMP_DIR/backup_db/cert" ]; then
  cp -a "$TEMP_DIR/backup_db/cert" /usr/sbin/potatonc/
fi

# Cleanup
rm -rf "$TEMP_DIR"

# Restart Core Services safely
systemctl reload nginx 2>/dev/null || systemctl restart nginx 2>/dev/null || true
systemctl restart dns-server 2>/dev/null || true
systemctl restart local paradis sketsa drawit 2>/dev/null || true

echo ""
echo -e "\033[1;32m====================================================\033[0m"
echo -e "\033[1;32m  UPDATE BERHASIL! OVERPOWER ENGINE TELAH AKTIF!   \033[0m"
echo -e "\033[1;32m====================================================\033[0m"
echo ""
read -p "Tekan [Enter] untuk kembali ke menu utama..."
menu
