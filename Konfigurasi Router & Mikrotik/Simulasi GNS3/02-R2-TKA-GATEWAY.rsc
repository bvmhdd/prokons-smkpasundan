# ==============================================================================
# KONFIGURASI SIMULASI GNS3: R2-TKA-GATEWAY
# Perangkat: MikroTik CHR (Cloud Hosted Router)
# Peran: Router Khusus Lab CBT Ujian TKA (84 PC + Proktor)
# ==============================================================================

# 1. IDENTITAS ROUTER
/system identity set name="R2-TKA-GATEWAY"

# 2. PENAMAAN INTERFACE
/interface ethernet
set [ find default-name=ether1 ] name=ether1-UPLINK comment="Dari Core Switch (Kabel 9 VIP)"
set [ find default-name=ether2 ] name=ether2-LAB-TJKT comment="Ke Switch Lab TJKT (42 PC)"
set [ find default-name=ether3 ] name=ether3-LAB-MP comment="Ke Switch Lab MP (40 PC)"
set [ find default-name=ether4 ] name=ether4-PROKTOR comment="Ke Server & PC Proktor"

# 3. IP ADDRESS & DEFAULT GATEWAY KE CORE
/ip address
add address=10.10.10.2/24 interface=ether1-UPLINK comment="IP Uplink R2"
add address=192.168.20.1/24 interface=ether2-LAB-TJKT comment="Gateway Lab TJKT"
add address=192.168.21.1/24 interface=ether3-LAB-MP comment="Gateway Lab MP"
add address=192.168.22.1/24 interface=ether4-PROKTOR comment="Gateway Proktor"

/ip route add dst-address=0.0.0.0/0 gateway=10.10.10.1 comment="Default Route ke Core Router"
/ip dns set allow-remote-requests=yes servers=10.10.10.1,8.8.8.8

# 4. DHCP POOL & SERVER LAB TKA
/ip pool
add name=pool-tjkt ranges=192.168.20.10-192.168.20.60
add name=pool-mp ranges=192.168.21.10-192.168.21.60
add name=pool-proktor ranges=192.168.22.10-192.168.22.20

/ip dhcp-server
add address-pool=pool-tjkt disabled=no interface=ether2-LAB-TJKT lease-time=3d name=dhcp-tjkt
add address-pool=pool-mp disabled=no interface=ether3-LAB-MP lease-time=3d name=dhcp-mp
add address-pool=pool-proktor disabled=no interface=ether4-PROKTOR lease-time=3d name=dhcp-proktor

/ip dhcp-server network
add address=192.168.20.0/24 dns-server=192.168.20.1,8.8.8.8 gateway=192.168.20.1
add address=192.168.21.0/24 dns-server=192.168.21.1,8.8.8.8 gateway=192.168.21.1
add address=192.168.22.0/24 dns-server=192.168.22.1,8.8.8.8 gateway=192.168.22.1

# 5. MANGLE & PCQ FAIRNESS LAB TKA
/ip firewall address-list
add address=192.168.20.0/24 list=LIST-TKA
add address=192.168.21.0/24 list=LIST-TKA
add address=192.168.22.0/24 list=LIST-PROKTOR

/ip firewall mangle
# 5.1 Marking Connection
add chain=forward src-address-list=LIST-PROKTOR action=mark-connection new-connection-mark=conn-proktor passthrough=yes comment="Mark Conn Proktor"
add chain=forward src-address-list=LIST-TKA action=mark-connection new-connection-mark=conn-tka passthrough=yes comment="Mark Conn TKA"

# 5.2 Marking Packet PROKTOR (Dipisah Download & Upload)
add chain=forward connection-mark=conn-proktor dst-address-list=LIST-PROKTOR action=mark-packet new-packet-mark=pkt-proktor-down passthrough=no comment="Proktor Download"
add chain=forward connection-mark=conn-proktor src-address-list=LIST-PROKTOR action=mark-packet new-packet-mark=pkt-proktor-up passthrough=no comment="Proktor Upload"

# 5.3 Marking Packet TKA (Download & Upload)
add chain=forward connection-mark=conn-tka dst-address-list=LIST-TKA action=mark-packet new-packet-mark=pkt-tka-down passthrough=no comment="TKA Download"
add chain=forward connection-mark=conn-tka src-address-list=LIST-TKA action=mark-packet new-packet-mark=pkt-tka-up passthrough=no comment="TKA Upload"

# 6. QUEUE TYPES (PCQ FAIR SHARE)
/queue type
add name=pcq-tka-down kind=pcq pcq-classifier=dst-address pcq-rate=2M
add name=pcq-tka-up   kind=pcq pcq-classifier=src-address pcq-rate=1M

# 7. QUEUE TREE (MANAJEMEN BANDWIDTH DEDICATED)
/queue tree
# --- DOWNLOAD TREE (Total Alokasi 80 Mbps) ---
add name=TOTAL-DOWNLOAD parent=global max-limit=80M
add name=Q-PROKTOR-DOWN parent=TOTAL-DOWNLOAD packet-mark=pkt-proktor-down limit-at=10M max-limit=75M priority=1 queue=default comment="Garansi Proktor Priority 1"
add name=Q-TKA-DOWN parent=TOTAL-DOWNLOAD packet-mark=pkt-tka-down limit-at=65M max-limit=75M priority=2 queue=pcq-tka-down comment="Fairness Siswa CBT"

# --- UPLOAD TREE (Total Alokasi 40 Mbps) ---
add name=TOTAL-UPLOAD parent=global max-limit=40M
add name=Q-PROKTOR-UP parent=TOTAL-UPLOAD packet-mark=pkt-proktor-up limit-at=10M max-limit=35M priority=1 queue=default comment="Upload Proktor Priority 1"
add name=Q-TKA-UP parent=TOTAL-UPLOAD packet-mark=pkt-tka-up limit-at=30M max-limit=35M priority=2 queue=pcq-tka-up comment="Fairness Upload Siswa"

# 8. AKTIFKAN RoMON
/tool romon set enabled=yes
