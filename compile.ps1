# compile.ps1
# Script for building QutyOS theme and creating .qutytheme file

# Set UTF-8 encoding for console
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=========================================="
Write-Host "📦 Сборка темы QutyOS"
Write-Host "=========================================="
Write-Host ""

# Parameters
$projectPath = "D:\Android\Themes\Quty.Launch.Theme.QutyOS"
$distPath = "D:\Android\Themes\Quty.Launch.Theme.QutyOS\dist"
$outputPath = "D:\Android\Themes\Quty.Launch.Theme.QutyOS\output"
$themeName = "QutyOS"
$publicPath = Join-Path $projectPath "public"

# Files to keep in the theme (copied from public folder to dist)
$keepFiles = @("manifest.json", "preview.png", "preview.ico", "preview.jpg", "favicon.ico")

# Create output folder if it doesn't exist
if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
    Write-Host "📁 Создана папка вывода: $outputPath" -ForegroundColor Cyan
}

# Create public folder if it doesn't exist
if (-not (Test-Path $publicPath)) {
    New-Item -ItemType Directory -Path $publicPath -Force | Out-Null
    Write-Host "📁 Создана папка public: $publicPath" -ForegroundColor Cyan
}

# ============================================
# READ CURRENT VERSION FROM manifest.json
# ============================================
Write-Host "📋 Чтение текущей версии из manifest.json..." -ForegroundColor Cyan

$manifestPath = Join-Path $publicPath "manifest.json"
$currentVersion = "0.0.1"

if (Test-Path $manifestPath) {
    try {
        $manifestContent = Get-Content -Path $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $currentVersion = $manifestContent.version
        Write-Host "  ✅ Текущая версия: $currentVersion" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️ Не удалось прочитать manifest.json, используется версия по умолчанию: $currentVersion" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️ manifest.json не найден в public/, используется версия по умолчанию: $currentVersion" -ForegroundColor Yellow
}

# ============================================
# ASK FOR NEW VERSION
# ============================================
Write-Host ""
Write-Host "📝 Введите новый номер версии (сейчас $currentVersion):" -ForegroundColor Yellow
$newVersion = Read-Host "> "

if ([string]::IsNullOrEmpty($newVersion)) {
    $newVersion = $currentVersion
    Write-Host "  ⚠️ Оставлена текущая версия: $newVersion" -ForegroundColor Yellow
} else {
    Write-Host "  ✅ Новая версия: $newVersion" -ForegroundColor Green
}

# ============================================
# ASK FOR CHANGELOG
# ============================================
Write-Host ""
Write-Host "📝 Введите описание изменений (changelog) для этой версии:" -ForegroundColor Yellow
Write-Host "   (несколько строк, для окончания введите пустую строку)" -ForegroundColor Yellow
Write-Host ""

$changelog = ""
while ($true) {
    $line = Read-Host "> "
    if ([string]::IsNullOrEmpty($line)) {
        break
    }
    if ([string]::IsNullOrEmpty($changelog)) {
        $changelog = $line
    } else {
        $changelog = $changelog + "`n" + $line
    }
}

if ([string]::IsNullOrEmpty($changelog)) {
    $changelog = "Исправление багов и улучшение производительности"
    Write-Host "  ⚠️ Использован стандартный changelog" -ForegroundColor Yellow
}

# ============================================
# UPDATE manifest.json IN PUBLIC FOLDER (without BOM)
# ============================================
Write-Host ""
Write-Host "📝 Обновление версии в manifest.json (public/)..." -ForegroundColor Cyan

if (Test-Path $manifestPath) {
    try {
        $manifestContent = Get-Content -Path $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $manifestContent.version = $newVersion
        $jsonContent = $manifestContent | ConvertTo-Json -Depth 10
        # Сохраняем без BOM
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        $bytes = $utf8NoBom.GetBytes($jsonContent)
        [System.IO.File]::WriteAllBytes($manifestPath, $bytes)
        Write-Host "  ✅ Версия обновлена в public/manifest.json (без BOM)" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️ Не удалось обновить версию: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️ manifest.json не найден в public/, создаём новый..." -ForegroundColor Yellow
    $defaultManifest = @{
        name = "QutyOS Theme"
        author = "QutyTeam"
        version = $newVersion
        preview = "preview.png"
        repoUrl = "https://raw.githubusercontent.com/Sanya2104/Quty.Launch.Theme.QutyOS/main/"
    }
    $jsonContent = $defaultManifest | ConvertTo-Json -Depth 10
    # Сохраняем без BOM
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $bytes = $utf8NoBom.GetBytes($jsonContent)
    [System.IO.File]::WriteAllBytes($manifestPath, $bytes)
    Write-Host "  ✅ Создан public/manifest.json с версией $newVersion (без BOM)" -ForegroundColor Green
}

# ============================================
# RUN BUILD
# ============================================
Write-Host ""
Write-Host "🔨 Запуск сборки (npm run build)..." -ForegroundColor Cyan

# Go to project directory
Set-Location -Path $projectPath

try {
    npm run build
    if ($LASTEXITCODE -ne 0) {
        throw "Ошибка сборки"
    }
    Write-Host "  ✅ Сборка завершена успешно!" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Ошибка при выполнении сборки: $_" -ForegroundColor Red
    exit 1
}

# Check if dist directory exists
if (-not (Test-Path $distPath)) {
    Write-Host "  ❌ Ошибка: директория dist не найдена после сборки" -ForegroundColor Red
    exit 1
}

# ============================================
# COPY FILES FROM PUBLIC TO DIST (BACKUP)
# Vite should copy public files automatically,
# but we do this as a backup in case it doesn't
# ============================================
Write-Host ""
Write-Host "📋 Проверка наличия файлов из public в dist..." -ForegroundColor Cyan

foreach ($file in $keepFiles) {
    $sourceFile = Join-Path $publicPath $file
    $destFile = Join-Path $distPath $file
    
    if (Test-Path $sourceFile) {
        # Проверяем, есть ли файл в dist
        if (-not (Test-Path $destFile)) {
            Copy-Item -Path $sourceFile -Destination $destFile -Force
            Write-Host "  ✅ Скопирован (не был в dist): $file" -ForegroundColor Green
        } else {
            Write-Host "  ✅ Уже есть в dist: $file" -ForegroundColor Green
        }
    } else {
        Write-Host "  ⚠️ Файл не найден в public: $file" -ForegroundColor Yellow
    }
}

# ============================================
# CREATE .QUTYTHEME FILE
# ============================================
Write-Host ""
Write-Host "📦 Создание архива $themeName.qutytheme..." -ForegroundColor Cyan

# Проверяем содержимое dist
Write-Host "  📋 Содержимое dist:" -ForegroundColor Cyan
Get-ChildItem -Path $distPath | ForEach-Object { Write-Host "    $($_.Name)" }

# Переходим в папку dist
Push-Location $distPath

# Создаём архив через .NET (как в Windows "Отправить → Сжатая ZIP-папка")
$zipPath = Join-Path $env:TEMP "$themeName.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

# Используем .NET Compression для создания ZIP (как вручную)
Add-Type -AssemblyName System.IO.Compression.FileSystem
$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
$zip = [System.IO.Compression.ZipFile]::Open($zipPath, 'Create')

# Добавляем все файлы и папки из dist
Get-ChildItem -Path . -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Substring((Get-Location).Path.Length + 1)
    if ($_.PSIsContainer) {
        # Пропускаем папки — они создаются автоматически при добавлении файлов
        # (папка создастся, когда добавим первый файл внутри неё)
    } else {
        # Добавляем файл
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $relativePath)
    }
}

