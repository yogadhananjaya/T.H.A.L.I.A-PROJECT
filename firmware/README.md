# T.H.A.L.I.A — ESP32 MicroPython Firmware

Firmware untuk *IoT Edge Node* **T.H.A.L.I.A** berbasis **ESP32 (`ESP-WROOM-32`) + MicroPython (`v1.29.0`)** menggunakan **Thonny IDE**.

---

## 1. Wiring Pinout ESP32

> **PENTING:**
> - **BME280** & **Raindrop FC-37** **WAJIB diberi tegangan `3V3`, JANGAN `5V`**, agar tegangan output analog `AO` FC-37 tidak melebihi batas 3.3V pin ADC ESP32.
> - **Capacitive Soil Moisture v1.2** (versi dengan IC regulator LDO 3.3V `U2` on-board) **diberi tegangan `VIN` (5V)** agar rangkaian osilatornya bekerja penuh; tegangan output `AOUT` tetap aman `< 3.0V` bagi ADC ESP32.

| Modul / Habitat | Pin Modul | Pin ESP32 | Keterangan |
|---|---|---|---|
| **LED Indikator** | On-board | `GPIO 2` | Kedip cepat (`80ms`) saat hujan (`DO=0`), mati saat kering |
| **BME280** *(Atmosphere)* | `VCC`, `GND`, `SDA`, `SCL` | `3V3`, `GND`, `P21`, `P22` | I2C `0x76` (`50 kHz`). Modul 6-pin: `CSB -> 3V3`, `SDO -> GND` |
| **Raindrop FC-37** *(Hydrosphere)* | `VCC`, `GND` | `3V3`, `GND` | **Wajib 3V3** |
| | `DO` | `P23` (`GPIO 23`) | Digital Active LOW (`0` = hujan/basah) untuk `is_raining` & LED |
| | `AO` | `P35` (`GPIO 35`) | **ADC1 input-only** — intensitas kebasahan `0–100%` (`rainfall_pct` & `rainfall_raw`) |
| **Soil Moisture v1.2** *(Lithosphere)* | `VCC`, `GND`, `AOUT` | `VIN` (5V), `GND`, `P34` | **Wajib ADC1** — kelembaban tanah `0–100%` (`soil_moisture_pct` & `soil_raw`) |

---

## 2. Kalibrasi Sebelum Demo

Sesuaikan nilai kalibrasi di bagian atas `firmware/main.py` menggunakan alat peraga demo:
- **`RAIN_DRY` / `RAIN_WET`** (default `4095` / `1200`):
  - Plat kering $\rightarrow$ `0%` (*Aman*)
  - Beberapa tetes $\rightarrow$ `< 30%` (*Aman / Light Rain*)
  - Disiram sedang $\rightarrow$ `30%–74%` (*Waspada / Alert*)
  - Plat basah penuh $\rightarrow$ `>= 75%` (*Bahaya / Danger*)
- **`SOIL_DRY` / `SOIL_WET`** (terkalibrasi `2480` / `650` — kering `~2481` vs celup air `~629–676`):
  - Media kering / lembap biasa $\rightarrow$ `< 65%` (*Aman*)
  - Media basah $\rightarrow$ `65%–84%` (*Waspada / Alert*)
  - Media sangat jenuh $\rightarrow$ `>= 85%` (*Bahaya / Danger*), **atau** `>= 80%` bersamaan dengan hujan `>= 30%` (*Bahaya / Danger*)

Kedua sensor analog menggunakan **rata-rata 15 sampel ADC**, dan khusus **Soil Moisture** memakai `SOIL_SMOOTH_WINDOW = 1` agar respons demo real-time instan (dapat dinaikkan ke `3` untuk deployment lapangan). Pengiriman mendukung **HTTP LAN maupun HTTPS/ngrok** (dengan header `ngrok-skip-browser-warning`, `Connection: close`, serta `gc.collect()` sebelum & sesudah TLS), berjalan setiap **2.5 detik** plus **pemicu instan** begitu status hujan (`DO`) berubah.

---

## 3. Cara Setup & Upload ke ESP32 (Thonny IDE)

1. Sambungkan ESP32 ke laptop dan pastikan interpreter Thonny mengarah ke **`MicroPython (ESP32)`**.
2. Buat file **`secrets.py`** dari [`secrets.example.py`](./secrets.example.py), lalu isi `WIFI_SSID` (2.4 GHz), `WIFI_PASS`, dan `API_URL` (`http://<IP_LAPTOP>:8000/api/v1/telemetry` atau URL HTTPS publik/ngrok).
3. Upload **kedua file** ke memori ESP32 via Thonny (**File -> Save copy... -> MicroPython device**):
   - `secrets.py` *(di-ignore oleh `firmware/.gitignore`)*
   - `main.py` *(otomatis jalan mandiri tiap 2.5 detik + pemicu hujan instan saat dicolok Power Bank 5V 2A)*

---

## 4. Kontrak Payload (Sinkron dengan Branch `Backend` `6501305` & `UI` `2b21304`)

`POST /api/v1/telemetry` (`Content-Type: application/json`, interval **2.5 detik** + pemicu perubahan hujan instan):

```json
{
  "node_id": "ESP32-NODE-01",
  "location_name": "Cibatu, Cikarang Selatan, Bekasi",
  "latitude": -6.3378,
  "longitude": 107.1541,
  "temperature_c": 24.94,
  "humidity_pct": 38.1,
  "pressure_hpa": 1004.7,
  "rainfall_pct": 0.0,
  "is_raining": false,
  "rainfall_raw": 4095,
  "soil_moisture_pct": 41.7,
  "soil_raw": 2407
}
```
