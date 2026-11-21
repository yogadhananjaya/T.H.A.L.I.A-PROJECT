# 📖 Dokumentasi API & Integrasi Frontend T.H.A.L.I.A

**Aplikasi:** T.H.A.L.I.A (*Tri-Habitat Analysis & Climate Forecasting Intelligence*)  
**Platform:** Flutter Mobile (Android, iOS, Web Chrome)  
**Tim:** Ayam Kecap Paijo (Politeknik Astra) — Hackathon HACKSPHERE 2026  
**File Path:** `frontend/T.H.A.L.I.A-PROJECT/API.md`  

---

## 🌐 1. Konfigurasi Base URL Backend

Backend T.H.A.L.I.A dibangun dengan FastAPI (Port `8000`). Sesuaikan target URL pada Flutter berdasarkan target perangkat pengujian:

| Lingkungan Target | Base URL API | Keterangan |
| :--- | :--- | :--- |
| **Flutter Web (Chrome)** | `http://localhost:8000/api/v1` | Pengujian lokal via browser |
| **Android Emulator** | `http://10.0.2.2:8000/api/v1` | IP gateway default Android Emulator |
| **HP Fisik / Jaringan LAN** | `http://10.8.14.246:8000/api/v1` | IP Wi-Fi lokal laptop (Port 8000 sudah di-allow Firewall) |

> 💡 **Dokumentasi Interaktif Swagger:** Buka `http://localhost:8000/docs` di browser untuk menguji setiap endpoint secara langsung.

---

## 🧭 2. Pemetaan API per Layar / Tab Frontend

Setiap endpoint FastAPI di bawah ini bekerja secara spesifik untuk menghidupkan komponen UI pada Flutter:

```mermaid
flowchart TD
    Backend[FastAPI Backend :8000] -->|GET /telemetry/latest| Home[HomeTabScreen: Live Cards & Status]
    Backend -->|GET /comparison| Compare[HomeTabScreen: Hyperlocal vs BMKG Card]
    Backend -->|GET /telemetry/history| Chart[HomeTabScreen: Grafik Fl-Chart 30 Data]
    Backend -->|GET /alerts| History[HistoryTabScreen: Riwayat Bencana]
    Backend -->|GET /alerts/{id}/verify| Web3Modal[HistoryTabScreen: Modal Verifikasi On-Chain]
    Backend -->|GET /alerts/summary/stats| Stats[HistoryTabScreen: Counter Pill Safe/Alert/Danger]
    OSM[OpenStreetMap Tile CDN] -->|tile.openstreetmap.org| Map[MapsTabScreen: Peta GPS 100% Gratis]
```

---

## 📡 3. Rincian Endpoint, Lokasi Bekerja, & Fungsinya

### 🏠 A. Tab Beranda (Home Tab)

#### 1. Telemetri Real-time Terkini
* **Endpoint:** `GET /api/v1/telemetry/latest`
* **Bekerja di:** `HomeTabScreen` (`lib/screens/dashboard/home_tab_screen.dart`)
* **Fungsi di UI:**
  * Menampilkan suhu udara (°C), kelembapan (%), tekanan atmosfer (hPa), intensitas hujan (%), dan kelembapan tanah (%).
  * Menentukan warna tema status sistem di header:
    * 🟢 `Safe` (Aman / Hijau)
    * 🟡 `Alert` (Waspada / Kuning)
    * 🔴 `Danger` (Bahaya / Merah)
* **Contoh Response JSON:**
  ```json
  {
    "id": 142,
    "timestamp": "2026-11-21T13:45:00Z",
    "node_id": "ESP32-NODE-01",
    "location_name": "Cibatu, Cikarang Selatan, Bekasi",
    "latitude": -6.3378,
    "longitude": 107.1541,
    "temperature_c": 27.2,
    "humidity_pct": 78.5,
    "pressure_hpa": 1011.2,
    "rainfall_pct": 12.0,
    "is_raining": true,
    "soil_moisture_pct": 52.4,
    "status": "Safe",
    "status_reason": "AMAN: Kondisi seluruh habitat dalam batas normal.",
    "habitat_analysis": {
      "habitats": {
        "atmosphere": "Normal",
        "hydrosphere": "Light Rain",
        "lithosphere": "Normal"
      }
    }
  }
  ```

---

