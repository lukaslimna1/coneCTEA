@echo off
echo ==================================================
echo Reiniciando servidor ADB e limpando conexoes antigas
echo ==================================================
adb kill-server
adb start-server
adb devices
pause
