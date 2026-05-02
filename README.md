# ✈️ MyFlightTracker — macOS App

Aplikasi macOS untuk memantau harga tiket pesawat, mendeteksi harga terendah secara otomatis, dan menganalisis pola harga terbaik berdasarkan jam, hari, dan maskapai.

---

## ℹ️ Tentang

**MyFlightTracker** adalah aplikasi macOS open-source yang membantu traveler Indonesia menemukan harga tiket pesawat terbaik. Aplikasi ini secara otomatis mengecek harga penerbangan secara berkala dan mengirim notifikasi macOS saat menemukan harga yang lebih rendah dari semua rekor harga sebelumnya.

- 🎯 **Harga historis per rute + maskapai + kelas kabin** — tidak ada pencampuran data antar rute
- 📊 **Pola harga** — identifikasi jam dan hari termurah untuk terbang
- 🔔 **Notifikasi real-time** — langsung tahu saat ada harga terbaik
- 🌐 **Data dari Google Flights** — harga terbaru langsung dari sumber
- 🤖 **Anti-deteksi** — random delay, rotasi user-agent, human-like behavior agar tidak diblokir

---

## 🚀 Fitur Utama

| Fitur | Deskripsi |
|-------|-----------|
| 🔔 **Notifikasi Harga Terendah** | Notifikasi otomatis saat harga penerbangan lebih rendah dari semua harga yang pernah tercatat |
| ✈️ **Multi Maskapai** | Pantau semua maskapai sekaligus untuk rute yang sama (Garuda, Lion Air, Batik Air, dll) |
| 📊 **Grafik Riwayat Harga** | Visualisasi perubahan harga dari waktu ke waktu per maskapai |
| 🕐 **Analisis Pola** | Temukan jam keberangkatan dan hari dalam seminggu dengan harga terendah rata-rata |
| 🗓️ **Rentang Tanggal Fleksibel** | Cek harga untuk N hari ke depan atau rentang tanggal tertentu (misal: seluruh Juni 2026) |
| 🖥️ **Menu Bar Widget** | Akses cepat harga terbaru dari menu bar macOS tanpa buka window utama |
| 📤 **Export CSV** | Export data untuk analisis lanjutan di Excel/Google Sheets |
| 🔄 **Auto-monitoring** | Cek harga secara otomatis dengan interval yang bisa dikonfigurasi |

---

## 📋 Cara Menggunakan

### 1. Pertama Kali

1. **Buka aplikasi** — `MyFlightTracker.app`
2. Klik **"Tambah Rute"** di sidebar atau tombol di layar selamat datang
3. Pilih kota asal, tujuan, maskapai (atau "Semua Maskapai"), dan kelas penerbangan
4. Klik **"Start Monitoring"** di toolbar

### 2. Monitoring Otomatis

- Aplikasi akan memeriksa harga secara otomatis sesuai interval yang ditentukan (default: setiap 1 jam)
- Notifikasi macOS dikirim otomatis saat harga baru lebih rendah dari semua harga sebelumnya

### 3. Memahami Notifikasi

```
✈️ Harga Terendah! Jakarta (CGK) → Bali (DPS)
Garuda Indonesia GA408 – Rp750.000
Terbang: Sel, 6 Mei 2026 07:00
Hemat Rp100.000 dari harga terendah sebelumnya!
```

### 4. Analisis Pola Harga

Buka tab **"Pola"** di detail rute untuk melihat:
- **Jam terbaik**: jam keberangkatan dengan rata-rata harga terendah
- **Hari terbaik**: hari dalam seminggu dengan rata-rata harga terendah
- **Bar chart** harga rata-rata per jam dan per hari

---

## 🔧 Sumber Data Harga

### Google Flights Scraper (default — data nyata)

Aplikasi mengambil data harga langsung dari **Google Flights** menggunakan browser automation (Playwright) dengan teknik anti-deteksi:

- **Tidak memerlukan API key** — data diambil langsung dari halaman Google Flights
- **Batch mode** — 1 browser session untuk seluruh rentang tanggal (lebih cepat & aman)
- **Anti-deteksi**: random delay 5–18 detik antar request, rotasi user-agent, human-like scrolling, fingerprint randomization
- **Estimasi waktu**: cek 31 hari ≈ 7–10 menit

> ⚠️ **Amadeus API (lama):** Amadeus Developer API akan berakhir layanan pada **Juli 2026**. Aplikasi ini sudah migrasi sepenuhnya ke mekanisme Google Flights scraper.

### Mode Demo

Tanpa koneksi internet, aplikasi berjalan dalam **mode demo** dengan data harga simulasi yang realistis:

- Harga mencerminkan pola nyata (Selasa termurah, Jumat/Sabtu termahal)
- Jam dini hari & malam lebih murah dari jam sibuk
- Harga berfluktuasi ±15% setiap pengecekan

---

## 🗓️ Mengatur Rentang Tanggal