#### 2. Komparasi Hyperlocal vs BMKG Regional (*Fitur Unggulan*)
* **Endpoint:** `GET /api/v1/comparison`
* **Bekerja di:** Card Komparasi Cuaca `HomeTabScreen`
* **Fungsi di UI:**
  * Membuktikan **Granularity Advantage** kepada juri.
  * Menampilkan perbandingan *side-by-side* antara pembacaan sensor tanah/hujan lokal T.H.A.L.I.A dengan prakiraan BMKG Makro Stasiun Cikarang (`32.16.19.2001`).
* **Contoh Response JSON:**
  ```json
  {
    "location": "Cibatu, Cikarang Selatan",
    "timestamp": "2026-11-21T13:45:00Z",
    "local_telemetry": {
      "source": "T.H.A.L.I.A Physical ESP32 Node",
      "temperature_c": 22.0,
      "humidity_pct": 94.0,
      "pressure_hpa": 1003.0,
      "rainfall_pct": 82.0,
      "soil_moisture_pct": 89.0,
      "status": "Danger",
      "status_reason": "BAHAYA: Lithosphere: Tanah sangat jenuh air (89.0%), risiko longsor tinggi."
    },
    "bmkg_regional_forecast": {
      "region_name": "Cibatu, Cikarang Selatan (Bekasi)",
      "weather_desc": "Hujan Ringan",
      "temperature_c": 26.0,
      "humidity_pct": 80.0,
      "rainfall_probability_pct": 60.0,
      "source": "BMKG Open Data API (Regional Macro Station)"
    },
    "granularity_advantage": "KEUNGGULAN GRANULARITAS TERBUKTI: BMKG Regional hanya memprediksi Hujan Ringan makro, namun sensor hyperlocal T.H.A.L.I.A mendeteksi curah hujan intensif 82.0% dan saturasi tanah lereng 89.0% (Siaga Longsor).",
    "status": "Danger"
  }
  ```

---

#### 3. Riwayat Tren Sensor (Grafik Lingkungan)
* **Endpoint:** `GET /api/v1/telemetry/history?limit=30`
* **Bekerja di:** Widget Chart Fl-Chart di `HomeTabScreen`
* **Fungsi di UI:**
  * Merender grafik kurva naik-turunnya curah hujan, saturasi tanah, suhu, dan tekanan udara selama beberapa jam terakhir.

---

### 🗺️ B. Tab Peta & Pemantauan Titik Rawan (Maps Tab)

