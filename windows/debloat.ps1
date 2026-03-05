#Requires -RunAsAdministrator
# ============================================================
# Browser Debloat & Performance Optimizer - Windows
# debloat.ps1 | v1.0
#
# [TR] Desteklenen tarayicilar : Brave Browser, Google Chrome
# [EN] Supported browsers      : Brave Browser, Google Chrome
#
# [TR] Desteklenen kurulumlar  : Standart installer, per-user,
#      Scoop, Winget, Chocolatey
# [EN] Supported installs      : Standard installer, per-user,
#      Scoop, Winget, Chocolatey
#
# [TR] Kullanim  : PowerShell'i Yonetici olarak ac, calistir.
# [EN] Usage     : Open PowerShell as Administrator, run it.
#
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\debloat.ps1
#   .\debloat.ps1 -DryRun   # [TR] Degisiklik yapmadan onizle
#                            # [EN] Preview without changes
# ============================================================

param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# ============================================================
# [TR] KONSOL ENCODING — Unicode karakterlerin dogru goruntulenmesi
# [EN] CONSOLE ENCODING — Correct display of Unicode characters
# ============================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding             = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

# ============================================================
# [TR] LOG SISTEMI / [EN] LOG SYSTEM
# ============================================================
$Global:LOG      = [System.Collections.Generic.List[string]]::new()
$Global:ERRORS   = [System.Collections.Generic.List[string]]::new()
$Global:WARNINGS = [System.Collections.Generic.List[string]]::new()

function _log($m) { $Global:LOG.Add($m) }

function wStep($m) {
    Write-Host "`n  >> $m" -ForegroundColor Cyan
    _log "[STEP]  $m"
}
function wOk($m) {
    Write-Host "     [+] $m" -ForegroundColor Green
    _log "[OK]    $m"
}
function wSkip($m) {
    Write-Host "     [-] $m" -ForegroundColor DarkGray
    _log "[SKIP]  $m"
}
function wFail($m) {
    Write-Host "     [X] $m" -ForegroundColor Red
    _log "[FAIL]  $m"
    $Global:ERRORS.Add($m)
}
function wWarn($m) {
    Write-Host "     [!] $m" -ForegroundColor Yellow
    _log "[WARN]  $m"
    $Global:WARNINGS.Add($m)
}
function wInfo($m) {
    Write-Host "     [i] $m" -ForegroundColor DarkCyan
    _log "[INFO]  $m"
}

# ============================================================
# [TR] YARDIMCI FONKSIYONLAR / [EN] HELPER FUNCTIONS
# ============================================================

# [TR] BOM'suz UTF-8 yaz — Chrome/Brave BOM'lu JSON'u sifirlayabilir
# [EN] Write UTF-8 without BOM — Chrome/Brave may reset BOM-prefixed JSON
function Write-UTF8NoBOM([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText(
        $Path,
        $Content,
        (New-Object System.Text.UTF8Encoding $false)
    )
}

# [TR] BOM'suz UTF-8 oku
# [EN] Read UTF-8 without BOM
function Read-UTF8NoBOM([string]$Path) {
    [System.IO.File]::ReadAllText(
        $Path,
        (New-Object System.Text.UTF8Encoding $false)
    )
}

# [TR] Nokta notasyonuyla ic ice JSON property'ye deger ata
# [EN] Set a nested JSON property using dot notation
function Set-JsonPath {
    param(
        [Parameter(Mandatory)][PSCustomObject]$Root,
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)]$Value
    )
    $parts = $Path -split "\."
    $node  = $Root
    for ($i = 0; $i -lt ($parts.Count - 1); $i++) {
        $k  = $parts[$i]
        $ep = $node.PSObject.Properties | Where-Object { $_.Name -eq $k }
        if (-not $ep) {
            $node | Add-Member -NotePropertyName $k `
                               -NotePropertyValue ([PSCustomObject]@{}) -Force
        }
        if ($node.$k -isnot [PSCustomObject]) {
            $node | Add-Member -NotePropertyName $k `
                               -NotePropertyValue ([PSCustomObject]@{}) -Force
        }
        $node = $node.$k
    }
    $lk = $parts[-1]
    $lp = $node.PSObject.Properties | Where-Object { $_.Name -eq $lk }
    if ($lp) { $node.$lk = $Value }
    else { $node | Add-Member -NotePropertyName $lk -NotePropertyValue $Value -Force }
}

# [TR] Dil ceviri yardimcisi / [EN] Language translation helper
function t([string]$TR, [string]$EN) {
    if ($Global:LANG -eq "en") { return $EN } else { return $TR }
}

# ============================================================
# [TR] DİL SECİMİ / [EN] LANGUAGE SELECTION
# ============================================================
Clear-Host
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "   DEBLOAT YOUR BROWSER  |  Windows  v1.0   " -ForegroundColor Cyan
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Lutfen dil secin / Please select language:" -ForegroundColor White
Write-Host ""
Write-Host "    [1]  Turkce" -ForegroundColor Yellow
Write-Host "    [2]  English" -ForegroundColor Yellow
Write-Host ""
$lc = Read-Host "  Secim / Choice [1/2]"
$Global:LANG = if ($lc -eq "2") { "en" } else { "tr" }

# ============================================================
# [TR] TARAYICI SECİMİ / [EN] BROWSER SELECTION
# ============================================================
Clear-Host
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "   DEBLOAT YOUR BROWSER  |  Windows  v1.0   " -ForegroundColor Cyan
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host ("  " + (t "Tarayici secin:" "Select browser:")) -ForegroundColor White
Write-Host ""
Write-Host "    [1]  Brave Browser" -ForegroundColor Yellow
Write-Host "    [2]  Google Chrome" -ForegroundColor Yellow
Write-Host ""
$bc = Read-Host ("  " + (t "Secim" "Choice") + " [1/2]")
$Global:BROWSER = if ($bc -eq "2") { "chrome" } else { "brave" }

