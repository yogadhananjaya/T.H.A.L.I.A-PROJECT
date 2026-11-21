# Salin file ini menjadi `secrets.py`, isi sesuai Hotspot 2.4 GHz & IP laptop backend,
# lalu upload ke ESP32 via Thonny: File -> Save copy... -> MicroPython device -> secrets.py
# Catatan: `secrets.py` sudah di-ignore oleh firmware/.gitignore (tidak akan masuk Git).

WIFI_SSID = "nama-hotspot-2.4GHz"
WIFI_PASS = "password-hotspot"

# Ganti IP dengan IPv4 laptop yang menjalankan FastAPI (cek via `ipconfig` di Windows)
# Pastikan ESP32 dan laptop terhubung ke Hotspot 2.4 GHz yang sama,
# atau ganti dengan URL publik jika backend sudah di-deploy ke cloud.
API_URL = "http://192.168.43.15:8000/api/v1/telemetry"

# Identitas & lokasi node (default sama dengan backend Cibatu, Cikarang Selatan)
NODE_ID = "ESP32-NODE-01"
LOCATION_NAME = "Cibatu, Cikarang Selatan, Bekasi"
LATITUDE = -6.3378
LONGITUDE = 107.1541
