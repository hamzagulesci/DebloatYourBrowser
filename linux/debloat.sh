#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║   Browser Debloat & Performance Optimizer                    ║
# ║   Linux Universal v3.0                                       ║
# ║                                                              ║
# ║   Desteklenen tarayicilar:                                   ║
# ║     ● Brave Browser                                          ║
# ║     ● Google Chrome                                          ║
# ║                                                              ║
# ║   Desteklenen kurulum tipleri:                               ║
# ║     native  apt/deb  Ubuntu, Debian, Zorin, Mint, Pop!OS    ║
# ║     native  rpm/dnf  Fedora, RHEL, openSUSE, Rocky          ║
# ║     native  pacman   Arch, Manjaro, EndeavourOS, Garuda      ║
# ║     flatpak          Tum distrolarda (policy sinirli)        ║
# ║     snap             Ubuntu ve turevleri                     ║
# ║     appimage         Manuel kurulum                          ║
# ║                                                              ║
# ║   Kullanim:                                                  ║
# ║     chmod +x debloat.sh                                      ║
# ║     sudo ./debloat.sh                                        ║
# ║     sudo ./debloat.sh --dry-run                              ║
# ╚══════════════════════════════════════════════════════════════╝

# NOT: set -e kullanmiyoruz.
# pkill, pgrep, flatpak gibi komutlar nonzero dondurunce script olmemeli.
# Her komut manuel SilentlyContinue benzeri kontrol ediliyor.

readonly SCRIPT_VERSION="3.0"
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# ─────────────────────────────────────────────────────────────
# RENKLER
# ─────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  CY='\033[1;36m' GR='\033[1;32m' RD='\033[1;31m'
  YL='\033[1;33m' GY='\033[0;90m' BL='\033[1;34m'
  BD='\033[1m'    RS='\033[0m'
else
  CY='' GR='' RD='' YL='' GY='' BL='' BD='' RS=''
fi

LOG=(); ERRORS=(); WARNINGS=()
_log() { LOG+=("$1"); }
wStep() { echo -e "\n${BL}${BD}▶ $1${RS}";  _log "[STEP]  $1"; }
wOk()   { echo -e "  ${GR}✓${RS} $1";        _log "[OK]    $1"; }
wSkip() { echo -e "  ${GY}─${RS} $1";        _log "[SKIP]  $1"; }
wFail() { echo -e "  ${RD}✗${RS} $1";        _log "[FAIL]  $1"; ERRORS+=("$1"); }
wWarn() { echo -e "  ${YL}!${RS} $1";        _log "[WARN]  $1"; WARNINGS+=("$1"); }
wInfo() { echo -e "  ${CY}i${RS} $1";        _log "[INFO]  $1"; }
t()     { [[ "$LANG_CODE" == "en" ]] && echo "$2" || echo "$1"; }

# ─────────────────────────────────────────────────────────────
# ROOT KONTROLU
# ─────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  echo -e "${RD}[HATA/ERROR] Root gerekli / Root required:${RS}"
  echo -e "  sudo ./debloat.sh"
  exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
[[ -z "$REAL_HOME" || ! -d "$REAL_HOME" ]] && {
  echo -e "${RD}[HATA] Home dizini bulunamadi.${RS}"; exit 1
}
TS=$(date +%Y%m%d_%H%M%S)
DISTRO=$(grep -oP '(?<=^PRETTY_NAME=").*(?=")' /etc/os-release 2>/dev/null || uname -sr)

# ─────────────────────────────────────────────────────────────
# MASAÜSTÜ PATH — xdg-user-dir ile locale'den bağımsız
# Türkçe: ~/Masaüstü | İngilizce: ~/Desktop | Almanca: ~/Schreibtisch
# ─────────────────────────────────────────────────────────────
_get_desktop() {
  # 1. xdg-user-dir: her distro ve locale'de doğru yolu verir
  if command -v xdg-user-dir &>/dev/null; then
    local xdg_desk
    xdg_desk=$(sudo -u "$REAL_USER" xdg-user-dir DESKTOP 2>/dev/null)
    [[ -n "$xdg_desk" && -d "$xdg_desk" ]] && { echo "$xdg_desk"; return; }
  fi
  # 2. Fallback: Bilinen isimler
  for d in \
    "$REAL_HOME/Masaüstü" \
    "$REAL_HOME/Desktop" \
    "$REAL_HOME/Schreibtisch" \
    "$REAL_HOME/Bureau" \
    "$REAL_HOME/Рабочий стол"; do
    [[ -d "$d" ]] && { echo "$d"; return; }
  done
  # 3. Son çare: klasik Desktop, yoksa oluştur
  echo "$REAL_HOME/Desktop"
}

DESKTOP=$(_get_desktop)
[[ ! -d "$DESKTOP" ]] && { mkdir -p "$DESKTOP"; chown "$REAL_USER:$REAL_USER" "$DESKTOP"; }

# ═══════════════════════════════════════════════════════════════
# EKRAN — Başlık + Dil Seçimi
# ═══════════════════════════════════════════════════════════════
clear
echo -e "${CY}${BD}"
echo "██████  ███████ ██████  ██       ██████   █████  ████████"
echo "██   ██ ██      ██   ██ ██      ██    ██ ██   ██    ██"
echo "██   ██ █████   ██████  ██      ██    ██ ███████    ██"
echo "██   ██ ██      ██   ██ ██      ██    ██ ██   ██    ██"
echo "██████  ███████ ██████  ███████  ██████  ██   ██    ██"
echo ""
echo "  BROWSER DEBLOAT & PERFORMANCE"
echo -e "  Linux Universal v${SCRIPT_VERSION}${RS}"
echo ""
echo -e "${BD}  Lütfen dil seçin / Please select language:${RS}"
echo ""
echo -e "  ${CY}[1]${RS} Türkçe"
echo -e "  ${CY}[2]${RS} English"
echo ""
printf "  Seçim / Choice [1/2]: "
read -r _lc
case "$_lc" in 2) LANG_CODE="en" ;; *) LANG_CODE="tr" ;; esac

