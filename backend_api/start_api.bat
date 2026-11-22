@echo off
cd /d "%~dp0"
echo Menjalankan T.H.A.L.I.A Personal API (PostgreSQL thalia_db) di port 8000...
echo Swagger Docs: http://localhost:8000/docs
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
pause
