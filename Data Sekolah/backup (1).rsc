# oct/06/2026 21:24:34 by RouterOS 6.49.13
# software id = 3DVR-7VK6
#
# model = RB941-2nD
# serial number = HG709Y1J9A1
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
add authentication-types=wpa2-psk mode=dynamic-keys name=RuangDR \
    supplicant-identity="" wpa2-pre-shared-key=@0987654321
/interface wireless
set [ find default-name=wlan1 ] ampdu-priorities=0,1,2,3,4,5,6,7 band=\
    2ghz-b/g/n channel-width=20/40mhz-XX disabled=no frequency=auto mode=\
    ap-bridge security-profile=RuangDR ssid="Ruang DR"
/ip pool
add name=dhcp_pool0 ranges=192.168.30.2-192.168.30.254
add name=dhcp_pool1 ranges=192.168.40.2-192.168.40.254
add name=dhcp_pool2 ranges=192.168.50.2-192.168.50.254
add name=dhcp_pool3 ranges=192.168.20.2-192.168.23.254
add name=dhcp_pool4 ranges=192.168.20.2-192.168.20.50
/ip dhcp-server
add address-pool=dhcp_pool0 disabled=no interface=ether2 name=dhcp1
add address-pool=dhcp_pool1 disabled=no interface=ether3 name=dhcp2
add address-pool=dhcp_pool2 disabled=no interface=ether4 name=dhcp3
add address-pool=dhcp_pool4 disabled=no interface=wlan1 name=dhcp4
/queue simple
add limit-at=10M/10M max-limit=10M/10M name=queue1 target=ether2
add limit-at=5M/5M max-limit=5M/5M name=queue3 target=ether3
add limit-at=5M/5M max-limit=5M/5M name=queue4 target=ether4
add max-limit=40M/40M name=queue2 queue=ethernet-default/ethernet-default \
    target=wlan1
/ip address
add address=192.168.20.1/24 interface=wlan1 network=192.168.20.0
add address=192.168.30.1/24 interface=ether2 network=192.168.30.0
add address=192.168.40.1/24 interface=ether3 network=192.168.40.0
add address=192.168.50.1/24 interface=ether4 network=192.168.50.0
/ip dhcp-client
add disabled=no interface=ether1
/ip dhcp-server network
add address=192.168.20.0/24 gateway=192.168.20.1
add address=192.168.30.0/24 gateway=192.168.30.1
add address=192.168.40.0/24 gateway=192.168.40.1
add address=192.168.50.0/24 gateway=192.168.50.1
/ip firewall nat
add action=masquerade chain=srcnat out-interface=ether1
/system clock
set time-zone-name=Europe/London
/system ntp client
set enabled=yes
