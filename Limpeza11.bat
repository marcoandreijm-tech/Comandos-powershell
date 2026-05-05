@echo off
title Otimizando o Windows - Por Marco
color 0A

echo Limpando arquivos temporários...
del /q /f /s "%TEMP%\*.*"
del /q /f /s "%TMP%\*.*"
del /q /f /s "%LOCALAPPDATA%\Temp\*.*"
del /q /f /s "%SYSTEMROOT%\Temp\*.*"
del /q /s /f %TEMP%\*.*
del /q /f /s %temp%\*
del /q /s /f "%SYSTEMROOT%\Prefetch\*.*
del /q /s /f "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db
del /q /s /f "%SYSTEMROOT%\SoftwareDistribution\Download\*.*
del /q /s /f "%LOCALAPPDATA%\Temp\*.*
del /q /s /f "AppData\Local\Temp\*.*
del /q /s /f "%TMP%\*.*
rmdir /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache

Stop-Process -Name msedgewebview2 -Force

echo Limpando prefetch e cache do Windows...
del /q /f /s "%SYSTEMROOT%\Prefetch\*.*"
del /q /f /s "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db"
del /q /f /s "%SYSTEMROOT%\SoftwareDistribution\Download\*.*"

echo Limpando cache do Chrome (se instalado)...
rmdir /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache"

echo Executando limpeza com o Cleanmgr...
echo cleanmgr /sageset:1 >nul
echo cleanmgr /sagerun:1 >nul

echo xxxxxxxxxxxxxxxxxxxxxxx
echo Limpando componentes obsoletos do Windows...
echo dism /online /cleanup-image /startcomponentcleanup

echo Verificando e reparando arquivos do sistema...
echo sfc /scannow

echo Ativando plano de alto desempenho...
powercfg -setactive SCHEME_MAX


cd\windows\system32
echo Resetando configurações de rede...
ipconfig /flushdns
netsh INT IP RESET ALL
netsh winsock reset
powercfg -setactive SCHEME_MAX
nbtstat -r
nbtstat -rr
ipconfig /renew