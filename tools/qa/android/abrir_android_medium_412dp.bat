@echo off
echo ==================================================
echo Abrindo Emulador: Android_Medium_412dp_QA
echo Modo: ANGLE (GPU Indirect)
echo ==================================================
start "" "%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -avd Android_Medium_412dp_QA -gpu angle_indirect -no-snapshot-load
echo Emulador enviado para o background.
pause
