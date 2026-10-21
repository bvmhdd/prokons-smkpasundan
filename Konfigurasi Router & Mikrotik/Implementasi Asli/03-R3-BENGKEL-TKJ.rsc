# ==============================================================================
# KONFIGURASI IMPLEMENTASI ASLI: R3-BENGKEL-TKJ
# Perangkat: MikroTik hAP lite (RB941-2nD)
# Lokasi: Lab / Bengkel Teknik Jaringan Komputer & Telekomunikasi (TKJ)
# ==============================================================================

# 1. IDENTITAS ROUTER
/system identity set name="R3-BENGKEL-TKJ"

# 2. PENAMAAN INTERFACE FISIK
/interface ethernet
set [ find default-name=ether1 ] name=ether1-UPLINK comment="Dari Gigabit Core Switch (Port 4)"
set [ find default-name=ether2 ] name=ether2-LAN-BENGKEL comment="Ke Switch Bengkel TKJ (PC Praktik)"
set [ find default-name=ether3 ] name=ether3-AP-GURU comment="Ke Access Point Ruang Guru TKJ"
set [ find default-name=ether4 ] name=ether4-CADANGAN comment="Cadangan / Teknisi"

# 3. PENGALAMATAN IP
/ip address
add address=10.10.10.3/24 interface=ether1-UPLINK comment="IP Uplink ke R1-CORE"
add address=192.168.30.1/24 interface=ether2-LAN-BENGKEL comment="Gateway PC Praktik TKJ"

# 4. DEFAULT ROUTE KE CORE ROUTER
/ip route add dst-address=0.0.0.0/0 gateway=10.10.10.1 comment="Gateway ke R1-CORE-ROUTER"

# 5. DNS RESOLVER
/ip dns set allow-remote-requests=yes cache-size=2048KiB servers=10.10.10.1,8.8.8.8

# 6. DHCP SERVER BENGKEL TKJ
/ip pool add name=pool-tkj ranges=192.168.30.10-192.168.30.50 comment="Pool PC Siswa TKJ"
/ip dhcp-server add address-pool=pool-tkj disabled=no interface=ether2-LAN-BENGKEL lease-time=1d name=dhcp-tkj
/ip dhcp-server network add address=192.168.30.0/24 dns-server=192.168.30.1,8.8.8.8 gateway=192.168.30.1

# 7. NAT MASQUERADE
/ip firewall nat add chain=srcnat out-interface=ether1-UPLINK action=masquerade comment="NAT Internet Bengkel TKJ"

# 8. LIMIT BANDWIDTH SEDERHANA (Maksimal 15 Mbps untuk Bengkel TKJ)
/queue simple add name="LIMIT-BENGKEL-TKJ" target=192.168.30.0/24 max-limit=15M/15M comment="Batas Total Bengkel TKJ 15 Mbps"

# 9. MANAGEMENT & RoMON
/tool romon set enabled=yes