$zip.Dispose()

# Возвращаемся обратно
Pop-Location

# Проверяем созданный архив
Write-Host "  📋 Проверка архива:" -ForegroundColor Cyan
try {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    $entries = $zip.Entries | Select-Object -ExpandProperty FullName
    $zip.Dispose()
    
    Write-Host "    Содержимое архива:" -ForegroundColor Cyan
    $entries | ForEach-Object { Write-Host "      $_" }
    
    if ($entries -contains "index.html") {
        Write-Host "  ✅ index.html найден" -ForegroundColor Green
    } else {
        Write-Host "  ❌ index.html НЕ НАЙДЕН в архиве!" -ForegroundColor Red
        exit 1
    }
    
    if ($entries -contains "manifest.json") {
        Write-Host "  ✅ manifest.json найден" -ForegroundColor Green
    } else {
        Write-Host "  ❌ manifest.json НЕ НАЙДЕН в архиве!" -ForegroundColor Red
        exit 1
    }
    
    # Проверяем наличие папки assets
    $hasAssets = $entries | Where-Object { $_ -like "assets/*" } | Select-Object -First 1
    if ($hasAssets) {
        Write-Host "  ✅ Папка assets найдена" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ Папка assets не найдена в корне архива" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠️ Не удалось проверить архив: $_" -ForegroundColor Yellow
}

# Rename to .qutytheme
$qutyThemePath = Join-Path $outputPath "$themeName.qutytheme"
if (Test-Path $qutyThemePath) {
    Remove-Item $qutyThemePath -Force
}
Move-Item -Path $zipPath -Destination $qutyThemePath -Force

# Get file size in MB
$fileSize = [math]::Round((Get-Item $qutyThemePath).Length / 1MB, 2)
Write-Host "  ✅ Файл создан: $themeName.qutytheme ($fileSize MB)" -ForegroundColor Green

# ============================================
# UPDATE THEME.JSON (without BOM)
# ============================================
Write-Host ""
Write-Host "📝 Обновление theme.json..." -ForegroundColor Cyan

$themeJsonPath = Join-Path $outputPath "theme.json"

# Create new theme.json
$themeJson = @{
    name = "QutyOS Theme"
    version = $newVersion
    downloadUrl = "https://raw.githubusercontent.com/Sanya2104/Quty.Launch.Theme.QutyOS/main/$themeName.qutytheme"
    changelog = $changelog
    fileSize = "$fileSize MB"
    lastUpdated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

# Сохраняем без BOM
$jsonContent = $themeJson | ConvertTo-Json -Depth 10
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$bytes = $utf8NoBom.GetBytes($jsonContent)
[System.IO.File]::WriteAllBytes($themeJsonPath, $bytes)

Write-Host "  ✅ theme.json обновлён (версия: $newVersion, без BOM)" -ForegroundColor Green

# ============================================
# SUMMARY
# ============================================
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✨ Готово! Тема QutyOS успешно собрана!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📦 Версия: $newVersion"
Write-Host "📄 Changelog:"
Write-Host "$changelog"
Write-Host ""
Write-Host "📦 Готовые файлы (папка output):"
Write-Host "   📄 $themeName.qutytheme ($fileSize MB)" -ForegroundColor Cyan
Write-Host "   📄 theme.json (версия: $newVersion)" -ForegroundColor Cyan
Write-Host ""
Write-Host "📂 Путь к файлам: $outputPath" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Pause to see the result
Read-Host "`nНажмите Enter для выхода"