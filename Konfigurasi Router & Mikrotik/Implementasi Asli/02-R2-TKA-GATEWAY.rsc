# ==============================================================================
# KONFIGURASI IMPLEMENTASI ASLI: R2-TKA-GATEWAY
# Perangkat: MikroTik hAP lite (RB941-2nD)
# Lokasi: Ruang Lab CBT / Server Ujian TKA & Lab MP
# Peran: Gateway Khusus PC Ujian CBT & Server Proktor
# Jalur Downstream:
#   - ether1 -> Uplink dari Switch Utama Ruang Guru (Port 9 Switch - IP 10.10.10.2)
#   - ether2 -> Switch Lab (Cascading ke Switch kedua & PC Siswa)
#   - ether3 -> Cadangan / Sambungan Langsung Server Proktor
#   - ether4 -> Cadangan / Port Maintenance Laptop Teknisi
# ==============================================================================

# 1. IDENTITAS ROUTER
/system identity set name="R2-TKA-GATEWAY"

# 2. PENAMAAN INTERFACE FISIK (HAP LITE RB941-2nD)
/interface ethernet
set [ find default-name=ether1 ] name=ether1-UPLINK comment="Dari Gigabit Core Switch (Port 9 - Jalur VIP)"
set [ find default-name=ether2 ] name=ether2-LAN-LAB comment="Ke Switch Lab Ujian (Cascading ke Switch 2)"
set [ find default-name=ether3 ] name=ether3-PROKTOR comment="Cadangan / Jalur Langsung Proktor"
set [ find default-name=ether4 ] name=ether4-CADANGAN comment="Cadangan / Teknisi"

# 3. BRIDGE LAN LAB UJIAN (HARDWARE OFFLOADED VIA SWITCH CHIP ATHEROS 8227)
# Menggabungkan ether2, ether3, dan ether4 dalam 1 Bridge ber-RSTP (Cegah Loop)
/interface bridge add name=bridge-LAN comment="Bridge LAN Lab Ujian & Proktor" protocol-mode=rstp disabled=no
/interface bridge port
remove [ find interface=ether1-UPLINK ]
remove [ find interface=ether2-LAN-LAB ]
remove [ find interface=ether3-PROKTOR ]
remove [ find interface=ether4-CADANGAN ]
add bridge=bridge-LAN interface=ether2-LAN-LAB comment="Jalur Switch Lab Siswa"
add bridge=bridge-LAN interface=ether3-PROKTOR comment="Jalur Proktor"
add bridge=bridge-LAN interface=ether4-CADANGAN comment="Maintenance Teknisi"

# 4. PENGALAMATAN IP
/ip address
add address=10.10.10.2/24 interface=ether1-UPLINK comment="IP Uplink Jalur VIP ke R1-CORE-ROUTER (Port 9 Switch)"
add address=192.168.20.1/24 interface=bridge-LAN comment="Gateway Lab Ujian CBT & Proktor"

# 5. DEFAULT ROUTE KE CORE ROUTER & DNS
/ip route add dst-address=0.0.0.0/0 gateway=10.10.10.1 comment="Gateway ke R1-CORE-ROUTER"
/ip dns set allow-remote-requests=yes cache-size=2048KiB servers=10.10.10.1,8.8.8.8

# 6. DHCP SERVER LAB UJIAN CBT (KAPASITAS LEGA 191 IP, LEASE TIME 3 HARI)
# Skema Alokasi IP pada Subnet 192.168.20.0/24:
# - 192.168.20.1         : Gateway Router R2-TKA
# - 192.168.20.2 - .9    : Khusus IP Statis (Server Proktor Lokal & PC Pengawas)
# - 192.168.20.10 - .200 : Pool Otomatis untuk Seluruh PC Siswa Ujian CBT (191 IP)
# - Lease-time 3 hari (3d) mencegah PC ujian melakukan renewal/refresh IP di tengah ujian
/ip pool add name=pool-tka ranges=192.168.20.10-192.168.20.200 comment="Pool Presisi PC Siswa Ujian CBT"
/ip dhcp-server add address-pool=pool-tka disabled=no interface=bridge-LAN lease-time=3d name=dhcp-tka
/ip dhcp-server network add address=192.168.20.0/24 dns-server=192.168.20.1,8.8.8.8 gateway=192.168.20.1 comment="Network Lab Ujian CBT"

# 7. NAT MASQUERADE
/ip firewall nat add chain=srcnat out-interface=ether1-UPLINK action=masquerade comment="NAT Internet Lab Ujian CBT"

# Pastikan FastTrack tidak mem-bypass antrean Bandwidth Queue
/ip firewall filter disable [ find action=fasttrack-connection ]

# 8. MANAJEMEN BANDWIDTH (JALUR VVIP UJIAN CBT 75 Mbps)
# Dialokasikan penuh hingga 75 Mbps tanpa membatasi ketat per-PC agar ujian lancar & cepat
/queue simple add name="Q-LAB-CBT-VIP" target=192.168.20.0/24 max-limit=75M/75M comment="Pipa VIP Ujian CBT (Maks 75 Mbps)"

# 9. MANAGEMENT & RoMON
/tool romon set enabled=yes
