# ==============================================================================
# KONFIGURASI IMPLEMENTASI ASLI: R4-BENGKEL-TBSM
# Perangkat: MikroTik hAP lite (RB941-2nD)
# Lokasi: Ruang Khusus Guru / Bengkel Teknik & Bisnis Sepeda Motor (TBSM)
# ==============================================================================

# 1. IDENTITAS ROUTER
/system identity set name="R4-BENGKEL-TBSM"

# 2. PENAMAAN INTERFACE FISIK
/interface ethernet
set [ find default-name=ether1 ] name=ether1-UPLINK comment="Dari Gigabit Core Switch (Port 5)"
set [ find default-name=ether2 ] name=ether2-LAN-TBSM comment="Ke Switch/PC Bengkel TBSM"
set [ find default-name=ether3 ] name=ether3-AP-GURU comment="Ke Access Point Ruang Guru TBSM"
set [ find default-name=ether4 ] name=ether4-CADANGAN comment="Cadangan / Teknisi"

# 3. PENGALAMATAN IP
/ip address
add address=10.10.10.4/24 interface=ether1-UPLINK comment="IP Uplink ke R1-CORE"
add address=192.168.40.1/24 interface=ether2-LAN-TBSM comment="Gateway Bengkel TBSM"

# 4. DEFAULT ROUTE KE CORE ROUTER
/ip route add dst-address=0.0.0.0/0 gateway=10.10.10.1 comment="Gateway ke R1-CORE-ROUTER"

# 5. DNS RESOLVER
/ip dns set allow-remote-requests=yes cache-size=2048KiB servers=10.10.10.1,8.8.8.8

# 6. DHCP SERVER BENGKEL TBSM
/ip pool add name=pool-tbsm ranges=192.168.40.10-192.168.40.50 comment="Pool PC TBSM"
/ip dhcp-server add address-pool=pool-tbsm disabled=no interface=ether2-LAN-TBSM lease-time=1d name=dhcp-tbsm
/ip dhcp-server network add address=192.168.40.0/24 dns-server=192.168.40.1,8.8.8.8 gateway=192.168.40.1

# 7. NAT MASQUERADE
/ip firewall nat add chain=srcnat out-interface=ether1-UPLINK action=masquerade comment="NAT Internet Bengkel TBSM"

# 8. LIMIT BANDWIDTH SEDERHANA (Maksimal 10 Mbps untuk Bengkel TBSM)
/queue simple add name="LIMIT-BENGKEL-TBSM" target=192.168.40.0/24 max-limit=10M/10M comment="Batas Total Bengkel TBSM 10 Mbps"

# 9. MANAGEMENT & RoMON
/tool romon set enabled=yes
