@echo off
echo ==================================================
echo Abrindo Emulador: QA_Xiaomi_Redmi_POCO_1_5K_438dp
echo Modo: GPU Host (RTX 3060 Accelerated) + WHPX Accel
echo ==================================================
start "" "%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -avd QA_Xiaomi_Redmi_POCO_1_5K_438dp -gpu host -accel auto -no-snapshot-load -dns-server 8.8.8.8,8.8.4.4
echo Emulador enviado para o background.
pause


