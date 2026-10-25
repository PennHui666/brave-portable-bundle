@echo off
setlocal EnableExtensions

set "PROGID=BravePortableHTML"
set "CLIENT=BravePortable"
set "APPNAME=Brave Portable"

echo ============================================
echo   Brave Portable - Unregister
echo ============================================
echo.
echo This will delete all registry keys written by setup.bat.
echo It will NOT change your current default browser setting.
echo.

set "WARN="
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\UrlAssociations\http\UserChoice" /v ProgId 2>nul | find /i "%PROGID%" >nul && set "WARN=1"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\UrlAssociations\https\UserChoice" /v ProgId 2>nul | find /i "%PROGID%" >nul && set "WARN=1"

if defined WARN (
    echo [WARNING] Current default browser is still Brave Portable.
    echo If you unregister now, external links will fail to open.
    echo Please switch to another browser in default apps settings first.
    echo.
    choice /C YN /M "Continue anyway? (Y/N)"
    if errorlevel 2 goto :end
)

echo.
echo [1/3] Deleting protocol ProgID...
reg delete "HKCU\Software\Classes\%PROGID%" /f >nul 2>&1

echo [2/3] Deleting browser client registration...
reg delete "HKCU\Software\Clients\StartMenuInternet\%CLIENT%" /f >nul 2>&1

echo [3/3] Deleting default apps registration...
reg delete "HKCU\Software\RegisteredApplications" /v "%APPNAME%" /f >nul 2>&1

echo.
echo Done. Desktop shortcut was not removed; delete it manually if needed.
echo.

:end
pause
endlocal