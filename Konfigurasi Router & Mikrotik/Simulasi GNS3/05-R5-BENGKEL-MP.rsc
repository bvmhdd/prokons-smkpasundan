# ==============================================================================
# KONFIGURASI SIMULASI GNS3: R5-BENGKEL-MP
# Perangkat: MikroTik CHR (Cloud Hosted Router)
# Peran: Router Praktik & Lab Bengkel Jurusan Manajemen Perkantoran (MP)
# ==============================================================================

# 1. IDENTITAS ROUTER
/system identity set name="R5-BENGKEL-MP"

# 2. PENAMAAN INTERFACE
/interface ethernet
set [ find default-name=ether1 ] name=ether1-UPLINK comment="Ke Core-Switch (Port 5)"
set [ find default-name=ether2 ] name=ether2-LAN-MP comment="Ke Switch Bengkel MP"

# 3. PENGALAMATAN IP
/ip address
add address=10.10.10.5/24 interface=ether1-UPLINK comment="IP Uplink ke Core"
add address=192.168.50.1/24 interface=ether2-LAN-MP comment="Gateway PC Bengkel MP"

# 4. DEFAULT ROUTE KE CORE ROUTER
/ip route add dst-address=0.0.0.0/0 gateway=10.10.10.1 comment="Gateway ke R1-CORE-ROUTER"

# 5. DNS RESOLVER
/ip dns set allow-remote-requests=yes servers=10.10.10.1,8.8.8.8

# 6. DHCP SERVER BENGKEL MP
/ip pool add name=pool-mp-bengkel ranges=192.168.50.10-192.168.50.50
/ip dhcp-server add address-pool=pool-mp-bengkel disabled=no interface=ether2-LAN-MP lease-time=1d name=dhcp-mp-bengkel
/ip dhcp-server network add address=192.168.50.0/24 dns-server=192.168.50.1,8.8.8.8 gateway=192.168.50.1

# 7. NAT MASQUERADE
/ip firewall nat add chain=srcnat out-interface=ether1-UPLINK action=masquerade comment="NAT Internet Bengkel MP"

# 8. LIMIT BANDWIDTH SEDERHANA
/queue simple add name="LIMIT-BENGKEL-MP" target=192.168.50.0/24 max-limit=10M/10M comment="Batas Total Bengkel MP 10 Mbps"

# 9. AKTIFKAN RoMON
/tool romon set enabled=yes
