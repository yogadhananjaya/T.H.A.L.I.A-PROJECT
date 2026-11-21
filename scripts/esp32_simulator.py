"""
T.H.A.L.I.A - ESP32 IoT Node Hardware Simulator
Simulates a physical ESP32 sensor node sending telemetry every 10-15 seconds.
Sensors simulated:
  1. Atmosphere: BME280 (Temperature, Humidity, Barometric Pressure)
  2. Hydrosphere: Rain Sensor (Rainfall Intensity mm/h)
  3. Lithosphere: Soil Moisture Sensor (% Saturation)
"""

import time
import random
import requests
import argparse
import sys

API_URL = "http://localhost:8000/api/v1/telemetry"

def generate_telemetry(mode="safe"):
    """
    Generate realistic sensor readings based on current simulated climate state.
    """
    if mode == "safe":
        temp = round(random.uniform(24.0, 27.0), 1)
        humidity = round(random.uniform(65.0, 75.0), 1)
        pressure = round(random.uniform(1010.0, 1014.0), 1)
        rainfall = round(random.uniform(0.0, 5.0), 1)
        soil = round(random.uniform(35.0, 55.0), 1)
    elif mode == "alert":
        temp = round(random.uniform(22.0, 24.0), 1)
        humidity = round(random.uniform(85.0, 92.0), 1)
        pressure = round(random.uniform(1004.0, 1007.0), 1)
        rainfall = round(random.uniform(22.0, 35.0), 1)
        soil = round(random.uniform(66.0, 78.0), 1)
    elif mode == "danger":
        temp = round(random.uniform(20.0, 22.0), 1)
        humidity = round(random.uniform(94.0, 99.0), 1)
        pressure = round(random.uniform(998.0, 1003.0), 1)
        rainfall = round(random.uniform(45.0, 65.0), 1)
        soil = round(random.uniform(82.0, 92.0), 1) # Saturated slope
    else:
        temp, humidity, pressure, rainfall, soil = 25.0, 70.0, 1012.0, 2.0, 40.0

    return {
        "node_id": "ESP32-NODE-01",
        "location_name": "Desa Sukamaju, Titik Rawan Lereng A",
        "latitude": -6.9175,
        "longitude": 107.6191,
        "temperature_c": temp,
        "humidity_pct": humidity,
        "pressure_hpa": pressure,
        "rainfall_mm_h": rainfall,
        "rainfall_raw": int(rainfall * 20),
        "soil_moisture_pct": soil,
        "soil_raw": int(soil * 40)
    }

def run_loop(target_url, interval, mode):
    print(f"==================================================")
    print(f"  T.H.A.L.I.A - ESP32 Hardware Simulator Starting ")
    print(f"  Target: {target_url}")
    print(f"  Interval: {interval} seconds | Initial Mode: {mode.upper()}")
    print(f"==================================================")

    step = 0
    current_mode = mode
    while True:
        step += 1
        payload = generate_telemetry(current_mode)
        try:
            res = requests.post(target_url, json=payload, timeout=5)
            if res.status_code == 200:
                data = res.json()
                print(f"[{time.strftime('%X')}] Step #{step:03d} | Status: {data.get('status'):<7} | "
                      f"Rain: {payload['rainfall_mm_h']:>4.1f} mm/h | Soil: {payload['soil_moisture_pct']:>4.1f}% | "
                      f"Temp: {payload['temperature_c']}C | Status Reason: {data.get('status_reason')[:40]}...")
            else:
                print(f"[{time.strftime('%X')}] Error {res.status_code}: {res.text}")
        except Exception as e:
            print(f"[{time.strftime('%X')}] Connection Error: {e}")

        time.sleep(interval)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="T.H.A.L.I.A ESP32 Node Simulator")
    parser.add_argument("--url", default=API_URL, help="Target backend API URL")
    parser.add_argument("--interval", type=int, default=10, help="Transmission interval in seconds (default: 10)")
    parser.add_argument("--mode", default="safe", choices=["safe", "alert", "danger"], help="Initial climate state")
    args = parser.parse_args()

    try:
        run_loop(args.url, args.interval, args.mode)
    except KeyboardInterrupt:
        print("\nSimulator stopped by user.")
