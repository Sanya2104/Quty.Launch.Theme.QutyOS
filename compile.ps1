# ============================================================
# compile.ps1 — Скрипт сборки темы Quty.Launch
# ============================================================
# Назначение:
#   1. Читает текущую версию из public/manifest.json
#   2. Запрашивает новую версию (можно оставить текущую)
#   3. Запрашивает changelog (многострочный)
#   4. Запрашивает минимальную версию лаунчера (можно пропустить)
#   5. Обновляет public/manifest.json (без BOM)
#   6. Запускает сборку (npm run build)
#   7. Копирует файлы из dist/ во временную папку
#   8. Создаёт .qutytheme архив через WinRAR
#   9. Копирует файлы в корень проекта:
#      - QutyOS.qutytheme
#      - theme.json
#   10. Удаляет временную папку
# ============================================================

# Отключаем вывод команд в консоль (делаем скрипт тише)
$ErrorActionPreference = "Stop"

# --- Конфигурация ---
$PROJECT_NAME = "QutyOS"                          # Имя темы
$MANIFEST_PATH = "public/manifest.json"           # Путь к манифесту
$DIST_PATH = "dist"                               # Папка со сборкой
$TEMP_DIR = "temp_theme_build"                    # Временная папка для архива
$OUTPUT_FILE = "$PROJECT_NAME.qutytheme"          # Итоговый файл темы

# Путь к WinRAR (укажите свой!)
$WINRAR_PATH = "G:\Programs\WinRAR\WinRAR.exe"

# Проверяем, существует ли WinRAR
if (-not (Test-Path $WINRAR_PATH)) {
    Write-Host "❌ Ошибка: WinRAR не найден по пути: $WINRAR_PATH" -ForegroundColor Red
    Write-Host "   Пожалуйста, укажите правильный путь к WinRAR.exe в скрипте." -ForegroundColor Yellow
    exit 1
}

# --- Функции ---

# Функция для удаления BOM-символа из строки
function Remove-BOM {
    param([string]$content)
    if ($content -and $content.Length -gt 0 -and $content[0] -eq [char]0xFEFF) {
        return $content.Substring(1)
    }
    return $content
}

# Функция для обновления JSON файла без BOM
function Update-JsonFile {
    param(
        [string]$FilePath,
        [string]$Key,
        [string]$Value
    )
    
    # Читаем файл
    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $content = Remove-BOM -content $content
    
    # Парсим JSON
    $json = $content | ConvertFrom-Json
    
    # Обновляем значение
    if ($Value) {
        $json | Add-Member -MemberType NoteProperty -Name $Key -Value $Value -Force
    } else {
        # Если значение пустое, удаляем поле
        $json.PSObject.Properties.Remove($Key)
    }
    
    # Преобразуем обратно в JSON (с отступами)
    $newContent = $json | ConvertTo-Json -Depth 10
    
    # Сохраняем без BOM
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($FilePath, $newContent, $utf8NoBom)
}

# --- Основной скрипт ---

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  🚀 СБОРКА ТЕМЫ $PROJECT_NAME" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Читаем текущую версию из manifest.json
Write-Host "📖 Чтение текущей версии из $MANIFEST_PATH..." -ForegroundColor Yellow

$manifestContent = Get-Content -Path $MANIFEST_PATH -Raw -Encoding UTF8
$manifestContent = Remove-BOM -content $manifestContent
$manifestJson = $manifestContent | ConvertFrom-Json

$currentVersion = $manifestJson.version
$currentMinLauncher = $manifestJson.minLauncherVersion

Write-Host "   Текущая версия темы: $currentVersion" -ForegroundColor Gray
if ($currentMinLauncher) {
    Write-Host "   Текущая минимальная версия лаунчера: $currentMinLauncher" -ForegroundColor Gray
} else {
    Write-Host "   Минимальная версия лаунчера не указана" -ForegroundColor Gray
}
Write-Host ""

# 2. Запрашиваем новую версию
Write-Host "📝 Введите новую версию (Enter для сохранения текущей $currentVersion):" -ForegroundColor Yellow
$newVersion = Read-Host
if ([string]::IsNullOrWhiteSpace($newVersion)) {
    $newVersion = $currentVersion
    Write-Host "   ✅ Оставлена версия: $newVersion" -ForegroundColor Green
} else {
    Write-Host "   ✅ Установлена версия: $newVersion" -ForegroundColor Green
}
Write-Host ""

