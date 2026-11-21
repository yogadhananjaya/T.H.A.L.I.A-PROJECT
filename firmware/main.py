import gc
import json
import network
import struct
import time
from machine import ADC, Pin, SoftI2C

try:
    import urequests as requests
except ImportError:
    requests = None

# ==============================================================================
# 1. KONFIGURASI (Kredensial dibaca dari `secrets.py` di memori ESP32)
# ==============================================================================
try:
    import secrets as _s
except ImportError:
    _s = None

WIFI_SSID = getattr(_s, "WIFI_SSID", "")
WIFI_PASS = getattr(_s, "WIFI_PASS", "")
API_URL = getattr(_s, "API_URL", "http://192.168.43.15:8000/api/v1/telemetry")

NODE_ID = getattr(_s, "NODE_ID", "ESP32-NODE-01")
LOCATION_NAME = getattr(_s, "LOCATION_NAME", "Cibatu, Cikarang Selatan, Bekasi")
LATITUDE = getattr(_s, "LATITUDE", -6.3378)
LONGITUDE = getattr(_s, "LONGITUDE", 107.1541)

# Sensor Hujan FC-37 (WAJIB VCC 3V3 — JANGAN 5V!)
# - DO -> GPIO 23 (deteksi hujan cepat + LED indikator)
# - AO -> GPIO 35 (ADC1 input-only, intensitas kebasahan 0-100%)
RAIN_DRY = 4095  # Kalibrasi: ADC saat plat kering
RAIN_WET = 1200  # Kalibrasi: ADC saat plat basah merata

# Sensor Tanah Soil Moisture Capacitive v1.2 (VCC -> VIN 5V karena ada regulator U2 3.3V, AOUT -> GPIO 34 ADC1)
SOIL_DRY = 2480  # Kalibrasi nyata: ADC kering di udara (~2481 -> 0.0%)
SOIL_WET = 650   # Kalibrasi nyata: ADC dicelup air (~629-676 -> 100.0%)

# Penghalusan khusus Soil Moisture (moving average 3 kiriman) untuk redam fluktuasi sekitar ambang 65%
SOIL_SMOOTH_WINDOW = 3

# Interval & proteksi jaringan (10 detik sesuai proposal & dokumentasi backend)
SEND_TO_API = True
SEND_INTERVAL_MS = 10000
WIFI_RETRY_COOLDOWN_MS = 30000


# ==============================================================================
# 2. HELPER SENSOR & PENGHALUSAN
# ==============================================================================
class MovingAverage:
    def __init__(self, size=3):
        self.size = max(1, size)
        self.buf = []

    def update(self, val):
        self.buf.append(val)
        if len(self.buf) > self.size:
            self.buf.pop(0)
        return round(sum(self.buf) / len(self.buf), 1)


def baca_adc_persen(adc_pin, dry_val, wet_val, samples=15):
    """Baca rata-rata 15 sampel ADC dan balik ke persen 0-100% (ADC tinggi = kering)."""
    total = 0
    for _ in range(samples):
        total += adc_pin.read()
        time.sleep_ms(5)
    raw = total // samples

    selisih = dry_val - wet_val
    if selisih == 0:
        return raw, 0.0
    pct = max(0.0, min(100.0, ((dry_val - raw) / selisih) * 100.0))
    return raw, round(pct, 1)


