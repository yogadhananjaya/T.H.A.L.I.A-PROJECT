@echo off
echo ========================================================
echo   Deploying THALIARegistry Smart Contract to Local Node
echo ========================================================
cd blockchain
call npx hardhat run scripts/deploy.js --network localhost
pause
