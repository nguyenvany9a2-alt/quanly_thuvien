@echo off
cd /d "%~dp0.."
if not exist server\.venv\Scripts\python.exe py -3 -m venv server\.venv
if errorlevel 1 exit /b 1
server\.venv\Scripts\python.exe -m pip install -r server\requirements.txt
if errorlevel 1 exit /b 1
if not exist server\data\mot.db (
  server\.venv\Scripts\python.exe server\manage.py init --demo
) else (
  server\.venv\Scripts\python.exe server\manage.py init
)
if errorlevel 1 exit /b 1
server\.venv\Scripts\python.exe -m uvicorn app:app --app-dir server --host 127.0.0.1 --port 8000