# 3. Запрашиваем changelog
Write-Host "📝 Введите changelog (многострочный, Enter для завершения):" -ForegroundColor Yellow
Write-Host "   (Для завершения ввода введите пустую строку или 'end')" -ForegroundColor Gray
$changelogLines = @()
while ($true) {
    $line = Read-Host
    if ([string]::IsNullOrWhiteSpace($line) -or $line -eq "end") {
        break
    }
    $changelogLines += $line
}
$changelog = if ($changelogLines.Count -gt 0) {
    $changelogLines -join "`n"
} else {
    "Обновление темы"
}
Write-Host "   ✅ Changelog записан" -ForegroundColor Green
Write-Host ""

# 4. Запрашиваем минимальную версию лаунчера
Write-Host "📝 Введите минимальную версию лаунчера (например, 1.0.0)" -ForegroundColor Yellow
Write-Host "   (Enter для пропуска, текущее значение: $currentMinLauncher)" -ForegroundColor Gray
$minLauncherVersion = Read-Host
if ([string]::IsNullOrWhiteSpace($minLauncherVersion)) {
    $minLauncherVersion = $currentMinLauncher
    if ($minLauncherVersion) {
        Write-Host "   ✅ Оставлена минимальная версия: $minLauncherVersion" -ForegroundColor Green
    } else {
        Write-Host "   ⏭️ Поле minLauncherVersion будет удалено" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ✅ Установлена минимальная версия: $minLauncherVersion" -ForegroundColor Green
}
Write-Host ""

# 5. Обновляем manifest.json
Write-Host "📝 Обновление $MANIFEST_PATH..." -ForegroundColor Yellow

# Обновляем версию
Update-JsonFile -FilePath $MANIFEST_PATH -Key "version" -Value $newVersion

# Обновляем или удаляем minLauncherVersion
if ($minLauncherVersion) {
    Update-JsonFile -FilePath $MANIFEST_PATH -Key "minLauncherVersion" -Value $minLauncherVersion
} else {
    # Если пусто — удаляем поле
    $content = Get-Content -Path $MANIFEST_PATH -Raw -Encoding UTF8
    $content = Remove-BOM -content $content
    $json = $content | ConvertFrom-Json
    $json.PSObject.Properties.Remove("minLauncherVersion")
    $newContent = $json | ConvertTo-Json -Depth 10
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($MANIFEST_PATH, $newContent, $utf8NoBom)
}

Write-Host "   ✅ manifest.json обновлён" -ForegroundColor Green
Write-Host ""

# 6. Запускаем сборку
Write-Host "🔨 Запуск сборки (npm run build)..." -ForegroundColor Yellow
npm run build

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ошибка сборки! Скрипт остановлен." -ForegroundColor Red
    exit 1
}
Write-Host "   ✅ Сборка завершена" -ForegroundColor Green
Write-Host ""

# 7. Создаём временную папку
Write-Host "📁 Подготовка файлов для архива..." -ForegroundColor Yellow

if (Test-Path $TEMP_DIR) {
    Remove-Item -Path $TEMP_DIR -Recurse -Force
}
New-Item -Path $TEMP_DIR -ItemType Directory | Out-Null

# Копируем файлы из dist во временную папку
Copy-Item -Path "$DIST_PATH\*" -Destination $TEMP_DIR -Recurse -Force

# Копируем manifest.json и preview из public во временную папку
if (Test-Path "public\manifest.json") {
    Copy-Item -Path "public\manifest.json" -Destination $TEMP_DIR -Force
}
if (Test-Path "public\preview.png") {
    Copy-Item -Path "public\preview.png" -Destination $TEMP_DIR -Force
}
if (Test-Path "public\preview.jpg") {
    Copy-Item -Path "public\preview.jpg" -Destination $TEMP_DIR -Force
}
if (Test-Path "public\preview.ico") {
    Copy-Item -Path "public\preview.ico" -Destination $TEMP_DIR -Force
}

# Копируем favicon.ico если есть
if (Test-Path "public\favicon.ico") {
    Copy-Item -Path "public\favicon.ico" -Destination $TEMP_DIR -Force
}

Write-Host "   ✅ Файлы скопированы во временную папку" -ForegroundColor Green
Write-Host ""

# 8. Создаём ZIP архив через WinRAR (без сжатия)
Write-Host "📦 Создание архива $OUTPUT_FILE..." -ForegroundColor Yellow

# Удаляем старый архив если есть
if (Test-Path $OUTPUT_FILE) {
    Remove-Item -Path $OUTPUT_FILE -Force
}