# ============================================================
# [TR] BASLIK EKRANI / [EN] HEADER SCREEN
# ============================================================
Clear-Host
$BrowserLabel = if ($Global:BROWSER -eq "brave") { "Brave Browser" } else { "Google Chrome" }
$TS           = Get-Date -Format "yyyyMMdd_HHmmss"
$ScriptVer    = "1.0"
$OSInfo       = (Get-CimInstance Win32_OperatingSystem).Caption

Write-Host ""
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "   DEBLOAT YOUR BROWSER  |  Windows  v$ScriptVer  " -ForegroundColor Cyan
Write-Host "   $BrowserLabel" -ForegroundColor Cyan
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host ("  " + (t "Kullanici" "User")     + "   : $env:USERNAME")
Write-Host ("  " + (t "Sistem"    "System")    + "   : $OSInfo")
Write-Host ("  " + (t "Tarayici"  "Browser")   + "  : $BrowserLabel")
Write-Host ("  " + (t "Dil"       "Language")  + "     : " + (t "Turkce" "English"))
if ($DryRun) {
    Write-Host ""
    Write-Host ("  [DRY-RUN] " + (t "Hicbir degisiklik yapilmayacak." `
        "No changes will be made.")) -ForegroundColor Yellow
}
Write-Host ""

# ============================================================
# [TR] MASAUSTU PATH — OneDrive dahil her senaryoda dogru calisir
# [EN] DESKTOP PATH — Works correctly even with OneDrive redirection
# ============================================================
$Desktop = [Environment]::GetFolderPath('Desktop')

# ============================================================
# [TR] TARAYICI PATH'LERİ / [EN] BROWSER PATHS
# ============================================================
if ($Global:BROWSER -eq "brave") {
    # [TR] Olasi Brave binary konumlari (kurulum tipine gore)
    # [EN] Possible Brave binary locations (depends on install type)
    $BinaryPaths = @(
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe"  # Standart / Standard
        "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe"  # Per-machine / Machine-wide
        "$env:ProgramFiles(x86)\BraveSoftware\Brave-Browser\Application\brave.exe"
        "$env:USERPROFILE\scoop\apps\brave\current\brave.exe"                  # Scoop
        "$env:ProgramData\chocolatey\lib\brave\brave.exe"                      # Chocolatey
    )
    $UserData    = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
    $RegPath     = "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave"
    $ProcessName = "brave"
    $BackupDir   = "$Desktop\BraveDebloat_Backup_$TS"
    $ReportPath  = "$Desktop\BraveDebloat_Rapor_$TS.txt"
}
else {
    # [TR] Olasi Chrome binary konumlari
    # [EN] Possible Chrome binary locations
    $BinaryPaths = @(
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"               # Standart / Standard
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"               # Per-user
        "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe"
        "$env:USERPROFILE\scoop\apps\googlechrome\current\chrome.exe"          # Scoop
        "$env:ProgramData\chocolatey\lib\GoogleChrome\chrome.exe"              # Chocolatey
    )
    $UserData    = "$env:LOCALAPPDATA\Google\Chrome\User Data"
    $RegPath     = "HKLM:\SOFTWARE\Policies\Google\Chrome"
    $ProcessName = "chrome"
    $BackupDir   = "$Desktop\ChromeDebloat_Backup_$TS"
    $ReportPath  = "$Desktop\ChromeDebloat_Rapor_$TS.txt"
}

$DefProfile  = "$UserData\Default"
$LocalState  = "$UserData\Local State"
$Prefs       = "$DefProfile\Preferences"

# ============================================================
# [TR] ADIM 0: KURULUM TESPİTİ / [EN] STEP 0: INSTALL DETECTION
# ============================================================
wStep (t "Kurulum tipi algilaniyor..." "Detecting installation type...")

$BrowserBin   = ""
$InstallType  = "unknown"

foreach ($p in $BinaryPaths) {
    if (Test-Path $p) {
        $BrowserBin  = $p
        # [TR] Kurulum tipini path'ten tahmin et
        # [EN] Infer install type from path
        if ($p -like "*scoop*")       { $InstallType = "scoop" }
        elseif ($p -like "*chocolatey*") { $InstallType = "chocolatey" }
        elseif ($p -like "*LOCALAPPDATA*" -and $p -notlike "*scoop*") { $InstallType = "per-user" }
        else                          { $InstallType = "standard" }
        break
    }
}

if ($BrowserBin -eq "") {
    wWarn (t "Binary bulunamadi, User Data kontrol ediliyor..." `
             "Binary not found, checking User Data...")
}
else {
    wOk (t "Binary bulundu ($InstallType)" "Binary found ($InstallType)") + ": $BrowserBin"
}

# [TR] User Data mevcut mu?
# [EN] Does User Data directory exist?
if (-not (Test-Path $UserData)) {
    Write-Host ""
    Write-Host ("  [" + (t "HATA" "ERROR") + "] " + `
        (t "User Data bulunamadi: " "User Data not found: ") + $UserData) -ForegroundColor Red
    Write-Host ("  " + (t "Tarayiciyi bir kez acip kapatin." `
        "Open and close the browser once first.")) -ForegroundColor Yellow
    exit 1
}

# [TR] Surum bilgisi
# [EN] Version info
$BrowserVer = "N/A"
if ($BrowserBin -ne "") {
    try {
        $BrowserVer = (Get-Item $BrowserBin).VersionInfo.FileVersion
    } catch { }
}