# ═══════════════════════════════════════════════════════════════
# TARAYICI SEÇİMİ
# ═══════════════════════════════════════════════════════════════
clear
echo -e "${CY}${BD}"
echo "██████  ███████ ██████  ██       ██████   █████  ████████"
echo "██   ██ ██      ██   ██ ██      ██    ██ ██   ██    ██"
echo "██   ██ █████   ██████  ██      ██    ██ ███████    ██"
echo "██   ██ ██      ██   ██ ██      ██    ██ ██   ██    ██"
echo "██████  ███████ ██████  ███████  ██████  ██   ██    ██"
echo ""
echo "  BROWSER DEBLOAT & PERFORMANCE"
echo -e "  Linux Universal v${SCRIPT_VERSION}${RS}"
echo ""
echo -e "  ${BD}$(t 'Tarayici seçin:' 'Select browser:')${RS}"
echo ""
echo -e "  ${CY}[1]${RS} Brave Browser"
echo -e "  ${CY}[2]${RS} Google Chrome"
echo ""
printf "  $(t 'Seçim' 'Choice') [1/2]: "
read -r _bc
case "$_bc" in 2) BROWSER="chrome" ;; *) BROWSER="brave" ;; esac

# ═══════════════════════════════════════════════════════════════
# BAŞLIK EKRANI
# ═══════════════════════════════════════════════════════════════
clear
if [[ "$BROWSER" == "brave" ]]; then
  BROWSER_LABEL="Brave Browser"
else
  BROWSER_LABEL="Google Chrome"
fi

echo -e "${CY}${BD}"
echo "██████  ███████ ██████  ██       ██████   █████  ████████"
echo "██   ██ ██      ██   ██ ██      ██    ██ ██   ██    ██"
echo "██   ██ █████   ██████  ██      ██    ██ ███████    ██"
echo "██   ██ ██      ██   ██ ██      ██    ██ ██   ██    ██"
echo "██████  ███████ ██████  ███████  ██████  ██   ██    ██"
echo ""
echo -e "  ${BROWSER_LABEL}  |  Linux Universal v${SCRIPT_VERSION}${RS}"
echo ""
echo -e "  ${BD}$(t 'Kullanici'  'User')${RS}     : $REAL_USER"
echo -e "  ${BD}$(t 'Sistem'     'System')${RS}    : $(uname -sr)"
echo -e "  ${BD}$(t 'Dagitim'    'Distro')${RS}    : $DISTRO"
echo -e "  ${BD}$(t 'Masaustu'   'Desktop')${RS}   : $DESKTOP"
echo -e "  ${BD}$(t 'Tarayici'   'Browser')${RS}   : $BROWSER_LABEL"
echo -e "  ${BD}$(t 'Dil'        'Language')${RS}  : $(t 'Türkçe' 'English')"
[[ "$DRY_RUN" == true ]] && \
  echo -e "\n  ${YL}${BD}[DRY-RUN] $(t 'Hicbir degisiklik yapilmayacak.' 'No changes will be made.')${RS}"
echo ""

# ═══════════════════════════════════════════════════════════════
# ADIM 0: KURULUM TESPİTİ
# ═══════════════════════════════════════════════════════════════
wStep "$(t 'Kurulum tipi algilaniyor...' 'Detecting installation type...')"

INSTALL_TYPE="" USER_DATA="" BROWSER_BIN="" PKG_MGR="unknown"
POLICY_DIR="" PROCESS_NAME="" FLATPAK_ID=""

if [[ "$BROWSER" == "brave" ]]; then
  # ── BRAVE TESPİTİ ───────────────────────────────────────────
  FLATPAK_ID="com.brave.Browser"
  PROCESS_NAME="brave-browser"

  if command -v brave-browser &>/dev/null; then
    BROWSER_BIN=$(command -v brave-browser)
    INSTALL_TYPE="native"
    USER_DATA="$REAL_HOME/.config/BraveSoftware/Brave-Browser"
    POLICY_DIR="/etc/brave/policies/managed"
    wOk "$(t 'Native kurulum' 'Native install'): $BROWSER_BIN"

  elif flatpak list --app 2>/dev/null | grep -q "com.brave.Browser"; then
    BROWSER_BIN="$FLATPAK_ID"
    INSTALL_TYPE="flatpak"
    USER_DATA="$REAL_HOME/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser"
    POLICY_DIR="/etc/brave/policies/managed"
    wOk "Flatpak: com.brave.Browser"
    wWarn "$(t 'Flatpak policy sinirli: /etc/brave/ sandbox disinda kalabilir.' \
              'Flatpak policy limited: /etc/brave/ may be outside sandbox.')"

  elif snap list 2>/dev/null | grep -qi "^brave"; then
    BROWSER_BIN="brave"
    INSTALL_TYPE="snap"
    USER_DATA="$REAL_HOME/snap/brave/current/.config/BraveSoftware/Brave-Browser"
    POLICY_DIR="/etc/brave/policies/managed"
    wOk "Snap: brave"
    wWarn "$(t 'Snap policy icin: sudo snap connect brave:system-files' \
              'For snap policy: sudo snap connect brave:system-files')"

  elif _ai=$(find /opt /usr/local "$REAL_HOME/.local/bin" -name "brave*" \
             -type f 2>/dev/null | head -1) && [[ -n "$_ai" ]]; then
    BROWSER_BIN="$_ai"
    INSTALL_TYPE="appimage"
    USER_DATA="$REAL_HOME/.config/BraveSoftware/Brave-Browser"
    POLICY_DIR="/etc/brave/policies/managed"
    wOk "AppImage: $BROWSER_BIN"
  fi

else
  # ── CHROME TESPİTİ ──────────────────────────────────────────
  FLATPAK_ID="com.google.Chrome"
  PROCESS_NAME="google-chrome"

  if command -v google-chrome-stable &>/dev/null; then
    BROWSER_BIN=$(command -v google-chrome-stable)
    INSTALL_TYPE="native"
    USER_DATA="$REAL_HOME/.config/google-chrome"
    POLICY_DIR="/etc/opt/chrome/policies/managed"
    wOk "$(t 'Native kurulum' 'Native install'): $BROWSER_BIN"

  elif command -v google-chrome &>/dev/null; then
    BROWSER_BIN=$(command -v google-chrome)
    INSTALL_TYPE="native"
    USER_DATA="$REAL_HOME/.config/google-chrome"
    POLICY_DIR="/etc/opt/chrome/policies/managed"
    wOk "$(t 'Native kurulum' 'Native install'): $BROWSER_BIN"

  elif flatpak list --app 2>/dev/null | grep -q "com.google.Chrome"; then
    BROWSER_BIN="$FLATPAK_ID"
    INSTALL_TYPE="flatpak"
    USER_DATA="$REAL_HOME/.var/app/com.google.Chrome/config/google-chrome"
    POLICY_DIR="/etc/opt/chrome/policies/managed"
    wOk "Flatpak: com.google.Chrome"
    wWarn "$(t 'Flatpak Chrome policy calismaz (sandbox kisitlamasi).' \
              'Flatpak Chrome policy does not work (sandbox restriction).')"
    wWarn "$(t 'Flags ve Preferences duzenlenir, policy atlanir.' \
              'Flags and Preferences will be edited, policy skipped.')"

  elif _ai=$(find /opt /usr/local "$REAL_HOME/.local/bin" \
             -name "google-chrome*" -type f 2>/dev/null | head -1) && [[ -n "$_ai" ]]; then
    BROWSER_BIN="$_ai"
    INSTALL_TYPE="appimage"
    USER_DATA="$REAL_HOME/.config/google-chrome"
    POLICY_DIR="/etc/opt/chrome/policies/managed"
    wOk "$(t 'Manuel kurulum' 'Manual install'): $BROWSER_BIN"
  fi
fi

# ── ORTAK: install tipi bulunamadiysa fallback ──────────────
if [[ -z "$INSTALL_TYPE" ]]; then
  # User data'ya bak
  for _ud in \
    "$REAL_HOME/.config/BraveSoftware/Brave-Browser" \
    "$REAL_HOME/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser" \
    "$REAL_HOME/.config/google-chrome" \
    "$REAL_HOME/.var/app/com.google.Chrome/config/google-chrome"; do
    if [[ -d "$_ud" ]]; then
      INSTALL_TYPE="unknown"; USER_DATA="$_ud"
      wWarn "$(t 'Binary bulunamadi, User Data mevcut' 'Binary not found, User Data found'): $_ud"
      break
    fi
  done
  [[ -z "$INSTALL_TYPE" ]] && {
    echo -e "\n${RD}$(t '[HATA] Tarayici bulunamadi.' '[ERROR] Browser not found.')${RS}"
    echo "$(t '  Kur ve bir kez acip kapatin.' '  Install and open it once.')"
    exit 1
  }
fi

# ── PAKET YÖNETİCİSİ ────────────────────────────────────────
if [[ "$INSTALL_TYPE" == "native" ]]; then
  if   command -v apt-get &>/dev/null; then PKG_MGR="apt"
  elif command -v dnf     &>/dev/null; then PKG_MGR="dnf"
  elif command -v pacman  &>/dev/null; then PKG_MGR="pacman"
  elif command -v zypper  &>/dev/null; then PKG_MGR="zypper"
  fi
fi

# ── USER DATA KONTROLU ──────────────────────────────────────
if [[ ! -d "$USER_DATA" ]]; then
  echo -e "\n${RD}$(t '[HATA] User Data yok:' '[ERROR] User Data missing:') $USER_DATA${RS}"
  echo "$(t '  Tarayiciyi bir kez acip kapatin.' '  Open and close the browser once.')"
  exit 1
fi

DEF_PROFILE="$USER_DATA/Default"
LOCAL_STATE="$USER_DATA/Local State"
PREFS="$DEF_PROFILE/Preferences"
BACKUP_DIR="$DESKTOP/$(t 'TarayiciDebloat' 'BrowserDebloat')_Backup_$TS"
REPORT_PATH="$DESKTOP/$(t 'TarayiciDebloat' 'BrowserDebloat')_Rapor_$TS.txt"

# Flatpak cache dizinleri
if [[ "$BROWSER" == "brave" ]]; then
  FP_CACHE="$REAL_HOME/.var/app/com.brave.Browser/cache/BraveSoftware/Brave-Browser"
else
  FP_CACHE="$REAL_HOME/.var/app/com.google.Chrome/cache/google-chrome"
fi

# Versiyon
BROWSER_VER="N/A"
if [[ "$INSTALL_TYPE" == "native" ]]; then
  BROWSER_VER=$(sudo -u "$REAL_USER" "$BROWSER_BIN" --version 2>/dev/null | head -1 || echo "N/A")
elif [[ "$INSTALL_TYPE" == "flatpak" ]]; then
  BROWSER_VER=$(flatpak info "$FLATPAK_ID" 2>/dev/null | grep "Version" | awk '{print $2}' || echo "N/A")
fi

wInfo "$(t 'Surum'     'Version')   : $BROWSER_VER"
wInfo "$(t 'Paket mgr' 'Pkg mgr')   : $PKG_MGR"
wInfo "$(t 'User Data' 'User Data') : $USER_DATA"
wInfo "Policy     : $POLICY_DIR"
wInfo "$(t 'Masaustu'  'Desktop')   : $DESKTOP"

# ═══════════════════════════════════════════════════════════════
# ADIM 1: TARAYICI KAPAT
# ═══════════════════════════════════════════════════════════════
wStep "$(t 'Tarayici kapatiliyor...' 'Closing browser...')"