class BME_BMP280:
    def __init__(self, i2c):
        self.i2c = i2c
        devs = i2c.scan()
        self.addr = 0x76 if 0x76 in devs else (0x77 if 0x77 in devs else None)
        if not self.addr:
            raise RuntimeError("BME/BMP280 tidak ditemukan di I2C!")

        # Soft reset agar tidak membeku di nilai power-on reset
        self.i2c.writeto_mem(self.addr, 0xE0, b"\xB6")
        time.sleep_ms(50)

        self.is_bme = self.i2c.readfrom_mem(self.addr, 0xD0, 1)[0] == 0x60
        self.name = "BME280" if self.is_bme else "BMP280"

        c = self.i2c.readfrom_mem(self.addr, 0x88, 24)
        (
            self.T1, self.T2, self.T3,
            self.P1, self.P2, self.P3,
            self.P4, self.P5, self.P6,
            self.P7, self.P8, self.P9,
        ) = struct.unpack("<HhhHhhhhhhhh", c)

        if self.is_bme:
            self.H1 = self.i2c.readfrom_mem(self.addr, 0xA1, 1)[0]
            hc = self.i2c.readfrom_mem(self.addr, 0xE1, 7)
            self.H2 = struct.unpack("<h", hc[0:2])[0]
            self.H3 = hc[2]
            self.H4 = (hc[3] << 4) | (hc[4] & 0x0F)
            self.H5 = (hc[5] << 4) | (hc[4] >> 4)
            self.H6 = struct.unpack("b", bytes([hc[6]]))[0]
            self.i2c.writeto_mem(self.addr, 0xF2, b"\x01")

        self.i2c.writeto_mem(self.addr, 0xF5, b"\x00")

    def read(self):
        # Forced Mode: selalu memicu pengukuran segar setiap pembacaan
        if self.is_bme:
            self.i2c.writeto_mem(self.addr, 0xF2, b"\x01")
        self.i2c.writeto_mem(self.addr, 0xF4, b"\x25")
        time.sleep_ms(50)

        raw = self.i2c.readfrom_mem(self.addr, 0xF7, 8 if self.is_bme else 6)
        pr = (raw[0] << 12) | (raw[1] << 4) | (raw[2] >> 4)
        tr = (raw[3] << 12) | (raw[4] << 4) | (raw[5] >> 4)

        v1 = (((tr >> 3) - (self.T1 << 1)) * self.T2) >> 11
        v2 = (((((tr >> 4) - self.T1) ** 2 >> 12) * self.T3) >> 14)
        tf = v1 + v2
        temp = ((tf * 5 + 128) >> 8) / 100.0

        v1 = tf - 128000
        v2 = v1 * v1 * self.P6 + ((v1 * self.P5) << 17) + (self.P4 << 35)
        v1 = ((v1 * v1 * self.P3) >> 8) + ((v1 * self.P2) << 12)
        v1 = (((1 << 47) + v1) * self.P1) >> 33
        press = 0.0
        if v1 != 0:
            p = (((1048576 - pr) << 31) - v2) * 3125 // v1
            p = p + ((self.P9 * (p >> 13) * (p >> 13)) >> 25) + ((self.P8 * p) >> 19)
            press = (((p >> 8) + (self.P7 << 4)) / 256.0) / 100.0

        hum = None
        if self.is_bme:
            hr = (raw[6] << 8) | raw[7]
            h = tf - 76800
            h = (
                ((((hr << 14) - (self.H4 << 20) - (self.H5 * h) + 16384) >> 15) *
                 (((((((h * self.H6) >> 10) * (((h * self.H3) >> 11) + 32768)) >> 10) + 2097152) *
                   self.H2 + 8192) >> 14))
            )
            h = max(0, min(h - (((((h >> 15) ** 2) >> 7) * self.H1) >> 4), 419430400))
            hum = (h >> 12) / 1024.0

        return temp, press, hum


def validasi_bme(temp, press, hum):
    """Pastikan nilai berada dalam batas Pydantic TelemetryCreate agar tidak kena HTTP 422."""
    if temp is None or press is None or hum is None:
        return False
    return (-20.0 <= temp <= 70.0) and (800.0 <= press <= 1200.0) and (0.0 <= hum <= 100.0)


# ==============================================================================
# 3. INISIALISASI HARDWARE
# ==============================================================================
print("[1/3] Menyiapkan pin & sensor...")
led = Pin(2, Pin.OUT)
led.value(0)

# FC-37 Raindrop: DO (GPIO 23) + AO (GPIO 35 / ADC1)
rain_pin = Pin(23, Pin.IN)
rain_adc = ADC(Pin(35))
rain_adc.atten(ADC.ATTN_11DB)

# Soil Moisture: AOUT (GPIO 34 / ADC1)
soil_adc = ADC(Pin(34))
soil_adc.atten(ADC.ATTN_11DB)
soil_smooth = MovingAverage(SOIL_SMOOTH_WINDOW)

# BME280: I2C SDA=21, SCL=22
i2c = SoftI2C(scl=Pin(22), sda=Pin(21), freq=50000)
bme = None
try:
    bme = BME_BMP280(i2c)
    print(f" ✓ {bme.name} siap di 0x{bme.addr:02X}")
except Exception as e:
    print(f" ⚠️ BME280 belum terbaca saat boot: {e}")


# ==============================================================================
# 4. KONEKSI WIFI (2.4 GHz, PM_NONE agar stabil di tethering HP)
# ==============================================================================
wlan = network.WLAN(network.STA_IF)
last_wifi_attempt = 0


