#Requires -Version 5.1

param(
    [string]$Path = ".",
    [long]$MinSize = 1024
)

# ── Resolver caminho ──

$Target = (Resolve-Path -Path $Path -ErrorAction SilentlyContinue).Path
if (-not $Target -or -not (Test-Path -Path $Target -PathType Container)) {
    Write-Host "Erro: '$Path' nao e um diretorio valido." -ForegroundColor Red
    exit 1
}

# ── Funcoes auxiliares ──

function Format-HumanSize {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { "{0:N1} GB" -f ($Bytes / 1GB) }
    elseif ($Bytes -ge 1MB) { "{0:N1} MB" -f ($Bytes / 1MB) }
    elseif ($Bytes -ge 1KB) { "{0:N0} KB" -f ($Bytes / 1KB) }
    else { "$Bytes B" }
}

function Get-ShortPath {
    param([string]$FullPath)
    $userHome = $env:USERPROFILE
    if ($FullPath.StartsWith($userHome)) {
        return "~" + $FullPath.Substring($userHome.Length)
    }
    return $FullPath
}

# Diretorios a ignorar
$SkipDirs = @('node_modules', '.git', '__pycache__', '.venv', 'venv')

# ── Passo 1: Listar arquivos ──

Write-Host ""
Write-Host "  Escaneando $Target..." -ForegroundColor White
Write-Host "  (ignorando arquivos < $(Format-HumanSize $MinSize))" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  Listando arquivos..." -NoNewline

$allFiles = Get-ChildItem -Path $Target -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        $skip = $false
        foreach ($dir in $SkipDirs) {
            if ($_.FullName -match "[\\/]${dir}[\\/]") {
                $skip = $true
                break
            }
        }
        (-not $skip) -and ($_.Length -ge $MinSize) -and ($_.Name -notlike '.*')
    }

$totalFiles = $allFiles.Count
Write-Host "`r  $totalFiles arquivos encontrados" -ForegroundColor White
Write-Host ""

if ($totalFiles -eq 0) {
    Write-Host "  Nenhum arquivo encontrado." -ForegroundColor DarkGray
    exit 0
}

# ── Passo 2: Agrupar por tamanho ──

Write-Host "  Agrupando por tamanho..." -NoNewline

$sizeGroups = $allFiles | Group-Object Length | Where-Object { $_.Count -gt 1 }
$candidates = $sizeGroups | ForEach-Object { $_.Group }

if (-not $candidates) {
    Write-Host "`r  Nenhuma duplicata encontrada." -ForegroundColor Green
    exit 0
}

Write-Host "`r  $($candidates.Count) candidatos a duplicata" -ForegroundColor White

# ── Passo 3: Hash ──

$hashResults = @()
$i = 0

foreach ($file in $candidates) {
    $i++
    if ($i % 50 -eq 0) {
        Write-Host "`r  Calculando hashes... $i/$($candidates.Count)" -NoNewline
    }

    try {
        $hash = Get-FileHash $file.FullName -Algorithm SHA256 -ErrorAction Stop
        $hashResults += [PSCustomObject]@{
            Hash = $hash.Hash
            Size = $file.Length
            Path = $file.FullName
        }
    } catch {
        # ignora erro
    }
}

Write-Host "`r  Calculando hashes... concluido" -ForegroundColor Green
Write-Host ""

# ── Passo 4: Agrupar por hash ──

$dupGroups = $hashResults | Group-Object Hash | Where-Object { $_.Count -gt 1 }

if ($dupGroups.Count -eq 0) {
    Write-Host "  Nenhuma duplicata encontrada." -ForegroundColor Green
    exit 0
}

# ── Passo 5: Exibir ──

$totalRecoverable = 0
$totalDupFiles = 0
$groupNum = 0

Write-Host "  Duplicatas encontradas:`n"

foreach ($group in $dupGroups) {
    $groupNum++
    $copies = $group.Count
    $size = $group.Group[0].Size
    $recoverable = $size * ($copies - 1)

    $totalRecoverable += $recoverable
    $totalDupFiles += $copies

    Write-Host "  Grupo $groupNum -- $copies copias -- $(Format-HumanSize $recoverable) recuperaveis" -ForegroundColor Yellow
    Write-Host "  Hash: $($group.Name.Substring(0,16))..." -ForegroundColor DarkGray

    foreach ($item in $group.Group) {
        Write-Host "    $(Get-ShortPath $item.Path)"
    }
    Write-Host ""
}

# ── Resumo ──

Write-Host "  -----------------------------------------------"
Write-Host "  Grupos:              $groupNum"
Write-Host "  Arquivos duplicados: $totalDupFiles"
Write-Host "  Espaco recuperavel:  $(Format-HumanSize $totalRecoverable)" -ForegroundColor Red
Write-Host "  -----------------------------------------------"
Write-Host ""
Write-Host "  Nenhum arquivo foi deletado." -ForegroundColor DarkGray