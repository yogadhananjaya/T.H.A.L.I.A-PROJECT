# T.H.A.L.I.A — ESP32 MicroPython Firmware

Firmware untuk *IoT Edge Node* **T.H.A.L.I.A** berbasis **ESP32 (`ESP-WROOM-32`) + MicroPython (`v1.29.0`)** menggunakan **Thonny IDE**.

---

## 1. Wiring Pinout ESP32

| Modul / Habitat | Pin Modul | Pin ESP32 | Keterangan |
|---|---|---|---|
| **LED Indikator** | On-board | `GPIO 2` | Kedip cepat (`80ms`) saat hujan, mati saat kering |
| **BME280** *(Atmosphere)* | `VCC`, `GND`, `SDA`, `SCL` | `3V3`, `GND`, `P21`, `P22` | I2C `0x76` (`50 kHz`). Modul 6-pin: `CSB -> 3V3`, `SDO -> GND` |
| **Raindrop FC-37** *(Hydrosphere)* | `VCC`, `GND`, `DO` | `3V3`, `GND`, `P23` | Active LOW (`0` = hujan/basah, `1` = kering) |
| **Soil Moisture** *(Lithosphere)* | `VCC`, `GND`, `AOUT` | `3V3`, `GND`, `P34` | **Wajib ADC1** (ADC2 mati saat Wi-Fi aktif) |

---

## 2. Cara Setup & Upload ke ESP32 (Thonny IDE)

1. Sambungkan ESP32 ke laptop dan pastikan interpreter Thonny mengarah ke **`MicroPython (ESP32)`** di port COM yang sesuai.
2. Buat file **`secrets.py`** dari contoh [`secrets.example.py`](./secrets.example.py), lalu isi:
   - `WIFI_SSID` & `WIFI_PASS` — wajib **Hotspot 2.4 GHz** (ESP32 tidak mendukung 5 GHz).
   - `API_URL` — arahkan ke endpoint backend FastAPI: `http://<IP_LAPTOP>:8000/api/v1/telemetry`.
3. Upload **kedua file** ke memori ESP32 lewat Thonny (**File -> Save copy... -> MicroPython device**):
   - `secrets.py` *(tidak di-commit ke Git, dilindungi `firmware/.gitignore`)*
   - `main.py` *(otomatis berjalan mandiri saat ESP32 dicolok ke Power Bank 5V 2A)*

---

## 3. Kontrak Payload (Sinkron dengan Branch `Backend`)

`POST /api/v1/telemetry` (`Content-Type: application/json`):

```json
{
  "node_id": "ESP32-NODE-01",
  "location_name": "Desa Sukamaju, Lereng Selatan",
  "latitude": -6.9175,
  "longitude": 107.6191,
  "temperature_c": 24.94,
  "humidity_pct": 38.1,
  "pressure_hpa": 1004.7,
  "rainfall_mm_h": 0.0,
  "rainfall_raw": 1,
  "soil_moisture_pct": 41.7,
  "soil_raw": 2407
}
```
