@echo off
REM ============================================================
REM  T.H.A.L.I.A - Start semua sistem dengan satu klik
REM  1) Hardhat node  2) Deploy kontrak  3) Backend  4) Dashboard
REM ============================================================
setlocal
cd /d "%~dp0"

echo [1/4] Menjalankan Hardhat node (jendela baru)...
start "THALIA - Blockchain Node" cmd /k "cd /d "%~dp0blockchain" && npx hardhat node"

echo Menunggu node siap di port 8545...
powershell -NoProfile -Command "$ok=$false; 1..40 | ForEach-Object { try { $r=Invoke-RestMethod -Uri http://127.0.0.1:8545 -Method Post -ContentType 'application/json' -Body '{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}' -TimeoutSec 2; if($r.result){$ok=$true; break} } catch { Start-Sleep -Milliseconds 750 } }; if(-not $ok){ exit 1 }"
if errorlevel 1 (
  echo GAGAL: node Hardhat tidak merespons. Cek jendela "THALIA - Blockchain Node".
  pause
  exit /b 1
)

echo [2/4] Deploy smart contract...
cd /d "%~dp0blockchain"
call npx hardhat run scripts/deploy.js --network localhost
if errorlevel 1 (
  echo GAGAL deploy kontrak.
  pause
  exit /b 1
)

echo [3/4] Menjalankan backend (jendela baru)...
start "THALIA - Backend API" cmd /k "cd /d "%~dp0backend" && call venv\Scripts\activate.bat && python -m uvicorn app.main:app --host 0.0.0.0 --port 8000"

echo Menunggu backend siap...
powershell -NoProfile -Command "1..40 | ForEach-Object { try { Invoke-RestMethod http://127.0.0.1:8000/ -TimeoutSec 2 | Out-Null; exit 0 } catch { Start-Sleep -Milliseconds 750 } }; exit 1"

echo [4/4] Membuka dashboard...
start "" http://localhost:8000/dashboard

echo.
echo ================= SISTEM SIAP =================
echo  Dashboard : http://localhost:8000/dashboard
echo  Swagger   : http://localhost:8000/docs
echo  Simulator : jalankan run_simulator.bat (alur demo bertahap)
echo  JANGAN tutup jendela Blockchain Node dan Backend API.
echo ===============================================
pause
