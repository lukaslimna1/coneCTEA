@echo off
echo ==================================================
echo Abrindo Emulador: QA_Samsung_S24_S25_360dp
echo Modo: GPU Host (RTX 3060 Accelerated) + WHPX Accel
echo ==================================================
start "" "%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -avd QA_Samsung_S24_S25_360dp -gpu host -accel auto -no-snapshot-load -dns-server 8.8.8.8,8.8.4.4
echo Emulador enviado para o background.
pause