wInfo (t "User Data  : $UserData" "User Data  : $UserData")
wInfo (t "Registry   : $RegPath"  "Registry   : $RegPath")
wInfo (t "Surum      : $BrowserVer" "Version    : $BrowserVer")
wInfo (t "Masaustu   : $Desktop"  "Desktop    : $Desktop")

# ============================================================
# [TR] ADIM 1: TARAYICI KAPAT / [EN] STEP 1: CLOSE BROWSER
# ============================================================
wStep (t "Tarayici kapatiliyor..." "Closing browser...")

# [TR] KRITİK: Stop-Process -Name wildcardSIZ kullaniliyor.
# [EN] CRITICAL: Stop-Process -Name used WITHOUT wildcards.
# [TR] Wildcard (*) tum eslesen processleri oldurur, tehlikeli.
# [EN] Wildcard (*) kills all matching processes, which is dangerous.
# [TR] Tam isim eslesimi (brave, chrome) sadece tarayiciyi kapatir.
# [EN] Exact name match (brave, chrome) only kills the browser.

$KillNames = if ($Global:BROWSER -eq "brave") {
    @("brave", "brave-browser")
} else {
    @("chrome", "google-chrome", "google-chrome-stable")
}

if (-not $DryRun) {
    $WasRunning = $false
    foreach ($pn in $KillNames) {
        if (Get-Process -Name $pn -ErrorAction SilentlyContinue) {
            $WasRunning = $true
            Stop-Process -Name $pn -Force -ErrorAction SilentlyContinue
        }
    }
    if ($WasRunning) {
        Start-Sleep -Seconds 2
        wOk (t "Tarayici kapatildi." "Browser closed.")
    }
    else {
        wSkip (t "Tarayici zaten kapaliydi." "Browser was already closed.")
    }
}
else {
    wSkip "[DRY-RUN]"
}

# ============================================================
# [TR] ADIM 2: BACKUP / [EN] STEP 2: BACKUP
# ============================================================
wStep (t "Dosyalar yedekleniyor..." "Backing up files...")

if (-not $DryRun) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

    # [TR] JSON dosyalarini yedekle
    # [EN] Back up JSON files
    $bc = 0
    foreach ($f in @($LocalState, $Prefs)) {
        if (Test-Path $f) {
            Copy-Item $f $BackupDir -Force
            wOk (t "Yedeklendi" "Backed up") + ": $(Split-Path $f -Leaf)"
            $bc++
        }
        else {
            wSkip (t "Yok" "Not found") + ": $(Split-Path $f -Leaf)"
        }
    }

    # [TR] Registry key'i de yedekle — geri alma icin
    # [EN] Also export registry key — for easy revert
    $RegBackupPath = "$BackupDir\registry_backup.reg"
    $RegParent = Split-Path $RegPath -Parent
    try {
        reg export ($RegPath -replace "HKLM:\\", "HKLM\") $RegBackupPath /y 2>$null | Out-Null
        if (Test-Path $RegBackupPath) {
            wOk (t "Registry yedeklendi" "Registry backed up") + ": registry_backup.reg"
        }
    } catch { }

    wOk (t "Backup tamam" "Backup done") + " ($bc $(t 'dosya' 'files')): $BackupDir"
}
else {
    wSkip "[DRY-RUN]"
}

# ============================================================
# [TR] ADIM 3: REGISTRY POLICİES
# [EN] STEP 3: REGISTRY POLICIES
#
# [TR] Deger tipi kurallari (Windows Registry):
#      - "Disabled" ile biten → kapatmak icin DWORD = 1
#      - "Enabled"  ile biten → kapatmak icin DWORD = 0
#      - Integer degerler (NetworkPredictionOptions vb.) → DWORD
#      - String degerler (DnsOverHttpsMode vb.) → REG_SZ (String)
#
# [EN] Value type rules (Windows Registry):
#      - Suffix "Disabled"  → set DWORD = 1 to disable
#      - Suffix "Enabled"   → set DWORD = 0 to disable
#      - Integer values (NetworkPredictionOptions etc.) → DWORD
#      - String values (DnsOverHttpsMode etc.) → REG_SZ (String)
# ============================================================
wStep (t "Registry policy yaziliyor..." "Writing registry policies...")

