<div align="center">

```
    ██████  ███████ ██████  ██       ██████   █████  ████████ 
    ██   ██ ██      ██   ██ ██      ██    ██ ██   ██    ██    
    ██   ██ █████   ██████  ██      ██    ██ ███████    ██    
    ██   ██ ██      ██   ██ ██      ██    ██ ██   ██    ██    
██████  ███████ ██████  ███████  ██████  ██   ██    ██
```

# DebloatYourBrowser

**A universal script to debloat, harden, and optimize Brave Browser and Google Chrome.**  
Supports Linux and Windows. Bilingual (Turkish / English).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Windows-blue)](#)
[![Shell](https://img.shields.io/badge/linux-bash-brightgreen)](#)
[![PowerShell](https://img.shields.io/badge/windows-powershell-blue)](#)
[![Browsers](https://img.shields.io/badge/browsers-Brave%20%7C%20Chrome-orange)](#)

[⬇️ Download](#%EF%B8%8F-download) · [🚀 Usage](#-usage) · [📋 What It Does](#-what-it-does) · [💾 Backup & Restore](#-backup--restore) · [🛠️ Troubleshooting](#%EF%B8%8F-troubleshooting)

</div>

---

> **⚠️ DISCLAIMER**
>
> This script modifies browser configuration files, policy files, registry entries, and cached data on your system. **All consequences of running this script — including data loss, unexpected browser behavior, or system changes — are solely the responsibility of the user.** The author provides this script as-is, with **no warranty of any kind**, express or implied. Always read and understand any script before running it with elevated privileges. A backup is created automatically before changes are made, but you are ultimately responsible for your own data.

---

## ⬇️ Download

Download the latest release directly — no `git clone` required:

| Platform | File | Command |
|---|---|---|
| 🐧 Linux | `debloat.sh` | `wget https://github.com/hamzagulesci/DebloatYourBrowser/releases/latest/download/debloat.sh` |
| 🪟 Windows | `debloat.ps1` | See below |

**Windows (PowerShell):**
```powershell
Invoke-WebRequest `
  -Uri "https://github.com/hamzagulesci/DebloatYourBrowser/releases/latest/download/debloat.ps1" `
  -OutFile "debloat.ps1"
```

Or go to the [Releases page](https://github.com/hamzagulesci/DebloatYourBrowser/releases) and download manually.

---

## ✨ Features

| | Feature | Details |
|---|---|---|
| 🌐 | **Bilingual** | Turkish & English — selected at startup |
| 🦁 | **Brave + Chrome** | Browser selected at startup |
| 🔍 | **Auto-detection** | Finds the correct installation type automatically |
| 🐧 | **Universal Linux** | apt · dnf · pacman · zypper · flatpak · snap |
| 🪟 | **Universal Windows** | Standard · per-user · Scoop · Winget · Chocolatey |
| 📋 | **Group Policy** | Linux: JSON file · Windows: Registry — survives browser UI changes |
| 🚀 | **Performance flags** | GPU rasterization, Vulkan, parallel downloads, HTTP/3 QUIC |
| 🔒 | **Privacy hardening** | Telemetry, AI features, P3A, wallet, rewards, sync — all disabled |
| 🧹 | **Cache cleanup** | GPUCache, ShaderCache, GrShaderCache, GraphiteDawnCache and more |
| 💾 | **Auto backup** | Files backed up to Desktop before any change |
| 📄 | **Report file** | Full timestamped log saved to Desktop after every run |
| 🧪 | **Dry-run mode** | Preview every action without touching anything |
| 🖥️ | **Locale-aware Desktop** | Linux: `xdg-user-dir` · Windows: `GetFolderPath('Desktop')` — both handle OneDrive and non-English desktops correctly |

---

## 🖥️ Supported Platforms

### 🐧 Linux

| Distro Family | Package Manager | Examples |
|---|---|---|
| Debian / Ubuntu | `apt` | Ubuntu, Zorin OS, Linux Mint, Pop!\_OS, Kali |
| Fedora / RHEL | `dnf` | Fedora, RHEL, Rocky Linux, AlmaLinux |
| openSUSE | `zypper` | openSUSE Leap, Tumbleweed |
| Arch | `pacman` | Arch Linux, Manjaro, EndeavourOS, Garuda |
| Any | `flatpak` | All distros with Flatpak support |
| Any | `snap` | Ubuntu and derivatives |

### 🪟 Windows

| Install type | Notes |
|---|---|
| Standard installer | Default install via Brave / Chrome installer |
| Per-user installer | Installed to `%LOCALAPPDATA%` |
| Scoop | `scoop install brave` / `scoop install googlechrome` |
| Winget / Chocolatey | Installs to standard Program Files path |

---

## 🚀 Usage

### 🐧 Linux

```bash
# Download
wget https://github.com/hamzagulesci/DebloatYourBrowser/releases/latest/download/debloat.sh

# Make executable
chmod +x debloat.sh

# Run (root required for policy file creation)
sudo ./debloat.sh

# Preview without making changes
sudo ./debloat.sh --dry-run
```

### 🪟 Windows

Open **PowerShell as Administrator**, then:

```powershell
# Allow script execution for this session only
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Run
.\debloat.ps1

# Preview without making changes
.\debloat.ps1 -DryRun
```

---

On startup, both scripts ask two questions:

```
Select language:
  [1] Turkce
  [2] English

Select browser:
  [1] Brave Browser
  [2] Google Chrome
```

Everything else is fully automatic.

---

## 📋 What It Does

Both scripts run the same logical steps. Implementation differs by platform.

### Step 0 — Detect installation
Probes known binary and install locations in order. Resolves the correct User Data path and policy directory for the detected install type.

### Step 1 — Close the browser

> **Why exact process name matching?**
> Linux uses `pkill -x` and Windows uses `Stop-Process -Name` — both without wildcards or full command-line scanning. This is intentional: scanning the full command line (`pkill -f` on Linux) would also match the script's own filename if it contains the browser name, killing the script itself mid-run.

### Step 2 — Backup

Backs up `Local State` and `Preferences` to a timestamped folder on your Desktop **before any modification**.

On Windows, the registry policy key is also exported as a `.reg` file — double-click to restore.

### Step 3 — Policies

The most powerful step. Policy-level settings are enforced by the browser engine and **cannot be overridden through the browser UI**.

| Platform | Method | Path |
|---|---|---|
| Linux (Brave) | JSON file | `/etc/brave/policies/managed/debloat.json` |
| Linux (Chrome) | JSON file | `/etc/opt/chrome/policies/managed/debloat.json` |
| Windows (Brave) | Registry | `HKLM\SOFTWARE\Policies\BraveSoftware\Brave` |
| Windows (Chrome) | Registry | `HKLM\SOFTWARE\Policies\Google\Chrome` |

> **Flatpak note (Linux):** The Flatpak sandbox prevents browsers from reading `/etc/` policy directories. Policy is automatically skipped for Flatpak installs. Flags and Preferences are still applied.

<details>
<summary><strong>Brave — policies applied</strong></summary>

| Policy | Effect |
|---|---|
| `BraveRewardsDisabled` | Disables BAT Rewards entirely |
| `BraveWalletDisabled` | Removes crypto wallet |
| `BraveVPNDisabled` | Removes VPN upsell |
| `BraveTalkDisabled` | Disables Brave Talk |
| `BraveAIChatEnabled: false` | Disables Leo AI |
| `BraveWebDiscoveryEnabled: false` | Stops web discovery ping |
| `BraveStatsPingEnabled: false` | Stops anonymous stats ping |
| `BraveP3AEnabled: false` | Disables P3A product analytics |
| `BravePlaylistEnabled: false` | Disables Playlist feature |
| `BraveReduceLanguageEnabled: true` | Reduces language fingerprinting |
| `MetricsReportingEnabled: false` | Disables crash/usage reporting |
| `BackgroundModeEnabled: false` | Prevents running in background |
| `SearchSuggestEnabled: false` | Disables search suggestions |
| `DnsPrefetchingEnabled: false` | Disables DNS prefetch |
| `PasswordManagerEnabled: false` | Disables built-in password manager |
| `AutofillAddressEnabled: false` | Disables address autofill |
| `AutofillCreditCardEnabled: false` | Disables payment autofill |
| `DefaultNotificationsSetting: 2` | Blocks notification permission requests |
| `DefaultGeolocationSetting: 2` | Blocks geolocation permission requests |
| `DefaultWebBluetoothGuardSetting: 2` | Blocks Web Bluetooth |
| `DefaultWebUsbGuardSetting: 2` | Blocks WebUSB |
| `DefaultWebHidGuardSetting: 2` | Blocks WebHID |
| `WebRtcIPHandling` | Limits WebRTC IP exposure |
| `EnableMediaRouter: false` | Disables Cast / Chromecast |
| `DnsOverHttpsMode: automatic` | Enables DNS-over-HTTPS |
| `PrivacySandbox*: false` | Disables all Privacy Sandbox APIs |

</details>

<details>
<summary><strong>Chrome — policies applied</strong></summary>

| Policy | Effect |
|---|---|
| `GeminiSettings: 1` | Disables Gemini AI sidebar |
| `AIModeSettings: 1` | Disables AI Mode |
| `GenAILocalFoundationalModelSettings: 1` | Blocks on-device AI model downloads |
| `DevToolsGenAiSettings: 1` | Disables AI in DevTools |
| `CreateThemesSettings: 1` | Disables AI theme creation |
| `TabOrganizerSettings: 1` | Disables AI tab organizer |
| `HelpMeWriteSettings: 1` | Disables "Help me write" |
| `SyncDisabled: true` | Disables Chrome Sync |
| `BrowserSignin: 0` | Prevents Google account sign-in prompts |
| `ChromeVariationsSettings: 2` | Disables A/B experiment variations |
| `MetricsReportingEnabled: false` | Disables crash/usage reporting |
| `BackgroundModeEnabled: false` | Prevents running in background |
| `ShowCastIconInToolbar: false` | Removes Cast icon |
| `EnableMediaRouter: false` | Disables Cast / Chromecast |
| `PrivacySandbox*: false` | Disables all Privacy Sandbox APIs |
| *(+ all shared policies)* | Password, autofill, geolocation, WebRTC, DoH, etc. |

</details>

### Step 4 — Performance & privacy flags (`chrome://flags`)

Written directly to `Local State` using Python (Linux) or `[IO.File]::WriteAllText` (Windows) — both use **BOM-free UTF-8**.

> **Why BOM-free matters:** PowerShell 5.1's `Set-Content -Encoding UTF8` and some Linux tools prepend a BOM (byte-order mark). Chrome and Brave treat a BOM-prefixed `Local State` as malformed and silently reset it on the next launch — erasing all flag changes. Both scripts explicitly prevent this.

<details>
<summary><strong>Performance flags enabled</strong></summary>

| Flag | Effect |
|---|---|
| `enable-parallel-downloading` | Multi-connection downloads — biggest download speed boost |
| `enable-gpu-rasterization` | GPU-accelerated page rendering |
| `enable-zero-copy` | Zero-copy GPU memory transfers |
| `enable-oop-rasterization` | Out-of-process rasterization |
| `canvas-oop-rasterization` | Canvas OOP rasterization |
| `enable-vulkan` | Vulkan GPU backend |
| `enable-skia-graphite` | Next-gen Skia GPU engine |
| `enable-accelerated-video-decode` | Hardware video decode |
| `enable-accelerated-video-encode` | Hardware video encode |
| `enable-hardware-overlays` | Hardware overlay compositing |
| `enable-quic` | HTTP/3 QUIC protocol |
| `enable-http2-alternative-service` | HTTP/2 connection optimization |
| `smooth-scrolling` | 60fps smooth scrolling |
| `ignore-gpu-blocklist` | Force GPU acceleration even if GPU is blocklisted |
| `brave-debounce` | *(Brave only)* URL debounce — strips tracking redirects |
| `brave-forget-first-party-storage` | *(Brave only)* First-party storage clearing |

</details>

<details>
<summary><strong>Bloat flags disabled</strong></summary>

| Flag | Effect |
|---|---|
| `enable-prerender2` | Aggressive background prerender (high RAM usage) |
| `back-forward-cache` | Back/forward cache (high RAM usage) |
| `commerce-price-tracking` | Shopping price tracker UI |
| `sharing-hub-desktop-app-menu` | Share hub in app menu |
| `tab-groups-save` | Cloud sync for tab groups |
| `webrtc-hide-local-ips-with-mdns` | mDNS IP obfuscation |
| *(Chrome only)* `chrome-ai`, `glic-rollout`, `compose-nudge`, `compose-proactive-nudge`, `chrome-labs`, `password-manager-redesign` | All Gemini / AI UI elements |
| *(Brave only)* `brave-news-peek`, `read-later`, `ntp-realbox` | Brave-specific bloat UI |

</details>

### Step 5 — Preferences
Edits `Default/Preferences` directly. Targets NTP widgets, sidebar visibility, wallet/rewards toolbar buttons, and shared browser settings.

### Step 6 — Updater services *(Windows only)*
Sets browser updater services (`BraveUpdate`, `gupdate`, `gupdatem`) to **Manual** startup — not Disabled, which would also block security updates. Disables scheduled update tasks.

### Step 7 — Cache cleanup
Removes stale GPU and shader caches. Typical space recovered: **100 MB – 800 MB**.

### Step 8 — Report
Saves a full timestamped log to your Desktop.

---

## 💾 Backup & Restore

### Where is the backup?

Saved to your Desktop in a timestamped folder before any changes:

```
Linux:   ~/Desktop/BrowserDebloat_Backup_20260228_214318/
         ~/Masaüstü/BrowserDebloat_Backup_20260228_214318/   ← Turkish locale

Windows: C:\Users\YourName\Desktop\BraveDebloat_Backup_20260228_214318\
         C:\Users\YourName\OneDrive\Masaüstü\...             ← OneDrive/Turkish
```

Both scripts detect the real Desktop path regardless of system language or OneDrive redirection.

**Contents:**

| File | What it stores |
|---|---|
| `Local State` | `chrome://flags` and browser state |
| `Preferences` | All browser preferences |
| `registry_backup.reg` | *(Windows only)* Full policy registry key |

---

### User Data locations

| Browser | Platform | Install type | User Data path |
|---|---|---|---|
| Brave | Linux | native | `~/.config/BraveSoftware/Brave-Browser/` |
| Brave | Linux | flatpak | `~/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser/` |
| Brave | Linux | snap | `~/snap/brave/current/.config/BraveSoftware/Brave-Browser/` |
| Brave | Windows | any | `%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\` |
| Chrome | Linux | native | `~/.config/google-chrome/` |
| Chrome | Linux | flatpak | `~/.var/app/com.google.Chrome/config/google-chrome/` |
| Chrome | Windows | any | `%LOCALAPPDATA%\Google\Chrome\User Data\` |

---

### Full restore procedure

**1. Close the browser completely.**

```bash
# Linux — verify no process is running
pgrep -x brave-browser
pgrep -x google-chrome
```

```powershell
# Windows
Get-Process brave -ErrorAction SilentlyContinue
Get-Process chrome -ErrorAction SilentlyContinue
```

**2. Restore `Local State`** — lives directly in User Data (not inside Default/):

```bash
# Linux — Brave native example
cp ~/Desktop/BrowserDebloat_Backup_20260228_214318/"Local State" \
   ~/.config/BraveSoftware/Brave-Browser/"Local State"
```

```powershell
# Windows — Brave example
Copy-Item "$env:USERPROFILE\Desktop\BraveDebloat_Backup_20260228_214318\Local State" `
          "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Local State" -Force
```

**3. Restore `Preferences`** — lives inside the `Default/` subfolder:

```bash
# Linux — Brave native example
cp ~/Desktop/BrowserDebloat_Backup_20260228_214318/Preferences \
   ~/.config/BraveSoftware/Brave-Browser/Default/Preferences
```

```powershell
# Windows — Brave example
Copy-Item "$env:USERPROFILE\Desktop\BraveDebloat_Backup_20260228_214318\Preferences" `
          "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Preferences" -Force
```

**4. Remove / restore policies:**

```bash
# Linux — remove policy file
sudo rm /etc/brave/policies/managed/debloat.json       # Brave
sudo rm /etc/opt/chrome/policies/managed/debloat.json  # Chrome
```

```powershell
# Windows — restore from .reg backup (double-click or run in terminal)
reg import "$env:USERPROFILE\Desktop\BraveDebloat_Backup_20260228_214318\registry_backup.reg"

# Or just delete the policy key entirely
Remove-Item -Path "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave" -Recurse -Force  # Brave
Remove-Item -Path "HKLM:\SOFTWARE\Policies\Google\Chrome"       -Recurse -Force  # Chrome
```

**5. Open the browser.** All settings will be restored to pre-script state.

---

## 🛠️ Troubleshooting

### "Your browser is managed by your organization"

**This is expected and normal.** It confirms the policy is active. The browser works identically; only the configured policies are enforced. To remove the message, delete the policy file or registry key (see step 4 above).

---

### YouTube or videos show a white / black screen

The script enables aggressive GPU acceleration flags. On certain hardware — older GPUs, NVIDIA Optimus (hybrid graphics), or some Intel configurations — this can cause video rendering issues.

**Fix — disable hardware acceleration:**

**Brave:** `brave://settings/system`  
→ **"Use hardware acceleration when available"** → toggle **OFF** → **Relaunch**

**Chrome:** `chrome://settings/system`  
→ **"Use graphics acceleration when available"** → toggle **OFF** → **Relaunch**

> If this fixes the issue, the culprit is likely one of these flags: `ignore-gpu-blocklist`, `enable-vulkan`, or `enable-skia-graphite`. You can selectively disable them at `brave://flags` or `chrome://flags` while keeping the rest active.

---

### Policy not showing in `brave://policy` or `chrome://policy`

1. Click **"Reload policies"** on the policy page
2. **Linux** — verify the file exists and has correct permissions:
   ```bash
   cat /etc/brave/policies/managed/debloat.json
   ls -la /etc/brave/policies/managed/
   # Expected: -rw-r--r-- 1 root root ... debloat.json
   ```
3. **Windows** — verify the registry key exists:
   ```powershell
   Get-Item "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave"
   ```
4. **Flatpak (Linux):** Policy does not work in the Flatpak sandbox — this is expected. Flags and Preferences are still applied.
5. **Snap (Linux):** May need: `sudo snap connect brave:system-files`

---

### Flags not applied after running the script

The browser was likely still running when the script wrote to `Local State`, and overwrote the changes on exit.

1. Fully close the browser first
2. **Linux** — check for lock files:
   ```bash
   ls ~/.config/BraveSoftware/Brave-Browser/ | grep Singleton
   # Must be empty if the browser is truly closed
   ```
3. Re-run the script

---

## 📁 Repository Structure

```
DebloatYourBrowser/
├── linux/
│   └── debloat.sh          bash — apt, dnf, pacman, flatpak, snap
├── windows/
│   └── debloat.ps1         PowerShell — all Windows install types
├── README.md
└── LICENSE
```

---

## 🔑 Requirements

### 🐧 Linux
| Requirement | Notes |
|---|---|
| `bash` 4.0+ | Pre-installed on all modern Linux distros |
| `python3` 3.6+ | For JSON editing — pre-installed on virtually all distros |
| `sudo` / root | Required for writing policy files to `/etc/` |
| `xdg-user-dirs` | For locale-aware Desktop path — pre-installed on most desktop distros |

### 🪟 Windows
| Requirement | Notes |
|---|---|
| PowerShell 5.1+ | Pre-installed on Windows 10/11 |
| Administrator rights | Required for writing registry policies |

---

## ⚠️ Known Limitations

| Limitation | Details |
|---|---|
| **Flatpak policy (Linux)** | `/etc/` is outside the Flatpak sandbox. Policy is skipped; flags and preferences still apply. |
| **Chrome telemetry** | Some Chrome telemetry channels cannot be fully disabled by policy — Google design decision. The script applies the maximum available restrictions. |
| **Flag persistence** | Flags may revert after major browser version updates. Re-run the script if needed. |
| **Multiple profiles** | Only the `Default` profile is modified. |
| **Snap policy (Linux)** | May require `sudo snap connect brave:system-files`. |

---

## 🗓️ Changelog

### v1.0
- Initial release
- Linux: Brave + Chrome (apt, dnf, pacman, flatpak, snap, appimage)
- Windows: Brave + Chrome (standard, per-user, Scoop, Winget, Chocolatey)
- Bilingual (Turkish / English)
- Group Policy JSON (Linux) + Registry (Windows)
- Performance flags, privacy hardening, cache cleanup
- Auto backup + timestamped report

---

## 📜 License

[MIT License](LICENSE) — free to use, modify, and distribute.

---

## 🔬 Research & Sources

- [Privacy Guides Community — Brave Group Policy (Jan 2026)](https://discuss.privacyguides.net/t/are-there-undocumented-group-policy-options-in-brave-browser/34092)
- [brave/brave-core — policy definitions (GitHub)](https://github.com/brave/brave-core/tree/master/components/policy/resources/templates/policy_definitions/BraveSoftware)
- [Google Chrome Enterprise Policy Reference](https://chromeenterprise.google/policies/)

---

<div align="center">

Made for the community. Use at your own risk.

[github.com/hamzagulesci/DebloatYourBrowser](https://github.com/hamzagulesci/DebloatYourBrowser)

</div>
