@echo off
echo ==================================================
echo Abrindo Emulador: QA_Xiaomi_Redmi_POCO_1_5K_438dp
echo Modo: ANGLE (GPU Indirect)
echo ==================================================
start "" "%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -avd QA_Xiaomi_Redmi_POCO_1_5K_438dp -gpu angle_indirect -no-snapshot-load
echo Emulador enviado para o background.
pause
