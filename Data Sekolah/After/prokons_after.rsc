# nov/03/2026 05:09:30 by RouterOS 6.49.13
# software id = 3DVR-7VK6
#
# model = RB941-2nD
# serial number = HG709Y1J9A1
/interface wireless
set [ find default-name=wlan1 ] ssid=MikroTik
/interface ethernet
set [ find default-name=ether1 ] comment="Kabel dari Router ISP (Port 2)" \
    name=ether1-WAN
set [ find default-name=ether2 ] comment=\
    "Ke Gigabit Core Switch (Port 23 - Uplink Backbone)" name=\
    ether2-DISTRIBUSI
set [ find default-name=ether3 ] comment=\
    "Port Khusus Teknisi / Winbox Darurat" name=ether3-MANAGEMENT
set [ find default-name=ether4 ] comment="Port Cadangan / Link Eksternal" \
    name=ether4-CADANGAN
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/ip pool
add comment="Pool Laptop/HP Ruang Guru & Tamu" name=pool-ruang-guru ranges=\
    10.10.10.100-10.10.10.200
/ip dhcp-server
add address-pool=pool-ruang-guru disabled=no interface=ether2-DISTRIBUSI \
    lease-time=2h name=dhcp-ruang-guru
/queue simple
add comment="Jalur Prioritas Ujian CBT (VIP CIR 75M)" limit-at=75M/75M \
    max-limit=90M/90M name=Q-JALUR-VIP-TKA priority=1/1 target=10.10.10.2/32
add comment="Limit Bengkel TBSM (Port 5 Switch) Maks 2 Mbps" max-limit=2M/2M \
    name=Q-TBSM-PORT5 target=10.10.10.4/32
add comment="Ruang Guru & AP Sekolah" limit-at=10M/10M max-limit=30M/30M \
    name=Q-RUANG-GURU priority=3/3 target=10.10.10.0/24
add comment="Bengkel Praktik" limit-at=5M/5M max-limit=15M/15M name=Q-BENGKEL \
    priority=5/5 target=10.10.10.3/32,10.10.10.4/32,10.10.10.5/32
/queue tree
add comment="Pipa Bersih ISP Fibernet" max-limit=95M name=TOTAL-DOWNLOAD \
    parent=global
/ip address
add address=10.10.10.1/24 comment="Gateway Backbone Distribusi Sekolah" \
    interface=ether2-DISTRIBUSI network=10.10.10.0
add address=192.168.88.1/24 comment="IP Akses Langsung Teknisi" interface=\
    ether3-MANAGEMENT network=192.168.88.0
/ip dhcp-client
add comment="DHCP dari ISP" disabled=no interface=ether1-WAN
/ip dhcp-server network
add address=10.10.10.0/24 comment="Network Ruang Guru & Distribusi AP" \
    dns-server=10.10.10.1,8.8.8.8 gateway=10.10.10.1
/ip dns
set allow-remote-requests=yes servers=8.8.8.8,1.1.1.1
/ip firewall filter
add action=accept chain=forward comment="Bypass FastTrack untuk Queue QoS"
/ip firewall nat
add action=masquerade chain=srcnat comment="NAT Masquerade Utama Sekolah" \
    out-interface=ether1-WAN
/ip route
add comment="Rute ke Lab TJKT via R2-TKA" distance=1 dst-address=\
    192.168.20.0/24 gateway=10.10.10.2
add comment="Rute ke Lab MP via R2-TKA" distance=1 dst-address=\
    192.168.21.0/24 gateway=10.10.10.2
add comment="Rute ke Server Proktor via R2-TKA" distance=1 dst-address=\
    192.168.22.0/24 gateway=10.10.10.2
add comment="Rute ke Bengkel TKJ via R3" distance=1 dst-address=\
    192.168.30.0/24 gateway=10.10.10.3
add comment="Rute ke Bengkel TBSM via R4" distance=1 dst-address=\
    192.168.40.0/24 gateway=10.10.10.4
add comment="Rute ke Bengkel MP via R5 (Jika Ada)" distance=1 dst-address=\
    192.168.50.0/24 gateway=10.10.10.5
/ip service
set telnet disabled=yes
set ftp disabled=yes
/system clock
set time-zone-name=Europe/London
/system identity
set name=R1-CORE-ROUTER
/tool romon
set enabled=yes
