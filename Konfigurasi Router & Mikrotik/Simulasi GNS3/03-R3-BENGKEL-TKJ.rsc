# ==============================================================================
# KONFIGURASI SIMULASI GNS3: R3-BENGKEL-TKJ
# Perangkat: MikroTik CHR (Cloud Hosted Router)
# Peran: Router Praktik & Lab Bengkel Jurusan TKJ (25 PC)
# Fitur: Dual-Mode Switcher (1: Mode Ujian TKA, 2: Mode Harian Biasa)
# ==============================================================================

# 1. IDENTITAS ROUTER
/system identity set name="R3-BENGKEL-TKJ"

# 2. PENAMAAN INTERFACE
/interface ethernet
set [ find default-name=ether1 ] name=ether1-UPLINK comment="Ke Core-Switch (Port 3)"
set [ find default-name=ether2 ] name=ether2-LAN-BENGKEL comment="Ke Switch Bengkel TKJ (25 PC)"
set [ find default-name=ether3 ] name=ether3-AP-GURU comment="Ke AP Guru TKJ"
set [ find default-name=ether4 ] name=ether4-CADANGAN comment="Cadangan / Teknisi"

/interface bridge add name=bridge comment="Bridge LAN Bengkel TKJ" disabled=no
/interface bridge port
remove [ find interface=ether1-UPLINK ]
add bridge=bridge interface=ether2-LAN-BENGKEL
add bridge=bridge interface=ether3-AP-GURU
add bridge=bridge interface=ether4-CADANGAN

# 3. PENGALAMATAN IP
/ip address
add address=10.10.10.3/24 interface=ether1-UPLINK comment="IP Uplink ke Core"
add address=192.168.30.1/24 interface=bridge comment="Gateway PC Bengkel TKJ"

# 4. DEFAULT ROUTE KE CORE ROUTER & DNS
/ip route add dst-address=0.0.0.0/0 gateway=10.10.10.1 comment="Gateway ke R1-CORE-ROUTER"
/ip dns set allow-remote-requests=yes servers=10.10.10.1,8.8.8.8

# 5. DHCP SERVER BENGKEL TKJ (ALOKASI TEPAT 25 PC SISWA)
# - 192.168.30.2 - .9   : Static IP (Guru / Server Praktik)
# - 192.168.30.10 - .34 : Pool Otomatis 25 PC Siswa
/ip pool add name=pool-tkj ranges=192.168.30.10-192.168.30.34 comment="Pool Presisi 25 PC"
/ip dhcp-server add address-pool=pool-tkj disabled=no interface=bridge lease-time=1d name=dhcp-tkj
/ip dhcp-server network add address=192.168.30.0/24 dns-server=192.168.30.1,8.8.8.8 gateway=192.168.30.1 comment="Network Bengkel TKJ"

# 6. NAT MASQUERADE
/ip firewall nat add chain=srcnat out-interface=ether1-UPLINK action=masquerade comment="NAT Internet Bengkel"

# 7. QUEUE TYPE (PCQ FAIRNESS UNTUK 25 PC)
/queue type
add name=pcq-tkj-down kind=pcq pcq-classifier=dst-address pcq-rate=2M
add name=pcq-tkj-up   kind=pcq pcq-classifier=src-address pcq-rate=1M

# 8. MANAJEMEN BANDWIDTH DEFAULT (MODE 2 - HARIAN BIASA)
/queue simple add name="Q-BENGKEL-TKJ" target=192.168.30.0/24 max-limit=25M/25M queue=pcq-tkj-up/pcq-tkj-down comment="Mode Harian 25 Mbps"

# 9. DUAL-MODE SWITCHER
/system script add name="1-MODE-TKA-AKTIF" comment="Mode TKA (Hemat 5 Mbps)" source={
  /queue simple set [find name="Q-BENGKEL-TKJ"] max-limit=5M/5M
  :log warning ">>> [R3-BENGKEL-TKJ] MODE TKA AKTIF: Bandwidth dibatasi 5 Mbps <<<"
}
/system script add name="2-MODE-HARIAN-AKTIF" comment="Mode Harian (Normal 25 Mbps)" source={
  /queue simple set [find name="Q-BENGKEL-TKJ"] max-limit=25M/25M
  :log info ">>> [R3-BENGKEL-TKJ] MODE HARIAN AKTIF: Bandwidth dibuka 25 Mbps <<<"
}

# 10. AKTIFKAN RoMON
/tool romon set enabled=yes
