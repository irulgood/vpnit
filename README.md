# IRULTUN Tunneling - Overpower High Performance Edition

Master installer autoscript VPN multi-protocol (SSH, Dropbear, VMess, VLess, Trojan, SlowDNS, Shadowsocks) dengan optimasi kernel tingkat tinggi (Google TCP BBR, Buffer 16MB, Ulimit 1M, Nginx Multi-Core Auto).

## 🚀 Cara Install di VPS Baru (One-Line Installer)
Jalankan perintah ini di terminal root VPS Debian / Ubuntu:
```bash
apt update -y && apt install -y curl wget unzip && wget -q https://raw.githubusercontent.com/irulgood/vpnit/main/install.sh && chmod +x install.sh && ./install.sh
```

## 🔄 Cara Update Script / Menu
Untuk memperbarui menu dan binary tanpa merusak akun database VPN yang sudah ada:
```bash
wget -q https://raw.githubusercontent.com/irulgood/vpnit/main/update.sh && chmod +x update.sh && ./update.sh
```
*Atau langsung dari menu VPS: pilih **Menu Opsi 20 (Update Script)***.

## ✨ Fitur Unggulan
- **Overpower Network Engine**: TCP BBR + FQ qdisc + TCP FastOpen + 1.048.576 open files.
- **Nginx Multi-Core Auto**: Menyesuaikan worker process dan core affinity CPU VPS secara otomatis.
- **Ad-Blocker System-wide**: DNSMasq anti iklan & judi online (Menu 22).
- **Cloudflare WARP Socks5**: Bebas unblock streaming & AI tanpa asymmetric routing (Menu 11).
- **Cloudflare Zero Trust Support**: Mendukung login organisasi mandiri via Service Token.
- **IRULTUN REST API**: Manajemen token API terintegrasi web store (Menu 23).