if (-not $DryRun) {
    New-Item -Path $RegPath -Force | Out-Null

    # [TR] DWORD politikalari (0 veya 1 deger)
    # [EN] DWORD policies (0 or 1 value)
    $DwordPolicies = if ($Global:BROWSER -eq "brave") {
        [ordered]@{
            # --- Telemetri / Telemetry ---
            "MetricsReportingEnabled"                    = 0
            "UrlKeyedAnonymizedDataCollectionEnabled"    = 0
            "FeedbackSurveysEnabled"                     = 0
            "UserFeedbackAllowed"                        = 0
            "ReportingEnabled"                           = 0

            # --- Brave Ozeline / Brave Specific ---
            "BraveRewardsDisabled"                       = 1  # Disabled → 1
            "BraveWalletDisabled"                        = 1  # Disabled → 1
            "BraveVPNDisabled"                           = 1  # Disabled → 1
            "BraveTalkDisabled"                          = 1  # Disabled → 1
            "BraveAIChatEnabled"                         = 0  # Enabled  → 0
            "BraveWebDiscoveryEnabled"                   = 0  # Enabled  → 0
            "BraveStatsPingEnabled"                      = 0  # Enabled  → 0
            "BraveP3AEnabled"                            = 0  # Enabled  → 0
            "BravePlaylistEnabled"                       = 0  # Enabled  → 0
            "BraveReduceLanguageEnabled"                 = 1  # Enabled  → 1 (ISTIYORUZ/WANTED)

            # --- Genel Gizlilik / General Privacy ---
            "BackgroundModeEnabled"                      = 0
            "SafeBrowsingExtendedReportingEnabled"       = 0
            "AlternateErrorPagesEnabled"                 = 0
            "ResolveNavigationErrorsUseWebService"       = 0
            "SearchSuggestEnabled"                       = 0
            "NetworkPredictionOptions"                   = 2  # 2 = Never predict
            "DnsPrefetchingEnabled"                      = 0
            "TranslateEnabled"                           = 0
            "SpellCheckServiceEnabled"                   = 0
            "PasswordManagerEnabled"                     = 0
            "AutofillAddressEnabled"                     = 0
            "AutofillCreditCardEnabled"                  = 0
            "PaymentMethodQueryEnabled"                  = 0

            # --- Izinler / Permissions ---
            "DefaultNotificationsSetting"                = 2  # 2 = Block
            "DefaultGeolocationSetting"                  = 2  # 2 = Block
            "DefaultWebBluetoothGuardSetting"            = 2  # 2 = Block
            "DefaultWebUsbGuardSetting"                  = 2  # 2 = Block
            "DefaultWebHidGuardSetting"                  = 2  # 2 = Block

            # --- UI / Arayuz ---
            "PromotionalTabsEnabled"                     = 0
            "HideWebStoreIcon"                           = 1
            "EnableMediaRouter"                          = 0  # Cast/Chromecast kapat

            # --- Privacy Sandbox ---
            "PrivacySandboxAdTopicsEnabled"              = 0
            "PrivacySandboxAdMeasurementEnabled"         = 0
            "PrivacySandboxSiteEnabledAdsEnabled"        = 0
            "PrivacySandboxPromptEnabled"                = 0
        }
    }
    else {
        # [TR] Chrome'a ozel AI politikalari (GeminiSettings vb.):
        #      1 = Disable (bu degerler integer "mode" olarak calisir)
        # [EN] Chrome-specific AI policies (GeminiSettings etc.):
        #      1 = Disable (these values work as integer "mode")
        [ordered]@{
            # --- Google AI / Gemini ---
            "GeminiSettings"                             = 1  # 1 = Disabled
            "AIModeSettings"                             = 1  # 1 = Disabled
            "GenAILocalFoundationalModelSettings"        = 1  # 1 = Disabled
            "DevToolsGenAiSettings"                      = 1  # 1 = Disabled
            "CreateThemesSettings"                       = 1  # 1 = Disabled
            "TabOrganizerSettings"                       = 1  # 1 = Disabled
            "HelpMeWriteSettings"                        = 1  # 1 = Disabled

            # --- Hesap / Sync ---
            "SyncDisabled"                               = 1
            "BrowserSignin"                              = 0  # 0 = Disable sign-in
            "GoogleSearchSidePanelEnabled"               = 0

            # --- Telemetri / Telemetry ---
            "MetricsReportingEnabled"                    = 0
            "UrlKeyedAnonymizedDataCollectionEnabled"    = 0
            "FeedbackSurveysEnabled"                     = 0
            "UserFeedbackAllowed"                        = 0
            "ReportingEnabled"                           = 0
            "ChromeVariationsSettings"                   = 2  # 2 = Disable variations

            # --- Genel Gizlilik / General Privacy ---
            "BackgroundModeEnabled"                      = 0
            "SafeBrowsingExtendedReportingEnabled"       = 0
            "AlternateErrorPagesEnabled"                 = 0
            "ResolveNavigationErrorsUseWebService"       = 0
            "SearchSuggestEnabled"                       = 0
            "NetworkPredictionOptions"                   = 2
            "DnsPrefetchingEnabled"                      = 0
            "TranslateEnabled"                           = 0
            "SpellCheckServiceEnabled"                   = 0
            "PasswordManagerEnabled"                     = 0
            "AutofillAddressEnabled"                     = 0
            "AutofillCreditCardEnabled"                  = 0
            "PaymentMethodQueryEnabled"                  = 0

            # --- Izinler / Permissions ---
            "DefaultNotificationsSetting"                = 2
            "DefaultGeolocationSetting"                  = 2
            "DefaultWebBluetoothGuardSetting"            = 2
            "DefaultWebUsbGuardSetting"                  = 2
            "DefaultWebHidGuardSetting"                  = 2

            # --- UI ---
            "PromotionalTabsEnabled"                     = 0
            "HideWebStoreIcon"                           = 1
            "ShowCastIconInToolbar"                      = 0
            "EnableMediaRouter"                          = 0

            # --- Privacy Sandbox ---
            "PrivacySandboxAdTopicsEnabled"              = 0
            "PrivacySandboxAdMeasurementEnabled"         = 0
            "PrivacySandboxSiteEnabledAdsEnabled"        = 0
            "PrivacySandboxPromptEnabled"                = 0
        }
    }

    # [TR] String politikalari (REG_SZ)
    # [EN] String policies (REG_SZ)
    $StringPolicies = [ordered]@{
        "DnsOverHttpsMode"   = "automatic"           # DoH modu / DoH mode
        "WebRtcIPHandling"   = "default_public_interface_only"
    }

    # [TR] DWORD'leri yaz / [EN] Write DWORDs
    $ok = 0; $fail = 0
    foreach ($key in $DwordPolicies.Keys) {
        try {
            Set-ItemProperty -Path $RegPath -Name $key `
                -Value $DwordPolicies[$key] -Type DWord -Force
            wOk "DWORD [$key] = $($DwordPolicies[$key])"
            $ok++
        }
        catch {
            wFail (t "Yazılamadi" "Failed to write") + ": $key"
            $fail++
        }
    }

    # [TR] String'leri yaz / [EN] Write strings
    foreach ($key in $StringPolicies.Keys) {
        try {
            Set-ItemProperty -Path $RegPath -Name $key `
                -Value $StringPolicies[$key] -Type String -Force
            wOk "STRING [$key] = $($StringPolicies[$key])"
            $ok++
        }
        catch {
            wFail (t "Yazılamadi" "Failed to write") + ": $key"
            $fail++
        }
    }

    wOk (t "Registry tamamlandi" "Registry done") + " ($ok OK / $fail $(t 'hata' 'error'))"
}
else {
    wSkip "[DRY-RUN]"
}

