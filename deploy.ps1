# deploy.ps1
# Скрипт для сборки проекта QutyOS и деплоя в Quty.Launch

# Параметры
$projectPath = "D:\Android\Themes\Quty.Launch.Theme.QutyOS"
$distPath = "D:\Android\Themes\Quty.Launch.Theme.QutyOS\dist"
$targetPath = "D:\Android\Quty.Launch\app\src\main\assets\themes\QutyOS"

# Файлы, которые нужно сохранить
$keepFiles = @("manifest.json", "preview.png", "preview.ico", "preview.jpg")

# Переходим в директорию проекта
Write-Host "📁 Переход в директорию проекта..." -ForegroundColor Cyan
Set-Location -Path $projectPath

# Проверяем наличие package.json
if (-not (Test-Path "package.json")) {
    Write-Host "❌ Ошибка: package.json не найден в $projectPath" -ForegroundColor Red
    exit 1
}

# Запускаем сборку
Write-Host "🔨 Запуск сборки (npm run build)..." -ForegroundColor Cyan
try {
    npm run build
    if ($LASTEXITCODE -ne 0) {
        throw "Ошибка сборки"
    }
    Write-Host "✅ Сборка завершена успешно!" -ForegroundColor Green
} catch {
    Write-Host "❌ Ошибка при выполнении сборки: $_" -ForegroundColor Red
    exit 1
}

# Проверяем наличие директории dist
if (-not (Test-Path $distPath)) {
    Write-Host "❌ Ошибка: директория dist не найдена после сборки" -ForegroundColor Red
    exit 1
}

# Проверяем существование целевой директории
if (-not (Test-Path $targetPath)) {
    Write-Host "📁 Создание директории $targetPath..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
}

# Сохраняем файлы, которые нужно оставить
Write-Host "💾 Сохранение защищенных файлов..." -ForegroundColor Cyan
$keptFiles = @()
foreach ($file in $keepFiles) {
    $filePath = Join-Path $targetPath $file
    if (Test-Path $filePath) {
        $tempPath = Join-Path $env:TEMP $file
        Copy-Item -Path $filePath -Destination $tempPath -Force
        $keptFiles += @{Name = $file; Path = $tempPath}
        Write-Host "  ✓ Сохранен: $file" -ForegroundColor Green
    }
}

# Удаляем все файлы в целевой директории, кроме защищенных
Write-Host "🗑️  Удаление старых файлов в $targetPath..." -ForegroundColor Cyan
$items = Get-ChildItem -Path $targetPath
foreach ($item in $items) {
    $shouldKeep = $false
    foreach ($keepFile in $keepFiles) {
        if ($item.Name -eq $keepFile) {
            $shouldKeep = $true
            break
        }
    }
    if (-not $shouldKeep) {
        Remove-Item -Path $item.FullName -Force -Recurse
        Write-Host "  ✓ Удален: $($item.Name)" -ForegroundColor Yellow
    }
}

# Копируем новые файлы из dist
Write-Host "📦 Копирование новых файлов из dist..." -ForegroundColor Cyan
Copy-Item -Path "$distPath\*" -Destination $targetPath -Recurse -Force
Write-Host "  ✓ Все файлы скопированы" -ForegroundColor Green

# Восстанавливаем сохраненные файлы
if ($keptFiles.Count -gt 0) {
    Write-Host "🔄 Восстановление защищенных файлов..." -ForegroundColor Cyan
    foreach ($keptFile in $keptFiles) {
        $destPath = Join-Path $targetPath $keptFile.Name
        if (Test-Path $keptFile.Path) {
            Copy-Item -Path $keptFile.Path -Destination $destPath -Force
            Remove-Item -Path $keptFile.Path -Force
            Write-Host "  ✓ Восстановлен: $($keptFile.Name)" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "✨ Готово! Тема QutyOS успешно собрана и развернута в Quty.Launch" -ForegroundColor Green
Write-Host "📂 Целевая директория: $targetPath" -ForegroundColor Cyan