# !! KRİTİK: pkill -f YERİNE pkill -x kullan !!
# pkill -f: TÜM process argümanlarını tarar → script adı eşleşirse script ölür
# pkill -x: SADECE tam process adı eşleşmesi → güvenli
_kill_browser() {
  # Flatpak / Snap özel kapatma
  [[ "$INSTALL_TYPE" == "flatpak" ]] && \
    flatpak kill "$FLATPAK_ID" 2>/dev/null || true
  [[ "$INSTALL_TYPE" == "snap" && "$BROWSER" == "brave" ]] && \
    snap stop brave 2>/dev/null || true

  local pnames=()
  if [[ "$BROWSER" == "brave" ]]; then
    pnames=("brave-browser" "brave")
  else
    pnames=("google-chrome" "google-chrome-stable" "chrome")
  fi

  local running=false
  for pn in "${pnames[@]}"; do
    pgrep -x "$pn" &>/dev/null && running=true && break
  done

  if $running; then
    for pn in "${pnames[@]}"; do
      pkill -x "$pn" 2>/dev/null || true
    done
    sleep 2
    # Hala çalışıyorsa SIGKILL
    for pn in "${pnames[@]}"; do
      pkill -9 -x "$pn" 2>/dev/null || true
    done
    sleep 1
    return 0  # kapatildi
  fi
  return 1  # zaten kapaliydi
}

if [[ "$DRY_RUN" == false ]]; then
  if _kill_browser; then
    wOk "$(t 'Tarayici kapatildi.' 'Browser closed.')"
  else
    wSkip "$(t 'Tarayici zaten kapaliydi.' 'Browser was already closed.')"
  fi
else
  wSkip "[DRY-RUN] $(t 'Kapatma atlandi.' 'Close skipped.')"
fi

# ═══════════════════════════════════════════════════════════════
# ADIM 2: BACKUP
# ═══════════════════════════════════════════════════════════════
wStep "$(t 'Kritik dosyalar yedekleniyor...' 'Backing up critical files...')"

if [[ "$DRY_RUN" == false ]]; then
  mkdir -p "$BACKUP_DIR"
  _bc=0
  for f in "$LOCAL_STATE" "$PREFS"; do
    if [[ -f "$f" ]]; then
      cp "$f" "$BACKUP_DIR/" 2>/dev/null \
        && { wOk "$(t 'Yedeklendi' 'Backed up'): $(basename "$f")"; ((_bc++)); } \
        || wFail "$(t 'Yedeklenemedi' 'Backup failed'): $(basename "$f")"
    else
      wSkip "$(t 'Yok' 'Not found'): $(basename "$f")"
    fi
  done
  chown -R "$REAL_USER:$REAL_USER" "$BACKUP_DIR"
  wOk "$(t 'Backup tamam' 'Backup done') ($_bc $(t 'dosya' 'files')): $BACKUP_DIR"
else
  wSkip "[DRY-RUN] $(t 'Backup atlandi.' 'Backup skipped.')"
fi

# ═══════════════════════════════════════════════════════════════
# ADIM 3: POLICY JSON
# ═══════════════════════════════════════════════════════════════
wStep "$(t 'Policy JSON yaziliyor...' 'Writing Policy JSON...'): $POLICY_DIR"

# Flatpak policy neden çalışmaz:
# Flatpak sandbox /etc/brave/ ve /etc/opt/chrome/ dizinlerine erişemez.
# Brave Flatpak özellikle /etc/brave/ mount etmiyor.
# Native kurulumda ise her iki browser da /etc/ policy'yi okur.
_policy_works=true
[[ "$INSTALL_TYPE" == "flatpak" ]] && _policy_works=false

_write_brave_policy() {
  cat > "$POLICY_DIR/debloat.json" << 'POLICY_JSON'
{
  "MetricsReportingEnabled"                  : false,
  "UrlKeyedAnonymizedDataCollectionEnabled"  : false,
  "FeedbackSurveysEnabled"                   : false,
  "UserFeedbackAllowed"                      : false,
  "ReportingEnabled"                         : false,

  "BraveRewardsDisabled"                     : true,
  "BraveWalletDisabled"                      : true,
  "BraveVPNDisabled"                         : true,
  "BraveTalkDisabled"                        : true,
  "BraveAIChatEnabled"                       : false,
  "BraveWebDiscoveryEnabled"                 : false,
  "BraveStatsPingEnabled"                    : false,
  "BraveP3AEnabled"                          : false,
  "BravePlaylistEnabled"                     : false,
  "BraveReduceLanguageEnabled"               : true,

  "BackgroundModeEnabled"                    : false,
  "SafeBrowsingExtendedReportingEnabled"     : false,
  "AlternateErrorPagesEnabled"               : false,
  "ResolveNavigationErrorsUseWebService"     : false,
  "SearchSuggestEnabled"                     : false,
  "NetworkPredictionOptions"                 : 2,
  "DnsPrefetchingEnabled"                    : false,
  "TranslateEnabled"                         : false,
  "SpellCheckServiceEnabled"                 : false,
  "PasswordManagerEnabled"                   : false,
  "AutofillAddressEnabled"                   : false,
  "AutofillCreditCardEnabled"                : false,
  "PaymentMethodQueryEnabled"                : false,

  "DefaultNotificationsSetting"              : 2,
  "DefaultGeolocationSetting"                : 2,
  "DefaultWebBluetoothGuardSetting"          : 2,
  "DefaultWebUsbGuardSetting"                : 2,
  "DefaultWebHidGuardSetting"                : 2,

  "WebRtcIPHandling"                         : "default_public_interface_only",

  "PromotionalTabsEnabled"                   : false,
  "HideWebStoreIcon"                         : true,
  "EnableMediaRouter"                        : false,

  "DnsOverHttpsMode"                         : "automatic",

  "PrivacySandboxAdTopicsEnabled"            : false,
  "PrivacySandboxAdMeasurementEnabled"       : false,
  "PrivacySandboxSiteEnabledAdsEnabled"      : false,
  "PrivacySandboxPromptEnabled"              : false
}
POLICY_JSON
}