#### 1. OpenStreetMap Tile Server
* **Endpoint:** `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
* **Bekerja di:** `MapsTabScreen` (`lib/screens/dashboard/maps_tab_screen.dart`) & `InteractiveGpsMapCard` (`lib/widgets/interactive_gps_map_card.dart`)
* **Fungsi di UI:**
  * Merender peta interaktif (zoom, drag, pan) **100% gratis tanpa Google Maps API Key** dan tanpa tagihan kartu kredit.
  * Dilengkapi pin marker lokasi koordinat sensor ESP32 (`-6.3378, 107.1541`) dan zona radius pantau (5–15 km).

---

### 📜 C. Tab Riwayat & Verifikasi Blockchain (History Tab)

#### 1. Daftar Riwayat Insiden Terdaftar
* **Endpoint:** `GET /api/v1/alerts?limit=20`
* **Bekerja di:** List View `HistoryTabScreen` (`lib/screens/dashboard/history_tab_screen.dart`)
* **Fungsi di UI:**
  * Menampilkan kartu insiden yang pernah terjadi (Banjir, Longsor, Badai).
  * Menampilkan badge `VALID_ON_CHAIN` dengan nomor blok Ethereum / Hardhat dan hash transaksi.

---

#### 2. Verifikasi On-Chain Anti-Fraud (*Fitur Pertahanan dari Juri*)
* **Endpoint:** `GET /api/v1/alerts/{id}/verify`
* **Bekerja di:** Dialog / Pop-up "Audit Blockchain Integrity" pada `HistoryTabScreen`
* **Fungsi di UI:**
  * Saat user mengklik salah satu riwayat, frontend memanggil endpoint ini.
  * Backend akan mencocokkan ulang SHA-256 hash database lokal dengan hash yang tersimpan di Smart Contract `THALIARegistry.sol`.
  * Menjamin juri bahwa data riwayat bencana tidak bisa dimanipulasi oleh siapapun di database SQL.
* **Contoh Response JSON:**
  ```json
  {
    "incident_id": 1,
    "on_chain_status": "VALID_ON_CHAIN",
    "local_sha256": "4b68427f7a73e65922c22271dfad9c46ce1eb8f1ec608d08cb5f98cf48937989",
    "contract_sha256": "4b68427f7a73e65922c22271dfad9c46ce1eb8f1ec608d08cb5f98cf48937989",
    "transaction_hash": "0x391f5e8d87a6b23d9a101f3cf955893d93172e27643b177d6124ce7b545464da",
    "blockchain_block": 12,
    "smart_contract_address": "0x5FbDB2315678afecb367f032d93F642f64180aa3",
    "network": "Hardhat Localhost (Chain ID: 31337)",
    "verified_at": "2026-11-21T13:50:00Z",
    "message": "Audit Integritas Lolos: Hash telemetri lokal identik 100% dengan bukti on-chain di Smart Contract."
  }
  ```

---

#### 3. Statistik Ringkasan Insiden
* **Endpoint:** `GET /api/v1/alerts/summary/stats`
* **Bekerja di:** Filter Bar Atas `HistoryTabScreen`
* **Fungsi di UI:**
  * Menampilkan angka counter total bencana: `Semua (12)`, `Aman (8)`, `Waspada (3)`, `Bahaya (1)`.

---

### 📷 D. Tab Kamera & Laporan Warga (Lens Form Tab)

* **Bekerja di:** `CameraTabScreen` & `SubpageLensReportSheet` (`lib/widgets/dashboard/subpage_lens_report_sheet.dart`)
* **Fungsi di UI:**
  * Mengambil foto lapangan via kamera perangkat menggunakan `image_picker`.
  * Memungkinkan warga mengirim laporan insiden manual (kategori: Banjir, Gempa, Tanah Longsor, Kebakaran Hutan) beserta teks deskripsi.

---

### 🧪 E. Endpoint Khusus Live Demo Juri (Simulator Inject)

* **Endpoint:** `POST /api/v1/simulator/inject`
* **Request Body:**
  ```json
  {
    "scenario": "danger_landslide",
    "location": "Lereng Bukit Selatan, Titik B"
  }
  ```
* **Fungsi:**
  * Menginjeksi data buatan secara instan tanpa perlu menunggu hujan sungguhan.
  * Pilihan skenario:
    1. `safe_normal`: Cuaca cerah dan tanah kering normal.
    2. `alert_storm`: Badai hujan deras dan angin kencang (Waspada).
    3. `danger_landslide`: Kejenuhan tanah 88% dan hujan ekstrem (Bahaya Longsor & tercatat ke Smart Contract).
    4. `danger_flood`: Intensitas air melebihi batas kritis (Bahaya Banjir).

---

## 💻 4. Template Service Client (Dart / Flutter)

Gunakan helper snippet berikut pada Flutter jika ingin mengambil data langsung dari backend:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ThaliaApiService {
  // Ganti IP dengan IP LAN laptop jika menggunakan HP fisik
  static const String baseUrl = 'http://localhost:8000/api/v1';

  /// 1. Ambil data sensor terkini
  static Future<Map<String, dynamic>> getLatestTelemetry() async {
    final response = await http.get(Uri.parse('$baseUrl/telemetry/latest'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Gagal memuat telemetri: ${response.statusCode}');
  }

  /// 2. Ambil komparasi hyperlocal vs BMKG
  static Future<Map<String, dynamic>> getWeatherComparison() async {
    final response = await http.get(Uri.parse('$baseUrl/comparison'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Gagal memuat komparasi: ${response.statusCode}');
  }

  /// 3. Verifikasi ke Smart Contract Blockchain
  static Future<Map<String, dynamic>> verifyAlertOnChain(int incidentId) async {
    final response = await http.get(Uri.parse('$baseUrl/alerts/$incidentId/verify'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Gagal verifikasi blockchain: ${response.statusCode}');
  }
}
```

---

## 🔒 5. Validasi Client-Side yang Berlaku di Frontend

Diimplementasikan pada `lib/controllers/auth_controller.dart`:
1. **Nama Lengkap:** Wajib diisi, hanya boleh huruf alfabet dan spasi (`RegExp(r'^[a-zA-Z\s]+$')`).
2. **Email:** Wajib berakhiran domain `@gmail.com` (`RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$')`).
3. **Password:** Wajib minimal 5 karakter.
4. **Konfirmasi Password:** Wajib cocok persis dengan kolom password.
5. **Persetujuan Ketentuan:** Checkbox Syarat & Ketentuan wajib dicentang (`true`).
6. **Validasi Login:** Email dan password tidak boleh kosong dan minimal 5 karakter. Banner pesan merah otomatis muncul jika format salah.
