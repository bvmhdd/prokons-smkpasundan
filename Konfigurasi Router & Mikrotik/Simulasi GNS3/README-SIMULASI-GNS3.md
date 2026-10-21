# PANDUAN SIMULASI GNS3: MULTI-ROUTER SMK INFORMATIKA PASUNDAN

Dokumen ini memandu langkah-langkah menjalankan simulasi jaringan 4+1 Router di GNS3.

---

## 1. Skema Pengkabelan Virtual di GNS3

| Dari Perangkat | Dari Port GNS3 (Interface) | Ke Perangkat | Ke Port GNS3 (Interface) | Keterangan |
| :--- | :---: | :--- | :---: | :--- |
| **`Cloud1`** | `Ethernet 2` | **`R1-CORE-ROUTER`** | `Ethernet0` (`ether1`) | Uplink Internet Laptop |
| **`R1-CORE-ROUTER`** | `Ethernet1` (`ether2`) | **`Core-Switch`** | `Ethernet25` | Backbone Distribusi |
| **`Core-Switch`** | `Ethernet8` | **`R2-TKA-GATEWAY`** | `Ethernet0` (`ether1`) | Kabel 9 VIP Ujian TKA |
| **`Core-Switch`** | `Ethernet3` | **`R3-BENGKEL-TKJ`** | `Ethernet0` (`ether1`) | Uplink Lab TKJ |
| **`Core-Switch`** | `Ethernet4` | **`R4-BENGKEL-TBSM`** | `Ethernet0` (`ether1`) | Uplink Lab TBSM |
| **`Core-Switch`** | `Ethernet5` | **`R5-BENGKEL-MP`** | `Ethernet0` (`ether1`) | Uplink Lab MP |
| **`Core-Switch`** | `Ethernet0` - `2` | `AP-RG1, AP-RG2, AP-RG3` | `Ethernet0` | Access Point Ruang Guru |
| **`Core-Switch`** | `Ethernet6` - `7` | `AP-Kepsek, AP-LT-2` | `Ethernet0` | Access Point Selasar/LT2 |

---

## 2. Urutan Pemasangan Script

Buka konsol terminal masing-masing router di GNS3, lalu copy-paste script berikut:

1. **`01-R1-CORE-ROUTER.rsc`** $\rightarrow$ Jalankan di `R1-CORE-ROUTER`.
2. **`02-R2-TKA-GATEWAY.rsc`** $\rightarrow$ Jalankan di `R2-TKA-GATEWAY`.
3. **`03-R3-BENGKEL-TKJ.rsc`** $\rightarrow$ Jalankan di `R3-BENGKEL-TKJ`.
4. **`04-R4-BENGKEL-TBSM.rsc`** $\rightarrow$ Jalankan di `R4-BENGKEL-TBSM`.
5. **`05-R5-BENGKEL-MP.rsc`** *(Opsional)* $\rightarrow$ Jalankan di `R5-BENGKEL-MP`.

---

## 3. Cara Pengujian & Validasi

### A. Uji Koneksi Antar-Router & Simulator Internet
Di terminal router mana pun (misal `R2-TKA-GATEWAY`):
```routeros
# Uji ping ke Core Router
/ping 10.10.10.1 count=4

# Uji ping ke Simulator Internet Google
/ping 8.8.8.8 count=4
```
*Hasil harus Reply 100%!*

### B. Uji Klien Komputer (VPCS)
1. Colokkan node **VPCS** ke port `ether2-LAB-TJKT` di `R2-TKA-GATEWAY`.
2. Buka konsol VPCS:
   ```text
   dhcp
   ping 8.8.8.8
   ```
*VPCS otomatis dapat IP `192.168.20.x` dan tembus ke 8.8.8.8.*

### C. Uji Bandwidth Management (Queue Tree & PCQ 2 Mbps)
1. Buka Winbox di `R2-TKA-GATEWAY`, masuk menu **Queues** > tab **Queue Tree**.
2. Di terminal `R2-TKA-GATEWAY`, jalankan uji tembak trafik:
   ```routeros
   /tool bandwidth-test address=10.10.10.1 direction=receive duration=15s
   ```
3. Lihat bar `TOTAL-DOWNLOAD` dan `Q-TKA-DOWN` di WinBox bergerak dan tertahan rapi di limit alokasi.
