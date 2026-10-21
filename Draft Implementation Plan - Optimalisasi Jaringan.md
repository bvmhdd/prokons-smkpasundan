<div style="font-family: 'Times New Roman', Times, serif; background-color: #121212; color: #e0e0e0; padding: 40px; line-height: 1.6; max-width: 900px; margin: auto; border: 1px solid #333; box-shadow: 0 4px 8px rgba(0,0,0,0.5);">

<div style="text-align: center; margin-bottom: 40px;">
  <!-- PLACEHOLDER LOGO UPI -->
  <img src="[MASUKKAN_PATH_LOGO_UPI_DI_SINI.png]" alt="Logo Universitas Pendidikan Indonesia" width="150" style="margin-bottom: 20px; border-radius: 50%; background-color: white; padding: 5px;" />
  
  <h1 style="color: #ffffff; text-transform: uppercase; border-bottom: 2px solid #555; padding-bottom: 15px; margin-bottom: 10px; font-size: 28px;">
    Draft Implementation Plan
  </h1>
  <h2 style="color: #b3b3b3; font-weight: normal; font-size: 20px; margin-top: 0;">
    Optimalisasi Infrastruktur Jaringan (Zero-Cost Approach)
  </h2>
  <br>
  <p style="font-size: 16px; margin: 5px 0;"><strong>Mitra:</strong> SMK Informatika Pasundan</p>
  <p style="font-size: 16px; margin: 5px 0;"><strong>Fokus:</strong> Pemerataan Beban Jaringan, Stabilitas Ujian TKA, dan Penghilangan <em>Bottleneck</em></p>
</div>

<div style="margin-bottom: 30px;">
  <h3 style="color: #ffffff; border-left: 4px solid #4CAF50; padding-left: 10px;">1. Identifikasi Masalah (Existing Kondisi)</h3>
  <p>Dari hasil peninjauan (<em>assessment</em>) terhadap topologi dan konfigurasi awal jaringan sekolah, ditemukan beberapa isu krusial yang menyebabkan keluhan koneksi terputus dan lambat:</p>
  <ol style="padding-left: 20px;">
    <li style="margin-bottom: 10px;"><strong>Pemutusan Koneksi Otomatis (Kick-out) di Ruang Guru:</strong> 1 unit AP Tenda kelas rumahan dipaksa menanggung beban puluhan perangkat secara bersamaan. Hardware mengalami batas maksimal (<em>overload</em>).</li>
    <li style="margin-bottom: 10px;"><strong>Limitasi Kecepatan Ekstrem (Bottleneck):</strong> Konfigurasi pada MikroTik hAP Lite yang digunakan membatasi <em>port</em> utama distribusi (ether3 & ether4) menjadi hanya <strong>5 Mbps</strong>, menghambat kapasitas riil ISP Fibernet yang mencapai 100 Mbps.</li>
    <li style="margin-bottom: 10px;"><strong>Kelelahan CPU Router (Single Point of Failure):</strong> 1 unit MikroTik hAP Lite (650MHz) dipaksa mengolah antrean data dari Lab TKA, Bengkel, dan Ruang Guru, menyebabkan beban kerja CPU hampir menyentuh 100%.</li>
    <li style="margin-bottom: 10px;"><strong>Topologi Berantai (Daisy-Chain):</strong> Jaringan ke Lab TKA dan Lantai 2 (OTKP) disambung secara seri dari satu perangkat ke perangkat lain, menyebabkan kerentanan total jika satu titik mati.</li>
    <li style="margin-bottom: 10px;"><strong>Penanganan Darurat TKA:</strong> Akibat poin 2 dan 4, pihak operator terpaksa melakukan tindakan darurat (menarik kabel langsung ke Modem ISP) setiap kali Ujian TKA berlangsung.</li>
  </ol>
</div>

<div style="margin-bottom: 30px;">
  <h3 style="color: #ffffff; border-left: 4px solid #4CAF50; padding-left: 10px;">2. Konsep Solusi: <em>Distributed Zero-Cost Architecture</em></h3>
  <p>Alih-alih menyarankan pihak sekolah untuk membeli <em>Core Router</em> tingkat <em>Enterprise</em> yang mahal, tim konsultan mengusulkan strategi <strong>Membagi Beban (Load Distribution)</strong> dengan <strong>100% Memanfaatkan Aset Menganggur (<em>Idle</em>)</strong> milik sekolah.</p>
  
  <div style="background-color: #1e1e1e; padding: 15px; border-radius: 5px; margin-top: 15px;">
    <strong style="color: #ffffff;">Aset Idle yang Akan Diberdayakan:</strong>
    <ul style="margin-top: 10px; margin-bottom: 0;">
      <li>3 dari 20 unit MikroTik hAP Lite yang tidak terpakai.</li>
      <li>5 unit Switch 16-Port Gigabit TP-Link.</li>
      <li>5 unit AP Tenda tambahan.</li>
    </ul>
  </div>
</div>

