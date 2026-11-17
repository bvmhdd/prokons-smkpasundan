# ==============================================================================
# KONFIGURASI IMPLEMENTASI ASLI: R1-CORE-ROUTER
# Perangkat: MikroTik hAP lite (RB941-2nD) / Router Utama
# Lokasi: Ruang Server / Ruang Guru
# ISP: Fibernet 100 Mbps Dedicated
# ==============================================================================

# 1. IDENTITAS ROUTER
/system identity set name="R1-CORE-ROUTER"

# 2. PENAMAAN INTERFACE FISIK
/interface ethernet set [ find default-name=ether1 ] name=ether1-WAN comment="Kabel dari Router ISP (Port 2)"
/interface ethernet set [ find default-name=ether2 ] name=ether2-DISTRIBUSI comment="Ke Gigabit Core Switch (Port 23 - Uplink Backbone)"
/interface ethernet set [ find default-name=ether3 ] name=ether3-MANAGEMENT comment="Port Khusus Teknisi / Winbox Darurat"
/interface ethernet set [ find default-name=ether4 ] name=ether4-CADANGAN comment="Port Cadangan / Link Eksternal"

# Lepas port dari Bridge bawaan (karena DHCP Server & IP tidak bisa jalan di slave interface)
/interface bridge port remove [ find interface=ether2-DISTRIBUSI ]
/interface bridge port remove [ find interface=ether3-MANAGEMENT ]

# 3. PENGALAMATAN IP
# 3.1 WAN Internet (Pilih salah satu sesuai jenis koneksi dari ISP)
# Mode DHCP Client dari Modem ISP:
/ip dhcp-client add interface=ether1-WAN disabled=no add-default-route=yes use-peer-dns=yes comment="DHCP dari ISP"

# 3.2 LAN Backbone Distribusi
/ip address add address=10.10.10.1/24 interface=ether2-DISTRIBUSI comment="Gateway Backbone Distribusi Sekolah"
/ip address add address=192.168.88.1/24 interface=ether3-MANAGEMENT comment="IP Akses Langsung Teknisi"

# 4. PENGATURAN DNS RESOLVER & CACHE
/ip dns set allow-remote-requests=yes cache-size=2048KiB servers=8.8.8.8,1.1.1.1

# 5. DHCP SERVER BACKBONE (UNTUK AP RUANG GURU & SELASAR)
# Karena AP Tenda/TP-Link diset Bridge Mode (DHCP Off), maka R1 yang membagikan IP ke guru & siswa
/ip pool add name=pool-ruang-guru ranges=10.10.10.100-10.10.10.200 comment="Pool Laptop/HP Ruang Guru & Tamu"
/ip dhcp-server add address-pool=pool-ruang-guru disabled=no interface=ether2-DISTRIBUSI lease-time=2h name=dhcp-ruang-guru
/ip dhcp-server network add address=10.10.10.0/24 dns-server=10.10.10.1,8.8.8.8 gateway=10.10.10.1 comment="Network Ruang Guru & Distribusi AP"

# 6. FIREWALL & NAT MASQUERADE PUSAT
/ip firewall nat add chain=srcnat out-interface=ether1-WAN action=masquerade comment="NAT Masquerade Utama Sekolah"

# PENTING: Matikan FastTrack agar antrean Queue berfungsi normal membatasi bandwidth
/ip firewall filter add chain=forward action=accept comment="Bypass FastTrack untuk Queue QoS"

# 7. STATIC ROUTING KE SELURUH ROUTER CABANG (LAB CBT & BENGKEL)
/ip route add dst-address=192.168.20.0/24 gateway=10.10.10.2 comment="Rute ke Lab TKA / Lab MP & Proktor via R2"
/ip route add dst-address=192.168.30.0/24 gateway=10.10.10.3 comment="Rute ke Bengkel TKJ via R3"
/ip route add dst-address=192.168.40.0/24 gateway=10.10.10.4 comment="Rute ke Bengkel TBSM via R4"
/ip route add dst-address=192.168.50.0/24 gateway=10.10.10.5 comment="Rute ke Bengkel MP via R5 (Jika Ada)"

# 8. MANAJEMEN BANDWIDTH PUSAT (QoS DUAL-MODE)
/queue simple add name=Q-JALUR-VIP-TKA target=10.10.10.2/32 limit-at=75M/75M max-limit=90M/90M priority=1/1 comment="Jalur Prioritas Ujian CBT (VIP CIR 75M)"
/queue simple add name=Q-RUANG-GURU target=10.10.10.0/24 limit-at=10M/10M max-limit=30M/30M priority=3/3 comment="Ruang Guru & AP Sekolah"
/queue simple add name=Q-BENGKEL target=10.10.10.3/32,10.10.10.4/32,10.10.10.5/32 limit-at=5M/5M max-limit=15M/15M priority=5/5 comment="Bengkel Praktik (25 PC)"

# 9. DUAL-MODE SWITCHER PUSAT (1-KLIK DI WINBOX SYSTEM > SCRIPTS)
# Mode 1: Saat Ujian TKA Berlangsung (Kunci 75 Mbps untuk TKA, batasi Guru & Bengkel)
/system script add name="1-SET-MODE-TKA-PUSAT" comment="Aktifkan saat Ujian TKA Berlangsung" source={
  /queue simple set [find name="Q-JALUR-VIP-TKA"] limit-at=75M/75M max-limit=90M/90M priority=1/1 comment="Mode TKA: Garansi VVIP 75 Mbps"
  /queue simple set [find name="Q-RUANG-GURU"] limit-at=10M/10M max-limit=15M/15M priority=4/4 comment="Mode TKA: Dibatasi 15 Mbps"
  /queue simple set [find name="Q-BENGKEL"] limit-at=5M/5M max-limit=10M/10M priority=6/6 comment="Mode TKA: Dibatasi 10 Mbps"
  :log warning ">>> [CORE ROUTER] MODE UJIAN TKA AKTIF: 75 Mbps dikunci untuk Lab Ujian CBT! <<<"
}

# Mode 2: Hari-Hari Biasa (Bagi rata: Ruang Guru 50 Mbps, Bengkel 40 Mbps, Lab TKA 25 Mbps)
/system script add name="2-SET-MODE-HARIAN-PUSAT" comment="Aktifkan untuk Hari-Hari Biasa (Normal)" source={
  /queue simple set [find name="Q-RUANG-GURU"] limit-at=30M/30M max-limit=50M/50M priority=1/1 comment="Mode Harian: Prioritas Guru 50 Mbps"
  /queue simple set [find name="Q-BENGKEL"] limit-at=25M/25M max-limit=40M/40M priority=2/2 comment="Mode Harian: Praktik Bengkel 40 Mbps"
  /queue simple set [find name="Q-JALUR-VIP-TKA"] limit-at=15M/15M max-limit=25M/25M priority=3/3 comment="Mode Harian: Lab TKA/MP 25 Mbps"
  :log info ">>> [CORE ROUTER] MODE HARIAN BIASA AKTIF: Bandwidth dibagi merata ke seluruh sekolah! <<<"
}

# 10. MANAGEMENT & KEAMANAN
/tool romon set enabled=yes
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes
