@echo off
schtasks /delete /tn "AttendanceTrackerServer" /f
echo [OK] Auto-start removed.
pause