# Формируем путь к архиву
$zipPath = Join-Path -Path (Get-Location) -ChildPath $OUTPUT_FILE

# Переходим во временную папку и создаём архив
Push-Location $TEMP_DIR

# WinRAR: a - добавить, -afzip - формат ZIP, -m0 - без сжатия, -r - рекурсивно
$arguments = "a -afzip -m0 -r `"$zipPath`" *"
$process = Start-Process -FilePath $WINRAR_PATH -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden

Pop-Location

if ($process.ExitCode -ne 0) {
    Write-Host "❌ Ошибка создания архива! Код ошибки: $($process.ExitCode)" -ForegroundColor Red
    exit 1
}

Write-Host "   ✅ Архив создан: $OUTPUT_FILE" -ForegroundColor Green

# Проверяем размер архива
$fileSize = (Get-Item $OUTPUT_FILE).Length
$fileSizeMB = [math]::Round($fileSize / 1MB, 2)
Write-Host "   📊 Размер архива: $fileSizeMB MB" -ForegroundColor Gray
Write-Host ""

# 9. Создаём theme.json для обновлений
Write-Host "📝 Создание theme.json..." -ForegroundColor Yellow

# Формируем ссылку на скачивание (используем raw.githubusercontent.com)
$repoUrl = "https://raw.githubusercontent.com/Sanya2104/Quty.Launch.Theme.QutyOS/main"
$downloadUrl = "$repoUrl/$OUTPUT_FILE"

# Создаём объект для theme.json
$themeJson = @{
    name = $PROJECT_NAME
    version = $newVersion
    downloadUrl = $downloadUrl
    changelog = $changelog
    fileSize = "$fileSizeMB MB"
}

# Добавляем minLauncherVersion только если она указана
if ($minLauncherVersion) {
    $themeJson | Add-Member -MemberType NoteProperty -Name "minLauncherVersion" -Value $minLauncherVersion
}

# Преобразуем в JSON с отступами
$themeJsonContent = $themeJson | ConvertTo-Json -Depth 10

# Сохраняем без BOM
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText("theme.json", $themeJsonContent, $utf8NoBom)

Write-Host "   ✅ theme.json создан" -ForegroundColor Green
Write-Host ""

# 10. Копируем файлы в корень проекта (исправлено!)
Write-Host "📁 Копирование файлов в корень проекта..." -ForegroundColor Yellow

# Проверяем, что файл существует и не пытаемся скопировать сам в себя
# Просто проверяем, что файл уже в корне (он там и создался)
if (Test-Path $OUTPUT_FILE) {
    # Файл уже в корне, ничего не делаем
    Write-Host "   ✅ $OUTPUT_FILE уже в корне проекта" -ForegroundColor Green
}

# theme.json тоже уже в корне
if (Test-Path "theme.json") {
    Write-Host "   ✅ theme.json уже в корне проекта" -ForegroundColor Green
}

Write-Host ""

# 11. Удаляем временную папку
Write-Host "🧹 Очистка временных файлов..." -ForegroundColor Yellow
if (Test-Path $TEMP_DIR) {
    Remove-Item -Path $TEMP_DIR -Recurse -Force
}
Write-Host "   ✅ Временная папка удалена" -ForegroundColor Green
Write-Host ""

# 12. Выводим итоговую информацию
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  ✅ СБОРКА ЗАВЕРШЕНА УСПЕШНО!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📦 Итоговые файлы:" -ForegroundColor Yellow
Write-Host "   📄 $OUTPUT_FILE ($fileSizeMB MB)" -ForegroundColor White
Write-Host "   📄 theme.json" -ForegroundColor White
Write-Host ""
Write-Host "📊 Информация о версии:" -ForegroundColor Yellow
Write-Host "   Версия темы: $newVersion" -ForegroundColor White
if ($minLauncherVersion) {
    Write-Host "   Минимальная версия лаунчера: $minLauncherVersion" -ForegroundColor White
} else {
    Write-Host "   Минимальная версия лаунчера: не указана" -ForegroundColor Gray
}
Write-Host ""
Write-Host "📝 Changelog:" -ForegroundColor Yellow
Write-Host "   $changelog" -ForegroundColor White
Write-Host ""

Write-Host "🔗 Ссылка для скачивания:" -ForegroundColor Yellow
Write-Host "   $downloadUrl" -ForegroundColor Gray
Write-Host ""

Write-Host "==================================================" -ForegroundColor Cyan