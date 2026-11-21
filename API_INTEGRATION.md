# Panduan Integrasi API T.H.A.L.I.A (untuk tim backend dan ESP32)

Aplikasi Flutter ini hanya **menampilkan data**. Semua data cuaca, sensor, dan laporan warga disimpan dan dihitung di backend (FastAPI + PostgreSQL). Aplikasi tidak menyimpan data apa pun selain cache tile peta dan token login.

```
ESP32 (BME280, hujan, soil moisture, dst.)
   |  POST telemetri tiap 10-15 detik
   v
Backend FastAPI  --->  PostgreSQL (data mentah + status Aman/Waspada/Bahaya)
   |   \-> BMKG Open Data (prakiraan)
   |   \-> Hardhat + THALIARegistry (catat kejadian kritis)
   |   \-> FCM (notifikasi)
   v
Aplikasi Flutter  (GET prakiraan, GET/POST laporan, POST login)
```

## 1. Di mana menaruh alamat API

Satu tempat saja: **`lib/config/api_config.dart`**.

| Nilai | Fungsi |
|---|---|
| `baseUrl` | Alamat server FastAPI, tanpa garis miring di akhir |
| `useMockData` | `true` = data contoh bawaan, `false` = API sungguhan |
| `loginPath`, `changePasswordPath`, `forecastPath`, `reportsPath` | Jalur endpoint (ubah bila backend memakai nama lain) |
| `requestTimeout` | Batas tunggu per permintaan (default 8 detik) |

Tidak perlu edit file untuk berpindah mode. Pakai `--dart-define`:

```bash
# Data contoh (default, tanpa server)
flutter run

# API sungguhan, emulator Android (10.0.2.2 = localhost laptop)
flutter run --dart-define=THALIA_USE_MOCK=false --dart-define=THALIA_API_URL=http://10.0.2.2:8000

# API sungguhan, HP fisik (laptop dan HP satu WiFi)
flutter run --dart-define=THALIA_USE_MOCK=false --dart-define=THALIA_API_URL=http://192.168.1.10:8000
```

Untuk HP fisik, jalankan FastAPI dengan `uvicorn main:app --host 0.0.0.0 --port 8000` dan izinkan port 8000 di firewall Windows. HTTP biasa (tanpa HTTPS) sudah diizinkan di `AndroidManifest.xml`.

## 2. Peta kode (konsep OOP)

Controller dan UI hanya bergantung pada **kelas abstrak**. Implementasinya bisa ditukar tanpa menyentuh UI.

```
lib/
  config/
    api_config.dart              <- alamat dan jalur API (EDIT DI SINI)
    map_tile_cache.dart          <- batas cache tile peta (50 MB)
  models/
    api_models.dart              <- ApiException, AuthSession, FieldReportDraft
    dashboard_models.dart        <- ForecastDayModel, FieldReportItemModel (+ fromJson)
  services/
    thalia_api_service.dart      <- KONTRAK: AuthService, ThaliaApiService (abstract)
    api_client.dart              <- klien HTTP (token, timeout, penanganan galat)
    http_thalia_api_service.dart <- implementasi ke FastAPI (HttpAuthService, HttpThaliaApiService)
    mock_thalia_api_service.dart <- implementasi data contoh (MockAuthService, MockThaliaApiService)
    thalia_services.dart         <- memilih mock atau http dari ApiConfig
  controllers/
    auth_controller.dart         <- memakai AuthService
    dashboard_controller.dart    <- memakai ThaliaApiService
```

Yang biasanya kalian sentuh: `api_config.dart`, `http_thalia_api_service.dart`, dan `fromJson` di `dashboard_models.dart`. Layar (`screens/`) tidak perlu diubah.

## 3. Kontrak endpoint

Semua jawaban berformat JSON. Galat dikirim dengan kode HTTP 4xx/5xx dan isi `{"detail": "pesan yang aman ditampilkan"}` (format bawaan FastAPI). Aplikasi menampilkan isi `detail` ke pengguna.

### 3.1 Login: `POST /api/v1/auth/login`

Request:
```json
{ "username": "admin", "password": "123" }
```
Jawaban 200:
```json
{ "access_token": "eyJhbGciOi...", "token_type": "bearer", "user": { "name": "Rafie" } }
```
Salah sandi: 401 `{"detail": "Username atau kata sandi salah."}`. Setelah login, setiap request berikutnya membawa header `Authorization: Bearer <access_token>`.

### 3.1b Ganti kata sandi: `POST /api/v1/auth/change-password`

Dipanggil dari layar Profil → Keamanan Akun & Kata Sandi. Wajib membawa header `Authorization: Bearer <access_token>`.

