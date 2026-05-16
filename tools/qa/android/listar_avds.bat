@echo off
echo ==================================================
echo Listando AVDs instalados
echo ==================================================
"%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -list-avds
pause
