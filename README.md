# ✈️ MyFlightTracker — macOS App

Aplikasi macOS untuk memantau harga tiket pesawat, mendeteksi harga terendah secara otomatis, dan menganalisis pola harga terbaik berdasarkan tanggal, jam, hari, dan maskapai.

---

## ℹ️ Tentang

**MyFlightTracker** adalah aplikasi macOS open-source yang membantu traveler menemukan harga tiket pesawat terbaik. Aplikasi ini secara otomatis mengecek harga penerbangan secara berkala dan mengirim notifikasi macOS saat menemukan harga yang lebih rendah dari semua rekor harga sebelumnya.

- 🎯 **Harga historis per rute + maskapai + kelas kabin** — tidak ada pencampuran data antar rute
- 📅 **Tanggal keberangkatan** — ditampilkan di tab Riwayat dan Pola, termasuk rekap harga terendah/tertinggi beserta detail tanggal, maskapai, dan nomor penerbangan
- 📊 **Pola harga** — identifikasi jam dan hari termurah untuk terbang
- 🔔 **Notifikasi real-time** — langsung tahu saat ada harga terbaik
- 🌐 **Data dari Google Flights** — harga terbaru langsung dari sumber, tanpa API key
- 🤖 **Anti-deteksi** — random delay, rotasi user-agent, human-like behavior
- 🔄 **Auto Update** — perbarui aplikasi cukup dengan browse file `.dmg` terbaru

---

## 🚀 Fitur Utama

| Fitur | Deskripsi |
|-------|-----------|
| 🔔 **Notifikasi Harga Terendah** | Notifikasi otomatis saat harga penerbangan lebih rendah dari semua harga yang pernah tercatat |
| ✈️ **Multi Maskapai** | Pantau semua maskapai sekaligus untuk rute yang sama (Garuda, Lion Air, Batik Air, dll) |
| 📅 **Tanggal di Riwayat & Pola** | Setiap data harga mencantumkan tanggal keberangkatan aktual, nomor penerbangan, dan jam |
| 📊 **Grafik Riwayat Harga** | Visualisasi perubahan harga dari waktu ke waktu per maskapai |
| 🕐 **Analisis Pola** | Temukan jam keberangkatan dan hari termurah; tampilkan harga terendah/tertinggi dengan tanggal lengkap |
| 🗓️ **Rentang Tanggal Fleksibel** | Cek harga untuk N hari ke depan atau rentang tanggal tertentu (misal: seluruh Agustus 2026) |
| 🖥️ **Menu Bar Widget** | Akses cepat harga terbaru dari menu bar macOS |
| 📤 **Export CSV** | Export data untuk analisis di Excel/Google Sheets |
| 🔄 **Auto Update** | Update aplikasi langsung dari file `.dmg` tanpa reinstall manual |

---

## 📋 Cara Menggunakan

### 1. Pertama Kali

1. **Buka aplikasi** — `MyFlightTracker.app`
2. Klik **"Tambah Rute"** di sidebar
3. Ketik nama kota, nama bandara, atau kode IATA di kolom pencarian (autocomplete)
4. Pilih maskapai (atau "Semua Maskapai") dan kelas penerbangan
5. Klik **"Start Monitoring"** di toolbar

### 2. Monitoring Otomatis

- Aplikasi memeriksa harga secara otomatis sesuai interval yang ditentukan (default: setiap 1 jam)
- Notifikasi macOS dikirim otomatis saat harga baru lebih rendah dari semua harga sebelumnya

### 3. Memahami Notifikasi

```
✈️ Harga Terendah! Jakarta (CGK) → Bali (DPS)
Garuda Indonesia GA408 – Rp750.000
Terbang: Sel, 10 Jun 2026 07:00
Hemat Rp100.000 dari harga terendah sebelumnya!
```

### 4. Tab Riwayat

Buka tab **"Riwayat"** di detail rute untuk melihat:
- **Kolom "Berangkat"** — tanggal keberangkatan aktual setiap penerbangan yang tercatat
- Baris harga terendah ditandai warna **hijau**
- Kartu ringkasan menampilkan tanggal + maskapai untuk harga terendah dan tertinggi

