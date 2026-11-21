@echo off
echo ========================================================
echo   Running T.H.A.L.I.A ESP32 Hardware Simulator (10s)
echo ========================================================
cd backend
call venv\Scripts\activate.bat
python ..\scripts\esp32_simulator.py --interval 10 --mode safe
pause
