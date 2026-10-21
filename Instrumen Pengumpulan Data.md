# Instrumen Pengumpulan Data & Evaluasi Rekursif
## Network Assessment & Optimization — SMK Informatika Pasundan

> **Petunjuk Penggunaan:** Dokumen ini adalah instrumen kerja lapangan yang digunakan tim konsultan saat kunjungan koordinasi (12 Okt), pemetaan fisik (13 Okt), dan pengujian performa (16 & 19 Okt). Instrumen ini dirancang dengan pendekatan **Closed-Loop / Rekursif** agar setiap temuan data langsung memvalidasi hipotesis dan menentukan siklus tuning berikutnya.

---

## Form 1 — Checklist Data Administratif & Topologi Logis Sekolah

| No | Data yang Diminta | Status | Rincian / Temuan Lapangan | Relevansi Teknis |
|---|---|:---:|---|---|
| 1 | **Tipe Layanan & IP WAN ISP** | ☐ | ☐ Single IP Statis (/30)<br/>☐ Multi-IP (/29)<br/>☐ PPPoE Dial<br/>☐ Dynamic DHCP | Menentukan apakah arsitektur Dual-Gateway memungkinkan langsung atau membutuhkan routing internal/failover fisik. |
| 2 | Jumlah guru & staf aktif | ☐ | | Analisis alokasi bandwidth Guru |
| 3 | Jumlah siswa per tingkat | ☐ | | Menghitung beban puncak BYOD siswa |
| 4 | Jumlah PC per lab (TJKT, MP, TSM) | ☐ | TJKT: ___ PC • MP: ___ PC • TSM: ___ PC | Menghitung kebutuhan port switch dan bandwidth TKA |
| 5 | Perkiraan device WiFi per area | ☐ | | Menghitung kebutuhan pool DHCP & kapasitas AP |
| 6 | Denah fisik gedung (lantai 1 & 2) | ☐ | | Penempatan 5 AP idle & jalur kabel uplink |
| 7 | Export konfigurasi router (`/export file=backup`) | ☐ | | Analisis script Mangle, Filter, NAT, & Queue |
| 8 | Versi RouterOS & model pasti router | ☐ | Model: _____________ ROS v: _______ | Cek batas conntrack table & bug firmware |
| 9 | Peran eksisting Router MikroTik ke-2 | ☐ | ☐ Idle total ☐ Hotspot ☐ Lab | Verifikasi kesiapan dialokasikan untuk Lab TKA |
| 10 | Konfigurasi DHCP Server eksisting | ☐ | Subnet: ___________ Lease time: _____ | Deteksi potensi DHCP starvation |
| 11 | Fitur Hotspot / Captive Portal | ☐ | ☐ Aktif (login page) ☐ Nonaktif (WPA2) | Mengetahui penyebab sesi terputus sendiri |
| 12 | Daftar AP eksisting (Model & Mode) | ☐ | Model: ____________ Mode: _________ | Deteksi double NAT / DHCP liar dari AP |
| 13 | Juknis & Moda TKA/ANBK terbaru | ☐ | ☐ Full Online CBT ☐ Semi-Online VHD | Menentukan kebutuhan bandwidth 1.0 Mbps/PC vs LAN Gigabit |
| 14 | Kontak darurat NOC Fibernet | ☐ | PIC: ____________ No: _____________ | SOP eskalasi cepat jika terjadi link drop saat ujian |

---

## Form 2 — Audit Fisik: Distribusi Port Switch & Eliminasi Bottleneck Lab

*Tujuan: Memverifikasi rasio ketersediaan port switch terhadap 84 PC lab agar tidak ada PC yang tidak tercolok.*

