# ==============================================================================
# KONFIGURASI IMPLEMENTASI ASLI: R3-BENGKEL-TKJ
# Perangkat: MikroTik hAP lite (RB941-2nD)
# Lokasi: Lab / Bengkel Teknik Jaringan Komputer & Telekomunikasi (TKJ)
# Jalur Downstream:
#   - ether2 -> Switch 1 Bengkel TKJ (Switch 2 & rantai Hub terhubung ke sini)
#   - ether3 -> Hub Ruang Kelas (R3 -> Hub -> PC/Perangkat Kelas)
#   - ether4 -> Cadangan / Port Maintenance Laptop Teknisi
# Fitur: Dual-Mode (Mode 1: Saat Ujian TKA Berlangsung, Mode 2: Hari-Hari Biasa)
# ==============================================================================

# 1. IDENTITAS ROUTER
/system identity set name="R3-BENGKEL-TKJ"

# 2. PENAMAAN INTERFACE FISIK (HAP LITE RB941-2nD)
# - ether1 : Uplink ke Gigabit Core Switch Ruang Guru (Port 4 Switch - IP 10.10.10.3)
# - ether2 : Ke Switch 1 Bengkel TKJ (Switch 2 menyambung ke Switch 1)
# - ether3 : Ke Hub Ruang Kelas (R3 -> Hub -> Kelas)
# - ether4 : Cadangan / Akses Maintenance Laptop Teknisi
/interface ethernet
set [ find default-name=ether1 ] name=ether1-UPLINK comment="Dari Gigabit Core Switch (Port 4)"
set [ find default-name=ether2 ] name=ether2-LAN-BENGKEL comment="Ke Switch 1 Bengkel (Cascading ke Switch 2)"
set [ find default-name=ether3 ] name=ether3-LAN-KELAS comment="Ke Hub Ruang Kelas"
set [ find default-name=ether4 ] name=ether4-CADANGAN comment="Cadangan / Teknisi"

# 3. BRIDGE LAN BENGKEL & KELAS (DILENGKAPI RSTP CEGAH LOOP)
# Menggabungkan ether2, ether3, dan ether4 dalam 1 Bridge ber-RSTP (Hardware Offload)
/interface bridge add name=bridge-LAN comment="Bridge LAN Bengkel TKJ & Kelas" protocol-mode=rstp disabled=no
/interface bridge port
remove [ find interface=ether1-UPLINK ]
remove [ find interface=ether2-LAN-BENGKEL ]
remove [ find interface=ether3-LAN-KELAS ]
remove [ find interface=ether4-CADANGAN ]
add bridge=bridge-LAN interface=ether2-LAN-BENGKEL comment="Jalur Switch Bengkel (Switch 1 & 2)"
add bridge=bridge-LAN interface=ether3-LAN-KELAS comment="Jalur ke Kelas via Hub"
add bridge=bridge-LAN interface=ether4-CADANGAN comment="Maintenance Teknisi"

# 4. PENGALAMATAN IP
/ip address
add address=10.10.10.3/24 interface=ether1-UPLINK comment="IP Uplink ke R1-CORE-ROUTER (Port 4 Switch)"
add address=192.168.30.1/24 interface=bridge-LAN comment="Gateway Bengkel & Kelas (192.168.30.1)"

# 5. DEFAULT ROUTE KE CORE ROUTER & DNS
/ip route add dst-address=0.0.0.0/0 gateway=10.10.10.1 comment="Gateway ke R1-CORE-ROUTER"
/ip dns set allow-remote-requests=yes cache-size=2048KiB servers=10.10.10.1,8.8.8.8

# 6. DHCP SERVER BENGKEL & KELAS (KAPASITAS LEGA 191 IP)
# Skema Alokasi IP pada Subnet 192.168.30.0/24:
# - 192.168.30.1         : Gateway Router R3
# - 192.168.30.2 - .9    : Alokasi IP Statis (PC Guru / Printer Lab / Server Praktik)
# - 192.168.30.10 - .200 : Pool Otomatis untuk PC Siswa di Bengkel & Kelas (191 IP)
/ip pool add name=pool-tkj ranges=192.168.30.10-192.168.30.200 comment="Pool PC Bengkel TKJ & Kelas"
/ip dhcp-server add address-pool=pool-tkj disabled=no interface=bridge-LAN lease-time=12h name=dhcp-tkj
/ip dhcp-server network add address=192.168.30.0/24 dns-server=192.168.30.1,8.8.8.8 gateway=192.168.30.1 comment="Network Bengkel & Kelas TKJ"

# 7. NAT MASQUERADE
/ip firewall nat add chain=srcnat out-interface=ether1-UPLINK action=masquerade comment="NAT Internet Bengkel & Kelas"

# Pastikan FastTrack tidak mem-bypass antrean Bandwidth Queue
/ip firewall filter disable [ find action=fasttrack-connection ]

# 8. QUEUE TYPE (PCQ FAIRNESS PER-PC MAKS 2 MBPS)
# Mencegah 1 PC (baik di bengkel maupun di kelas) memonopoli bandwidth
/queue type
add name=pcq-tkj-down kind=pcq pcq-classifier=dst-address pcq-rate=2M
add name=pcq-tkj-up   kind=pcq pcq-classifier=src-address pcq-rate=1M

# 9. MANAJEMEN BANDWIDTH (NO LIMIT / UNLIMITED)
# Antrean dinonaktifkan agar kecepatan tidak dibatasi (Full Speed)
/queue simple disable [find name="Q-BENGKEL-TKJ"]

# 10. DUAL-MODE SWITCHER (1-KLIK VIA WINBOX SYSTEM > SCRIPTS)
# Menu System > Scripts > pilih script lalu klik "Run Script"

# Mode 1: Saat Ujian TKA Berlangsung (Dibatasi ketat 5 Mbps agar amankan ujian di Lab TKA)
/system script add name="1-MODE-TKA-AKTIF" comment="Aktifkan saat Ujian TKA berlangsung (Hemat Bandwidth)" source={
  /queue simple set [find name="Q-BENGKEL-TKJ"] max-limit=5M/5M comment="Mode TKA: Dibatasi 5 Mbps untuk amankan ujian CBT"
  :log warning ">>> [R3-BENGKEL-TKJ] MODE TKA AKTIF: Bandwidth dibatasi 5 Mbps agar jalur ujian TKA aman! <<<"
}

# Mode 2: Hari-Hari Biasa (Dibuka 25 Mbps dengan PCQ Fairness untuk PC siswa & kelas)
/system script add name="2-MODE-HARIAN-AKTIF" comment="Aktifkan untuk hari-hari biasa (Operasional Normal)" source={
  /queue simple set [find name="Q-BENGKEL-TKJ"] max-limit=25M/25M comment="Mode Harian: Alokasi Lega 25 Mbps (PCQ Fairness)"
  :log info ">>> [R3-BENGKEL-TKJ] MODE HARIAN AKTIF: Bandwidth normal 25 Mbps dibuka untuk PC siswa & kelas! <<<"
}

# 11. MANAGEMENT & RoMON
/tool romon set enabled=yes