_write_chrome_policy() {
  cat > "$POLICY_DIR/debloat.json" << 'POLICY_JSON'
{
  "MetricsReportingEnabled"                  : false,
  "UrlKeyedAnonymizedDataCollectionEnabled"  : false,
  "FeedbackSurveysEnabled"                   : false,
  "UserFeedbackAllowed"                      : false,
  "ReportingEnabled"                         : false,

  "GeminiSettings"                           : 1,
  "AIModeSettings"                           : 1,
  "GenAILocalFoundationalModelSettings"      : 1,
  "DevToolsGenAiSettings"                    : 1,
  "CreateThemesSettings"                     : 1,
  "TabOrganizerSettings"                     : 1,
  "HelpMeWriteSettings"                      : 1,
  "BraveAIChatEnabled"                       : false,

  "SyncDisabled"                             : true,
  "BrowserSignin"                            : 0,
  "GoogleSearchSidePanelEnabled"             : false,

  "BackgroundModeEnabled"                    : false,
  "SafeBrowsingExtendedReportingEnabled"     : false,
  "AlternateErrorPagesEnabled"               : false,
  "ResolveNavigationErrorsUseWebService"     : false,
  "SearchSuggestEnabled"                     : false,
  "NetworkPredictionOptions"                 : 2,
  "DnsPrefetchingEnabled"                    : false,
  "TranslateEnabled"                         : false,
  "SpellCheckServiceEnabled"                 : false,
  "PasswordManagerEnabled"                   : false,
  "AutofillAddressEnabled"                   : false,
  "AutofillCreditCardEnabled"                : false,
  "PaymentMethodQueryEnabled"                : false,

  "DefaultNotificationsSetting"              : 2,
  "DefaultGeolocationSetting"                : 2,
  "DefaultWebBluetoothGuardSetting"          : 2,
  "DefaultWebUsbGuardSetting"                : 2,
  "DefaultWebHidGuardSetting"                : 2,

  "WebRtcIPHandling"                         : "default_public_interface_only",

  "PromotionalTabsEnabled"                   : false,
  "HideWebStoreIcon"                         : true,
  "ShowCastIconInToolbar"                    : false,
  "EnableMediaRouter"                        : false,

  "DnsOverHttpsMode"                         : "automatic",

  "PrivacySandboxAdTopicsEnabled"            : false,
  "PrivacySandboxAdMeasurementEnabled"       : false,
  "PrivacySandboxSiteEnabledAdsEnabled"      : false,
  "PrivacySandboxPromptEnabled"              : false
}
POLICY_JSON
}

if [[ "$DRY_RUN" == false ]]; then
  if $_policy_works; then
    mkdir -p "$POLICY_DIR"
    chmod 755 "$(dirname "$(dirname "$POLICY_DIR")")" 2>/dev/null || true
    chmod 755 "$(dirname "$POLICY_DIR")"              2>/dev/null || true
    chmod 755 "$POLICY_DIR"

    if [[ "$BROWSER" == "brave" ]]; then
      _write_brave_policy 2>/dev/null && {
        chmod 644 "$POLICY_DIR/debloat.json"
        wOk "$(t 'Policy JSON olusturuldu (Brave).' 'Policy JSON created (Brave).')"
      } || wFail "$(t 'Policy yazılamadi.' 'Policy write failed.')"
    else
      _write_chrome_policy 2>/dev/null && {
        chmod 644 "$POLICY_DIR/debloat.json"
        wOk "$(t 'Policy JSON olusturuldu (Chrome).' 'Policy JSON created (Chrome).')"
      } || wFail "$(t 'Policy yazılamadi.' 'Policy write failed.')"
    fi
    wInfo "$(t 'Kontrol: tarayici://policy -> Reload policies' \
              'Verify: browser://policy -> Reload policies')"
  else
    wSkip "$(t 'Flatpak sandbox: policy yazilmadi (calismiyor).' \
              'Flatpak sandbox: policy skipped (not supported).')"
    wInfo "$(t 'Flags ve Preferences yine de uygulanacak.' \
              'Flags and Preferences will still be applied.')"
  fi
else
  wSkip "[DRY-RUN] $(t 'Policy atlandi.' 'Policy skipped.')"
fi

# ═══════════════════════════════════════════════════════════════
# ADIM 4: chrome://flags (Local State)
# ═══════════════════════════════════════════════════════════════
wStep "$(t 'chrome://flags duzenleniyor (Local State)...' 'Editing chrome://flags (Local State)...')"

if [[ ! -f "$LOCAL_STATE" ]]; then
  wSkip "$(t 'Local State yok. Tarayiciyi acip kapatin.' \
            'Local State missing. Open and close the browser first.')"
elif [[ "$DRY_RUN" == false ]]; then

  BRAVE_FLAGS_JSON='true'
  [[ "$BROWSER" == "chrome" ]] && BRAVE_FLAGS_JSON='false'

  _BROWSER="$BROWSER" _LS_PATH="$LOCAL_STATE" \
  _BRAVE_SPECIFIC="$BRAVE_FLAGS_JSON" python3 << 'PYEOF'
import json, sys, os

path      = os.environ.get("_LS_PATH", "")
browser   = os.environ.get("_BROWSER", "brave")
brave_sp  = os.environ.get("_BRAVE_SPECIFIC", "true") == "true"

if not path or not os.path.isfile(path):
    print("  ✗ _LS_PATH gecersiz")
    sys.exit(0)

try:
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
except Exception as e:
    print(f"  ✗ Okunamadi: {e}")
    sys.exit(0)

