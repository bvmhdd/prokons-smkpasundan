# ==============================================================================
# KONFIGURASI IMPLEMENTASI ASLI: R5-BENGKEL-MP
# Perangkat: MikroTik hAP lite (RB941-2nD)
# Lokasi: Ruang Lab / Bengkel Manajemen Perkantoran (MP)
# Fitur: Dual-Mode (Mode 1: Saat Ujian TKA Berlangsung, Mode 2: Hari-Hari Biasa)
# ==============================================================================

# 1. IDENTITAS ROUTER
/system identity set name="R5-BENGKEL-MP"

# 2. PENAMAAN INTERFACE FISIK (HAP LITE RB941-2nD)
/interface ethernet
set [ find default-name=ether1 ] name=ether1-UPLINK comment="Dari Gigabit Core Switch (Kabel 6)"
set [ find default-name=ether2 ] name=ether2-LAN-MP comment="Ke Switch Bengkel MP (PC Praktik)"
set [ find default-name=ether3 ] name=ether3-AP-GURU comment="Ke Access Point Ruang Guru MP"
set [ find default-name=ether4 ] name=ether4-CADANGAN comment="Port Cadangan / Teknisi"

# Bridge LAN (Hardware Offloaded)
/interface bridge add name=bridge comment="Bridge LAN Bengkel MP (HW Offloaded)" disabled=no
/interface bridge port
remove [ find interface=ether1-UPLINK ]
add bridge=bridge interface=ether2-LAN-MP
add bridge=bridge interface=ether3-AP-GURU
add bridge=bridge interface=ether4-CADANGAN

# 3. PENGALAMATAN IP
/ip address
add address=10.10.10.5/24 interface=ether1-UPLINK comment="IP Uplink ke R1-CORE"
add address=192.168.50.1/24 interface=bridge comment="Gateway PC Praktik MP"

# 4. DEFAULT ROUTE KE CORE ROUTER & DNS
/ip route add dst-address=0.0.0.0/0 gateway=10.10.10.1 comment="Gateway ke R1-CORE-ROUTER"
/ip dns set allow-remote-requests=yes cache-size=2048KiB servers=10.10.10.1,8.8.8.8

# 5. DHCP SERVER BENGKEL MP
/ip pool add name=pool-mp-bengkel ranges=192.168.50.10-192.168.50.40 comment="Pool PC Siswa MP"
/ip dhcp-server add address-pool=pool-mp-bengkel disabled=no interface=bridge lease-time=1d name=dhcp-mp-bengkel
/ip dhcp-server network add address=192.168.50.0/24 dns-server=192.168.50.1,8.8.8.8 gateway=192.168.50.1 comment="Network Bengkel MP"

# 6. NAT MASQUERADE
/ip firewall nat add chain=srcnat out-interface=ether1-UPLINK action=masquerade comment="NAT Internet Bengkel MP"

# 7. MANAJEMEN BANDWIDTH (DEFAULT AKTIF: MODE 2 - HARIAN BIASA)
/queue simple add name="Q-BENGKEL-MP" target=192.168.50.0/24 max-limit=20M/20M comment="Mode Harian MP 20 Mbps"

# 8. DUAL-MODE SWITCHER (1-KLIK VIA SYSTEM SCRIPT)
/system script add name="1-MODE-TKA-AKTIF" comment="Mode TKA (Hemat 5 Mbps)" source={
  /queue simple set [find name="Q-BENGKEL-MP"] max-limit=5M/5M
  :log warning ">>> [R5-BENGKEL-MP] MODE TKA AKTIF: Bandwidth dibatasi 5 Mbps <<<"
}
/system script add name="2-MODE-HARIAN-AKTIF" comment="Mode Harian (Normal 20 Mbps)" source={
  /queue simple set [find name="Q-BENGKEL-MP"] max-limit=20M/20M
  :log info ">>> [R5-BENGKEL-MP] MODE HARIAN AKTIF: Bandwidth dibuka 20 Mbps <<<"
}

# 9. MANAGEMENT & RoMON
/tool romon set enabled=yes
