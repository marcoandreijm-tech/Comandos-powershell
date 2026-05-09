Add-Type -AssemblyName System.Windows.Forms

# Selecionar primeira pasta
$Dialog1 = New-Object System.Windows.Forms.FolderBrowserDialog
$Dialog1.Description = "Selecione a PRIMEIRA pasta"

if ($Dialog1.ShowDialog() -ne "OK") { exit }

$Pasta1 = $Dialog1.SelectedPath

# Selecionar segunda pasta
$Dialog2 = New-Object System.Windows.Forms.FolderBrowserDialog
$Dialog2.Description = "Selecione a SEGUNDA pasta"

if ($Dialog2.ShowDialog() -ne "OK") { exit }

$Pasta2 = $Dialog2.SelectedPath

# Ler arquivos
$Arquivos1 = Get-ChildItem $Pasta1 -Recurse -File |
Select-Object -ExpandProperty Name

$Arquivos2 = Get-ChildItem $Pasta2 -Recurse -File |
Select-Object -ExpandProperty Name

Clear-Host

Write-Host "`n========================================" -ForegroundColor DarkGray
Write-Host "ARQUIVOS FALTANDO ENTRE AS PASTAS" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor DarkGray

Write-Host "Arquivos que existem na Pasta 1 e faltam na Pasta 2:" -ForegroundColor Cyan

Compare-Object $Arquivos1 $Arquivos2 |
Where-Object { $_.SideIndicator -eq "<=" } |
Select-Object -ExpandProperty InputObject

Write-Host "`n----------------------------------------`n" -ForegroundColor DarkGray

Write-Host "Arquivos que existem na Pasta 2 e faltam na Pasta 1:" -ForegroundColor Yellow

Compare-Object $Arquivos1 $Arquivos2 |
Where-Object { $_.SideIndicator -eq "=>" } |
Select-Object -ExpandProperty InputObject

Write-Host "`nComparação concluída!" -ForegroundColor Green
Pause