Request:
```json
{ "current_password": "123", "new_password": "KataSandiBaru9" }
```
Jawaban 200 (isi bebas, aplikasi tidak membacanya): `{"ok": true}`.
Sandi lama salah: 400/401 `{"detail": "Kata sandi saat ini salah."}`.
Aplikasi sudah memvalidasi sandi baru minimal 8 karakter dengan huruf dan angka, tetapi backend tetap harus memeriksanya sendiri.

### 3.2 Prakiraan 5 hari: `GET /api/v1/forecast?lat=-6.284500&lng=107.170500&days=5`

Jawaban 200 (boleh berupa objek `{"days": [...]}` atau langsung array):
```json
{
  "location": "Cikarang Utara, Bekasi",
  "days": [
    {
      "date": "2026-11-21",
      "condition_code": "light_rain",
      "temperature_c": 26,
      "rainfall_mm_per_hour": 2.0,
      "humidity_pct": 77,
      "water_level_cm": 110,
      "soil_moisture_pct": 52,
      "status": "aman",
      "source": "sensor"
    },
    {
      "date": "2026-11-22",
      "condition_code": "partly_cloudy",
      "temperature_c": 28,
      "rainfall_mm_per_hour": 0.4,
      "humidity_pct": 70,
      "water_level_cm": 98,
      "soil_moisture_pct": 48,
      "status": "aman",
      "source": "bmkg"
    }
  ]
}
```

| Field | Wajib | Keterangan |
|---|---|---|
| `date` | ya | `YYYY-MM-DD`. Aplikasi membuat label hari ("Sen") dan tanggal ("12/5") dari sini |
| `condition_code` | ya | `sunny`, `partly_cloudy`, `cloudy`, `light_rain`, `rain`, `storm`. Menentukan ikon dan judul, dan `sunny` mengaktifkan tema oranye |
| `temperature_c` | disarankan | Angka, dibulatkan |
| `rainfall_mm_per_hour` | disarankan | Dipakai di subjudul "Curah 2.0 mm/jam" |
| `humidity_pct` | disarankan | Atmosfer |
| `water_level_cm` | disarankan | Hidrosfer |
| `soil_moisture_pct` | disarankan | Litosfer |
| `status` | disarankan | `aman`, `waspada`, atau `bahaya` |
| `condition_title`, `condition_subtitle`, `day_short` | opsional | Bila diisi, menggantikan teks yang dibuat otomatis oleh aplikasi |
| `location`, `source` | opsional | Belum dipakai UI, aman dikirim |

Saran: isi **hari pertama dari pembacaan sensor ESP32 terbaru** dan hari-hari berikutnya dari BMKG, sesuai konsep perbandingan lokal vs BMKG di proposal. Field yang kosong ditampilkan sebagai "-".

### 3.3 Riwayat laporan: `GET /api/v1/reports`

Hanya laporan milik pengguna yang sedang login. Boleh array langsung atau `{"reports": [...]}`:
```json
[
  {
    "id": 17,
    "title": "Luapan Pintu Air Manggarai",
    "created_at": "2026-11-21T07:20:00Z",
    "habitat": "hydrosphere",
    "category": "Banjir",
    "status": "received",
    "metric_summary": "Tinggi Air 110 cm • pH 6.8",
    "latitude": -6.2146,
    "longitude": 106.8492
  }
]
```
`habitat`: `atmosphere`, `hydrosphere`, `lithosphere`, atau kosong. `status`: `received`/`processing` (tampil "Diterima", masuk filter Proses) atau `completed`/`verified` (tampil "Selesai"). `created_at` memakai ISO 8601; aplikasi mengubahnya jadi "Hari Ini, 14:20" atau "10 Mei 2026".

### 3.4 Kirim laporan: `POST /api/v1/reports`

Request (JSON; foto dikirim sebagai base64, sudah dikecilkan ke lebar maksimal 1200 px):
```json
{
  "category": "Banjir",
  "description": "Air sungai mulai meluap ke jalan utama RT 04...",
  "latitude": -6.2845,
  "longitude": 107.1705,
  "location_name": "Cikarang Utara, Bekasi",
  "captured_at": "2026-11-21T13:42:10Z",
  "photo_base64": "/9j/4AAQSkZJRg..."
}
```
Jawaban 200/201: satu objek laporan dengan bentuk yang sama seperti item di 3.3. Ini juga tempat yang pas untuk menghitung SHA-256 foto dan mencatatnya ke blockchain, lalu mengembalikan `status`.