| Area / Lab | Jumlah PC | Switch 16-Port (Qty) | Perangkat 8-Port (Qty) | Model Pasti Perangkat 8-Port | Tipe Riil Perangkat | Port Tersedia vs Terpakai | Status Link (10/100/1000) |
|---|:---:|:---:|:---:|---|---|:---:|:---:|
| **Lab TJKT** | 42 PC | ___ unit | ___ unit | _________________ | ☐ Switch Unmanaged<br/>☐ Hub Murni (Half-duplex) | ___ port / 42 PC | ☐ 1000M ☐ 100M |
| **Lab MP** | 40 PC | ___ unit | ___ unit | _________________ | ☐ Switch Unmanaged<br/>☐ Hub Murni (Half-duplex) | ___ port / 40 PC | ☐ 1000M ☐ 100M |
| **Lab TSM / Guru** | ___ PC | ___ unit | ___ unit | _________________ | ☐ Switch ☐ Hub | ___ port / ___ PC | ☐ 1000M ☐ 100M |
| **Selasar / Core** | — | ___ unit | ___ unit | _________________ | ☐ Switch ☐ Hub | Uplink antar-lantai | ☐ 1000M ☐ 100M |

> **Catatan Lapangan:** Jika perangkat 8-port adalah *Switch Unmanaged* (misal: TP-Link TL-SF1008D), perangkat tersebut **diizinkan digunakan** untuk baris PC sisa. Jika bertuliskan *Hub (Collision indicator menyala)*, perangkat **wajib diganti**.

---

## Form 3 — Diagnostik Router Gateway Eksisting (Beban Puncak vs Normal)

*Ambil data 2 kali: (1) Off-peak Jumat/pagi hari, (2) Peak time: **Senin–Kamis 09.00–12.00**.*

| Parameter Uji | Perintah / Menu MikroTik | Nilai Off-Peak | Nilai Jam Sibuk (Peak) | Ambang Batas Wajar | Status Celah |
|---|---|:---:|:---:|:---:|:---:|
| **CPU Usage** | `/system resource monitor` | ____ % | ____ % | < 75% | ☐ Aman ☐ Overload |
| **Free Memory** | `/system resource print` | ____ MB | ____ MB | > 8 MB (dari 32MB) | ☐ Aman ☐ Kritis |
| **CPU Profiler Terbesar** | `/tool profile duration=10` | _________ | _________ | firewall / queue / routing | Indikator bottleneck |
| **Connection Tracking** | `/ip firewall connection print count-only` | ____ sesi | ____ sesi | < 4.000 sesi | ☐ Aman ☐ Conntrack Penuh |
| **Lease DHCP Aktif** | `/ip dhcp-server lease print count-only` | ____ IP | ____ IP | < 80% dari pool | ☐ Aman ☐ Pool Habis |
| **Status FastTrack** | `/ip firewall filter print where action=fasttrack` | ☐ Aktif ☐ Mati | ☐ Aktif ☐ Mati | Jika aktif, Queue Tree dilewati | ☐ Celah QoS |
| **NAT Masquerade** | `/ip firewall nat print` | ☐ Lengkap ☐ Tidak | ☐ Lengkap ☐ Tidak | Wajib ada out-interface WAN | ☐ Celah Internet |
| **DNS Cache Usage** | `/ip dns print` | Allow remote: ☐ Ya | Allow remote: ☐ Ya | Cache max: 2048 KiB | ☐ Resolving drop |
| **Top-Talker Host** | Tools → Torch pada LAN interface | IP: ___________ | IP: ___________ | Rate: ________ Mbps | Indikasi monopoli |

---

## Form 4 — Audit Access Point & Kebersihan Kanal Wireless

