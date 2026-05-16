@echo off
echo ==================================================
echo Abrindo Emulador: QA_Motorola_Edge_Curved_384dp
echo Modo: ANGLE (GPU Indirect)
echo ==================================================
start "" "%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -avd QA_Motorola_Edge_Curved_384dp -gpu angle_indirect -no-snapshot-load
echo Emulador enviado para o background.
pause