### 5. Tab Pola

Buka tab **"Pola"** di detail rute untuk melihat:
- **Jam terbaik** — jam keberangkatan dengan rata-rata harga terendah
- **Hari terbaik** — hari dalam seminggu dengan rata-rata harga terendah
- **Harga Terendah yang Pernah Tercatat** — detail lengkap: tanggal, maskapai, nomor penerbangan, jam
- **Harga Tertinggi yang Pernah Tercatat** — detail yang sama untuk referensi

---

## 🔄 Update Aplikasi

MyFlightTracker mendukung **auto update via file `.dmg`**:

1. Download versi terbaru dari [GitHub Releases](https://github.com/leoui/MyFlightTracker/releases)
2. Buka aplikasi → **Pengaturan** (⚙️) → scroll ke bagian **"Update Aplikasi"**
3. Klik **"Browse & Update dari .dmg"**
4. Pilih file `.dmg` yang sudah di-download
5. Aplikasi akan otomatis:
   - Mount DMG dan menemukan `.app` di dalamnya
   - Mengganti versi lama dengan versi baru
   - Re-sign dan **restart otomatis** ✅

---

## 🔧 Sumber Data Harga

### Google Flights Scraper (default — data nyata)

Aplikasi mengambil data harga langsung dari **Google Flights** menggunakan browser automation (Playwright) tanpa API key:

- **Batch mode** — 1 sesi browser untuk seluruh rentang tanggal
- **Anti-deteksi**: random delay 5–18 detik, rotasi user-agent, human-like scrolling & mouse movement
- **Estimasi waktu**: cek 31 hari ≈ 7–10 menit

> ⚠️ **Amadeus API (lama):** Amadeus Developer API akan berakhir layanan pada **Juli 2026**. Aplikasi ini sudah migrasi sepenuhnya ke Google Flights scraper.

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

Pintasan cepat tersedia untuk: 7 hari, 14 hari, 30 hari, dan setiap bulan ke depan.

---

## 🗺️ Bandara yang Didukung (95 Bandara)

Gunakan kolom **search/autocomplete** untuk menemukan bandara — cukup ketik nama kota, kode IATA, atau nama bandara.

### 🇮🇩 Domestik Indonesia (50 Bandara)

**Jawa**
| Kode | Kota | Bandara |
|------|------|---------|
| CGK | Jakarta | Soekarno-Hatta International |
| HLP | Jakarta | Halim Perdanakusuma |
| BDO | Bandung | Husein Sastranegara |
| KJT | Majalengka | Kertajati International |
| SRG | Semarang | Achmad Yani International |
| JOG | Yogyakarta | Adisutjipto International |
| YIA | Yogyakarta | Yogyakarta International |
| SOC | Solo | Adisumarmo International |
| SUB | Surabaya | Juanda International |
| MLG | Malang | Abdul Rachman Saleh |

**Bali & Nusa Tenggara**
| Kode | Kota | Bandara |
|------|------|---------|
| DPS | Bali | Ngurah Rai International |
| LOP | Lombok | Lombok International |
| BMU | Bima | Sultan Muhammad Salahudin |
| LBJ | Labuan Bajo | Komodo |
| TMC | Sumba | Tambolaka |
| KOE | Kupang | El Tari |

**Sumatra**
| Kode | Kota | Bandara |
|------|------|---------|
| KNO | Medan | Kualanamu International |
| BTJ | Banda Aceh | Sultan Iskandar Muda |
| PDG | Padang | Minangkabau International |
| PKU | Pekanbaru | Sultan Syarif Kasim II |
| PLM | Palembang | Sultan Mahmud Badaruddin II |
| BKS | Bengkulu | Fatmawati Soekarno |
| TKG | Bandar Lampung | Radin Inten II |
| PGK | Pangkal Pinang | Depati Amir |
| TNJ | Tanjung Pinang | Raja Haji Fisabilillah |
| BTH | Batam | Hang Nadim International |

**Kalimantan**
| Kode | Kota | Bandara |
|------|------|---------|
| BPN | Balikpapan | Sultan Aji Muhammad Sulaiman |
| BDJ | Banjarmasin | Syamsudin Noor |
| PNK | Pontianak | Supadio International |
| TRK | Tarakan | Juwata International |
| BEJ | Berau | Kalimarau |
| KTG | Ketapang | Rahadi Oesman |
| TJG | Tanjung | Warukin |
| AAP | Samarinda | Aji Pangeran Tumenggung Pranoto |

**Sulawesi**
| Kode | Kota | Bandara |
|------|------|---------|
| UPG | Makassar | Sultan Hasanuddin International |
| MDC | Manado | Sam Ratulangi International |
| KDI | Kendari | Haluoleo |
| GTO | Gorontalo | Jalaluddin |
| PLW | Palu | Mutiara SIS Al-Jufrie |
| LUW | Luwuk | Bubung |
| PSJ | Poso | Kasiguncu |
| BUW | Buton | Baubau |

**Maluku & Papua**
| Kode | Kota | Bandara |
|------|------|---------|
| AMQ | Ambon | Pattimura International |
| TTE | Ternate | Sultan Babullah |
| DJJ | Jayapura | Sentani |
| BIK | Biak | Frans Kaisiepo |
| SOQ | Sorong | Dominique Edward Osok |
| TIM | Timika | Mozes Kilangin |
| MKW | Manokwari | Rendani |
| NBX | Nabire | Nabire |
| WMX | Wamena | Wamena |
| MLN | Merauke | Mopah |
| KNG | Kaimana | Kaimana |

---

### 🌏 Internasional (45 Bandara)

**Asia Tenggara**
| Kode | Kota | Negara |
|------|------|--------|
| SIN | Singapore | Singapore |
| KUL | Kuala Lumpur | Malaysia |
| BKK | Bangkok (Suvarnabhumi) | Thailand |
| DMK | Bangkok (Don Mueang) | Thailand |
| CNX | Chiang Mai | Thailand |
| SGN | Ho Chi Minh City | Vietnam |
| HAN | Hanoi | Vietnam |
| MNL | Manila | Philippines |
| PNH | Phnom Penh | Cambodia |
| REP | Siem Reap | Cambodia |
| RGN | Yangon | Myanmar |

**Asia Timur**
| Kode | Kota | Negara |
|------|------|--------|
| HKG | Hong Kong | Hong Kong |
| TPE | Taipei | Taiwan |
| NRT | Tokyo (Narita) | Japan |
| HND | Tokyo (Haneda) | Japan |
| KIX | Osaka | Japan |
| FUK | Fukuoka | Japan |
| ICN | Seoul | South Korea |
| PVG | Shanghai | China |
| PEK | Beijing | China |
| CAN | Guangzhou | China |
| KMG | Kunming | China |

**Asia Selatan & Timur Tengah**
| Kode | Kota | Negara |
|------|------|--------|
| DEL | New Delhi | India |
| BOM | Mumbai | India |
| MLE | Male | Maldives |
| DXB | Dubai | UAE |
| DWC | Dubai (Al Maktoum) | UAE |
| AUH | Abu Dhabi | UAE |
| DOH | Doha | Qatar |
| JED | Jeddah | Saudi Arabia |
| RUH | Riyadh | Saudi Arabia |
| MED | Madinah | Saudi Arabia |
| IST | Istanbul | Turkey |

**Oceania & Eropa**
| Kode | Kota | Negara |
|------|------|--------|
| SYD | Sydney | Australia |
| MEL | Melbourne | Australia |
| PER | Perth | Australia |
| AKL | Auckland | New Zealand |
| LHR | London | United Kingdom |
| CDG | Paris | France |
| FRA | Frankfurt | Germany |
| AMS | Amsterdam | Netherlands |
| FCO | Rome | Italy |
| MUC | Munich | Germany |

---

## ✈️ Maskapai yang Didukung (42 Maskapai)

**Indonesia:** Garuda (GA), Lion Air (JT), Sriwijaya Air (SJ), Batik Air (ID), Wings Air (IW), Nam Air (IN), AirAsia Indonesia (QZ), Indonesia AirAsia X (XT), Citilink (QG), TransNusa (TN), Aviastar (MV)

**Asia Tenggara:** Singapore Airlines (SQ), Scoot (TR), Malaysia Airlines (MH), AirAsia (AK), Thai Airways (TG), Thai AirAsia (FD), Vietnam Airlines (VN), Philippine Airlines (PR), Cathay Pacific (CX), Pacific Airlines (BL)

**Asia Timur:** Japan Airlines (JL), ANA (NH), Korean Air (KE), Asiana Airlines (OZ), China Eastern (MU), Air China (CA), China Southern (CZ), EVA Air (BR), China Airlines (CI)

**Timur Tengah:** Emirates (EK), Qatar Airways (QR), Etihad Airways (EY), Turkish Airlines (TK), Saudia (SV)

**Eropa & Oceania:** British Airways (BA), Lufthansa (LH), Air France (AF), KLM (KL), Qantas (QF), Air New Zealand (NZ)

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
- `CGK-DPS + GA + Economy` dibandingkan dengan historis `CGK-DPS + GA + Economy` saja
- Tidak tercampur dengan rute atau maskapai lain

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
│   ├── AutoUpdater.swift           # Auto update via file .dmg (mount, replace, restart)
│   ├── CheckScheduler.swift        # Auto-check scheduler + notification engine
│   ├── MenuBarWidget.swift         # macOS menu bar popover widget
│   └── Views/
│       ├── MainView.swift          # Window utama dengan sidebar navigation
│       ├── AddRouteView.swift      # Form tambah rute baru + search/autocomplete bandara
│       ├── RouteDetailView.swift   # Detail rute: penawaran, riwayat, pola
│       ├── PriceChartView.swift    # Grafik harga + kartu pola + detail tanggal
│       ├── SettingsView.swift      # Pengaturan tanggal, interval, notifikasi, update
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

## ⌨️ Keyboard Shortcuts

| Shortcut | Aksi |
|----------|------|
| `⌘R` | Cek harga sekarang |
| `⌘⇧M` | Toggle start/stop monitoring |
| `⌘⇧Q` | Hentikan semua monitoring & keluar |
| `⌘,` | Buka pengaturan |

---

## 📦 Changelog

### v1.3.0
- 📅 Tab **Riwayat**: kolom baru "Berangkat" menampilkan tanggal keberangkatan aktual; baris harga terendah berwarna hijau; kartu ringkasan menampilkan tanggal + maskapai
- 📊 Tab **Pola**: kartu "Harga Terendah" mencantumkan tanggal, maskapai, dan jam; dua kartu detail baru — "Harga Terendah yang Pernah Tercatat" dan "Harga Tertinggi yang Pernah Tercatat" dengan info penerbangan lengkap

### v1.2.0
- 🔄 **Auto Update via DMG** — browse file `.dmg` terbaru, app mengganti dirinya sendiri dan restart otomatis
- Nomor versi ditampilkan di halaman Pengaturan

### v1.1.0
- ✈️ **95 bandara** — 50 domestik Indonesia + 45 internasional (Asia, Timur Tengah, Eropa, Oceania)
- ✈️ **42 maskapai** dari seluruh dunia
- 🔍 **Search / Autocomplete** bandara — ketik kode IATA, nama kota, atau nama bandara; hasil dibagi seksi Domestik 🇮🇩 dan Internasional 🌏

### v1.0.0
- Rilis perdana
- Monitoring harga otomatis via Google Flights (Playwright, tanpa API key)
- Anti-deteksi: batch mode, random delay 5–18 detik, rotasi user-agent, human-like behavior
- Menu bar widget, notifikasi harga terendah, grafik riwayat, analisis pola
- Export CSV, mode demo offline
