Add-Type -AssemblyName System.Windows.Forms

# Selecionar Word
$openWord = New-Object System.Windows.Forms.OpenFileDialog
$openWord.Filter = "Word (*.docx)|*.docx"
$openWord.Title = "Selecione o modelo Word"

if ($openWord.ShowDialog() -ne "OK") { exit }
$wordFile = $openWord.FileName

# Selecionar CSV
$openCSV = New-Object System.Windows.Forms.OpenFileDialog
$openCSV.Filter = "CSV (*.csv)|*.csv"
$openCSV.Title = "Selecione o CSV"

if ($openCSV.ShowDialog() -ne "OK") { exit }
$csvFile = $openCSV.FileName

# Saída
$outputFile = [System.IO.Path]::Combine(
    [System.IO.Path]::GetDirectoryName($wordFile),
    "Termos_Gerados.docx"
)

# Abrir Word
$word = New-Object -ComObject Word.Application
$word.Visible = $true

# Abrir documento
$doc = $word.Documents.Open($wordFile)

# 🔥 TRANSFORMAR EM MALA DIRETA
$doc.MailMerge.MainDocumentType = 0  # wdFormLetters

# 🔥 CONECTAR CSV (FORMA CORRETA)
$doc.MailMerge.OpenDataSource(
    $csvFile,
    $false,  # ConfirmConversions
    $true    # ReadOnly
)

# Executar
$doc.MailMerge.Destination = 0
$doc.MailMerge.Execute()

# Documento final
$resultDoc = $word.ActiveDocument

# Salvar
$resultDoc.SaveAs([ref] $outputFile)

Write-Host "OK! Gerado em: $outputFile"