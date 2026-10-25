@echo off
chcp 65001 >nul
setlocal EnableExtensions

set "WRAPPER=%~dp0brave-portable.exe"
set "PROGID=BravePortableHTML"
set "CLIENT=BravePortable"

if not exist "%WRAPPER%" (
    echo [错误] 未找到启动器：%WRAPPER%
    pause
    goto :eof
)

call :selfheal

start "" "%WRAPPER%" %*
exit /b

:selfheal
set "CUR="
for /f "tokens=2,*" %%a in ('reg query "HKCU\Software\Classes\%PROGID%\shell\open\command" /ve 2^>nul ^| find /i "REG_SZ"') do set "CUR=%%b"
if not defined CUR goto :eof
echo "%CUR%" | find /i "%WRAPPER%" >nul
if errorlevel 1 (
    echo [自愈] 检测到注册路径与当前位置不一致，正在修正...
    reg add "HKCU\Software\Classes\%PROGID%\shell\open\command" /ve /d "\"%WRAPPER%\" \"%%1\"" /f >nul
    reg add "HKCU\Software\Classes\%PROGID%\DefaultIcon" /ve /d "\"%WRAPPER%\",0" /f >nul
    reg add "HKCU\Software\Clients\StartMenuInternet\%CLIENT%\shell\open\command" /ve /d "\"%WRAPPER%\"" /f >nul
    reg add "HKCU\Software\Clients\StartMenuInternet\%CLIENT%\DefaultIcon" /ve /d "\"%WRAPPER%\",0" /f >nul
)
goto :eof