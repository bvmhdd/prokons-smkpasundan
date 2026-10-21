# ==============================================================================
# KONFIGURASI IMPLEMENTASI ASLI: R2-TKA-GATEWAY
# Perangkat: MikroTik hAP lite (RB941-2nD)
# Lokasi: Ruang Lab CBT / Server Ujian TKA
# Peran: Gateway Khusus 84 PC Peserta Ujian + Server Proktor
# ==============================================================================

# 1. IDENTITAS ROUTER
/system identity set name="R2-TKA-GATEWAY"

# 2. PENAMAAN INTERFACE FISIK (HAP LITE 4 PORT)
/interface ethernet
set [ find default-name=ether1 ] name=ether1-UPLINK comment="Kabel 9 VIP dari Gigabit Core Switch"
set [ find default-name=ether2 ] name=ether2-LAB-TJKT comment="Ke Switch Gigabit Lab TJKT (42 PC)"
set [ find default-name=ether3 ] name=ether3-LAB-MP comment="Ke Switch Gigabit Lab MP (40 PC)"
set [ find default-name=ether4 ] name=ether4-PROKTOR comment="Ke Switch Server Proktor & Monitoring CBT"

# 3. PENGALAMATAN IP & GATEWAY PUSAT
/ip address
add address=10.10.10.2/24 interface=ether1-UPLINK comment="IP Uplink Jalur VIP"
add address=192.168.20.1/24 interface=ether2-LAB-TJKT comment="Gateway Lab TJKT (42 PC)"
add address=192.168.21.1/24 interface=ether3-LAB-MP comment="Gateway Lab MP (40 PC)"
add address=192.168.22.1/24 interface=ether4-PROKTOR comment="Gateway Server Proktor"

/ip route add dst-address=0.0.0.0/0 gateway=10.10.10.1 comment="Default Route ke R1-CORE-ROUTER"
/ip dns set allow-remote-requests=yes cache-size=2048KiB servers=10.10.10.1,8.8.8.8

# 4. DHCP POOL & SERVER LAB TKA (LEASE TIME 3 HARI)
# Catatan: Lease-time 3 hari penting agar PC ujian tidak me-refresh IP di tengah sesi ujian
/ip pool
add name=pool-tjkt ranges=192.168.20.10-192.168.20.60 comment="Pool 51 IP untuk 42 PC TJKT"
add name=pool-mp ranges=192.168.21.10-192.168.21.60 comment="Pool 51 IP untuk 40 PC MP"
add name=pool-proktor ranges=192.168.22.10-192.168.22.20 comment="Pool 11 IP untuk Proktor"

/ip dhcp-server
add address-pool=pool-tjkt disabled=no interface=ether2-LAB-TJKT lease-time=3d name=dhcp-tjkt
add address-pool=pool-mp disabled=no interface=ether3-LAB-MP lease-time=3d name=dhcp-mp
add address-pool=pool-proktor disabled=no interface=ether4-PROKTOR lease-time=3d name=dhcp-proktor

/ip dhcp-server network
add address=192.168.20.0/24 dns-server=192.168.20.1,8.8.8.8 gateway=192.168.20.1 comment="Network Lab TJKT"
add address=192.168.21.0/24 dns-server=192.168.21.1,8.8.8.8 gateway=192.168.21.1 comment="Network Lab MP"
add address=192.168.22.0/24 dns-server=192.168.22.1,8.8.8.8 gateway=192.168.22.1 comment="Network Server Proktor"

# 5. LIGHTWEIGHT MANGLE (OPTIMALISASI KHUSUS CPU 650 MHz HAP LITE)
# Mematikan FastTrack agar Queue Tree aktif
/ip firewall filter disable [ find action=fasttrack-connection ]
/ip firewall filter add chain=forward action=accept comment="Bypass FastTrack" place-before=0

/ip firewall address-list
add address=192.168.20.0/24 list=LIST-TKA
add address=192.168.21.0/24 list=LIST-TKA
add address=192.168.22.0/24 list=LIST-PROKTOR

/ip firewall mangle
# 5.1 Connection Marking
add chain=forward src-address-list=LIST-PROKTOR action=mark-connection new-connection-mark=conn-proktor passthrough=yes comment="Mark Conn Proktor"
add chain=forward src-address-list=LIST-TKA action=mark-connection new-connection-mark=conn-tka passthrough=yes comment="Mark Conn TKA"

# 5.2 Packet Marking PROKTOR (Dipisah Download & Upload)
add chain=forward connection-mark=conn-proktor dst-address-list=LIST-PROKTOR action=mark-packet new-packet-mark=pkt-proktor-down passthrough=no comment="Proktor Download"
add chain=forward connection-mark=conn-proktor src-address-list=LIST-PROKTOR action=mark-packet new-packet-mark=pkt-proktor-up passthrough=no comment="Proktor Upload"

# 5.3 Packet Marking TKA SISWA (Dipisah Download & Upload)
add chain=forward connection-mark=conn-tka dst-address-list=LIST-TKA action=mark-packet new-packet-mark=pkt-tka-down passthrough=no comment="TKA Download"
add chain=forward connection-mark=conn-tka src-address-list=LIST-TKA action=mark-packet new-packet-mark=pkt-tka-up passthrough=no comment="TKA Upload"

# 6. QUEUE TYPES (PCQ FAIRNESS PER-PC SISWA)
/queue type
add name=pcq-tka-down kind=pcq pcq-classifier=dst-address pcq-rate=2M
add name=pcq-tka-up   kind=pcq pcq-classifier=src-address pcq-rate=1M

# 7. QUEUE TREE (ALOKASI JALUR VIP 80 Mbps)
/queue tree
# --- DOWNLOAD TREE (Total Pipa 80 Mbps) ---
add name=TOTAL-DOWNLOAD parent=global max-limit=80M
add name=Q-PROKTOR-DOWN parent=TOTAL-DOWNLOAD packet-mark=pkt-proktor-down limit-at=10M max-limit=75M priority=1 queue=default comment="Garansi Proktor Priority 1"
add name=Q-TKA-DOWN parent=TOTAL-DOWNLOAD packet-mark=pkt-tka-down limit-at=65M max-limit=75M priority=2 queue=pcq-tka-down comment="Fairness Siswa CBT"

# --- UPLOAD TREE (Total Pipa 40 Mbps) ---
add name=TOTAL-UPLOAD parent=global max-limit=40M
add name=Q-PROKTOR-UP parent=TOTAL-UPLOAD packet-mark=pkt-proktor-up limit-at=10M max-limit=35M priority=1 queue=default comment="Upload Proktor Priority 1"
add name=Q-TKA-UP parent=TOTAL-UPLOAD packet-mark=pkt-tka-up limit-at=30M max-limit=35M priority=2 queue=pcq-tka-up comment="Fairness Upload Siswa"

# 8. MANAGEMENT & RoMON
/tool romon set enabled=yes
