@echo off
echo ========================================================
echo   T.H.A.L.I.A ESP32 Simulator - mode DEMO bertahap
echo   Aman - Waspada - Bahaya - pulih (1 langkah = 5 detik)
echo   Hentikan dengan Ctrl+C
echo ========================================================
cd /d "%~dp0backend"
call venv\Scripts\activate.bat
python ..\scripts\esp32_simulator.py --interval 5 --mode demo
pause
