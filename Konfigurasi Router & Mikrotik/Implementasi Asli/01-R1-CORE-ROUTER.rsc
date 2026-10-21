# ==============================================================================
# KONFIGURASI IMPLEMENTASI ASLI: R1-CORE-ROUTER
# Perangkat: MikroTik hAP lite (RB941-2nD) / Router Utama
# Lokasi: Ruang Server / Ruang Guru
# ISP: Fibernet 100 Mbps Dedicated
# ==============================================================================

# 1. IDENTITAS ROUTER
/system identity set name="R1-CORE-ROUTER"

# 2. PENAMAAN INTERFACE FISIK
/interface ethernet
set [ find default-name=ether1 ] name=ether1-WAN comment="Kabel dari Modem ISP Fibernet"
set [ find default-name=ether2 ] name=ether2-DISTRIBUSI comment="Ke Gigabit Core Switch (Port 1)"
set [ find default-name=ether3 ] name=ether3-MANAGEMENT comment="Port Khusus Teknisi / Winbox Darurat"
set [ find default-name=ether4 ] name=ether4-CADANGAN comment="Port Cadangan / Link Eksternal"

# 3. PENGALAMATAN IP
# 3.1 WAN Internet (Pilih salah satu sesuai jenis koneksi dari ISP)
# Mode DHCP Client dari Modem ISP:
/ip dhcp-client add interface=ether1-WAN disabled=no add-default-route=yes use-peer-dns=yes comment="DHCP dari ISP"

# 3.2 LAN Backbone Distribusi
/ip address add address=10.10.10.1/24 interface=ether2-DISTRIBUSI comment="Gateway Backbone Distribusi Sekolah"
/ip address add address=192.168.88.1/24 interface=ether3-MANAGEMENT comment="IP Akses Langsung Teknisi"

# 4. PENGATURAN DNS RESOLVER & CACHE
/ip dns set allow-remote-requests=yes cache-size=2048KiB servers=8.8.8.8,1.1.1.1

# 5. FIREWALL & NAT MASQUERADE PUSAT
/ip firewall nat add chain=srcnat out-interface=ether1-WAN action=masquerade comment="NAT Masquerade Utama Sekolah"

# PENTING: Matikan FastTrack agar Queue Tree berfungsi normal membatasi bandwidth
/ip firewall filter disable [ find action=fasttrack-connection ]
/ip firewall filter add chain=forward action=accept comment="Bypass FastTrack untuk Queue Tree" place-before=0

# 6. STATIC ROUTING KE SELURUH ROUTER CABANG (LAB CBT & BENGKEL)
/ip route
add dst-address=192.168.20.0/24 gateway=10.10.10.2 comment="Rute ke Lab TJKT via R2-TKA"
add dst-address=192.168.21.0/24 gateway=10.10.10.2 comment="Rute ke Lab MP via R2-TKA"
add dst-address=192.168.22.0/24 gateway=10.10.10.2 comment="Rute ke Server Proktor via R2-TKA"
add dst-address=192.168.30.0/24 gateway=10.10.10.3 comment="Rute ke Bengkel TKJ via R3"
add dst-address=192.168.40.0/24 gateway=10.10.10.4 comment="Rute ke Bengkel TBSM via R4"
add dst-address=192.168.50.0/24 gateway=10.10.10.5 comment="Rute ke Bengkel MP via R5 (Jika Ada)"

# 7. QUEUE TREE PUSAT (KAPASITAS TOTAL FIBERNET 100M -> 95M USABLE)
/queue tree
add name=TOTAL-DOWNLOAD parent=global max-limit=95M comment="Pipa Bersih ISP Fibernet"

# Garansi Bandwidth Jalur VIP TKA (Prioritas 1, minimal 75 Mbps saat ujian)
add name=Q-JALUR-VIP-TKA parent=TOTAL-DOWNLOAD limit-at=75M max-limit=90M priority=1 dst=10.10.10.2 comment="Jalur Prioritas Ujian CBT"

# Ruang Guru & WiFi Selasar (Prioritas 3, sisa bandwidth maksimal 30 Mbps)
add name=Q-RUANG-GURU     parent=TOTAL-DOWNLOAD limit-at=10M max-limit=30M priority=3 dst=10.10.10.0/24 comment="Ruang Guru & AP Sekolah"

# Bengkel Jurusan TKJ & TBSM (Prioritas 5, dibatasi saat jam ujian)
add name=Q-BENGKEL        parent=TOTAL-DOWNLOAD limit-at=5M  max-limit=15M priority=5 dst=10.10.10.3,10.10.10.4,10.10.10.5 comment="Bengkel Praktik"

# 8. MANAGEMENT & KEAMANAN
/tool romon set enabled=yes
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes
