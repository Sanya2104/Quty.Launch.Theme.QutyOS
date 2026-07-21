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
$themeName = "QutyOS"
$publicPath = Join-Path $projectPath "public"
$tempThemePath = Join-Path $env:TEMP "qutytheme_temp"

# Files to keep in the theme (copied from public folder to dist)
$keepFiles = @("manifest.json", "preview.png", "preview.ico", "preview.jpg", "favicon.ico")

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
# COPY FILES TO TEMP (КАК В deploy.ps1)
# ============================================
Write-Host ""
Write-Host "📋 Создание временной папки с файлами..." -ForegroundColor Cyan

# Создаём чистую временную папку
if (Test-Path $tempThemePath) {
    Remove-Item -Path $tempThemePath -Recurse -Force
}
New-Item -ItemType Directory -Path $tempThemePath -Force | Out-Null

# Копируем все файлы из dist во временную папку (как deploy.ps1)
Copy-Item -Path "$distPath\*" -Destination $tempThemePath -Recurse -Force

# Копируем защищённые файлы из public (если их нет)
foreach ($file in $keepFiles) {
    $sourceFile = Join-Path $publicPath $file
    $destFile = Join-Path $tempThemePath $file
    if ((Test-Path $sourceFile) -and (-not (Test-Path $destFile))) {
        Copy-Item -Path $sourceFile -Destination $destFile -Force
        Write-Host "  ✅ Скопирован: $file" -ForegroundColor Green
    }
}

Write-Host "  ✅ Все файлы скопированы во временную папку" -ForegroundColor Green

# ============================================
# CREATE .QUTYTHEME FILE (using WinRAR)
# ============================================
Write-Host ""
Write-Host "📦 Создание архива $themeName.qutytheme (через WinRAR)..." -ForegroundColor Cyan

# Проверяем содержимое временной папки
Write-Host "  📋 Содержимое временной папки:" -ForegroundColor Cyan
Get-ChildItem -Path $tempThemePath | ForEach-Object { Write-Host "    $($_.Name)" }

# Путь к WinRAR
$winRarPath = "G:\Programs\WinRAR\WinRAR.exe"

if (-not (Test-Path $winRarPath)) {
    Write-Host "  ❌ WinRAR не найден по пути: $winRarPath" -ForegroundColor Red
    Write-Host "  ⚠️ Используем стандартный ZIP..." -ForegroundColor Yellow
    
    $zipPath = Join-Path $env:TEMP "$themeName.zip"
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    
    Push-Location $tempThemePath
    Compress-Archive -Path * -DestinationPath $zipPath -Force
    Pop-Location
} else {
    Write-Host "  ✅ Найден WinRAR: $winRarPath" -ForegroundColor Green
    
    $zipPath = Join-Path $env:TEMP "$themeName.zip"
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    
    # Используем WinRAR для создания архива
    Push-Location $tempThemePath
    
    # Параметры WinRAR: 
    # a - добавить в архив
    # -afzip - формат ZIP
    # -m0 - без сжатия (Store) - как вручную
    # -r - рекурсивно (включая подпапки)
    $arguments = "a -afzip -m0 -r `"$zipPath`" *"
    
    Write-Host "  🔧 Запуск WinRAR: $winRarPath $arguments" -ForegroundColor Cyan
    
    $process = Start-Process -FilePath $winRarPath -ArgumentList $arguments -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -ne 0) {
        Write-Host "  ❌ Ошибка WinRAR (код: $($process.ExitCode))" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    Pop-Location
    Write-Host "  ✅ Архив создан через WinRAR" -ForegroundColor Green
}

# Проверяем созданный архив
Write-Host "  📋 Проверка архива:" -ForegroundColor Cyan
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
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

# ============================================
# COPY FILES TO PROJECT ROOT (замена существующих)
# ============================================
Write-Host ""
Write-Host "📦 Копирование файлов в корень проекта..." -ForegroundColor Cyan

# Путь к .qutytheme в корне проекта
$qutyThemePath = Join-Path $projectPath "$themeName.qutytheme"

# Удаляем старый .qutytheme если есть
if (Test-Path $qutyThemePath) {
    Remove-Item $qutyThemePath -Force
    Write-Host "  🗑️ Удалён старый $themeName.qutytheme" -ForegroundColor Yellow
}

# Копируем .qutytheme в корень проекта
Move-Item -Path $zipPath -Destination $qutyThemePath -Force
Write-Host "  ✅ Скопирован $themeName.qutytheme" -ForegroundColor Green

# Обновляем theme.json в корне проекта
$themeJsonPath = Join-Path $projectPath "theme.json"

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

# Delete temp folder
Remove-Item -Path $tempThemePath -Recurse -Force

# Get file size in MB
$fileSize = [math]::Round((Get-Item $qutyThemePath).Length / 1MB, 2)

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
Write-Host "📦 Файлы обновлены в корне проекта:"
Write-Host "   📄 $themeName.qutytheme ($fileSize MB)" -ForegroundColor Cyan
Write-Host "   📄 theme.json (версия: $newVersion)" -ForegroundColor Cyan
Write-Host ""
Write-Host "📂 Путь: $projectPath" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Pause to see the result
Read-Host "`nНажмите Enter для выхода"