# ============================================================
# [TR] ADIM 4: chrome://flags (Local State)
# [EN] STEP 4: chrome://flags (Local State)
#
# [TR] BOM sorunu: PowerShell 5.1'de Set-Content -Encoding UTF8
#      JSON'a BOM (3 gorunmez byte) ekler. Chrome/Brave baslarken
#      BOM'lu Local State'i sifirlayabilir. Cozum: WriteAllText.
# [EN] BOM issue: PowerShell 5.1's Set-Content -Encoding UTF8
#      adds a BOM (3 invisible bytes) to the JSON. Chrome/Brave
#      may reset a BOM-prefixed Local State on launch. Fix: WriteAllText.
# ============================================================
wStep (t "chrome://flags duzenleniyor (Local State)..." `
         "Editing chrome://flags (Local State)...")

if (-not (Test-Path $LocalState)) {
    wSkip (t "Local State yok. Tarayiciyi bir kez acip kapatin." `
             "Local State not found. Open and close the browser once.")
}
elseif (-not $DryRun) {
    try {
        $lsRaw = Read-UTF8NoBOM $LocalState
        $LS    = $lsRaw | ConvertFrom-Json

        # [TR] Ortak performans flag'leri (Brave + Chrome icin)
        # [EN] Common performance flags (for both Brave and Chrome)
        $EnableFlags = @(
            "enable-parallel-downloading@1"              # Cok parcali indirme / Multi-connection download
            "enable-gpu-rasterization@1"                 # GPU rasterizasyon / GPU rasterization
            "enable-zero-copy@1"                         # Sifir kopya GPU aktarimi / Zero-copy GPU
            "enable-oop-rasterization@1"                 # OOP rasterizasyon
            "canvas-oop-rasterization@1"                 # Canvas OOP
            "enable-vulkan@1"                            # Vulkan GPU backend
            "enable-skia-graphite@1"                     # Yeni Skia motoru / New Skia engine
            "enable-accelerated-video-decode@1"          # Donanim video decode / HW video decode
            "enable-accelerated-video-encode@1"          # Donanim video encode / HW video encode
            "enable-hardware-overlays@single-fullscreen,single-on-top,underlay"
            "overlay-strategies@occluded-and-non-occluded"
            "enable-quic@1"                              # HTTP/3 QUIC protokolu / protocol
            "enable-http2-alternative-service@1"         # HTTP/2 optimizasyon / optimization
            "smooth-scrolling@1"                         # Yumusak kaydirma / Smooth scroll
            "ignore-gpu-blocklist@1"                     # GPU kara listesini yoksay / Ignore GPU blocklist
            "ThrottleDisplayNoneAndVisibilityHiddenCrossOriginIframes@1"
        )

        # [TR] Brave'e ozel flag'ler
        # [EN] Brave-specific flags
        $BraveEnableFlags = @(
            "brave-debounce@1"                           # URL debounce — tracking temizle / strip
            "brave-forget-first-party-storage@1"         # 1st-party storage temizleme / clearing
        )

        # [TR] Ortak devre disi birakilacak flag'ler
        # [EN] Common flags to disable
        $DisableFlags = @(
            "enable-prerender2@2"                        # Agresif prerender — RAM tuketiyor / RAM hog
            "back-forward-cache@2"                       # BF cache — RAM tuketiyor / RAM hog
            "sharing-hub-desktop-app-menu@2"             # Paylasim hub / Share hub
            "commerce-price-tracking@2"                  # Fiyat takibi / Price tracking
            "tab-groups-save@2"                          # Bulut sekme gruplari / Cloud tab groups
            "webrtc-hide-local-ips-with-mdns@2"          # mDNS (Brave'de zaten kapali / already off)
        )

        # [TR] Chrome'a ozel devre disi flag'ler
        # [EN] Chrome-specific flags to disable
        $ChromeDisableFlags = @(
            "optimization-guide-on-device-model@2"       # On-device AI model indirme / download
            "chrome-ai@2"                                # Chrome AI ozellikler / features
            "compose-nudge@2"                            # AI yazma istemi / AI write prompt
            "compose-proactive-nudge@2"                  # Proaktif AI istemi / Proactive AI prompt
            "glic-rollout@2"                             # Gemini Live in Chrome
            "chrome-labs@2"                              # Chrome Labs panel
            "ntp-comprehensive-theming@2"                # NTP tema / theme
            "side-panel-journey@2"                       # Journey side panel
            "password-manager-redesign@2"                # Sifre yoneticisi yeni UI / new UI
        )

        # [TR] Brave'e ozel devre disi flag'ler
        # [EN] Brave-specific flags to disable
        $BraveDisableFlags = @(
            "brave-news-peek@2"                          # Haber onizleme / News peek
            "read-later@2"                               # Daha sonra oku / Read later
            "side-panel-journey@2"                       # Journey panel
            "ntp-realbox@2"                              # NTP arama kutusu / search box
        )

        # [TR] Tarayiciye gore toplam flag listesini olustur
        # [EN] Build total flag list based on browser
        if ($Global:BROWSER -eq "brave") {
            $AllFlags = $EnableFlags + $BraveEnableFlags + $DisableFlags + $BraveDisableFlags
        }
        else {
            $AllFlags = $EnableFlags + $DisableFlags + $ChromeDisableFlags
        }

        # [TR] Mevcut flag'leri koru, sadece bizimkileri guncelle
        # [EN] Preserve existing flags, only update ours
        if (-not ($LS.PSObject.Properties.Name -contains "browser")) {
            $LS | Add-Member -NotePropertyName "browser" `
                             -NotePropertyValue ([PSCustomObject]@{}) -Force
        }

        $existing = @()
        if ($LS.browser.PSObject.Properties.Name -contains "enabled_labs_experiments") {
            $existing = @($LS.browser.enabled_labs_experiments)
        }

        $newNames = $AllFlags | ForEach-Object { ($_ -split "@")[0] }
        $filtered = $existing | Where-Object { ($_ -split "@")[0] -notin $newNames }
        $final    = @($filtered) + @($AllFlags)

        if ($LS.browser.PSObject.Properties.Name -contains "enabled_labs_experiments") {
            $LS.browser.enabled_labs_experiments = $final
        }
        else {
            $LS.browser | Add-Member -NotePropertyName "enabled_labs_experiments" `
                                     -NotePropertyValue $final -Force
        }

        # [TR] BOM'suz yaz (kritik!)
        # [EN] Write without BOM (critical!)
        $jsonOut = $LS | ConvertTo-Json -Depth 100 -Compress
        Write-UTF8NoBOM -Path $LocalState -Content $jsonOut

        $en = if ($Global:BROWSER -eq "brave") {
            $EnableFlags.Count + $BraveEnableFlags.Count
        } else { $EnableFlags.Count }
        $di = $AllFlags.Count - $en

        wOk "$($AllFlags.Count) $(t 'flag uygulandi' 'flags applied') ($en enabled / $di disabled)"
    }
    catch {
        wFail (t "Local State duzenlenemedi" "Failed to edit Local State") + ": $_"
    }
}
else {
    wSkip "[DRY-RUN]"
}

