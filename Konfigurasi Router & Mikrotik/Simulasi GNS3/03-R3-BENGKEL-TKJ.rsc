# ==============================================================================
# KONFIGURASI SIMULASI GNS3: R3-BENGKEL-TKJ
# Perangkat: MikroTik CHR (Cloud Hosted Router)
# Peran: Router Praktik & Lab Bengkel Jurusan TKJ
# ==============================================================================

# 1. IDENTITAS ROUTER
/system identity set name="R3-BENGKEL-TKJ"

# 2. PENAMAAN INTERFACE
/interface ethernet
set [ find default-name=ether1 ] name=ether1-UPLINK comment="Ke Core-Switch (Port 3)"
set [ find default-name=ether2 ] name=ether2-LAN-BENGKEL comment="Ke Switch Bengkel TKJ"

# 3. PENGALAMATAN IP
/ip address
add address=10.10.10.3/24 interface=ether1-UPLINK comment="IP Uplink ke Core"
add address=192.168.30.1/24 interface=ether2-LAN-BENGKEL comment="Gateway PC Bengkel TKJ"

# 4. DEFAULT ROUTE KE CORE ROUTER
/ip route add dst-address=0.0.0.0/0 gateway=10.10.10.1 comment="Gateway ke R1-CORE-ROUTER"

# 5. DNS RESOLVER
/ip dns set allow-remote-requests=yes servers=10.10.10.1,8.8.8.8

# 6. DHCP SERVER BENGKEL TKJ
/ip pool add name=pool-tkj ranges=192.168.30.10-192.168.30.50
/ip dhcp-server add address-pool=pool-tkj disabled=no interface=ether2-LAN-BENGKEL lease-time=1d name=dhcp-tkj
/ip dhcp-server network add address=192.168.30.0/24 dns-server=192.168.30.1,8.8.8.8 gateway=192.168.30.1

# 7. NAT MASQUERADE (Opsional: jika pure routing dari Core aktif, rule ini bertindak sebagai fallback)
/ip firewall nat add chain=srcnat out-interface=ether1-UPLINK action=masquerade comment="NAT Internet Bengkel"

# 8. LIMIT BANDWIDTH SEDERHANA (Agar Praktik TKJ tidak memakan kuota berlebih)
/queue simple add name="LIMIT-BENGKEL-TKJ" target=192.168.30.0/24 max-limit=10M/10M comment="Batas Total Bengkel TKJ 10 Mbps"

# 9. AKTIFKAN RoMON
/tool romon set enabled=yes