| AP ID | Lokasi Fisik | Merek & Model | Mode Operasi | SSID | Kanal (CH) | Lebar Kanal | TX Power | Klien Peak | DHCP Internal AP |
|:---:|---|---|---|---|:---:|:---:|---|:---:|:---:|
| **AP-01** | Ruang Guru Bawah | | ☐ Bridge ☐ Router | | | ☐ 20MHz ☐ 40MHz | | | ☐ OFF (Benar) ☐ ON (Double NAT) |
| **AP-02** | R. Guru Khusus TSM | | ☐ Bridge ☐ Router | | | ☐ 20MHz ☐ 40MHz | | | ☐ OFF (Benar) ☐ ON (Double NAT) |
| **AP-03** | Selasar Atas (Utara) | | ☐ Bridge ☐ Router | | | ☐ 20MHz ☐ 40MHz | | | ☐ OFF (Benar) ☐ ON (Double NAT) |
| **AP-04** | Selasar Atas (Selatan) | | ☐ Bridge ☐ Router | | | ☐ 20MHz ☐ 40MHz | | | ☐ OFF (Benar) ☐ ON (Double NAT) |
| **AP-05** | Area Bawah Lain | | ☐ Bridge ☐ Router | | | ☐ 20MHz ☐ 40MHz | | | ☐ OFF (Benar) ☐ ON (Double NAT) |
| **AP-06 s.d 10** | *(5 AP Idle Cadangan)* | | Siap pasang? ☐ Ya | Target lokasi: | 1 / 6 / 11 | 20 MHz | 60% | — | Wajib diset Bridge |

---

## Form 5 — Pengujian Performa Divide & Conquer (Titik A s.d. E)

*Standar Acuan TIPHON: Download/Upload (Speedtest), Latensi & Packet Loss (100 ping ke 8.8.8.8 & Gateway), Throughput LAN (iperf3).*

| Titik Uji | Titik Pengukuran | Media | Speedtest Down / Up | Ping Gateway (Avg / Loss) | Ping Internet (Avg / Loss) | iperf3 LAN (Local Throughput) | Hasil & Analisis |
|:---:|---|:---:|:---:|:---:|:---:|:---:|---|
| **A** | Langsung Switch ISP | Kabel UTP | ___ / ___ Mbps | — | ___ ms / ___ % | — | Baseline performa ISP |
| **B** | Port LAN Router Gateway | Kabel UTP | ___ / ___ Mbps | ___ ms / ___ % | ___ ms / ___ % | ___ Mbps | Pengaruh CPU & NAT Router |
| **C1** | Switch Lab TJKT (PC 01) | Kabel UTP | ___ / ___ Mbps | ___ ms / ___ % | ___ ms / ___ % | ___ Mbps | Kualitas kabel & switch lab |
| **C2** | Switch Lab MP (PC 01) | Kabel UTP | ___ / ___ Mbps | ___ ms / ___ % | ___ ms / ___ % | ___ Mbps | Kualitas kabel & switch lab |
| **D** | Dekat AP Selasar (< 3m) | WiFi | ___ / ___ Mbps | ___ ms / ___ % | ___ ms / ___ % | ___ Mbps | Kinerja murni AP |
| **E** | Ujung Selasar (Dead zone) | WiFi | ___ / ___ Mbps | ___ ms / ___ % | ___ ms / ___ % | ___ Mbps | Efek jarak & interferensi |

---

## Form 6 — Heatmap & Analisis Dead Zone Wireless (Sebelum vs Sesudah 5 AP Idle)

| Titik Ukur | Lokasi Spesifik | RSSI Awal (Existing) | Kualitas Sinyal Awal | SSID & CH Terdeteksi | Rekomendasi Titik AP Baru | RSSI Setelah Pasang AP Baru |
|:---:|---|:---:|:---:|:---:|---|:---:|
| **T-01** | Meja Guru Ruang Bawah | ____ dBm | ☐ Baik ☐ Cukup ☐ Buruk | | | ____ dBm |
| **T-02** | Selasar Luar Lab TJKT | ____ dBm | ☐ Baik ☐ Cukup ☐ Buruk | | Pasang AP Idle #6 | ____ dBm |
| **T-03** | Selasar Tengah Lantai 2 | ____ dBm | ☐ Baik ☐ Cukup ☐ Buruk | | Pasang AP Idle #7 | ____ dBm |
| **T-04** | Selasar Luar Lab MP | ____ dBm | ☐ Baik ☐ Cukup ☐ Buruk | | Pasang AP Idle #8 | ____ dBm |
| **T-05** | Ruang Tata Usaha (TU) | ____ dBm | ☐ Baik ☐ Cukup ☐ Buruk | | Pasang AP Idle #9 | ____ dBm |
| **T-06** | Area Kantin / Bawah | ____ dBm | ☐ Baik ☐ Cukup ☐ Buruk | | Pasang AP Idle #10 | ____ dBm |

