@echo off
echo ==================================================
echo Abrindo Emulador: QA_Samsung_S24_S25_Ultra_480dp
echo Modo: ANGLE (GPU Indirect)
echo ==================================================
start "" "%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -avd QA_Samsung_S24_S25_Ultra_480dp -gpu angle_indirect -no-snapshot-load
echo Emulador enviado para o background.
pause
