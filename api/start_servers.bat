@echo off
title CineTrack Server Manager
echo ========================================================
echo          CineTrack Backend Baslatiliyor...
echo ========================================================

REM 1. MySQL Kontrolu ve Baslatilmasi
netstat -ano | findstr :3306 >nul
if %errorlevel% neq 0 (
    echo [1/2] MySQL (MariaDB) baslatiliyor...
    start /b "" "C:\xampp\mysql\bin\mysqld.exe" --defaults-file="C:\xampp\mysql\bin\my.ini" --standalone
    timeout /t 2 /nobreak >nul
) else (
    echo [1/2] MySQL zaten calisiyor (Port 3306).
)

REM 2. CodeIgniter API Sunucusu (Port 8080)
echo [2/2] CodeIgniter API Sunucusu baslatiliyor (http://localhost:8080)...
cd /d "C:\xampp\htdocs\cinetrack"
"C:\xampp\php\php.exe" spark serve --host 0.0.0.0 --port 8080

pause