<div style="margin-bottom: 40px; text-align: center; background-color: #1a1a1a; padding: 20px; border-radius: 8px;">
  <h3 style="color: #ffffff; margin-top: 0;">Desain Topologi Baru</h3>
  
  <!-- PLACEHOLDER GAMBAR TOPOLOGI -->
  <!-- Silakan ganti bagian src="..." dengan nama file/path gambar topologi yang Anda upload tadi -->
  <img src="[MASUKKAN_NAMA_FILE_GAMBAR_TOPOLOGI_ANDA_DI_SINI.png]" alt="Gambar Topologi Jaringan Zero Cost" style="max-width: 100%; border: 1px solid #444; border-radius: 4px; box-shadow: 0 4px 8px rgba(0,0,0,0.5);" />
  
  <p style="color: #999; font-size: 14px; font-style: italic; margin-top: 15px;">Gambar 1: Skema Pemisahan Beban ke 3 Router MikroTik Berbeda</p>
</div>

<div style="margin-bottom: 30px;">
  <h3 style="color: #ffffff; border-left: 4px solid #4CAF50; padding-left: 10px;">3. Rencana Eksekusi (Tahapan Implementasi)</h3>
  
  <h4 style="color: #cccccc;">Tahap 1: Persiapan & Distribusi Inti (Core Distribution)</h4>
  <ul style="padding-left: 20px;">
    <li>Meletakkan 1 unit <strong>Switch Gigabit TP-Link</strong> di samping Modem ISP sebagai "Terminal Pusat".</li>
    <li>Mengambil 3 unit <strong>MikroTik hAP Lite</strong> dari gudang, melakukan <em>reset</em> konfigurasi penuh (kosong).</li>
    <li>Menghubungkan <em>port</em> WAN (ether1) dari ketiga MikroTik tersebut secara paralel ke Terminal Pusat.</li>
  </ul>

  <h4 style="color: #cccccc; margin-top: 20px;">Tahap 2: Konfigurasi per-Zona (Isolasi Beban)</h4>
  <ul style="padding-left: 20px;">
    <li style="margin-bottom: 8px;"><strong>Router #1 (Zona Guru):</strong> Fokus <em>setting</em> DHCP untuk melayani trafik ringan. Memasang 3 unit AP Tenda <em>idle</em> sekaligus di Ruang Guru (Bridge Mode, DHCP Off) dengan nama SSID terpisah (contoh: <code>Guru-1</code>, <code>Guru-2</code>) dan <em>channel</em> pancaran berbeda (1, 6, 11).</li>
    <li style="margin-bottom: 8px;"><strong>Router #2 (Zona Ujian TKA):</strong> Fokus <em>routing</em> statis, <strong>tanpa pembatasan <em>bandwidth</em></strong> sama sekali. Jalur LAN dihubungkan langsung ke 2 Switch Gigabit di Lab TKA. Tidak ada lagi tarikan kabel darurat.</li>
    <li><strong>Router #3 (Zona Bengkel & Siswa):</strong> Menerapkan limitasi (Queue Tree / Simple Queue) kecepatan untuk Bengkel TKJ, TBSM, MP, dan AP OSIS agar lalu lintas unduhan besar tidak mengganggu zona lain.</li>
  </ul>

  <h4 style="color: #cccccc; margin-top: 20px;">Tahap 3: Pengujian & Serah Terima (Testing & Commissioning)</h4>
  <ul style="padding-left: 20px;">
    <li><strong>Load Test Ruang Guru:</strong> Menghubungkan 30-40 perangkat secara acak ke ketiga AP Tenda untuk memastikan hilangnya gejala perangkat terlempar (<em>kick-out</em>).</li>
    <li><strong>Throughput Test Lab TKA:</strong> Melakukan tes kecepatan murni dari Lab TKA untuk memastikan tercapainya kapasitas maksimal tanpa tertahan <em>limit</em> 5 Mbps.</li>
  </ul>
</div>

<div style="margin-bottom: 10px;">
  <h3 style="color: #ffffff; border-left: 4px solid #4CAF50; padding-left: 10px;">4. Keuntungan (Benefit) Pendekatan Ini</h3>
  <ol style="padding-left: 20px;">
    <li style="margin-bottom: 8px;"><strong>Zero-Budget:</strong> Sekolah tidak perlu mengeluarkan biaya perangkat keras baru, menghemat puluhan juta rupiah.</li>
    <li style="margin-bottom: 8px;"><strong>Stabilitas Tingkat Tinggi:</strong> Kerusakan jaringan di Bengkel tidak akan mematikan koneksi di Ruang Guru atau Lab TKA karena "otak" pengendalinya terpisah.</li>
    <li><strong>Masa Pakai Hardware yang Panjang:</strong> Membagi tugas ke 3 MikroTik hAP Lite memastikan beban CPU dan utilisasi RAM selalu terjaga dalam batas aman (di bawah 40%).</li>
  </ol>
</div>

</div>
