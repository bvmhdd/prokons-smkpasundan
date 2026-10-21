# PANDUAN IMPLEMENTASI ASLI: HARDWARE MIKROTIK HAP LITE
## SMK INFORMATIKA PASUNDAN (ZERO-COST OPTIMIZATION)

Panduan ini digunakan oleh tim teknisi/konsultan saat melakukan instalasi langsung pada unit router fisik **MikroTik hAP lite (RB941-2nD)** dan switch fisik sekolah.

---

## 1. Inventaris & Penempatan Perangkat Fisik

| Kode Router | Model Hardware | Lokasi Fisik | Peran & Beban Pengguna | Port Switch Utama |
| :--- | :--- | :--- | :--- | :---: |
| **`R1-CORE-ROUTER`** | hAP lite (RB941-2nD) | Ruang Server / Ruang Guru | Otak Utama, NAT Pusat, Queue ISP 100M | Port 1 (Gigabit) |
| **`R2-TKA-GATEWAY`** | hAP lite (RB941-2nD) | Ruang Lab CBT / Server TKA | Khusus Ujian TKA (84 PC + Proktor) | Port 9 VIP |
| **`R3-BENGKEL-TKJ`** | hAP lite (RB941-2nD) | Ruang Bengkel TKJ | Praktik Jaringan Siswa TKJ | Port 4 |
| **`R4-BENGKEL-TBSM`** | hAP lite (RB941-2nD) | Ruang Guru TBSM | PC Administrasi & Praktik TBSM | Port 5 |
| **`R5-BENGKEL-MP`** | hAP lite (RB941-2nD) | Ruang Bengkel MP | Praktik Administrasi & Lab MP | Port 6 |

---

## 2. Prosedur Reset & Penerapan Konfigurasi

Sebelum memasukkan script konfigurasi, **WAJIB melakukan reset tanpa konfigurasi default (*No Default Configuration*)** agar tidak terjadi bentrok IP `192.168.88.1`:

### Langkah 1: Reset Bersih Router
1. Nyalakan MikroTik hAP lite.
2. Buka **Winbox**, login via MAC Address.
3. Buka menu **System** > **Reset Configuration**.
4. **Centang:**
   - [x] **No Default Configuration**
   - [x] **Do Not Backup**
5. Klik **Reset Configuration** dan tunggu router restart (sekitar 30–45 detik).

### Langkah 2: Import Script Konfigurasi
Setelah router menyala kembali:
1. Login kembali ke router menggunakan **Winbox** (via MAC Address, User: `admin`, Password: kosong).
2. Buka menu **New Terminal**.
3. Buka file `.rsc` yang bersangkutan dengan text editor (Notepad/VS Code).
4. **Copy seluruh isi file** dan **Paste** langsung ke jendela Terminal Winbox.
5. Tekan **Enter** sampai baris perintah selesai diproses.
6. Berikan password admin baru:
   ```routeros
   /user set [find name=admin] password="PasswordKuatSekolah123"
   ```

---

## 3. Skema Pengkabelan Fisik (Physical Cable Layout)

### A. Pada `R1-CORE-ROUTER`
- **Port 1 (`ether1`):** Kabel dari Modem ISP Fibernet 100 Mbps.
- **Port 2 (`ether2`):** Kabel ke **Port 1** Switch Utama 16-Port Gigabit TP-Link.
- **Port 3 (`ether3`):** Port maintenance teknisi (IP: `192.168.88.1`).

### B. Pada `R2-TKA-GATEWAY` (VVIP Ujian CBT)
- **Port 1 (`ether1`):** Kabel VIP (Kabel 9) langsung dari **Port 9** Switch Utama.
- **Port 2 (`ether2`):** Kabel ke Switch Gigabit Lab TJKT (42 PC Siswa).
- **Port 3 (`ether3`):** Kabel ke Switch Gigabit Lab MP (40 PC Siswa).
- **Port 4 (`ether4`):** Kabel ke Switch Ruang Server / PC Proktor.

### C. Pada Router Bengkel (`R3-BENGKEL-TKJ`, `R4-BENGKEL-TBSM`, & `R5-BENGKEL-MP`)
- **Port 1 (`ether1`):** Kabel dari Port 4 (TKJ), Port 5 (TBSM), atau Port 6 (MP) dari Switch Utama.
- **Port 2 (`ether2`):** Kabel ke Switch Lab Bengkel masing-masing.

---

## 4. Standar Operasional Prosedur (SOP) Hari Ujian TKA

1. **H-1 Hari Ujian:**
   - Nyalakan seluruh PC Lab TJKT dan Lab MP.
   - Pastikan seluruh 84 PC mendapatkan IP secara otomatis dari DHCP Server R2 (`192.168.20.x` dan `192.168.21.x`).
   - Cek masa sewa IP (`Lease Time` = 3 hari).
2. **Saat Sesi Ujian Berlangsung:**
   - Buka Winbox di `R2-TKA-GATEWAY`, pantau menu **System** > **Resources**.
   - Beban CPU hAP lite harus berada di kisaran aman **50%–75%**.
   - Pantau menu **Queues** > **Queue Tree** di `R1-CORE-ROUTER`. Baris `Q-JALUR-VIP-TKA` harus mendapatkan prioritas penuh (minimal 75 Mbps).
