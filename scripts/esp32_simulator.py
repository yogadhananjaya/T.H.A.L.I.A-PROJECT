"""
T.H.A.L.I.A - ESP32 IoT Node Hardware Simulator

Mode:
  safe / alert / danger : nilai acak di sekitar kondisi tersebut (konstan)
  demo                  : alur cerita bertahap Aman -> Waspada -> Bahaya -> pulih
                          (cocok untuk presentasi; tiap langkah = --interval detik)
"""

import time
import random
import argparse
import requests

API_URL = "http://localhost:8000/api/v1/telemetry"
LOCATION = "Cibatu, Cikarang Selatan, Bekasi"


def lerp(a, b, t):
    return a + (b - a) * max(0.0, min(1.0, t))


def demo_values(step, total=36):
    """Storyline: 0-30% aman, 30-60% hujan makin deras (waspada), 60-85% bahaya, sisanya pulih."""
    p = (step % total) / total
    if p < 0.30:
        t = p / 0.30
        rain, soil, press, hum = lerp(0, 10, t), lerp(40, 50, t), lerp(1013, 1010, t), lerp(70, 78, t)
    elif p < 0.60:
        t = (p - 0.30) / 0.30
        rain, soil, press, hum = lerp(10, 48, t), lerp(50, 72, t), lerp(1010, 1004, t), lerp(78, 90, t)
    elif p < 0.85:
        t = (p - 0.60) / 0.25
        rain, soil, press, hum = lerp(48, 88, t), lerp(72, 90, t), lerp(1004, 999, t), lerp(90, 97, t)
    else:
        t = (p - 0.85) / 0.15
        rain, soil, press, hum = lerp(88, 5, t), lerp(90, 60, t), lerp(999, 1010, t), lerp(97, 80, t)
    j = lambda v, s: round(v + random.uniform(-s, s), 1)
    return j(rain, 0.8), j(soil, 0.5), j(press, 0.3), j(hum, 0.8), j(lerp(26, 21, p if p < 0.85 else 0.85), 0.2)


def generate_telemetry(mode="safe", step=0):
    if mode == "demo":
        rain, soil, pressure, humidity, temp = demo_values(step)
        rain, soil = min(max(rain, 0.0), 100.0), min(max(soil, 0.0), 100.0)
        humidity = min(humidity, 100.0)
    elif mode == "alert":
        temp = round(random.uniform(22.0, 24.0), 1)
        humidity = round(random.uniform(85.0, 92.0), 1)
        pressure = round(random.uniform(1004.0, 1007.0), 1)
        rain = round(random.uniform(35.0, 55.0), 1)
        soil = round(random.uniform(66.0, 78.0), 1)
    elif mode == "danger":
        temp = round(random.uniform(20.0, 22.0), 1)
        humidity = round(random.uniform(94.0, 99.0), 1)
        pressure = round(random.uniform(998.0, 1003.0), 1)
        rain = round(random.uniform(60.0, 92.0), 1)
        soil = round(random.uniform(82.0, 92.0), 1)
    else:
        temp = round(random.uniform(24.0, 27.0), 1)
        humidity = round(random.uniform(65.0, 75.0), 1)
        pressure = round(random.uniform(1010.0, 1014.0), 1)
        rain = round(random.uniform(0.0, 10.0), 1)
        soil = round(random.uniform(35.0, 55.0), 1)

    return {
        "node_id": "ESP32-NODE-01",
        "location_name": LOCATION,
        "latitude": -6.3378,
        "longitude": 107.1541,
        "temperature_c": temp,
        "humidity_pct": humidity,
        "pressure_hpa": pressure,
        "rainfall_pct": rain,
        "is_raining": rain >= 15.0,
        "rainfall_raw": int(rain * 40),
        "soil_moisture_pct": soil,
        "soil_raw": int(soil * 40),
    }


def run_loop(url, interval, mode):
    print("=" * 62)
    print(f"  T.H.A.L.I.A ESP32 Simulator | target: {url}")
    print(f"  interval: {interval}s | mode: {mode.upper()}")
    print("=" * 62)
    step = 0
    while True:
        payload = generate_telemetry(mode, step)
        try:
            res = requests.post(url, json=payload, timeout=5)
            if res.status_code == 200:
                d = res.json()
                print(f"[{time.strftime('%X')}] #{step:03d} {d.get('status'):<6} | "
                      f"hujan {payload['rainfall_pct']:>5.1f}% | tanah {payload['soil_moisture_pct']:>5.1f}% | "
                      f"tekanan {payload['pressure_hpa']:>6.1f}")
            else:
                print(f"[{time.strftime('%X')}] HTTP {res.status_code}: {res.text[:120]}")
        except Exception as e:
            print(f"[{time.strftime('%X')}] Tidak bisa terhubung: {e}")
        step += 1
        time.sleep(interval)


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description="T.H.A.L.I.A ESP32 Node Simulator")
    ap.add_argument("--url", default=API_URL)
    ap.add_argument("--interval", type=int, default=5)
    ap.add_argument("--mode", default="demo", choices=["safe", "alert", "danger", "demo"])
    a = ap.parse_args()
    try:
        run_loop(a.url, a.interval, a.mode)
    except KeyboardInterrupt:
        print("\nSimulator dihentikan.")
