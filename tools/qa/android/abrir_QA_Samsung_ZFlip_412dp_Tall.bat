@echo off
echo ==================================================
echo Abrindo Emulador: QA_Samsung_ZFlip_412dp_Tall
echo Modo: ANGLE (GPU Indirect)
echo ==================================================
start "" "%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -avd QA_Samsung_ZFlip_412dp_Tall -gpu angle_indirect -no-snapshot-load
echo Emulador enviado para o background.
pause
