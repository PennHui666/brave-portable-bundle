@echo off
setlocal EnableExtensions

set "WRAPPER=%~dp0brave-portable.exe"
set "PROGID=BravePortableHTML"
set "CLIENT=BravePortable"
set "APPNAME=Brave Portable"
set "DESC=Brave Portable: data stored in this folder."

echo ============================================
echo   Brave Portable - Setup
echo ============================================
echo.

if not exist "%WRAPPER%" (
    echo [ERROR] Launcher not found: %WRAPPER%
    echo Please ensure setup.bat and brave-portable.exe are in the same folder.
    goto :end
)

echo [1/4] Registering protocol ProgID (%PROGID%)...
reg add "HKCU\Software\Classes\%PROGID%" /ve /d "Brave Portable Document" /f >nul
reg add "HKCU\Software\Classes\%PROGID%\DefaultIcon" /ve /d "\"%WRAPPER%\",0" /f >nul
reg add "HKCU\Software\Classes\%PROGID%\shell\open\command" /ve /d "\"%WRAPPER%\" \"%%1\"" /f >nul

echo [2/4] Registering browser client (StartMenuInternet\%CLIENT%)...
reg add "HKCU\Software\Clients\StartMenuInternet\%CLIENT%" /ve /d "%APPNAME%" /f >nul
reg add "HKCU\Software\Clients\StartMenuInternet\%CLIENT%\DefaultIcon" /ve /d "\"%WRAPPER%\",0" /f >nul
reg add "HKCU\Software\Clients\StartMenuInternet\%CLIENT%\shell\open\command" /ve /d "\"%WRAPPER%\"" /f >nul
reg add "HKCU\Software\Clients\StartMenuInternet\%CLIENT%\Capabilities" /v ApplicationName /d "%APPNAME%" /f >nul
reg add "HKCU\Software\Clients\StartMenuInternet\%CLIENT%\Capabilities" /v ApplicationDescription /d "%DESC%" /f >nul
reg add "HKCU\Software\Clients\StartMenuInternet\%CLIENT%\Capabilities\Startmenu" /v StartMenuInternet /d "%CLIENT%" /f >nul
reg add "HKCU\Software\Clients\StartMenuInternet\%CLIENT%\Capabilities\URLAssociations" /v http /d "%PROGID%" /f >nul
reg add "HKCU\Software\Clients\StartMenuInternet\%CLIENT%\Capabilities\URLAssociations" /v https /d "%PROGID%" /f >nul
reg add "HKCU\Software\Clients\StartMenuInternet\%CLIENT%\Capabilities\FileAssociations" /v .html /d "%PROGID%" /f >nul
reg add "HKCU\Software\Clients\StartMenuInternet\%CLIENT%\Capabilities\FileAssociations" /v .htm /d "%PROGID%" /f >nul
reg add "HKCU\Software\Clients\StartMenuInternet\%CLIENT%\Capabilities\FileAssociations" /v .shtml /d "%PROGID%" /f >nul
reg add "HKCU\Software\Clients\StartMenuInternet\%CLIENT%\Capabilities\FileAssociations" /v .xht /d "%PROGID%" /f >nul
reg add "HKCU\Software\Clients\StartMenuInternet\%CLIENT%\Capabilities\FileAssociations" /v .xhtml /d "%PROGID%" /f >nul

echo [3/4] Registering to default apps list (RegisteredApplications)...
reg add "HKCU\Software\RegisteredApplications" /v "%APPNAME%" /d "Software\Clients\StartMenuInternet\%CLIENT%\Capabilities" /f >nul

echo [4/4] Creating desktop shortcut...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ws=New-Object -ComObject WScript.Shell; $p=[Environment]::GetFolderPath('Desktop')+'\Brave Portable.lnk'; $s=$ws.CreateShortcut($p); $s.TargetPath='%~dp0launch.vbs'; $s.WorkingDirectory='%~dp0'; $s.IconLocation='%WRAPPER%,0'; $s.Description='Brave Portable launcher'; $s.Save(); Write-Output ('Created: '+$p)"

echo.
echo ============================================
echo   Setup complete
echo ============================================
echo Next: set as default browser manually
echo   1. readme.html will open automatically
echo   2. Click the "Open default apps settings" button
echo   3. Find "Brave Portable" in the list and set as default
echo.
echo Do NOT click "Set as default browser" inside Brave.
echo.

start "" "%~dp0readme.html"

:end
echo.
pause
endlocal