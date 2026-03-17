@echo off
:: Registers the Attendance Tracker server to start automatically when Windows logs on.
:: Run this script ONCE as Administrator (right-click → Run as administrator).

set "TASK_NAME=AttendanceTrackerServer"
set "SCRIPT=%~dp0start_server.bat"

:: Remove existing task if any
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1

:: Create task: run at logon of any user, hidden window, highest privileges
schtasks /create ^
  /tn "%TASK_NAME%" ^
  /tr "\"%SCRIPT%\"" ^
  /sc ONLOGON ^
  /rl HIGHEST ^
  /f ^
  /it >nul

if %errorlevel% == 0 (
    echo [OK] Task "%TASK_NAME%" registered.
    echo      The server will start automatically at next login.
    echo      To start it now, run:  schtasks /run /tn "%TASK_NAME%"
) else (
    echo [ERROR] Failed to register task. Make sure you ran this as Administrator.
)
pause
