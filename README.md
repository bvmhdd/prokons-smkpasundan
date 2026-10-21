# Optimalisasi Infrastruktur Jaringan & Pengamanan Jalur Ujian TKA
## SMK Informatika Pasundan — Zero-Cost Architecture (Multi-Router Distribution)

[![MikroTik RouterOS](https://img.shields.io/badge/MikroTik-RouterOS_v7-00599C?logo=mikrotik&logoColor=white)](https://mikrotik.com)
[![GNS3 Network Simulator](https://img.shields.io/badge/GNS3-Local_Server-green?logo=gns3&logoColor=white)](https://gns3.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **Proyek Konsultansi Jaringan — Semester 5 (Kelas 5A SISTEL)**  
> **Mitra Proyek:** SMK Informatika Pasundan  
> **Fokus Utama:** Pengamanan Jalur Ujian CBT TKA (84 PC), Penyelesaian Masalah Wi-Fi Ruang Guru, dan Pemecahan Beban Jaringan Tanpa Pengadaan Alat Baru (*Zero-Cost Optimization*).

---

## 📌 1. Latar Belakang & Permasalahan

Berdasarkan audit infrastruktur jaringan di SMK Informatika Pasundan:
1. **Beban Tinggi Jam Sibuk (08.00–13.00):** Wi-Fi Ruang Guru mengalami gejala *"Terkoneksi tanpa akses"*, *"Sering logout sendiri"*, dan *"Buffering"*.
2. **Keterbatasan Spesifikasi Router:** Router eksisting adalah **MikroTik hAP lite (RB941-2nD)** dengan CPU single-core 650 MHz dan RAM 32MB. Menangani 80+ PC ujian sekaligus bersamaan dengan Wi-Fi guru berisiko memicu CPU 100% dan *freeze*.
3. **Event Berisiko Tinggi (TKA / CBT):** Pelaksanaan ujian melibatkan **84 unit PC** secara simultan di 2 laboratorium (**Lab TJKT: 42 PC** dan **Lab MP: 40 PC**).
4. **Peluang Aset Idle:** Sekolah memiliki **20 unit router MikroTik hAP lite idle** yang belum dimanfaatkan di gudang.

---

## 💡 2. Solusi: Arsitektur Distribusi 5-Router Zero-Cost (Gambar 5 Laporan)

Daripada membeli router enterprise mahal, solusi terbaik adalah **memecah beban komputasi jaringan** menggunakan aset router idle yang sudah dimiliki sekolah:

<p align="center">
  <a href="assets/topologi_distribusi_zero_cost_hd.png">
    <img src="assets/topologi_distribusi_zero_cost_hd.png" alt="Gambar 5: Topologi Distribusi Zero Cost" width="100%"/>
  </a>
  <br>
  <em><b>Gambar 5:</b> Topologi Distribusi Zero-Cost SMK Informatika Pasundan (Klik gambar untuk resolusi 8K Ultra-HD • Tersedia format vektor <a href="assets/topologi_distribusi_zero_cost.svg"><b>SVG</b></a>)</em>
</p>

### Diagram Detail Alur Logis Jaringan:

```mermaid
flowchart TD
    %% Internet & Core
    CLOUD(("Cloud / Internet ISP"))
    MODEM["Modem ISP Fibernet 100M<br/>(192.168.1.1 / IP Publik)"]
    R1["R1-CORE-ROUTER<br/>(Otak Utama & NAT Pusat)<br/>WAN ether1: DHCP / Static<br/>LAN ether2: 10.10.10.1/24<br/>Simulator: 8.8.8.8/32"]

    CLOUD --> MODEM
    MODEM -->|"Satu Kabel Utama (ether1)"| R1

    %% Core Switch Terminal Pusat
    CORE_SW["GIGABIT CORE SWITCH<br/>(Terminal Pusat 16/24 Port TP-Link)<br/>Subnet Backbone: 10.10.10.0/24"]
    R1 -->|"Kabel Distribusi Backbone (10.10.10.1)"| CORE_SW

    %% Zona Ruang Guru
    subgraph ZRG["Zona Ruang Guru (Beban Tinggi) — DHCP: 10.10.10.100 - .200"]
        AP1["AP Tenda 1<br/>IP: 10.10.10.11<br/>(Channel 1 - Bridge)"]
        AP2["AP Tenda 2<br/>IP: 10.10.10.12<br/>(Channel 6 - Bridge)"]
        AP3["AP Tenda 3<br/>IP: 10.10.10.13<br/>(Channel 11 - Bridge)"]

        CORE_SW -->|"Kabel 1"| AP1
        CORE_SW -->|"Kabel 2"| AP2
        CORE_SW -->|"Kabel 3"| AP3
    end

    %% Zona Bengkel Jurusan
    subgraph ZBJ["Zona Bengkel Jurusan (Pemisahan Beban Praktik)"]
        R3["R3-BENGKEL-TKJ<br/>WAN: 10.10.10.3/24<br/>LAN: 192.168.30.1/24"]
        R4["R4-BENGKEL-TBSM<br/>WAN: 10.10.10.4/24<br/>LAN: 192.168.40.1/24"]
        R5["R5-BENGKEL-MP<br/>WAN: 10.10.10.5/24<br/>LAN: 192.168.50.1/24"]

        SW_TKJ["Switch Lab TKJ<br/>DHCP: 192.168.30.10 - .50"]
        SW_TBSM["Switch Lab TBSM<br/>DHCP: 192.168.40.10 - .50"]
        SW_MP["Switch Lab MP<br/>DHCP: 192.168.50.10 - .50"]

        R3 -->|"ether2"| SW_TKJ
        R4 -->|"ether2"| SW_TBSM
        R5 -->|"ether2"| SW_MP
    end

    CORE_SW -->|"Kabel 4 (10.10.10.3)"| R3
    CORE_SW -->|"Kabel 5 (10.10.10.4)"| R4
    CORE_SW -->|"Kabel 6 (10.10.10.5)"| R5

    %% Zona Administrasi & Siswa Selasar
    subgraph ZAS["Zona Administrasi & Siswa — Subnet: 10.10.10.0/24"]
        AP_KEPSEK["AP Ruang GR<br/>IP: 10.10.10.14<br/>(Kepsek / Admin)"]
        AP_LT2["AP Lantai 2<br/>IP: 10.10.10.15<br/>(Selasar Siswa BYOD)"]
    end

    CORE_SW -->|"Kabel 7"| AP_KEPSEK
    CORE_SW -->|"Kabel 8"| AP_LT2

    %% Zona VVIP Lab Ujian TKA
    subgraph ZTKA["Zona VVIP Ujian TKA / CBT Online (Dedicated Gateway)"]
        R2["R2-TKA-GATEWAY<br/>WAN: 10.10.10.2/24<br/>LAN TJKT ether2: 192.168.20.1/24<br/>LAN MP ether3: 192.168.21.1/24<br/>LAN Proktor ether4: 192.168.22.1/24"]

        SW_TKA["Switch Utama Gigabit Lab TKA<br/>(Cascade Switch 16p Gigabit)"]
        PC_TJKT["42 PC Lab TJKT<br/>DHCP: 192.168.20.10 - .60"]
        PC_MP["40 PC Lab MP<br/>DHCP: 192.168.21.10 - .60"]
        SRV_PRK["Server Proktor & Pengawas<br/>IP: 192.168.22.10 - .20<br/>(Priority 1 - CIR 10M)"]

        R2 -->|"Trunk / Uplink LAN"| SW_TKA
        SW_TKA --> PC_TJKT
        SW_TKA --> PC_MP
        SW_TKA --> SRV_PRK
    end

    CORE_SW -->|"Kabel 9 VIP (10.10.10.2 - CIR 75M)"| R2
```

---

## 📊 3. Master Rencana Pengalamatan IP (IP Addressing Plan)

| No | Perangkat / Segmen | Port / Interface | Alamat IP | Subnet | Gateway | Rentang DHCP Pool | Keterangan |
|:--:|:---|:---:|:---:|:---:|:---:|:---:|:---|
| **1** | **`R1-CORE-ROUTER`** | `ether1` | Sesuai ISP | - | Modem ISP | - | Uplink Utama Internet |
| | | `ether2` | **`10.10.10.1`** | `/24` | - | - | Backbone Distribusi Sekolah |
| | | `loopback` | **`8.8.8.8`** | `/32` | - | - | Simulator Internet (Simulasi) |
| **2** | **Ruang Guru (AP 1, 2, 3)** | LAN | `10.10.10.11 - .13` | `/24` | `10.10.10.1` | - | Bridge Mode (Kanal 1, 6, 11) |
| | **Client Ruang Guru** | WiFi | Dinamis | `/24` | `10.10.10.1` | **`.100 - .200`** | DHCP dari Core Router |
| **3** | **AP Kepsek & Selasar** | LAN | `10.10.10.14 - .15` | `/24` | `10.10.10.1` | - | Bridge Mode |
| **4** | **`R2-TKA-GATEWAY`** | `ether1` | **`10.10.10.2`** | `/24` | `10.10.10.1` | - | Uplink Kabel 9 VIP |
| | ↳ **Lab TJKT (42 PC)** | `ether2` | **`192.168.20.1`** | `/24` | `192.168.20.1` | **`.10 - .60`** | PCQ 2M/1M (Lease 3 Hari) |
| | ↳ **Lab MP (40 PC)** | `ether3` | **`192.168.21.1`** | `/24` | `192.168.21.1` | **`.10 - .60`** | PCQ 2M/1M (Lease 3 Hari) |
| | ↳ **Server Proktor** | `ether4` | **`192.168.22.1`** | `/24` | `192.168.22.1` | **`.10 - .20`** | Priority 1 (CIR 10 Mbps) |
| **5** | **`R3-BENGKEL-TKJ`** | `ether1` | **`10.10.10.3`** | `/24` | `10.10.10.1` | - | Uplink Kabel 4 |
| | ↳ **Praktik TKJ** | `ether2` | **`192.168.30.1`** | `/24` | `192.168.30.1` | **`.10 - .50`** | Limit Simple Queue 15M |
| **6** | **`R4-BENGKEL-TBSM`** | `ether1` | **`10.10.10.4`** | `/24` | `10.10.10.1` | - | Uplink Kabel 5 |
| | ↳ **Praktik TBSM** | `ether2` | **`192.168.40.1`** | `/24` | `192.168.40.1` | **`.10 - .50`** | Limit Simple Queue 10M |
| **7** | **`R5-BENGKEL-MP`** | `ether1` | **`10.10.10.5`** | `/24` | `10.10.10.1` | - | Uplink Kabel 6 |
| | ↳ **Praktik MP** | `ether2` | **`192.168.50.1`** | `/24` | `192.168.50.1` | **`.10 - .50`** | Limit Simple Queue 15M |

---

## 📁 4. Struktur Direktori Repositori

```text
├── Konfigurasi Router & Mikrotik/
│   ├── Simulasi GNS3/                    # Script siap pakai untuk simulasi GNS3 (CHR)
│   │   ├── 01-R1-CORE-ROUTER.rsc         # (Simulator 8.8.8.8, Backbone, Bandwidth Server)
│   │   ├── 02-R2-TKA-GATEWAY.rsc         # (PCQ 2M/1M, Queue Tree, Lab TJKT & MP)
│   │   ├── 03-R3-BENGKEL-TKJ.rsc         # (Subnet 192.168.30.0/24)
│   │   ├── 04-R4-BENGKEL-TBSM.rsc        # (Subnet 192.168.40.0/24)
│   │   ├── 05-R5-BENGKEL-MP.rsc          # (Subnet 192.168.50.0/24)
│   │   └── README-SIMULASI-GNS3.md       # Panduan pengujian GNS3 & VPCS
│   │
│   └── Implementasi Asli/                # Script untuk hardware fisik MikroTik hAP lite
│       ├── 01-R1-CORE-ROUTER.rsc         # (ISP Fibernet 100M, FastTrack bypass)
│       ├── 02-R2-TKA-GATEWAY.rsc         # (Lightweight Mangle hemat CPU 650 MHz)
│       ├── 03-R3-BENGKEL-TKJ.rsc         # (Subnet Praktik TKJ)
│       ├── 04-R4-BENGKEL-TBSM.rsc        # (Subnet Praktik TBSM)
│       ├── 05-R5-BENGKEL-MP.rsc          # (Subnet Praktik MP)
│       └── README-IMPLEMENTASI-ASLI.md   # SOP Reset & Wiring Fisik
│
├── Data Sekolah/                         # Foto survei lapangan & backup eksisting
├── Dokumen PDF/                          # Berkas PDF laporan resmi proyek konsultasi
├── assets/                               # Diagram arsitektur & fishbone SVG
│
├── Laporan Komprehensif Optimalisasi Jaringan SMK Informatika Pasundan.docx # Berkas Laporan Utama
├── Analisis dan Strategi Prioritas TKA.md
├── Brainstorming dan Analysis Plan.md
├── Panduan Simulasi GNS3 dan Implementasi MikroTik.md
├── Instrumen Pengumpulan Data.md
├── Spesifikasi Infrastruktur Sekolah.md
└── Objektif.md
```

---

## 🚀 5. Cara Penggunaan

### A. Untuk Simulasi di GNS3:
1. Buka project di **GNS3**, pastikan node router menggunakan template **MikroTik CHR**.
2. Buka terminal console masing-masing router.
3. Import atau copy-paste isi file dari folder `Konfigurasi Router & Mikrotik/Simulasi GNS3/`.
4. Uji koneksi internet simulator: `/ping 8.8.8.8` dari router mana pun.
5. Panduan lengkap pengujian ada di [README-SIMULASI-GNS3.md](file:///d:/Belajar/Semester%205/Project/Project%20Konsultasi/Konfigurasi%20Router%20&%20Mikrotik/Simulasi%20GNS3/README-SIMULASI-GNS3.md).

### B. Untuk Implementasi Hardware Asli:
1. Reset router hAP lite: **No Default Configuration** & **Do Not Backup**.
2. Login Winbox via MAC Address.
3. Paste script dari folder `Konfigurasi Router & Mikrotik/Implementasi Asli/`.
4. Panduan kabel dan SOP hari-H ujian tersedia di [README-IMPLEMENTASI-ASLI.md](file:///d:/Belajar/Semester%205/Project/Project%20Konsultasi/Konfigurasi%20Router%20&%20Mikrotik/Implementasi%20Asli/README-IMPLEMENTASI-ASLI.md).

---

## 👥 Tim Konsultan
* **Muhammad Muhibin** — Sistem Telekomunikasi (Kelas 5A SISTEL)
* **Mitra:** SMK Informatika Pasundan
