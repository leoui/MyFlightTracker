# ✈️ Flight Price Tracker — macOS App

Aplikasi macOS untuk memantau harga tiket pesawat, mendeteksi harga terendah secara otomatis, dan menganalisis pola harga terbaik berdasarkan jam, hari, dan maskapai.

---

## 🚀 Fitur Utama

| Fitur | Deskripsi |
|-------|-----------|
| 🔔 **Notifikasi Harga Terendah** | Notifikasi otomatis saat harga penerbangan lebih rendah dari semua harga yang pernah tercatat |
| ✈️ **Multi Maskapai** | Pantau semua maskapai sekaligus untuk rute yang sama (Garuda, Lion Air, Batik Air, dll) |
| 📊 **Grafik Riwayat Harga** | Visualisasi perubahan harga dari waktu ke waktu per maskapai |
| 🕐 **Analisis Pola** | Temukan jam keberangkatan dan hari dalam seminggu dengan harga terendah rata-rata |
| 🗓️ **Cek N Hari ke Depan** | Cek harga untuk beberapa hari ke depan sekaligus |
| 🖥️ **Menu Bar Widget** | Akses cepat harga terbaru dari menu bar macOS tanpa buka window utama |
| 📤 **Export CSV** | Export data untuk analisis lanjutan di Excel/Google Sheets |
| 🔄 **Auto-monitoring** | Cek harga secara otomatis dengan interval yang bisa dikonfigurasi |

---

## 📋 Cara Menggunakan

### 1. Pertama Kali

1. **Buka aplikasi** — `FlightTracker.app`
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

## 🔧 Konfigurasi API

### Mode Demo (default)
Tanpa konfigurasi apapun, aplikasi berjalan dalam **mode demo** dengan data harga simulasi yang realistis:
- Harga mencerminkan pola nyata (Selasa termurah, Jumat/Sabtu termahal)
- Jam dini hari & malam lebih murah dari jam sibuk
- Harga berfluktuasi ±15% setiap pengecekan

### Mode Amadeus API (data nyata)
Untuk data harga penerbangan nyata, gunakan **Amadeus Test API** (gratis):

1. Daftar di [developers.amadeus.com](https://developers.amadeus.com/register)
2. Buat aplikasi baru → dapatkan **API Key** dan **API Secret**
3. Buka **Settings** di aplikasi (ikon gear di toolbar)
4. Masukkan API Key dan API Secret
5. Klik **Simpan** → aplikasi otomatis beralih ke data nyata

> 💡 Amadeus test environment menyediakan data harga penerbangan nyata secara gratis dengan limit yang cukup untuk personal use.

---

## 🏗️ Build dari Source

### Prasyarat
- macOS 14 (Sonoma) atau lebih baru
- Xcode Command Line Tools atau Xcode
- Swift 5.9+

### Build
```bash
cd FlightTracker
swift build -c release
bash build_app.sh
open FlightTracker.app
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
│   ├── FlightScraper.swift         # Amadeus API + Demo scraper
│   ├── CheckScheduler.swift        # Auto-check scheduler + notification engine
│   ├── MenuBarWidget.swift         # macOS menu bar popover widget
│   └── Views/
│       ├── MainView.swift          # Window utama dengan sidebar navigation
│       ├── AddRouteView.swift      # Form tambah rute baru
│       ├── RouteDetailView.swift   # Detail rute: offers, history, pattern tabs
│       ├── PriceChartView.swift    # Grafik riwayat harga + analisis pola
│       ├── SettingsView.swift      # Pengaturan API key, interval, notifikasi
│       └── AlertsHistoryView.swift # Riwayat lengkap notifikasi harga
├── Package.swift
├── build_app.sh                    # Script build .app bundle
└── README.md
```

---

## 💾 Data Tersimpan

Data disimpan di:
```
~/Library/Application Support/FlightTracker/
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
- Garuda Indonesia (GA), Lion Air (JT), Batik Air (ID), Sriwijaya Air (SJ), Wings Air (IW), AirAsia Indonesia (QZ), Nam Air (IN), Singapore Airlines (SQ), Malaysia Airlines (MH), Emirates (EK), Qatar Airways (QR)

---

## 🔮 Cara Kerja Logika Harga Terendah

```
Hari 1: Rp 1.000.000 → Dicatat sebagai minimum (pertama kali)
Hari 2: Rp 1.250.000 → Lebih tinggi, tidak ada notifikasi
Hari 3: Rp 1.150.000 → Masih lebih tinggi dari hari 1, tidak ada notifikasi  
Hari 4: Rp   980.000 → ✅ LEBIH RENDAH dari Rp 1.000.000 → NOTIFIKASI!
         "Harga terendah! Hemat Rp 20.000 dari sebelumnya"
```

Perbandingan dilakukan **per rute + per maskapai + per kelas**:
- `CGK-DPS + GA + Economy` dibandingkan dengan data historis `CGK-DPS + GA + Economy` saja
- Tidak tercampur dengan rute atau maskapai lain

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Aksi |
|----------|------|
| `⌘R` | Cek harga sekarang |
| `⌘⇧M` | Toggle start/stop monitoring |
| `⌘,` | Buka pengaturan |
