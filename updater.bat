@echo off
chcp 65001 > nul 
setlocal

set TARGET_DIR=%~dp0
set RAW_CONTENT_URL="https://raw.githubusercontent.com/oslook/cursor-ai-downloads/main/README.md"


echo.
echo ===========================================
echo Start update...
echo Target install directory: %TARGET_DIR%
echo ===========================================
echo.

:: ==============================================
:: Use PowerShell to get latest files list, download and extract
:: ==============================================
powershell .\App\utils\updater.ps1 %TARGET_DIR% %RAW_CONTENT_URL%

if ERRORLEVEL 1 ( 
    echo.
    echo ERROR!
    echo.
    pause 
    endlocal 
    exit /b 
) 


pause 
endlocal
