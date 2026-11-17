# ==============================================================================
# KONFIGURASI SIMULASI GNS3: R2-TKA-GATEWAY
# Perangkat: MikroTik CHR (Cloud Hosted Router)
# Peran: Router Khusus Lab CBT Ujian TKA / Lab MP (84 PC + Proktor)
# ==============================================================================

# 1. IDENTITAS ROUTER
/system identity set name="R2-TKA-GATEWAY"

# 2. PENAMAAN INTERFACE
# R2: ether1 untuk Uplink (routing), ether2 s.d. ether4 masuk ke Bridge LAN
/interface ethernet
set [ find default-name=ether1 ] name=ether1-UPLINK comment="Dari Core Switch (Kabel VIP)"
set [ find default-name=ether2 ] name=ether2-LAN-LAB comment="Ke Switch Lab TKA / Lab MP (84 PC Siswa & Proktor)"
set [ find default-name=ether3 ] name=ether3-CADANGAN comment="Port Cadangan / Opsional Proktor"
set [ find default-name=ether4 ] name=ether4-CADANGAN comment="Port Cadangan / Maintenance"

/interface bridge add name=bridge comment="Bridge LAN Lab TKA/MP" disabled=no
/interface bridge port
remove [ find interface=ether1-UPLINK ]
add bridge=bridge interface=ether2-LAN-LAB
add bridge=bridge interface=ether3-CADANGAN
add bridge=bridge interface=ether4-CADANGAN

# Bersihkan sisa DHCP Client & IP Default bawaan pabrik (88.x)
/ip dhcp-client remove [find interface=ether1-UPLINK]
/ip dhcp-server remove [find name="defconf"]
/ip dhcp-server network remove [find address="192.168.88.0/24"]
/ip pool remove [find name="default-dhcp"]
/ip address remove [find address="192.168.88.1/24"]
/ip address remove [find interface="ether2-LAN-LAB"]

# 3. PENGALAMATAN IP & DEFAULT GATEWAY KE CORE
/ip address
add address=10.10.10.2/24 interface=ether1-UPLINK comment="IP Uplink R2"
add address=192.168.20.1/24 interface=bridge comment="Gateway Tunggal Lab TKA / Lab MP (84 PC & Proktor)"

/ip route remove [find static=yes dst-address="0.0.0.0/0"]
/ip route add dst-address=0.0.0.0/0 gateway=10.10.10.1 comment="Default Route ke Core Router"
/ip dns set allow-remote-requests=yes servers=10.10.10.1,8.8.8.8

# NAT Masquerade ke Core Router
/ip firewall nat add chain=srcnat out-interface=ether1-UPLINK action=masquerade comment="NAT Internet Lab TKA ke Core"

# 4. DHCP POOL & SERVER LAB TKA / LAB MP
# - 192.168.20.2 - .9    : Server Proktor & Laptop Pengawas (IP Statis)
# - 192.168.20.10 - .100 : Pool Otomatis untuk 84 PC Siswa Ujian CBT
/ip pool
add name=pool-tka ranges=192.168.20.10-192.168.20.100 comment="Pool 91 IP untuk 84 PC Siswa TKA/MP"

/ip dhcp-server
add address-pool=pool-tka disabled=no interface=bridge lease-time=3d name=dhcp-tka

/ip dhcp-server network
add address=192.168.20.0/24 dns-server=192.168.20.1,8.8.8.8 gateway=192.168.20.1 comment="Network Lab TKA / Lab MP & Proktor"

# 5. MANGLE & PCQ FAIRNESS LAB TKA
/ip firewall address-list
add address=192.168.20.2-192.168.20.9 list=LIST-PROKTOR comment="IP Server CBT & PC Proktor (Priority 1)"
add address=192.168.20.10-192.168.20.100 list=LIST-TKA comment="84 PC Siswa Ujian CBT (Priority 2)"

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
