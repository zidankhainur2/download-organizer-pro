@echo off
title Download Organizer Pro v2.1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0DownloadOrganizer.ps1" -GUI
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo An error occurred while launching Download Organizer Pro GUI.
    pause
)
