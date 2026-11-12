#!/bin/bash
set -e

echo "=== Memasang IRULTUN TUNNELING (Fixed Edition) ==="

# 0. System packages & dependencies
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx dropbear sqlite3 curl socat cron zip unzip iptables net-tools jq python2 figlet toilet lolcat vnstat neofetch openvpn squid 2>/dev/null || apt-get install -y nginx dropbear sqlite3 curl socat cron zip unzip iptables net-tools jq python figlet toilet lolcat vnstat neofetch openvpn squid
if [ ! -f /usr/bin/python ] && [ -f /usr/bin/python2 ]; then
  ln -sf /usr/bin/python2 /usr/bin/python
fi

# 1. Sysctl limits & Overpower Kernel Network Tuning (TCP BBR, Buffer, Conntrack)
sysctl -w fs.nr_open=10000000 fs.file-max=10000000

# Overpower Kernel & Network Tuning
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
net.ipv4.ip_local_port_range = 1024 65535
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_mtu_probing = 1
net.netfilter.nf_conntrack_max = 524288
vm.swappiness = 10
vm.vfs_cache_pressure = 50
SYSEOF
sysctl --system 2>/dev/null || sysctl -p /etc/sysctl.d/99-irultun-overpower.conf 2>/dev/null || true

# Overpower Ulimit limits
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

# Overpower Auto Swap RAM (1GB Emergency Fallback)
if [ $(free -m | awk '/Swap:/ {print $2}') -eq 0 ]; then
  echo "=== Menyiapkan Swap RAM 1GB untuk stabilitas server ==="
  fallocate -l 1G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=1024 2>/dev/null || true
  if [ -f /swapfile ]; then
    chmod 600 /swapfile
    mkswap /swapfile >/dev/null 2>&1 || true
    swapon /swapfile >/dev/null 2>&1 || true
    grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab
  fi
fi

# Download IRULTUN Package dari GitHub jika dijalankan via curl/wget
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
if [ ! -d "$INSTALL_DIR/bin" ] || [ ! -d "$INSTALL_DIR/lib" ]; then
  echo "=== Mengunduh master package dari GitHub irulgood/vpnit ==="
  TEMP_DL="/tmp/irultun_install_tmp"
  rm -rf "$TEMP_DL" && mkdir -p "$TEMP_DL"
  curl -sL "https://raw.githubusercontent.com/irulgood/vpnit/main/irultun.zip" -o "$TEMP_DL/irultun.zip"
  unzip -q -o "$TEMP_DL/irultun.zip" -d "$TEMP_DL"
  INSTALL_DIR="$TEMP_DL"
fi

# 2. Shared libraries
cp -a "$INSTALL_DIR/lib/"* /usr/lib/x86_64-linux-gnu/ 2>/dev/null || true
cp -a "$INSTALL_DIR/lib/"* /lib/x86_64-linux-gnu/ 2>/dev/null || true
ldconfig

# 3. Binaries and scripts
cp -a "$INSTALL_DIR/bin/"* /usr/sbin/
chmod +x /usr/sbin/* 2>/dev/null || true
ln -sf /usr/sbin/menu /usr/bin/menu
ln -sf /usr/sbin/menu /usr/bin/irultun
ln -sf /usr/sbin/menu /usr/sbin/irultun
ln -sf /usr/sbin/apimanage /usr/bin/apimanage
ln -sf /usr/sbin/adblock /usr/bin/adblock
ln -sf /usr/sbin/update-irultun /usr/bin/update-irultun
ln -sf /usr/sbin/update-irultun /usr/bin/update

# 4. Auxiliary /usr/bin binaries (ctl & watchgnupg, xray, aus-cloud)
if [ -d "$INSTALL_DIR/usr/bin" ]; then
  cp -a "$INSTALL_DIR/usr/bin/"* /usr/bin/
  chmod +x /usr/bin/* 2>/dev/null || true
fi

# 5. IRULTUNnc and libc64
mkdir -p /etc/potatonc
[ -d "$INSTALL_DIR/etc/etc_potatonc" ] && cp -rn "$INSTALL_DIR/etc/etc_potatonc/"* /etc/potatonc/ 2>/dev/null || true
cp -a "$INSTALL_DIR/potatonc" /usr/sbin/
cp -a "$INSTALL_DIR/libc64" /

# 6. Syncron & Xray log directory
mkdir -p /etc/default
cp -a "$INSTALL_DIR/syncron" /etc/default/
mkdir -p /var/log/xray
mkdir -p /etc/xray

# 7. OHP, OpenVPN, Squid, and banner
[ -d "$INSTALL_DIR/etc/openvpn" ] && cp -a "$INSTALL_DIR/etc/openvpn" /etc/ 2>/dev/null || true
[ -d "$INSTALL_DIR/etc/squid" ] && cp -a "$INSTALL_DIR/etc/squid" /etc/ 2>/dev/null || true
[ -f "$INSTALL_DIR/potato.ohp" ] && cp -a "$INSTALL_DIR/potato.ohp" /etc/potato.ohp && chmod +x /etc/potato.ohp || true
[ -f "$INSTALL_DIR/banner.com" ] && cp -a "$INSTALL_DIR/banner.com" /etc/banner.com || true

# 8. Configure Dropbear
grep -qxF "/bin/false" /etc/shells || echo "/bin/false" >> /etc/shells
grep -qxF "/usr/sbin/nologin" /etc/shells || echo "/usr/sbin/nologin" >> /etc/shells

cat << "DBEOF" > /etc/default/dropbear
NO_START=0
DROPBEAR_PORT=90
DROPBEAR_EXTRA_ARGS="-p 143 -p 69"
DROPBEAR_BANNER="/etc/banner.com"
DROPBEAR_RECEIVE_WINDOW=65536
DBEOF
systemctl restart dropbear || true

# 9. Configure Nginx (Multi-core Overpower & Free port 80 & 443 for local.service)
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

mkdir -p /etc/nginx/conf.d
cp -a "$INSTALL_DIR/nginx/"* /etc/nginx/conf.d/ 2>/dev/null || true
[ -f /etc/nginx/conf.d/xray.conf ] && mv /etc/nginx/conf.d/xray.conf /etc/nginx/conf.d/xray.conf.disabled || true
[ -f /etc/nginx/sites-enabled/default ] && rm -f /etc/nginx/sites-enabled/default || true
nginx -t && systemctl restart nginx || true

# 10. Init vnstat neofetch
chown -R vnstat:vnstat /var/lib/vnstat 2>/dev/null || true
systemctl enable --now vnstat 2>/dev/null || true

# 11. Systemd services
cp -a "$INSTALL_DIR/systemd/"* /etc/systemd/system/
systemctl daemon-reload

# 12. Start services
systemctl enable --now local paradis sketsa drawit cuagfs "tunws@sochs" dropbear
systemctl enable --now ikus@runlip1 ikus@runlip2 ikus@runlip3 ikus@runlip4 ikus@runlip5 ikus@runlip6 ikus@runlip7 ikus@runlip8 ikus@scci ikus@sccu 2>/dev/null || true
systemctl enable --now potato-ohp aus-cloud 2>/dev/null || true
systemctl enable --now openvpn openvpn@server-tcp-1194 openvpn@server-udp-25000 squid udp-server apache2 2>/dev/null || true

# 13. Dynamic Key Generation (Unique SlowDNS & API Key on each install)
echo "=== Generating Unique SlowDNS Keypair & Random API Key ==="
mkdir -p /usr/sbin/potatonc/slowdns
rm -f /usr/sbin/potatonc/slowdns/server.key /usr/sbin/potatonc/slowdns/server.pub
/usr/sbin/dns-server -gen-key -privkey-file /usr/sbin/potatonc/slowdns/server.key -pubkey-file /usr/sbin/potatonc/slowdns/server.pub
chmod 600 /usr/sbin/potatonc/slowdns/server.key
chmod 644 /usr/sbin/potatonc/slowdns/server.pub
SLOWDNS_PUB=$(cat /usr/sbin/potatonc/slowdns/server.pub | tr -d " \r\n")

RANDOM_API_KEY="irultun$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 29)"
RANDOM_AUTH_KEY=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)

MY_IP=$(curl -s -4 icanhazip.com || hostname -I | awk '{print $1}')
MY_DOMAIN=$(openssl x509 -in /usr/sbin/potatonc/cert/cert.pem -noout -subject 2>/dev/null | sed -n 's/.*CN = //p' || echo "$MY_IP")
if [ -z "$MY_DOMAIN" ]; then MY_DOMAIN="$MY_IP"; fi

sqlite3 /usr/sbin/potatonc/potato.db "UPDATE servers SET address='$MY_IP', domain='$MY_DOMAIN', key='$RANDOM_API_KEY', auth='$RANDOM_AUTH_KEY', pub='$SLOWDNS_PUB', ns='ns-${MY_DOMAIN}';" 2>/dev/null || true

cat << EOF_SLOWDNS > /usr/sbin/envslowdns
NAMESERVER="ns-${MY_DOMAIN}"
CONFIG_PRIV="/usr/sbin/potatonc/slowdns/server.key"
CONFIG_PUB="/usr/sbin/potatonc/slowdns/server.pub"
SERVICE_CLIENT="127.0.0.1:90"
SERVICE_SERVER="127.0.0.1:90"
LISTEN_CLIENT="8.8.8.8:53"
LISTEN_SERVER=":5300"
EOF_SLOWDNS

iptables -I INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null || true
iptables -t nat -D POSTROUTING -j MASQUERADE 2>/dev/null || true
iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null || true

systemctl restart aus-cloud 2>/dev/null || true
systemctl enable --now dns-server 2>/dev/null || true

# 14. Login banner (Neofetch)
cat << "EOF_PROF" > /root/.profile
# ~/.profile: executed by Bourne-compatible login shells.

if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi

mesg n 2> /dev/null || true
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

if [ -t 1 ]; then
  clear
  neofetch
fi
EOF_PROF

# Cleanup temporary download
rm -rf /tmp/irultun_install_tmp 2>/dev/null || true

echo "=== Selesai! Jalankan 'menu' atau 'irultun' untuk membuka dashboard ==="