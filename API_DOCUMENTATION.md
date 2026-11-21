# T.H.A.L.I.A API & Integration Documentation
**Project:** Tri-Habitat Analysis & Climate Forecasting Intelligence  
**Team:** Ayam Kecap Paijo (ASTRA Polytechnic)  
**Hackathon:** HACKSPHERE 2026  
**Base URL:** `http://<SERVER_IP>:8000/api/v1` (Local testing: `http://localhost:8000/api/v1`)  
**Swagger UI:** `http://localhost:8000/docs`

---

## 📡 1. Panduan untuk Teman IoT & Hardware (ESP32)

Kirim data telemetri berkala (setiap **10–15 detik**) via HTTP `POST` ke endpoint berikut:

### `POST /api/v1/telemetry`
**Headers:** `Content-Type: application/json`

#### Request Body (JSON):
```json
{
  "node_id": "ESP32-NODE-01",
  "location_name": "Desa Sukamaju, Lereng Selatan",
  "latitude": -6.9175,
  "longitude": 107.6191,
  "temperature_c": 24.5,
  "humidity_pct": 82.0,
  "pressure_hpa": 1011.5,
  "rainfall_mm_h": 15.0,
  "rainfall_raw": 300,
  "soil_moisture_pct": 55.0,
  "soil_raw": 2200
}
```

#### Response (200 OK):
```json
{
  "id": 1,
  "timestamp": "2026-11-21T05:00:00",
  "node_id": "ESP32-NODE-01",
  "location_name": "Desa Sukamaju, Lereng Selatan",
  "latitude": -6.9175,
  "longitude": 107.6191,
  "temperature_c": 24.5,
  "humidity_pct": 82.0,
  "pressure_hpa": 1011.5,
  "rainfall_mm_h": 15.0,
  "soil_moisture_pct": 55.0,
  "status": "Safe",
  "status_reason": "AMAN: Kondisi seluruh habitat (Atmosfer, Hidrosfer, Litosfer) dalam batas normal.",
  "habitat_analysis": {
    "habitats": {
      "atmosphere": "Normal",
      "hydrosphere": "Normal",
      "lithosphere": "Normal"
    }
  }
}
```

---

## 📱 2. Panduan untuk Teman Frontend (Flutter Mobile App)

### A. Mendapatkan Telemetri Terakhir (Live Gauge / Status Card)
`GET /api/v1/telemetry/latest`
* Mengembalikan data sensor terkini dari node ESP32 beserta status klasifikasinya (`Safe`, `Alert`, atau `Danger`).

### B. Mendapatkan Riwayat Sensor (Grafik & Tren)
`GET /api/v1/telemetry/history?limit=30`
* Mengembalikan array 30 data terakhir untuk digambar pada chart fl_chart / syncfusion flutter (Curah Hujan, Soil Moisture, Suhu, Tekanan Udara).

### C. Side-by-Side Comparison (Sensor Lokal vs BMKG) - **FITUR UNGGULAN**
`GET /api/v1/comparison`
#### Response:
```json
{
  "location": "Desa Sukamaju, Lereng Selatan",
  "timestamp": "2026-11-21T05:05:00Z",
  "local_telemetry": {
    "source": "T.H.A.L.I.A Physical ESP32 Node",
    "temperature_c": 21.0,
    "humidity_pct": 95.0,
    "pressure_hpa": 1002.5,
    "rainfall_mm_h": 42.0,
    "soil_moisture_pct": 88.5,
    "status": "Danger",
    "status_reason": "BAHAYA: Lithosphere: Tanah sangat jenuh air (88.5%), risiko longsor tinggi..."
  },
  "bmkg_regional_forecast": {
    "region_name": "Wilayah Kabupaten / Makro Jawa Barat",
    "weather_desc": "Berawan Tebal / Potensi Hujan Ringan",
    "temperature_c": 28.5,
    "humidity_pct": 78.0,
    "rainfall_probability_pct": 45.0,
    "source": "BMKG Open Data API (Regional Macro Station)"
  },
  "granularity_advantage": "KEUNGGULAN GRANULARITAS TERBUKTI: BMKG Regional memprediksi 'Berawan Tebal', namun sensor lokal T.H.A.L.I.A mendeteksi curah hujan lokal 42.0 mm/jam dan kejenuhan tanah lereng mencapai 88.5%.",
  "status": "Danger"
}
```

### D. Riwayat Insiden & Audit Trail Blockchain
* `GET /api/v1/alerts`: Menampilkan daftar bencana yang tercatat beserta hash dan `blockchain_tx_hash`.
* `GET /api/v1/alerts/{id}/verify`: Memverifikasi langsung ke Smart Contract bahwa data insiden valid dan tidak pernah dimanipulasi (Anti-Fraud).
* `GET /api/v1/alerts/summary/stats`: Statistik total insiden (Aman/Waspada/Bahaya).

---

## 🎯 3. Endpoint Simulator untuk Live Pitching Juri

Gunakan endpoint ini di browser atau postman saat presentasi jika ingin menunjukkan respon sistem seketika:

`POST /api/v1/simulator/inject`
```json
{
  "scenario": "danger_landslide",
  "location": "Desa Sukamaju, Titik Rawan Lereng A"
}
```
* **Pilihan skenario:**
  - `safe_normal`: Kondisi cuaca cerah & tanah stabil.
  - `alert_rain`: Hujan lebat (>20mm/jam), status Waspada.
  - `alert_moisture`: Kejenuhan tanah meningkat (>65%), status Waspada.
  - `danger_landslide`: Kejenuhan tanah ekstrem (88.5%) + hujan lebat -> Status Bahaya, tercatat di Smart Contract & memicu Notifikasi FCM.
  - `danger_flashflood`: Hujan badai ekstrem (>70mm/jam).

---

## 🚀 4. Cara Menjalankan Sistem

1. **Jalankan Node Blockchain Lokal:**
   Double-click `run_blockchain.bat`
2. **Deploy Smart Contract:**
   Double-click `deploy_contract.bat`
3. **Jalankan Backend Server:**
   Double-click `run_backend.bat` (Buka `http://localhost:8000/docs` di browser)
4. **Jalankan Sensor Simulator (Opsional jika hardware belum tersambung):**
   Double-click `run_simulator.bat`