---

## Form 7 — Kuesioner Verifikasi Kepuasan Pengguna (Validasi Masalah)

1. **Status Responden:** ☐ Guru / Staf ☐ Siswa / Peserta Ujian ☐ Proktor
2. **Lokasi Penggunaan Terbanyak:** ☐ Lab Komputer ☐ Ruang Guru ☐ Selasar
3. **Jenis Perangkat:** ☐ Laptop Sekolah ☐ PC Lab Kabel ☐ HP Pribadi
4. **Gejala yang Paling Sering Dirasakan (Beri tanda cek):**
   * [ ] Status WiFi terhubung, tapi muncul tulisan *"No Internet Access"*.
   * [ ] Tiba-tiba logout atau terputus sendiri setiap beberapa menit.
   * [ ] Loading memutar lama (*buffering*) saat membuka web atau ujian CBT.
   * [ ] Sinyal hilang sama sekali di pojok ruangan (*dead zone*).
5. **Waktu Kejadian Terparah:** ☐ 08.00–10.00 ☐ 10.00–12.00 ☐ 12.00–14.00

---

## Form 8 — Matriks Validasi Hipotesis (Penetapan Akar Masalah)

| Kode | Hipotesis yang Diuji | Sumber Data Pembuktian | Hasil Uji Lapangan | Kesimpulan Konsultan |
|:---:|---|---|:---:|:---:|
| **H0** | ISP Fibernet sesuai SLA saat jam sibuk | Form 5 Titik A | Throughput: ___ Mbps • Loss: ___ % | ☐ Valid (Bukan ISP) ☐ Drop (Salah ISP) |
| **H1** | CPU Router hAP lite overload pada jam sibuk | Form 3 (CPU & Profile) | CPU Peak: ____ % | ☐ Terbukti ☐ Ditolak |
| **H2** | DHCP pool habis / lease time terlalu lama | Form 3 (DHCP lease) | Lease: ___ dari ___ IP | ☐ Terbukti ☐ Ditolak |
| **H3** | AP consumer kelebihan klien (> 25 device) | Form 4 (Klien Peak) | Max Klien AP: ____ device | ☐ Terbukti ☐ Ditolak |
| **H4** | Interferensi frekuensi 2.4 GHz & sinyal lemah | Form 4 & Form 6 | Kanal tumpang tindih: ☐ Ya ☐ Tidak | ☐ Terbukti ☐ Ditolak |
| **H5** | Monopoli bandwidth tanpa keadilan antrean | Form 3 (Torch) & Form 5 | Ada host memakan > 40 Mbps: ☐ Ya | ☐ Terbukti ☐ Ditolak |
| **H6** | AP salah mode (aktif DHCP Server / Double NAT) | Form 4 (DHCP AP) | AP membagikan IP sendiri: ☐ Ya | ☐ Terbukti ☐ Ditolak |
| **H7** | Alokasi Queue Tree statis 100% tanpa borrowing | Form 3 & Config export | Queue Atas mentok 50M: ☐ Ya | ☐ Terbukti ☐ Ditolak |
| **H8** | Hambatan fisik (Hub half-duplex / port 100M) | Form 2 | Ada Hub collision: ☐ Ya ☐ Tidak | ☐ Terbukti ☐ Ditolak |


