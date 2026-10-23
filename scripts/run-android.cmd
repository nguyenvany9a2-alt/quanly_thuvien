@echo off
cd /d "%~dp0.."
call flutter pub get
if errorlevel 1 exit /b 1
call flutter run -d emulator-5554
