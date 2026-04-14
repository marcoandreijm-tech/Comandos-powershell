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

# ── Funções ──
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

# Diretórios ignorados
$SkipDirs = @('node_modules', '.git', '__pycache__', '.venv', 'venv')

# ── Listar arquivos ──
$allFiles = Get-ChildItem -Path $Target -Recurse -File -ErrorAction SilentlyContinue |
Where-Object {
    $skip = $false
    foreach ($dir in $SkipDirs) {
        if ($_.FullName -match "[\\/]${dir}[\\/]") {
            $skip = $true
            break
        }
    }
    (-not $skip) -and ($_.Length -ge $MinSize)
}

# ── Agrupar por tamanho ──
$sizeGroups = $allFiles | Group-Object Length | Where-Object { $_.Count -gt 1 }
$candidates = $sizeGroups | ForEach-Object { $_.Group }

# ── Hash ──
$hashResults = @()

foreach ($file in $candidates) {
    try {
        $hash = Get-FileHash $file.FullName -Algorithm SHA256
        $hashResults += [PSCustomObject]@{
            Hash = $hash.Hash
            Size = $file.Length
            Path = $file.FullName
        }
    } catch {}
}

# ── Agrupar duplicados ──
$dupGroups = $hashResults | Group-Object Hash | Where-Object { $_.Count -gt 1 }

if ($dupGroups.Count -eq 0) {
    Write-Host "Nenhuma duplicata encontrada." -ForegroundColor Green
    exit
}

# ── Mostrar duplicatas ──
Write-Host "`nDuplicatas encontradas:`n"

$filesToDelete = @()

foreach ($group in $dupGroups) {
    $files = $group.Group
    Write-Host "Grupo ($($files.Count) arquivos):" -ForegroundColor Yellow

    # Mantém o primeiro
    $keep = $files[0]

    foreach ($item in $files) {
        if ($item -eq $keep) {
            Write-Host "  [MANTER] $(Get-ShortPath $item.Path)" -ForegroundColor Green
        } else {
            Write-Host "  [DELETAR] $(Get-ShortPath $item.Path)" -ForegroundColor Red
            $filesToDelete += $item.Path
        }
    }
    Write-Host ""
}

# ── Pergunta ao usuário ──
Write-Host "Total a deletar: $($filesToDelete.Count) arquivos"
$confirm = Read-Host "Deseja deletar os arquivos duplicados? (S/N)"

if ($confirm -match '^[sS]') {

    $confirm2 = Read-Host "Tem certeza absoluta? Essa ação NÃO pode ser desfeita! (S/N)"

    if ($confirm2 -match '^[sS]') {

        foreach ($file in $filesToDelete) {
            try {
                Remove-Item -Path $file -Force -ErrorAction Stop
                Write-Host "Deletado: $(Get-ShortPath $file)" -ForegroundColor DarkRed
            } catch {
                Write-Host "Erro ao deletar: $file" -ForegroundColor Yellow
            }
        }

        Write-Host "`nLimpeza concluida!" -ForegroundColor Green

    } else {
        Write-Host "Operacao cancelada." -ForegroundColor Yellow
    }

} else {
    Write-Host "Nenhum arquivo foi deletado." -ForegroundColor Cyan
}