def connect_wifi():
    global last_wifi_attempt
    last_wifi_attempt = time.ticks_ms()

    if not WIFI_SSID:
        print("[2/3] ⚠️ WIFI_SSID kosong! Buat secrets.py di ESP32. Lanjut mode offline.")
        return False

    print(f"[2/3] Menghubungkan Wi-Fi '{WIFI_SSID}'...", end="")
    try:
        wlan.active(False)
        time.sleep_ms(500)
        wlan.active(True)
        time.sleep_ms(500)
        try:
            wlan.config(pm=0)  # Matikan Wi-Fi Power Saving (PM_NONE)
        except Exception:
            pass
        wlan.connect(WIFI_SSID, WIFI_PASS)

        t = 15
        while not wlan.isconnected() and t > 0:
            led.value(not led.value())
            print(".", end="")
            time.sleep_ms(500)
            t -= 0.5
    except Exception as e:
        print(f"\n ⚠️ Error Wi-Fi: {e}")
    finally:
        led.value(0)

    print()
    if wlan.isconnected():
        print(f" ✅ Wi-Fi Terhubung! IP: {wlan.ifconfig()[0]}")
        return True
    print(f" ⚠️ Gagal Wi-Fi (status: {wlan.status()}), lanjut mode offline.")
    return False


def post_telemetry(payload_dict):
    """Kirim JSON ke FastAPI dengan proteksi socket leak (selalu close)."""
    if not requests:
        return
    res = None
    body = json.dumps(payload_dict)
    headers = {"Content-Type": "application/json"}
    try:
        try:
            res = requests.post(API_URL, data=body, headers=headers, timeout=5)
        except TypeError:
            res = requests.post(API_URL, data=body, headers=headers)
        print(f" -> API {res.status_code}")
        if res.status_code != 200:
            try:
                print(f" -> API Body: {res.text[:150]}")
            except Exception:
                pass
    except Exception as e:
        print(f" -> API Error: {e}")
    finally:
        if res is not None:
            try:
                res.close()
            except Exception:
                pass


connect_wifi()


# ==============================================================================
# 5. LOOP UTAMA T.H.A.L.I.A (NON-BLOCKING & ANTI MEMORY LEAK)
# ==============================================================================
print("[3/3] T.H.A.L.I.A berjalan!\n")
last_send = time.ticks_ms()
last_blink = time.ticks_ms()
led_state = False

while True:
    now = time.ticks_ms()

    # 1. Raindrop DO real-time (GPIO 23) -> LED indikator (GPIO 2)
    is_raining = rain_pin.value() == 0
    if is_raining:
        if time.ticks_diff(now, last_blink) >= 80:
            led_state = not led_state
            led.value(led_state)
            last_blink = now
    else:
        led.value(0)
        led_state = False

    # 2. Baca sensor & kirim telemetri setiap 10 detik
    if time.ticks_diff(now, last_send) >= SEND_INTERVAL_MS:
        if bme is None:
            try:
                bme = BME_BMP280(i2c)
                print(f" ✓ {bme.name} tersambung ulang!")
            except Exception:
                pass

        temp, press, hum = (None, None, None)
        if bme:
            try:
                temp, press, hum = bme.read()
            except OSError:
                print(" ⚠️ Koneksi BME280 terputus, akan reconnect otomatis...")
                bme = None

        # Baca FC-37 AO (GPIO 35): langsung 15-sample ADC (tanpa moving average agar respons demo instan)
        rain_raw, rainfall_pct = baca_adc_persen(rain_adc, RAIN_DRY, RAIN_WET)

        # Baca Soil Moisture (GPIO 34): 15-sample ADC + moving average 3 kiriman
        soil_raw, soil_pct_now = baca_adc_persen(soil_adc, SOIL_DRY, SOIL_WET)
        soil_pct = soil_smooth.update(soil_pct_now)

        # Jangan kirim data lama jika BME280 error; lewati pengiriman hingga sensor valid
        if validasi_bme(temp, press, hum):
            payload = {
                "node_id": NODE_ID,
                "location_name": LOCATION_NAME,
                "latitude": LATITUDE,
                "longitude": LONGITUDE,
                "temperature_c": round(temp, 2),
                "humidity_pct": round(hum, 1),
                "pressure_hpa": round(press, 1),
                "rainfall_pct": rainfall_pct,
                "is_raining": is_raining,
                "rainfall_raw": rain_raw,
                "soil_moisture_pct": soil_pct,
                "soil_raw": soil_raw,
            }
            print("[TELEMETRY]", json.dumps(payload))

            if SEND_TO_API:
                if not wlan.isconnected() and time.ticks_diff(now, last_wifi_attempt) >= WIFI_RETRY_COOLDOWN_MS:
                    connect_wifi()
                if wlan.isconnected():
                    post_telemetry(payload)
        else:
            print(
                f"[SKIP API] Data BME280 belum valid (T={temp}, P={press}, H={hum}) | "
                f"Rain={rainfall_pct}% (ADC={rain_raw}, DO={is_raining}) | "
                f"Soil={soil_pct}% (ADC={soil_raw})"
            )

        gc.collect()  # Cegah fragmentasi RAM / MemoryError pada run 24 jam
        last_send = now

    time.sleep_ms(10)