Bila lebih nyaman memakai multipart, ubah `submitReport` di `http_thalia_api_service.dart` dan `FieldReportDraft.toJson` di `api_models.dart`.

### 3.5 Telemetri ESP32 (sisi backend, tidak dipanggil aplikasi)

Usulan agar rantai datanya lengkap; bentuknya bebas selama backend bisa membangun jawaban 3.2:
```
POST /api/v1/telemetry
{ "node_id": "thalia-01", "temperature_c": 26.4, "humidity_pct": 77, "pressure_hpa": 1012,
  "rainfall_mm": 0.5, "soil_moisture_pct": 52, "water_level_cm": 110, "ph": 6.8 }
```
Simpan ke PostgreSQL, hitung status Aman/Waspada/Bahaya dengan aturan ambang batas, dan bila Waspada/Bahaya catat hash ke `THALIARegistry.logAlert`.

## 4. Menambah endpoint baru

1. Tambah method di kelas abstrak `ThaliaApiService` (`services/thalia_api_service.dart`).
2. Implementasikan di `HttpThaliaApiService` (panggil `_client.get/post`) dan di `MockThaliaApiService` (data contoh). Kompiler akan memaksa dua-duanya diisi.
3. Bila perlu model baru, taruh di `models/` lengkap dengan `fromJson`.
4. Panggil dari controller. UI cukup membaca state controller.

## 5. Penanganan galat dan data contoh

- Selama belum ada jawaban sukses, layar menampilkan **data contoh**. `DashboardController.isSampleData` bernilai `true` pada kondisi itu.
- Bila request gagal, data yang sedang tampil dipertahankan dan `DashboardController.loadError` berisi pesan. Belum ada banner di UI; silakan tambahkan di `home_tab_screen.dart` bila dibutuhkan.
- Laporan yang dikirim langsung muncul di Riwayat dengan status "Mengirim", lalu berubah sesuai jawaban server, atau "Gagal Kirim" bila server tidak terjangkau.
- Dashboard dimuat ulang otomatis saat login dan saat lokasi pengguna berubah (`main.dart`).

## 6. Server percobaan 30 baris

Untuk menguji aplikasi sebelum backend asli jadi (`pip install fastapi uvicorn`, simpan sebagai `main.py`):

```python
from fastapi import FastAPI, HTTPException

app = FastAPI()
REPORTS = []

@app.post("/api/v1/auth/login")
def login(body: dict):
    if body.get("username") == "admin" and body.get("password") == "123":
        return {"access_token": "dev-token", "token_type": "bearer", "user": {"name": "Admin"}}
    raise HTTPException(status_code=401, detail="Username atau kata sandi salah.")

@app.post("/api/v1/auth/change-password")
def change_password(body: dict):
    if body.get("current_password") != "123":
        raise HTTPException(status_code=400, detail="Kata sandi saat ini salah.")
    return {"ok": True}

@app.get("/api/v1/forecast")
def forecast(lat: float, lng: float, days: int = 5):
    codes = ["light_rain", "partly_cloudy", "cloudy", "sunny", "storm"]
    return {"days": [
        {"date": f"2026-11-{21 + i}", "condition_code": codes[i % 5], "temperature_c": 26 + i,
         "rainfall_mm_per_hour": 1.5 * i, "humidity_pct": 70 + i, "water_level_cm": 100 + i * 5,
         "soil_moisture_pct": 50 + i, "status": "waspada" if i == 4 else "aman"}
        for i in range(days)
    ]}

@app.get("/api/v1/reports")
def list_reports():
    return REPORTS

@app.post("/api/v1/reports", status_code=201)
def create_report(body: dict):
    item = {"id": len(REPORTS) + 1, "title": f"Laporan {body['category']} • {body['location_name']}",
            "created_at": body["captured_at"], "category": body["category"], "status": "received",
            "metric_summary": body["description"], "latitude": body["latitude"], "longitude": body["longitude"]}
    REPORTS.insert(0, item)
    return item
```
Jalankan dengan `uvicorn main:app --host 0.0.0.0 --port 8000`, lalu buka aplikasi dengan `--dart-define=THALIA_USE_MOCK=false` seperti di bagian 1.

## 7. Ukuran aplikasi

Build debug (`flutter run`) bisa mencapai 100 MB lebih karena membawa mesin debug. Untuk ukuran sebenarnya, bangun versi release:

```bash
flutter build apk --release --split-per-abi   # satu APK per arsitektur, ambil yang arm64-v8a
flutter build appbundle --release             # untuk Play Store
```

Cache tile peta dibatasi 50 MB (`lib/config/map_tile_cache.dart`), dan foto sementara dari kamera atau galeri dihapus setelah dibaca.
