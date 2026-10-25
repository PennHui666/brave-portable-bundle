@echo off
chcp 65001 >nul
setlocal EnableExtensions

set "PROGID=BravePortableHTML"
set "CLIENT=BravePortable"
set "APPNAME=Brave Portable"

echo ============================================
echo   Brave Portable - 取消注册
echo ============================================
echo.
echo 本操作将删除本方案写入的全部注册表键（不改变当前默认浏览器设置）。
echo.

set "WARN="
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\UrlAssociations\http\UserChoice" /v ProgId 2>nul | find /i "%PROGID%" >nul && set "WARN=1"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\UrlAssociations\https\UserChoice" /v ProgId 2>nul | find /i "%PROGID%" >nul && set "WARN=1"

if defined WARN (
    echo [警告] 检测到当前默认浏览器仍为 Brave Portable。
    echo 若直接取消注册，外部链接将无法打开。
    echo 请先在"默认应用"设置中改回其他浏览器，再运行本脚本。
    echo.
    choice /C YN /M "仍要继续删除吗？(Y/N)"
    if errorlevel 2 goto :end
)

echo.
echo [1/3] 删除协议 ProgID...
reg delete "HKCU\Software\Classes\%PROGID%" /f >nul 2>&1

echo [2/3] 删除浏览器客户端注册...
reg delete "HKCU\Software\Clients\StartMenuInternet\%CLIENT%" /f >nul 2>&1

echo [3/3] 删除默认应用候选登记...
reg delete "HKCU\Software\RegisteredApplications" /v "%APPNAME%" /f >nul 2>&1

echo.
echo 删除完成。桌面快捷方式未自动删除，如不再需要可手动删除。
echo.

:end
pause
endlocal