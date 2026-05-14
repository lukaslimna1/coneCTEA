@echo off
echo ==================================================
echo Abrindo Emulador: Samsung_A05_Small (QA ConeCTEA)
echo Modo: ANGLE (GPU Indirect)
echo ==================================================
start "" "%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -avd Samsung_A05_Small -gpu angle_indirect -no-snapshot-load
echo Emulador enviado para o background.
pause
