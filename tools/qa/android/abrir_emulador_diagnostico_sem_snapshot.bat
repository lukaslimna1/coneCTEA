@echo off
echo ==================================================
echo Abrindo Emulador em Modo de Diagnostico
echo AVD: QA_Samsung_A15_A16_360dp
echo Modo: GPU Host + WHPX + Sem Carregamento/Salvamento de Snapshots
echo ==================================================
start "" "%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -avd QA_Samsung_A15_A16_360dp -gpu host -accel auto -no-snapshot-load -no-snapshot-save -dns-server 8.8.8.8,8.8.4.4
echo Emulador de Diagnostico enviado para o background.
pause

