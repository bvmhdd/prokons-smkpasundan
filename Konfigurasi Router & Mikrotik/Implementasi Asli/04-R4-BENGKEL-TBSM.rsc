# ==============================================================================
# KONFIGURASI IMPLEMENTASI ASLI: R4-BENGKEL-TBSM
# Perangkat: MikroTik hAP lite (RB941-2nD)
# Lokasi: Ruang Khusus Guru / Bengkel Teknik & Bisnis Sepeda Motor (TBSM)
# Fitur: Dual-Mode (Mode 1: Saat Ujian TKA Berlangsung, Mode 2: Hari-Hari Biasa)
# ==============================================================================

# 1. IDENTITAS ROUTER
/system identity set name="R4-BENGKEL-TBSM"

# 2. PENAMAAN INTERFACE FISIK (HAP LITE RB941-2nD)
/interface ethernet
set [ find default-name=ether1 ] name=ether1-UPLINK comment="Dari Gigabit Core Switch (Port 5)"
set [ find default-name=ether2 ] name=ether2-LAN-TBSM comment="Ke Switch/PC Bengkel TBSM"
set [ find default-name=ether3 ] name=ether3-AP-GURU comment="Ke Access Point Ruang Guru TBSM"
set [ find default-name=ether4 ] name=ether4-CADANGAN comment="Cadangan / Teknisi"

# Bridge LAN (Hardware Offloaded)
/interface bridge add name=bridge comment="Bridge LAN Bengkel TBSM (HW Offloaded)" disabled=no
/interface bridge port
remove [ find interface=ether1-UPLINK ]
add bridge=bridge interface=ether2-LAN-TBSM
add bridge=bridge interface=ether3-AP-GURU
add bridge=bridge interface=ether4-CADANGAN

# 3. PENGALAMATAN IP
/ip address
add address=10.10.10.4/24 interface=ether1-UPLINK comment="IP Uplink ke R1-CORE"
add address=192.168.40.1/24 interface=bridge comment="Gateway Bengkel TBSM"

# 4. DEFAULT ROUTE KE CORE ROUTER & DNS
/ip route add dst-address=0.0.0.0/0 gateway=10.10.10.1 comment="Gateway ke R1-CORE-ROUTER"
/ip dns set allow-remote-requests=yes cache-size=2048KiB servers=10.10.10.1,8.8.8.8

# 5. DHCP SERVER BENGKEL TBSM
/ip pool add name=pool-tbsm ranges=192.168.40.10-192.168.40.35 comment="Pool PC TBSM"
/ip dhcp-server add address-pool=pool-tbsm disabled=no interface=bridge lease-time=1d name=dhcp-tbsm
/ip dhcp-server network add address=192.168.40.0/24 dns-server=192.168.40.1,8.8.8.8 gateway=192.168.40.1 comment="Network Bengkel TBSM"

# 6. NAT MASQUERADE
/ip firewall nat add chain=srcnat out-interface=ether1-UPLINK action=masquerade comment="NAT Internet Bengkel TBSM"

# 7. MANAJEMEN BANDWIDTH (DEFAULT AKTIF: MODE 2 - HARIAN BIASA)
/queue simple add name="Q-BENGKEL-TBSM" target=192.168.40.0/24 max-limit=15M/15M comment="Mode Harian TBSM 15 Mbps"

# 8. DUAL-MODE SWITCHER (1-KLIK VIA SYSTEM SCRIPT)
/system script add name="1-MODE-TKA-AKTIF" comment="Mode TKA (Hemat 5 Mbps)" source={
  /queue simple set [find name="Q-BENGKEL-TBSM"] max-limit=5M/5M
  :log warning ">>> [R4-BENGKEL-TBSM] MODE TKA AKTIF: Bandwidth dibatasi 5 Mbps <<<"
}
/system script add name="2-MODE-HARIAN-AKTIF" comment="Mode Harian (Normal 15 Mbps)" source={
  /queue simple set [find name="Q-BENGKEL-TBSM"] max-limit=15M/15M
  :log info ">>> [R4-BENGKEL-TBSM] MODE HARIAN AKTIF: Bandwidth dibuka 15 Mbps <<<"
}

# 9. MANAGEMENT & RoMON
/tool romon set enabled=yes
