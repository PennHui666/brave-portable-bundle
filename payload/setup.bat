@echo off
chcp 65001 >nul
setlocal EnableExtensions

set "WRAPPER=%~dp0brave-portable.exe"
set "PROGID=BravePortableHTML"
set "CLIENT=BravePortable"
set "APPNAME=Brave Portable"
set "DESC=Brave 便携版：数据保存在本文件夹内。"

echo ============================================
echo   Brave Portable - 首次注册
echo ============================================
echo.

if not exist "%WRAPPER%" (
    echo [错误] 未找到启动器：%WRAPPER%
    echo 请确认本脚本与 brave-portable.exe 位于同一目录。
    goto :end
)

echo [1/4] 注册协议 ProgID（%PROGID%）...
reg add "HKCU\Software\Classes\%PROGID%" /ve /d "Brave Portable Document" /f >nul
reg add "HKCU\Software\Classes\%PROGID%\DefaultIcon" /ve /d "\"%WRAPPER%\",0" /f >nul
reg add "HKCU\Software\Classes\%PROGID%\shell\open\command" /ve /d "\"%WRAPPER%\" \"%%1\"" /f >nul

echo [2/4] 注册浏览器客户端（StartMenuInternet\%CLIENT%）...
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

echo [3/4] 登记到默认应用候选（RegisteredApplications）...
reg add "HKCU\Software\RegisteredApplications" /v "%APPNAME%" /d "Software\Clients\StartMenuInternet\%CLIENT%\Capabilities" /f >nul

echo [4/4] 创建桌面快捷方式...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ws=New-Object -ComObject WScript.Shell; $p=[Environment]::GetFolderPath('Desktop')+'\Brave Portable.lnk'; $s=$ws.CreateShortcut($p); $s.TargetPath='%~dp0launch.vbs'; $s.WorkingDirectory='%~dp0'; $s.IconLocation='%WRAPPER%,0'; $s.Description='Brave Portable 便携启动器'; $s.Save(); Write-Output ('已创建：'+$p)"

echo.
echo ============================================
echo   注册完成
echo ============================================
echo 接下来请手动设置默认浏览器：
echo   1. 即将自动打开说明页 readme.html
echo   2. 点击页面中的"打开默认应用设置"按钮
echo   3. 在列表中找到"Brave Portable"并设为默认
echo.
echo 切勿点击 Brave 内部的"设为默认浏览器"。
echo.

start "" "%~dp0readme.html"

:end
echo.
pause
endlocal