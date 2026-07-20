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

# Create temporary folder for archive
$tempDir = Join-Path $env:TEMP "qutytheme_build_$([System.DateTime]::Now.Ticks)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Copy all files from dist to temp folder
Copy-Item -Path "$distPath\*" -Destination $tempDir -Recurse -Force

# Check if manifest.json exists in temp
$manifestPath = Join-Path $tempDir "manifest.json"
if (-not (Test-Path $manifestPath)) {
    Write-Host "  ❌ Ошибка: manifest.json не найден в dist!" -ForegroundColor Red
    Write-Host "  Проверьте, что файл manifest.json есть в папке public/" -ForegroundColor Yellow
    Remove-Item -Path $tempDir -Recurse -Force
    exit 1
}

# Verify version in manifest.json
try {
    $manifestContent = Get-Content -Path $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $currentVersionInManifest = $manifestContent.version
    Write-Host "  ✅ Версия в manifest.json: $currentVersionInManifest" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️ Не удалось прочитать версию из manifest.json" -ForegroundColor Yellow
}

# Create ZIP archive
$zipPath = Join-Path $env:TEMP "$themeName.zip"
Compress-Archive -Path "$tempDir\*" -DestinationPath $zipPath -Force

# Rename to .qutytheme
$qutyThemePath = Join-Path $outputPath "$themeName.qutytheme"
Move-Item -Path $zipPath -Destination $qutyThemePath -Force

# Delete temporary folder
Remove-Item -Path $tempDir -Recurse -Force

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