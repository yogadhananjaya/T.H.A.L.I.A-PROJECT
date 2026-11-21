@echo off
echo ========================================================
echo   Starting T.H.A.L.I.A FastAPI Backend API (Port 8000)
echo ========================================================
cd backend
call venv\Scripts\activate.bat
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
pause
