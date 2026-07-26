@echo off
title Download Organizer Pro v2.1
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0DownloadOrganizer.ps1" -GUI
