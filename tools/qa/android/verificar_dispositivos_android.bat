@echo off
echo ==================================================
echo Verificando Dispositivos Android (ADB e Flutter)
echo ==================================================
echo.
echo [ADB Devices]
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" devices
echo.
echo [Flutter Devices]
flutter devices --device-timeout 60
echo.
pause