# ── Ortak enable flags (Brave + Chrome) ────────────────────
enable_flags = [
    # İndirme hızlandırma
    "enable-parallel-downloading@1",

    # GPU & Render performansı
    "enable-gpu-rasterization@1",
    "enable-zero-copy@1",
    "enable-oop-rasterization@1",
    "canvas-oop-rasterization@1",
    "enable-vulkan@1",
    "enable-skia-graphite@1",
    "enable-accelerated-video-decode@1",
    "enable-accelerated-video-encode@1",
    "enable-hardware-overlays@single-fullscreen,single-on-top,underlay",
    "overlay-strategies@occluded-and-non-occluded",

    # Ağ & Protokol
    "enable-quic@1",
    "enable-http2-alternative-service@1",

    # Genel
    "smooth-scrolling@1",
    "ignore-gpu-blocklist@1",
    "ThrottleDisplayNoneAndVisibilityHiddenCrossOriginIframes@1",
]

# ── Ortak disable flags ─────────────────────────────────────
disable_flags = [
    "enable-prerender2@2",
    "back-forward-cache@2",
    "sharing-hub-desktop-app-menu@2",
    "commerce-price-tracking@2",
    "tab-groups-save@2",
    "webrtc-hide-local-ips-with-mdns@2",
]

# ── Brave'e özel ────────────────────────────────────────────
brave_enable = [
    "brave-debounce@1",
    "brave-forget-first-party-storage@1",
]
brave_disable = [
    "brave-news-peek@2",
    "read-later@2",
    "side-panel-journey@2",
    "ntp-realbox@2",
]

# ── Chrome'a özel ───────────────────────────────────────────
chrome_disable = [
    "optimization-guide-on-device-model@2",
    "chrome-ai@2",
    "compose-nudge@2",
    "compose-proactive-nudge@2",
    "glic-rollout@2",
    "chrome-labs@2",
    "ntp-comprehensive-theming@2",
    "side-panel-journey@2",
    "ntp-realbox@2",
    "password-manager-redesign@2",
]

if brave_sp:
    enable_flags += brave_enable
    disable_flags += brave_disable
else:
    disable_flags += chrome_disable

all_flags = enable_flags + disable_flags

data.setdefault("browser", {})
existing  = data["browser"].get("enabled_labs_experiments", [])
new_names = {f.split("@")[0] for f in all_flags}
filtered  = [f for f in existing if f.split("@")[0] not in new_names]
data["browser"]["enabled_labs_experiments"] = filtered + all_flags

try:
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'), ensure_ascii=False)
    print(f"  ✓ {len(all_flags)} flag uygulandi "
          f"({len(enable_flags)} enabled / {len(disable_flags)} disabled)")
except Exception as e:
    print(f"  ✗ Yazma hatasi: {e}")
PYEOF

else
  wSkip "[DRY-RUN] $(t 'Flags atlandi.' 'Flags skipped.')"
fi

# ═══════════════════════════════════════════════════════════════
# ADIM 5: PREFERENCES
# ═══════════════════════════════════════════════════════════════
wStep "$(t 'Preferences duzenleniyor...' 'Editing Preferences...')"

if [[ ! -f "$PREFS" ]]; then
  wSkip "$(t 'Preferences yok. Tarayiciyi acip kapatin.' \
            'Preferences missing. Open and close the browser first.')"
elif [[ "$DRY_RUN" == false ]]; then

  BRAVE_PREFS='true'
  [[ "$BROWSER" == "chrome" ]] && BRAVE_PREFS='false'

  _BROWSER="$BROWSER" _LS_PATH="$PREFS" \
  _BRAVE_SPECIFIC="$BRAVE_PREFS" python3 << 'PYEOF'
import json, sys, os

path    = os.environ.get("_LS_PATH", "")
browser = os.environ.get("_BROWSER", "brave")
brave_sp = os.environ.get("_BRAVE_SPECIFIC", "true") == "true"

if not path or not os.path.isfile(path):
    sys.exit(0)

try:
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
except Exception as e:
    print(f"  ✗ Okunamadi: {e}")
    sys.exit(0)

def set_nested(obj, dotpath, val):
    keys = dotpath.split(".")
    for k in keys[:-1]:
        if k not in obj or not isinstance(obj[k], dict):
            obj[k] = {}
        obj = obj[k]
    obj[keys[-1]] = val

# ── Ortak tweaks (Brave + Chrome) ───────────────────────────
common_tweaks = {
    "browser.show_home_button"                  : False,
    "bookmark_bar.show_on_all_tabs"             : False,
    "background_mode.enabled"                   : False,
    "search.suggest_enabled"                    : False,
    "translate.enabled"                         : False,
    "safebrowsing.extended_reporting_enabled"   : False,
    "safebrowsing.enhanced"                     : False,
    "credentials_enable_service"                : False,
    "credentials_enable_autosignin"             : False,
}

# ── Brave'e özel ────────────────────────────────────────────
brave_tweaks = {
    "brave.new_tab_page.show_rewards"           : False,
    "brave.new_tab_page.show_brave_news"        : False,
    "brave.new_tab_page.show_together"          : False,
    "brave.new_tab_page.show_clock"             : False,
    "brave.new_tab_page.show_stats"             : False,
    "brave.new_tab_page.show_background_image"  : False,
    "brave.new_tab_page.show_top_sites"         : False,
    "brave.rewards.enabled"                     : False,
    "brave.rewards.show_button"                 : False,
    "brave.wallet.show_wallet_icon_on_toolbar"  : False,
    "brave.sidebar.sidebar_show_option"         : 3,
}

# ── Chrome'a özel ───────────────────────────────────────────
chrome_tweaks = {
    "ntp.show_shortcut_type"                    : 2,
    "signin.allowed"                            : False,
    "sync.requested"                            : False,
}

all_tweaks = {**common_tweaks}
if brave_sp:
    all_tweaks.update(brave_tweaks)
else:
    all_tweaks.update(chrome_tweaks)