Aplikasi mendukung dua mode pengecekan tanggal:

1. **N Hari ke Depan** — otomatis cek N hari dari hari ini
2. **Rentang Tanggal Tertentu** — pilih tanggal mulai & selesai secara eksplisit

Untuk cek seluruh bulan (misal: 1–30 Juni 2026):
1. Buka **Pengaturan** → tab "Tanggal yang Dicek"
2. Pilih **"Rentang Tanggal Tertentu"**
3. Gunakan pintasan cepat seperti "Jun 2026" atau setel manual tanggal mulai & selesai
4. Preview akan menampilkan jumlah tanggal yang akan dicek

---

## 🏗️ Build dari Source

### Prasyarat
- macOS 14 (Sonoma) atau lebih baru
- Swift 5.9+
- Python 3.11+ dengan `uv` dan `playwright` (untuk scraping harga nyata)

### Install dependencies
```bash
# Install uv (Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install playwright untuk scraping
uv tool install playwright
playwright install chromium
```

### Build
```bash
cd FlightTracker
swift build -c release
bash build_app.sh
open MyFlightTracker.app
```

### Development build
```bash
swift build
.build/debug/FlightTracker
```

---

## 📁 Struktur Proyek

```
FlightTracker/
├── Sources/FlightTracker/
│   ├── FlightTrackerApp.swift      # Entry point, AppDelegate, menu commands
│   ├── Models.swift                # Data models (Airport, Route, FlightOffer, PriceRecord, dll)
│   ├── DataStore.swift             # Persistence (JSON files di Application Support)
│   ├── FlightScraper.swift         # Demo scraper + scraper config
│   ├── GoogleFlightsScraper.swift  # Google Flights batch scraper (Swift → scraper.py bridge)
│   ├── CheckScheduler.swift        # Auto-check scheduler + notification engine
│   ├── MenuBarWidget.swift         # macOS menu bar popover widget
│   └── Views/
│       ├── MainView.swift          # Window utama dengan sidebar navigation
│       ├── AddRouteView.swift      # Form tambah rute baru
│       ├── RouteDetailView.swift   # Detail rute: offers, history, pattern tabs
│       ├── PriceChartView.swift    # Grafik riwayat harga + analisis pola
│       ├── SettingsView.swift      # Pengaturan rentang tanggal, interval, notifikasi
│       └── AlertsHistoryView.swift # Riwayat lengkap notifikasi harga
├── scraper.py                      # Google Flights scraper (Python/Playwright)
├── Package.swift
├── build_app.sh                    # Script build .app bundle + DMG
└── README.md
```

---

## 💾 Data Tersimpan

Data disimpan di:
```
~/Library/Application Support/MyFlightTracker/
├── tracked_routes.json    # Rute yang dipantau
├── price_history.json     # Semua data harga historis (max 10.000 record)
└── check_sessions.json    # Log setiap sesi pengecekan (max 500)
```

---

## 🗺️ Rute yang Didukung

**Indonesia Domestik:**
- Jakarta (CGK) ↔ Bali (DPS), Surabaya (SUB), Makassar (UPG), Medan (KNO), Balikpapan (BPN), Yogyakarta (JOG), Solo (SOC), Palembang (PLM), Padang (PDG)

**International:**
- Jakarta ↔ Singapore (SIN), Kuala Lumpur (KUL), Bangkok (BKK), Dubai (DXB), Doha (DOH), Sydney (SYD)

**Maskapai yang Didukung:**
- Garuda Indonesia (GA), Lion Air (JT), Batik Air (ID), Sriwijaya Air (SJ), Wings Air (IW), AirAsia Indonesia (QZ), Nam Air (IN), Citilink (QG), TransNusa (TN), Singapore Airlines (SQ), Malaysia Airlines (MH), Emirates (EK), Qatar Airways (QR)

---

## 🔮 Cara Kerja Logika Harga Terendah

```
Hari 1: Rp 1.000.000 → Dicatat sebagai minimum (pertama kali)
Hari 2: Rp 1.250.000 → Lebih tinggi, tidak ada notifikasi
Hari 3: Rp 1.150.000 → Masih lebih tinggi dari hari 1, tidak ada notifikasi
Hari 4: Rp   980.000 → ✅ LEBIH RENDAH dari Rp 1.000.000 → NOTIFIKASI!
         "Harga terendah! Hemat Rp 20.000 dari sebelumnya"
```

Perbandingan dilakukan **per rute + per maskapai + per kelas kabin**:
- `CGK-DPS + GA + Economy` dibandingkan dengan data historis `CGK-DPS + GA + Economy` saja
- Tidak tercampur dengan rute atau maskapai lain

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Aksi |
|----------|------|
| `⌘R` | Cek harga sekarang |
| `⌘⇧M` | Toggle start/stop monitoring |
| `⌘⇧Q` | Hentikan semua monitoring & keluar |
| `⌘,` | Buka pengaturan |
