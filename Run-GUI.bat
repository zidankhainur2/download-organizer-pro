@echo off
title Download Organizer Pro
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0DownloadOrganizer.ps1" -GUI
