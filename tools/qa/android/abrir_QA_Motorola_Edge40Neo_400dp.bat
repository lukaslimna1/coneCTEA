@echo off
echo ==================================================
echo Abrindo Emulador: QA_Motorola_Edge40Neo_400dp
echo Modo: ANGLE (GPU Indirect)
echo ==================================================
start "" "%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -avd QA_Motorola_Edge40Neo_400dp -gpu angle_indirect -no-snapshot-load
echo Emulador enviado para o background.
pause