ok = 0; fail = 0
for k, v in all_tweaks.items():
    try:
        set_nested(data, k, v)
        print(f"  ✓ [{k}] = {v}")
        ok += 1
    except Exception as e:
        print(f"  ✗ [{k}]: {e}")
        fail += 1

try:
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'), ensure_ascii=False)
    print(f"  ✓ Kaydedildi ({ok} basarili / {fail} hata)")
except Exception as e:
    print(f"  ✗ Yazma hatasi: {e}")
PYEOF

else
  wSkip "[DRY-RUN] $(t 'Preferences atlandi.' 'Preferences skipped.')"
fi

# ═══════════════════════════════════════════════════════════════
# ADIM 6: DOSYA İZİNLERİ
# ═══════════════════════════════════════════════════════════════
wStep "$(t 'Dosya izinleri duzeltiliyor...' 'Fixing file permissions...')"
if [[ "$DRY_RUN" == false ]]; then
  for f in "$LOCAL_STATE" "$PREFS"; do
    [[ -f "$f" ]] && chown "$REAL_USER:$REAL_USER" "$f" 2>/dev/null || true
  done
  wOk "$(t 'Sahiplik geri verildi' 'Ownership restored'): $REAL_USER"
else
  wSkip "[DRY-RUN]"
fi

# ═══════════════════════════════════════════════════════════════
# ADIM 7: GÜNCELLEME BİLGİSİ
# ═══════════════════════════════════════════════════════════════
wStep "$(t 'Guncelleme bilgisi' 'Update info')"

if [[ "$BROWSER" == "brave" ]]; then
  case "$INSTALL_TYPE" in
    native)  wInfo "$(t "Guncelleme: sudo $PKG_MGR upgrade brave-browser" \
                       "Update: sudo $PKG_MGR upgrade brave-browser")" ;;
    flatpak) wInfo "$(t 'Guncelleme: flatpak update com.brave.Browser' \
                       'Update: flatpak update com.brave.Browser')" ;;
    snap)    wInfo "$(t 'Guncelleme: sudo snap refresh brave' \
                       'Update: sudo snap refresh brave')" ;;
    *)       wInfo "$(t 'Manuel guncelleme.' 'Manual update required.')" ;;
  esac
else
  case "$INSTALL_TYPE" in
    native)  wInfo "$(t "Guncelleme: sudo $PKG_MGR upgrade google-chrome-stable" \
                       "Update: sudo $PKG_MGR upgrade google-chrome-stable")" ;;
    flatpak) wInfo "$(t 'Guncelleme: flatpak update com.google.Chrome' \
                       'Update: flatpak update com.google.Chrome')" ;;
    *)       wInfo "$(t 'Manuel guncelleme.' 'Manual update required.')" ;;
  esac
fi

# ═══════════════════════════════════════════════════════════════
# ADIM 8: CACHE TEMİZLİĞİ
# ═══════════════════════════════════════════════════════════════
wStep "$(t 'Cache temizleniyor...' 'Cleaning cache...')"

CACHE_NAMES=(
  "Cache"
  "Code Cache"
  "GPUCache"
  "ShaderCache"
  "GrShaderCache"
  "GraphiteDawnCache"
  "NetworkDataMigrated"
  "FP Cache"
  "FP Code Cache"
  "FP GPUCache"
)
CACHE_PATHS=(
  "$DEF_PROFILE/Cache"
  "$DEF_PROFILE/Code Cache"
  "$DEF_PROFILE/GPUCache"
  "$USER_DATA/ShaderCache"
  "$USER_DATA/GrShaderCache"
  "$USER_DATA/GraphiteDawnCache"
  "$DEF_PROFILE/Network/NetworkDataMigrated"
  "$FP_CACHE/Default/Cache"
  "$FP_CACHE/Default/Code Cache"
  "$FP_CACHE/Default/GPUCache"
)

TOTAL_BYTES=0; CLEANED=0
for i in "${!CACHE_NAMES[@]}"; do
  NAME="${CACHE_NAMES[$i]}"; DIR="${CACHE_PATHS[$i]}"
  if [[ -d "$DIR" ]]; then
    SZ=$(du -sb "$DIR" 2>/dev/null | awk '{print $1}' || echo 0)
    MB=$(python3 -c "print(f'{$SZ/1048576:.1f}')" 2>/dev/null || echo "?")
    if [[ "$DRY_RUN" == false ]]; then
      rm -rf "$DIR"
      wOk "$(t 'Temizlendi' 'Cleaned'): $NAME (~${MB} MB)"
    else
      wInfo "[DRY-RUN] $(t 'Temizlenebilir' 'Would clean'): $NAME (~${MB} MB)"
    fi
    TOTAL_BYTES=$((TOTAL_BYTES + SZ)); ((CLEANED++))
  else
    wSkip "$(t 'Yok' 'Not found'): $NAME"
  fi
done

TOTAL_MB=$(python3 -c "print(f'{$TOTAL_BYTES/1048576:.1f}')" 2>/dev/null || echo "?")
[[ "$DRY_RUN" == false ]] \
  && wOk "$(t 'Toplam temizlendi' 'Total cleaned'): ~${TOTAL_MB} MB ($CLEANED $(t 'dizin' 'dirs'))" \
  || wInfo "$(t 'Temizlenebilir' 'Would clean'): ~${TOTAL_MB} MB"

# ═══════════════════════════════════════════════════════════════
# ADIM 9: RAPOR
# ═══════════════════════════════════════════════════════════════
wStep "$(t 'Rapor olusturuluyor...' 'Generating report...')"

