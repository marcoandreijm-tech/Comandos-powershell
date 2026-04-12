Comando em powershell pra limpar arquivos temporarios windows
# Executar como Administrador
Clear-Host
Write-Host "Otimizando o Windows..." -ForegroundColor Green

# Função para apagar arquivos com segurança
function Limpar-Pasta {
    param ($caminho)

    if (Test-Path $caminho) {
        Write-Host "Limpando: $caminho"
        Get-ChildItem -Path $caminho -Recurse -Force -ErrorAction SilentlyContinue |
        Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    }
}

# Limpando arquivos temporários
Limpar-Pasta "$env:TEMP"
Limpar-Pasta "$env:TMP"
Limpar-Pasta "$env:LOCALAPPDATA\Temp"
Limpar-Pasta "$env:WINDIR\Temp"

# Prefetch e cache do sistema
Limpar-Pasta "$env:WINDIR\Prefetch"
Limpar-Pasta "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"

# Windows Update cache
Limpar-Pasta "$env:WINDIR\SoftwareDistribution\Download"

# Cache do Chrome
$chromeCache = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
if (Test-Path $chromeCache) {
    Write-Host "Limpando cache do Chrome..."
    Remove-Item $chromeCache -Recurse -Force -ErrorAction SilentlyContinue
}

# Limpeza de disco (Cleanmgr)
Write-Host "Executando limpeza de disco..."
Start-Process cleanmgr -ArgumentList "/sagerun:1" -Wait

# Limpeza de componentes do Windows
Write-Host "Limpando componentes do sistema..."
Start-Process dism -ArgumentList "/online /cleanup-image /startcomponentcleanup" -Wait

# Verificação de arquivos do sistema
Write-Host "Verificando arquivos do sistema (SFC)..."
Start-Process sfc -ArgumentList "/scannow" -Wait

# Plano de energia alto desempenho
Write-Host "Ativando alto desempenho..."
powercfg -setactive SCHEME_MAX

# Reset de rede
Write-Host "Resetando rede..."
ipconfig /flushdns
netsh int ip reset
netsh winsock reset
nbtstat -r
nbtstat -rr
ipconfig /renew

Write-Host "Processo concluído!" -ForegroundColor Green
Pause