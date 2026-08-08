#Requires -Version 5.1

Add-Type -AssemblyName System.Windows.Forms

# ── Selecionar pasta ──
$dialog = New-Object System.Windows.Forms.FolderBrowserDialog
$dialog.Description = "Selecione a pasta onde deseja procurar arquivos duplicados"
$dialog.ShowNewFolderButton = $false

if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "Nenhuma pasta foi selecionada." -ForegroundColor Yellow
    exit
}

$Target = $dialog.SelectedPath

Write-Host "`nPasta selecionada:" -ForegroundColor Cyan
Write-Host $Target -ForegroundColor White

# ── Pasta de duplicados ──
$DupFolder = "_Duplicados"
$DupPath = Join-Path $Target $DupFolder

if (-not (Test-Path $DupPath)) {
    New-Item -ItemType Directory -Path $DupPath | Out-Null
}

# ── Tamanho mínimo ──
$MinSize = 1024

# ── Funções ──
function Format-HumanSize {
    param([long]$Bytes)

    if ($Bytes -ge 1GB) {
        "{0:N1} GB" -f ($Bytes / 1GB)
    }
    elseif ($Bytes -ge 1MB) {
        "{0:N1} MB" -f ($Bytes / 1MB)
    }
    elseif ($Bytes -ge 1KB) {
        "{0:N0} KB" -f ($Bytes / 1KB)
    }
    else {
        "$Bytes B"
    }
}

function Get-ShortPath {
    param([string]$FullPath)

    $userHome = $env:USERPROFILE

    if ($FullPath.StartsWith($userHome)) {
        return "~" + $FullPath.Substring($userHome.Length)
    }

    return $FullPath
}

# ── Diretórios ignorados ──
$SkipDirs = @(
    'node_modules',
    '.git',
    '__pycache__',
    '.venv',
    'venv',
    '_Duplicados'
)

# ── Listar arquivos ──
Write-Host "`nProcurando arquivos..." -ForegroundColor Cyan

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

Write-Host "Arquivos encontrados: $($allFiles.Count)" -ForegroundColor Gray

# ── Agrupar por tamanho ──
$sizeGroups = $allFiles |
    Group-Object Length |
    Where-Object { $_.Count -gt 1 }

$candidates = $sizeGroups |
    ForEach-Object { $_.Group }

Write-Host "Possíveis duplicados: $($candidates.Count)" -ForegroundColor Gray

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

    }
    catch {
        Write-Host "Não foi possível calcular hash: $($file.FullName)" -ForegroundColor Yellow
    }
}

# ── Agrupar duplicados ──
$dupGroups = $hashResults |
    Group-Object Hash |
    Where-Object { $_.Count -gt 1 }

if (-not $dupGroups -or $dupGroups.Count -eq 0) {

    Write-Host "`nNenhuma duplicata encontrada." -ForegroundColor Green

    # Remover pasta vazia criada
    if (Test-Path $DupPath) {
        Remove-Item $DupPath -Force -ErrorAction SilentlyContinue
    }

    exit
}

# ── Mostrar duplicatas ──
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "       DUPLICATAS ENCONTRADAS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$filesToMove = @()
$totalSize = 0

foreach ($group in $dupGroups) {

    $files = $group.Group

    Write-Host "Grupo ($($files.Count) arquivos):" -ForegroundColor Yellow

    # Mantém o primeiro arquivo
    $keep = $files[0]

    foreach ($item in $files) {

        if ($item -eq $keep) {

            Write-Host "  [MANTER] $(Get-ShortPath $item.Path)" -ForegroundColor Green

        }
        else {

            Write-Host "  [MOVER]  $(Get-ShortPath $item.Path)" -ForegroundColor Red

            $filesToMove += $item.Path
            $totalSize += $item.Size
        }
    }

    Write-Host ""
}

# ── Resumo ──
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Arquivos a mover : $($filesToMove.Count)"
Write-Host "Espaço recuperável: $(Format-HumanSize $totalSize)"
Write-Host "Destino: $DupPath"
Write-Host "========================================`n" -ForegroundColor Cyan

# ── Pergunta ao usuário ──
$confirm = Read-Host "Deseja mover os arquivos duplicados? (S/N)"

if ($confirm -match '^[sS]') {

    $contador = 0

    foreach ($file in $filesToMove) {

        try {

            $dest = Join-Path $DupPath ([System.IO.Path]::GetFileName($file))

            # Evitar sobrescrever
            $i = 1

            while (Test-Path $dest) {

                $name = [System.IO.Path]::GetFileNameWithoutExtension($file)
                $ext = [System.IO.Path]::GetExtension($file)

                $dest = Join-Path $DupPath ("${name}_$i$ext")

                $i++
            }

            Move-Item `
                -Path $file `
                -Destination $dest `
                -Force `
                -ErrorAction Stop

            $contador++

            Write-Host "[$contador/$($filesToMove.Count)] Movido: $(Get-ShortPath $file)" `
                -ForegroundColor DarkYellow

        }
        catch {

            Write-Host "Erro ao mover: $file" -ForegroundColor Yellow
        }
    }

    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "Concluído!" -ForegroundColor Green
    Write-Host "Arquivos movidos: $contador" -ForegroundColor Green
    Write-Host "Destino: $DupPath" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green

}
else {

    Write-Host "`nNenhum arquivo foi movido." -ForegroundColor Cyan
}