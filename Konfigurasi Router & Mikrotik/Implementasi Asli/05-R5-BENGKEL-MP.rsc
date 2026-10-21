# ==============================================================================
# KONFIGURASI IMPLEMENTASI ASLI: R5-BENGKEL-MP
# Perangkat: MikroTik hAP lite (RB941-2nD)
# Lokasi: Ruang Lab / Bengkel Manajemen Perkantoran (MP)
# Jalur: Kabel 6 dari Gigabit Core Switch (Penambahan Baru)
# ==============================================================================

# 1. IDENTITAS ROUTER
/system identity set name="R5-BENGKEL-MP"

# 2. PENAMAAN INTERFACE FISIK (HAP LITE 4 PORT)
/interface ethernet
set [ find default-name=ether1 ] name=ether1-UPLINK comment="Dari Gigabit Core Switch (Kabel 6)"
set [ find default-name=ether2 ] name=ether2-LAN-MP comment="Ke Switch Bengkel MP (PC Praktik)"
set [ find default-name=ether3 ] name=ether3-AP-GURU comment="Ke Access Point Ruang Guru MP"
set [ find default-name=ether4 ] name=ether4-CADANGAN comment="Port Cadangan / Teknisi"

# 3. PENGALAMATAN IP
/ip address
add address=10.10.10.5/24 interface=ether1-UPLINK comment="IP Uplink ke R1-CORE"
add address=192.168.50.1/24 interface=ether2-LAN-MP comment="Gateway PC Praktik MP"

# 4. DEFAULT ROUTE KE CORE ROUTER
/ip route add dst-address=0.0.0.0/0 gateway=10.10.10.1 comment="Gateway ke R1-CORE-ROUTER"

# 5. DNS RESOLVER
/ip dns set allow-remote-requests=yes cache-size=2048KiB servers=10.10.10.1,8.8.8.8

# 6. DHCP SERVER BENGKEL MP
/ip pool add name=pool-mp-bengkel ranges=192.168.50.10-192.168.50.50 comment="Pool PC Siswa MP"
/ip dhcp-server add address-pool=pool-mp-bengkel disabled=no interface=ether2-LAN-MP lease-time=1d name=dhcp-mp-bengkel
/ip dhcp-server network add address=192.168.50.0/24 dns-server=192.168.50.1,8.8.8.8 gateway=192.168.50.1

# 7. NAT MASQUERADE
/ip firewall nat add chain=srcnat out-interface=ether1-UPLINK action=masquerade comment="NAT Internet Bengkel MP"

# 8. LIMIT BANDWIDTH SEDERHANA (Maksimal 15 Mbps untuk Bengkel MP)
/queue simple add name="LIMIT-BENGKEL-MP" target=192.168.50.0/24 max-limit=15M/15M comment="Batas Total Bengkel MP 15 Mbps"

# 9. MANAGEMENT & RoMON
/tool romon set enabled=yes
