# ==============================================================================
# KONFIGURASI SIMULASI GNS3: R1-CORE-ROUTER (MANDIRI / TANPA CLOUD)
# Perangkat: MikroTik CHR (Cloud Hosted Router)
# Peran: Otak Utama Jaringan, Gateway Backbone, & Simulator Internet (8.8.8.8)
# ==============================================================================

# 1. IDENTITAS ROUTER
/system identity set name="R1-CORE-ROUTER"

# 2. PENAMAAN INTERFACE
/interface ethernet
set [ find default-name=ether1 ] name=ether1-WAN comment="Opsional: Jalur jika ingin disambung ke Cloud1 / Host Laptop"
set [ find default-name=ether2 ] name=ether2-DISTRIBUSI comment="Kabel Utama ke Core-Switch (Port 25)"

# 3. INTERNET SIMULATOR (PENGGANTI CLOUD - 100% OFFLINE CAPABLE)
# Membuat interface loopback dengan IP Google 8.8.8.8 agar ping dari seluruh klien selalu Reply
/interface bridge add name=loopback-internet comment="Simulator Server Internet Google"
/ip address add address=8.8.8.8/32 interface=loopback-internet comment="IP Target Ping Internet"

# 4. PENGALAMATAN IP BACKBONE DISTRIBUSI (KE CORE-SWITCH)
/ip address add address=10.10.10.1/24 interface=ether2-DISTRIBUSI comment="Gateway Backbone Distribusi Sekolah"

# (Opsional) IP Statis untuk WinBox jika ether1 dicolokkan ke Cloud1 (VirtualBox Host-Only):
/ip address add address=192.168.56.2/24 interface=ether1-WAN comment="IP Akses WinBox Laptop (Jika Menggunakan Cloud)"

# 5. DNS RESOLVER PUSAT
/ip dns set allow-remote-requests=yes servers=8.8.8.8,1.1.1.1

# 6. DHCP SERVER RUANG GURU & DISTRIBUSI (UNTUK 3 AP RUANG GURU & SELASAR)
/ip pool add name=pool-ruang-guru ranges=10.10.10.100-10.10.10.200 comment="Pool Laptop/HP Ruang Guru & Tamu"
/ip dhcp-server add address-pool=pool-ruang-guru disabled=no interface=ether2-DISTRIBUSI lease-time=12h name=dhcp-core
/ip dhcp-server network add address=10.10.10.0/24 dns-server=10.10.10.1,8.8.8.8 gateway=10.10.10.1 comment="Network Ruang Guru & Distribusi"

# 7. STATIC ROUTING LENGKAP KE SELURUH ROUTER CABANG (LAB CBT & 3 BENGKEL)
/ip route
add dst-address=192.168.20.0/24 gateway=10.10.10.2 comment="Rute ke Lab TJKT via R2-TKA"
add dst-address=192.168.21.0/24 gateway=10.10.10.2 comment="Rute ke Lab MP via R2-TKA"
add dst-address=192.168.22.0/24 gateway=10.10.10.2 comment="Rute ke Server Proktor via R2-TKA"
add dst-address=192.168.30.0/24 gateway=10.10.10.3 comment="Rute ke Bengkel TKJ via R3"
add dst-address=192.168.40.0/24 gateway=10.10.10.4 comment="Rute ke Bengkel TBSM via R4"
add dst-address=192.168.50.0/24 gateway=10.10.10.5 comment="Rute ke Bengkel MP via R5"

# 8. FIREWALL NAT
/ip firewall nat add chain=srcnat action=masquerade comment="NAT Masquerade Simulasi Pusat"

# 9. QUEUE TREE PUSAT (SIMULASI ALOKASI BANDWIDTH 95 Mbps FIBERNET)
/queue tree
add name=TOTAL-DOWNLOAD parent=global max-limit=95M comment="Total Pipa Bandwidth ISP"
add name=Q-JALUR-VIP-TKA parent=TOTAL-DOWNLOAD limit-at=75M max-limit=90M priority=1 dst=10.10.10.2 comment="Garansi 75 Mbps Jalur TKA"
add name=Q-RUANG-GURU     parent=TOTAL-DOWNLOAD limit-at=10M max-limit=30M priority=3 dst=10.10.10.0/24 comment="Ruang Guru & Distribusi AP"
add name=Q-BENGKEL        parent=TOTAL-DOWNLOAD limit-at=5M  max-limit=15M priority=5 dst=10.10.10.3,10.10.10.4,10.10.10.5 comment="Bengkel Jurusan (TKJ, TBSM, MP)"

# 10. BANDWIDTH TEST SERVER & RoMON (ALAT UJI SIMULASI)
# Memungkinkan uji tembak bandwidth dari router cabang untuk membuktikan Queue Tree bekerja
/tool bandwidth-server set enabled=yes authenticate=no
/tool romon set enabled=yes
