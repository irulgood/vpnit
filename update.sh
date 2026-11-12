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
systemctl restart dropbear 2>/dev/null || true
systemctl restart nginx 2>/dev/null || true
systemctl restart local paradis sketsa drawit 2>/dev/null || true

echo ""
echo -e "\033[1;32m====================================================\033[0m"
echo -e "\033[1;32m  UPDATE BERHASIL! Seluruh script telah tersinkron. \033[0m"
echo -e "\033[1;32m====================================================\033[0m"
echo ""
read -p "Tekan [Enter] untuk kembali ke menu utama..."
menu