# ============================================================
# [TR] ADIM 5: PREFERENCES
# [EN] STEP 5: PREFERENCES
# ============================================================
wStep (t "Preferences duzenleniyor..." "Editing Preferences...")

if (-not (Test-Path $Prefs)) {
    wSkip (t "Preferences yok. Tarayiciyi bir kez acip kapatin." `
             "Preferences not found. Open and close the browser once.")
}
elseif (-not $DryRun) {
    try {
        $pRaw = Read-UTF8NoBOM $Prefs
        $P    = $pRaw | ConvertFrom-Json

        # [TR] Her iki tarayicida ortak tweaks
        # [EN] Common tweaks for both browsers
        $CommonTweaks = [ordered]@{
            "browser.show_home_button"                   = $false
            "bookmark_bar.show_on_all_tabs"              = $false
            "background_mode.enabled"                    = $false
            "search.suggest_enabled"                     = $false
            "translate.enabled"                          = $false
            "safebrowsing.extended_reporting_enabled"    = $false
            "safebrowsing.enhanced"                      = $false
            "credentials_enable_service"                 = $false
            "credentials_enable_autosignin"              = $false
        }

        # [TR] Brave'e ozel tweaks
        # [EN] Brave-specific tweaks
        $BraveTweaks = [ordered]@{
            "brave.new_tab_page.show_rewards"            = $false
            "brave.new_tab_page.show_brave_news"         = $false
            "brave.new_tab_page.show_together"           = $false
            "brave.new_tab_page.show_clock"              = $false
            "brave.new_tab_page.show_stats"              = $false
            "brave.new_tab_page.show_background_image"   = $false
            "brave.new_tab_page.show_top_sites"          = $false
            "brave.rewards.enabled"                      = $false
            "brave.rewards.show_button"                  = $false
            "brave.wallet.show_wallet_icon_on_toolbar"   = $false
            "brave.sidebar.sidebar_show_option"          = 3   # 3 = Never show
        }

        # [TR] Chrome'a ozel tweaks
        # [EN] Chrome-specific tweaks
        $ChromeTweaks = [ordered]@{
            "ntp.show_shortcut_type"                     = 2
            "signin.allowed"                             = $false
            "sync.requested"                             = $false
        }

        # [TR] Tarayiciye gore tweaks sec
        # [EN] Select tweaks based on browser
        $AllTweaks = if ($Global:BROWSER -eq "brave") {
            $CommonTweaks + $BraveTweaks
        } else {
            $CommonTweaks + $ChromeTweaks
        }

        $ok = 0; $fail = 0
        foreach ($kv in $AllTweaks.GetEnumerator()) {
            try {
                Set-JsonPath -Root $P -Path $kv.Key -Value $kv.Value
                wOk "PREF [$($kv.Key)] = $($kv.Value)"
                $ok++
            }
            catch {
                wFail (t "Yazılamadi" "Failed") + ": $($kv.Key)"
                $fail++
            }
        }

        # [TR] BOM'suz yaz / [EN] Write without BOM
        Write-UTF8NoBOM -Path $Prefs -Content ($P | ConvertTo-Json -Depth 100 -Compress)
        wOk (t "Preferences kaydedildi" "Preferences saved") + " ($ok OK / $fail $(t 'hata' 'error'))"
    }
    catch {
        wFail (t "Preferences duzenlenemedi" "Failed to edit Preferences") + ": $_"
    }
}
else {
    wSkip "[DRY-RUN]"
}

# ============================================================
# [TR] ADIM 6: GUNCELLEME SERVİSLERİ
# [EN] STEP 6: UPDATER SERVICES
#
# [TR] Guncelleme servisleri Manual moda alinir (Disabled degil).
#      Disabled yapmak guvenlik guncellemelerini de engeller.
# [EN] Update services are set to Manual (not Disabled).
#      Disabling them would also block security updates.
# ============================================================
wStep (t "Guncelleme servisleri kontrol ediliyor..." `
         "Checking updater services...")

if (-not $DryRun) {
    $Services = if ($Global:BROWSER -eq "brave") {
        @("BraveUpdate", "BraveUpdateService", "braveupdatem", "brave_updater_service")
    }
    else {
        @("gupdate", "gupdatem", "GoogleChromeElevationService")
    }

    $Tasks = if ($Global:BROWSER -eq "brave") {
        @("BraveUpdateTaskMachineCore", "BraveUpdateTaskMachineUA")
    }
    else {
        @("GoogleUpdateTaskMachineCore", "GoogleUpdateTaskMachineUA")
    }

    foreach ($svc in $Services) {
        $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($s) {
            Stop-Service  -Name $svc -Force               -ErrorAction SilentlyContinue
            Set-Service   -Name $svc -StartupType Manual  -ErrorAction SilentlyContinue
            wOk (t "Manuel moda alindi" "Set to Manual") + ": $svc"
        }
        else {
            wSkip (t "Servis yok" "Service not found") + ": $svc"
        }
    }

    foreach ($task in $Tasks) {
        $t2 = Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue
        if ($t2) {
            Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Out-Null
            wOk (t "Gorev devre disi" "Task disabled") + ": $task"
        }
        else {
            wSkip (t "Gorev yok" "Task not found") + ": $task"
        }
    }
}
else {
    wSkip "[DRY-RUN]"
}

# ============================================================
# [TR] ADIM 7: CACHE TEMIZLIGI / [EN] STEP 7: CACHE CLEANUP
# ============================================================
wStep (t "Cache temizleniyor..." "Cleaning cache...")

$CacheNames = @(
    "Cache"
    "Code Cache"
    "GPUCache"
    "ShaderCache"
    "GrShaderCache"
    "GraphiteDawnCache"
    "Network\NetworkDataMigrated"
)

$CachePaths = $CacheNames | ForEach-Object {
    if ($_ -in @("ShaderCache", "GrShaderCache", "GraphiteDawnCache")) {
        "$UserData\$_"
    }
    elseif ($_ -eq "Network\NetworkDataMigrated") {
        "$DefProfile\$_"
    }
    else {
        "$DefProfile\$_"
    }
}

$TotalBytes = 0
$Cleaned    = 0

for ($i = 0; $i -lt $CacheNames.Count; $i++) {
    $name = $CacheNames[$i]
    $dir  = $CachePaths[$i]
    if (Test-Path $dir) {
        $size = (Get-ChildItem $dir -Recurse -ErrorAction SilentlyContinue |
                 Measure-Object Length -Sum).Sum
        $mb   = [math]::Round($size / 1MB, 1)
        if (-not $DryRun) {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
            wOk (t "Temizlendi" "Cleaned") + ": $name (~$mb MB)"
        }
        else {
            wInfo "[DRY-RUN] $(t 'Temizlenebilir' 'Would clean'): $name (~$mb MB)"
        }
        $TotalBytes += $size
        $Cleaned++
    }
    else {
        wSkip (t "Yok" "Not found") + ": $name"
    }
}

$TotalMB = [math]::Round($TotalBytes / 1MB, 1)
if (-not $DryRun) {
    wOk (t "Toplam temizlendi" "Total cleaned") + ": ~$TotalMB MB ($Cleaned $(t 'dizin' 'dirs'))"
}
else {
    wInfo (t "Temizlenebilir toplam" "Would clean total") + ": ~$TotalMB MB"
}

# ============================================================
# [TR] ADIM 8: RAPOR / [EN] STEP 8: REPORT
# ============================================================
wStep (t "Rapor olusturuluyor..." "Generating report...")

if (-not $DryRun) {
    $sep  = "=" * 60
    $sep2 = "-" * 60

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add($sep)
    $lines.Add("  BROWSER DEBLOAT RAPORU / REPORT  v$ScriptVer")
    $lines.Add("  $(t 'Tarih'    'Date')     : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    $lines.Add("  $(t 'Kullanici' 'User')    : $env:USERNAME")
    $lines.Add("  $(t 'Sistem'   'System')   : $OSInfo")
    $lines.Add("  $(t 'Tarayici' 'Browser')  : $BrowserLabel")
    $lines.Add("  $(t 'Surum'    'Version')  : $BrowserVer")
    $lines.Add("  $(t 'Kurulum'  'Install')  : $InstallType")
    $lines.Add("  User Data : $UserData")
    $lines.Add("  Registry  : $RegPath")
    $lines.Add("  $(t 'Masaustu' 'Desktop')  : $Desktop")
    if ($DryRun) { $lines.Add("  MODE      : DRY-RUN") }
    $lines.Add($sep)
    $lines.Add("")
    $lines.Add("$(t 'YAPILAN ISLEMLER:' 'PERFORMED ACTIONS:')")
    $lines.Add($sep2)
    foreach ($entry in $Global:LOG) { $lines.Add($entry) }
    $lines.Add("")

    if ($Global:ERRORS.Count -gt 0) {
        $lines.Add("$(t 'HATALAR' 'ERRORS') ($($Global:ERRORS.Count)):")
        $lines.Add($sep2)
        foreach ($e in $Global:ERRORS) { $lines.Add("  [!] $e") }
        $lines.Add("")
    }

    if ($Global:WARNINGS.Count -gt 0) {
        $lines.Add("$(t 'UYARILAR' 'WARNINGS') ($($Global:WARNINGS.Count)):")
        $lines.Add($sep2)
        foreach ($w in $Global:WARNINGS) { $lines.Add("  [?] $w") }
        $lines.Add("")
    }

    $lines.Add($sep2)
    $lines.Add("$(t 'SONRAKI ADIMLAR:' 'NEXT STEPS:')")
    $lines.Add($sep2)
    $lines.Add("")
    if ($Global:BROWSER -eq "brave") {
        $lines.Add("  1. brave://policy  -> Reload policies")
        $lines.Add("  2. brave://flags   -> Parallel Downloading: Enabled?")
        $lines.Add("  3. brave://gpu     -> Hardware accelerated?")
        $lines.Add("  4. brave://settings/brave-news -> Disabled?")
        $lines.Add("  5. brave://settings/wallet     -> Disabled?")
    }
    else {
        $lines.Add("  1. chrome://policy  -> Reload policies")
        $lines.Add("  2. chrome://flags   -> Parallel Downloading: Enabled?")
        $lines.Add("  3. chrome://gpu     -> Hardware accelerated?")
        $lines.Add("  4. chrome://settings/ai -> Gemini disabled?")
        $lines.Add("  5. chrome://settings/system -> Hardware acceleration ON?")
    }
    $lines.Add("")
    $lines.Add("$(t 'YOUTUBE BEYAZ/SIYAH EKRAN SORUNU:' 'YOUTUBE WHITE/BLACK SCREEN:')")
    $lines.Add($sep2)
    if ($Global:BROWSER -eq "brave") {
        $lines.Add("  brave://settings/system")
        $lines.Add("  -> $(t 'Kullanilabilir oldugunda grafik hizlandirmayi kullan' 'Use hardware acceleration when available')")
        $lines.Add("  -> $(t 'KAPAT ve yeniden ac' 'DISABLE and relaunch')")
    }
    else {
        $lines.Add("  chrome://settings/system")
        $lines.Add("  -> $(t 'Kullanilabilir oldugunda grafik hizlandirmayi kullan' 'Use graphics acceleration when available')")
        $lines.Add("  -> $(t 'KAPAT ve yeniden ac' 'DISABLE and relaunch')")
    }
    $lines.Add("")
    $lines.Add("$(t 'GERI ALMA:' 'REVERT:')")
    $lines.Add($sep2)
    $lines.Add("  $(t '1. Registry geri yukle:' '1. Restore registry:')")
    $lines.Add("     regedit -> $BackupDir\registry_backup.reg")
    $lines.Add("  $(t '2. Local State geri yukle:' '2. Restore Local State:')")
    $lines.Add("     copy `"$BackupDir\Local State`" `"$LocalState`"")
    $lines.Add("  $(t '3. Preferences geri yukle:' '3. Restore Preferences:')")
    $lines.Add("     copy `"$BackupDir\Preferences`" `"$Prefs`"")
    $lines.Add("  $(t '4. Registry policy key sil:' '4. Delete registry policy key:')")
    $lines.Add("     Remove-Item -Path `"$RegPath`" -Recurse -Force")
    $lines.Add("")
    $lines.Add("$(t 'NOT:' 'NOTE:')")
    $lines.Add("  $(t `"'Managed by your organization' -> NORMALDIR.`" `"'Managed by your organization' -> NORMAL.`")")
    $lines.Add($sep)

    Write-UTF8NoBOM -Path $ReportPath -Content ($lines -join "`r`n")
    wOk (t "Rapor olusturuldu" "Report saved") + ": $ReportPath"
}
else {
    wSkip "[DRY-RUN]"
}

# ============================================================
# [TR] TAMAMLANDI / [EN] COMPLETED
# ============================================================
$sep60 = "=" * 60
Write-Host ""
Write-Host "  $sep60" -ForegroundColor Cyan
if ($Global:ERRORS.Count -eq 0) {
    Write-Host ("  " + (t "TAMAMLANDI  [OK]" "COMPLETED  [OK]")) -ForegroundColor Green
}
else {
    Write-Host ("  " + (t "TAMAMLANDI" "COMPLETED") + `
        "  [$($Global:ERRORS.Count) $(t 'hata' 'error') / " + `
        "$($Global:WARNINGS.Count) $(t 'uyari' 'warning')]") -ForegroundColor Yellow
}
Write-Host "  $sep60" -ForegroundColor Cyan
Write-Host ("  $(t 'Tarayici'  'Browser')  : $BrowserLabel")
Write-Host ("  $(t 'Surum'     'Version')  : $BrowserVer")
Write-Host ("  $(t 'Kurulum'   'Install')  : $InstallType")
Write-Host ("  Registry  : $RegPath")
if (-not $DryRun) {
    Write-Host ("  $(t 'Backup'    'Backup')    : $BackupDir")
    Write-Host ("  $(t 'Rapor'     'Report')    : $ReportPath")
}
Write-Host "  $sep60" -ForegroundColor Cyan
Write-Host ""

if ($Global:BROWSER -eq "brave") {
    Write-Host ("  [!] brave://policy -> Reload policies") -ForegroundColor Yellow
    Write-Host ("  [!] brave://flags  -> Parallel Downloading: Enabled?") -ForegroundColor Yellow
    Write-Host ("  [!] brave://gpu    -> Hardware accelerated?") -ForegroundColor Yellow
}
else {
    Write-Host ("  [!] chrome://policy -> Reload policies") -ForegroundColor Yellow
    Write-Host ("  [!] chrome://flags  -> Parallel Downloading: Enabled?") -ForegroundColor Yellow
    Write-Host ("  [!] chrome://gpu    -> Hardware accelerated?") -ForegroundColor Yellow
    Write-Host ("  [!] chrome://settings/ai -> Gemini disabled?") -ForegroundColor Yellow
}

Write-Host ("  [!] " + (t "'Managed by your organization' -> NORMALDIR." `
                           "'Managed by your organization' -> NORMAL.")) -ForegroundColor Yellow

if ($DryRun) {
    Write-Host ("  [!] DRY-RUN -- " + (t "hicbir degisiklik yapilmadi." `
        "no changes were made.")) -ForegroundColor Yellow
}
Write-Host ""