_write_report() {
  local S="================================================================"
  local s="----------------------------------------------------------------"
  {
    echo "$S"
    echo "  BROWSER DEBLOAT RAPORU / REPORT  v$SCRIPT_VERSION"
    echo "  $(t 'Tarih'     'Date')       : $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  $(t 'Kullanici' 'User')       : $REAL_USER"
    echo "  $(t 'Sistem'    'System')     : $(uname -sr)"
    echo "  Distro       : $DISTRO"
    echo "  $(t 'Tarayici'  'Browser')    : $BROWSER_LABEL"
    echo "  $(t 'Kurulum'   'Install')    : $INSTALL_TYPE ($PKG_MGR)"
    echo "  $(t 'Surum'     'Version')    : $BROWSER_VER"
    echo "  User Data    : $USER_DATA"
    echo "  Policy       : $POLICY_DIR/debloat.json"
    echo "  $(t 'Masaustu'  'Desktop')    : $DESKTOP"
    [[ "$DRY_RUN" == true ]] && echo "  MODE         : DRY-RUN"
    echo "$S"
    echo ""
    echo "$(t 'YAPILAN ISLEMLER:' 'PERFORMED ACTIONS:')"
    echo "$s"
    for e in "${LOG[@]}"; do echo "$e"; done
    echo ""
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
      echo "$(t 'HATALAR' 'ERRORS') (${#ERRORS[@]}):"
      echo "$s"
      for e in "${ERRORS[@]}"; do echo "  [!] $e"; done
      echo ""
    fi
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
      echo "$(t 'UYARILAR' 'WARNINGS') (${#WARNINGS[@]}):"
      echo "$s"
      for w in "${WARNINGS[@]}"; do echo "  [?] $w"; done
      echo ""
    fi
    echo "$s"
    echo "$(t 'SONRAKI ADIMLAR:' 'NEXT STEPS:')"
    echo "$s"
    echo ""
    if [[ "$BROWSER" == "brave" ]]; then
      echo "  1. brave://policy -> Reload policies"
      echo "  2. brave://flags  -> Parallel Downloading: Enabled"
      echo "  3. brave://gpu    -> Hardware accelerated"
      echo "  4. brave://settings/brave-news -> Disabled"
      echo "  5. brave://settings/wallet -> Disabled"
    else
      echo "  1. chrome://policy -> Reload policies"
      echo "  2. chrome://flags  -> Parallel Downloading: Enabled"
      echo "  3. chrome://gpu    -> Hardware accelerated"
      echo "  4. chrome://settings/ai -> Gemini kapalı / disabled"
      echo "  5. chrome://settings/system -> Donanım hızlandırma açık"
    fi
    echo ""
    echo "$(t 'GERI ALMA / REVERT:'  'REVERT:')"
    echo "$s"
    echo "  cp '$BACKUP_DIR/Local State' '$LOCAL_STATE'"
    echo "  cp '$BACKUP_DIR/Preferences' '$PREFS'"
    [[ "$_policy_works" == "true" ]] && \
      echo "  sudo rm '$POLICY_DIR/debloat.json'"
    echo ""
    echo "$(t "NOT: 'Managed by your organization' -> NORMALDIR." \
              "NOTE: 'Managed by your organization' -> NORMAL.")"
    echo "$S"
  } > "$REPORT_PATH"
  chown "$REAL_USER:$REAL_USER" "$REPORT_PATH"
}

if [[ "$DRY_RUN" == false ]]; then
  _write_report && wOk "$(t 'Rapor' 'Report'): $REPORT_PATH" \
               || wFail "$(t 'Rapor olusturulamadi.' 'Report failed.')"
else
  wSkip "[DRY-RUN]"
fi

# ═══════════════════════════════════════════════════════════════
# TAMAMLANDI
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${CY}${BD}================================================================${RS}"
if [[ ${#ERRORS[@]} -eq 0 ]]; then
  echo -e "${GR}${BD}  $(t 'TAMAMLANDI' 'COMPLETED')  ✓${RS}"
else
  echo -e "${YL}${BD}  $(t 'TAMAMLANDI' 'COMPLETED')  ⚠ ${#ERRORS[@]} $(t 'hata' 'error(s)') / ${#WARNINGS[@]} $(t 'uyari' 'warning(s)')${RS}"
fi
echo -e "${CY}${BD}================================================================${RS}"
echo -e "  ${BD}$(t 'Tarayici' 'Browser')${RS} : $BROWSER_LABEL"
echo -e "  ${BD}$(t 'Kurulum'  'Install')${RS} : $INSTALL_TYPE  ($PKG_MGR)"
echo -e "  ${BD}$(t 'Surum'    'Version')${RS} : $BROWSER_VER"
echo -e "  ${BD}Policy${RS}   : $POLICY_DIR/debloat.json"
[[ "$DRY_RUN" == false ]] && {
  echo -e "  ${BD}$(t 'Backup'  'Backup')${RS}  : $BACKUP_DIR"
  echo -e "  ${BD}$(t 'Rapor'   'Report')${RS}  : $REPORT_PATH"
}
echo -e "${CY}${BD}================================================================${RS}"
echo ""

if [[ "$BROWSER" == "brave" ]]; then
  echo -e "${YL}[!] brave://policy -> Reload policies${RS}"
  echo -e "${YL}[!] brave://flags  -> Parallel Downloading: Enabled?${RS}"
  echo -e "${YL}[!] brave://gpu    -> Hardware accelerated?${RS}"
else
  echo -e "${YL}[!] chrome://policy -> Reload policies${RS}"
  echo -e "${YL}[!] chrome://flags  -> Parallel Downloading: Enabled?${RS}"
  echo -e "${YL}[!] chrome://gpu    -> Hardware accelerated?${RS}"
  echo -e "${YL}[!] chrome://settings/ai -> Gemini disabled?${RS}"
fi

echo -e "${YL}[!] '$(t 'Managed by your organization' 'Managed by your organization')' -> $(t 'NORMALDIR.' 'NORMAL.')${RS}"
[[ "$DRY_RUN" == true ]] && \
  echo -e "${YL}[!] DRY-RUN — $(t 'degisiklik yapilmadi.' 'no changes were made.')${RS}"
echo ""
