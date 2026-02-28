<div align="center">

```
    ██████  ███████ ██████  ██       ██████   █████  ████████ 
    ██   ██ ██      ██   ██ ██      ██    ██ ██   ██    ██    
    ██   ██ █████   ██████  ██      ██    ██ ███████    ██    
    ██   ██ ██      ██   ██ ██      ██    ██ ██   ██    ██    
██████  ███████ ██████  ███████  ██████  ██   ██    ██
```

# DebloatYourBrowser

**A universal Linux shell script to debloat, harden, and optimize Brave Browser and Google Chrome.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Platform](https://img.shields.io/badge/platform-Linux-blue)
![Shell](https://img.shields.io/badge/shell-bash-green)
![Browsers](https://img.shields.io/badge/browsers-Brave%20%7C%20Chrome-orange)

[Usage](#-usage) · [What It Does](#-what-it-does) · [Backup & Restore](#-backup--restore) · [Troubleshooting](#%EF%B8%8F-troubleshooting) · [Requirements](#-requirements)

</div>

---

> **⚠️ DISCLAIMER**
>
> This script modifies browser configuration files, policy files, and cached data on your system. **All consequences of running this script — including data loss, unexpected browser behavior, or system changes — are solely the responsibility of the user.** The author provides this script as-is, with **no warranty of any kind**, express or implied. Always read and understand any script before running it with elevated privileges. A backup is created automatically before changes are made, but you are ultimately responsible for your own data.

---

## ✨ Features

| | Feature | Details |
|---|---|---|
| 🌐 | **Bilingual** | Turkish & English — selected at startup |
| 🦁 | **Brave + Chrome** | Browser selected at startup |
| 🔍 | **Auto-detection** | Finds `native` / `flatpak` / `snap` / `appimage` installs automatically |
| 🐧 | **Universal Linux** | apt · dnf · pacman · zypper · flatpak · snap |
| 📋 | **Group Policy JSON** | Enforced via system policy directory — survives browser UI changes |
| 🚀 | **Performance flags** | GPU rasterization, Vulkan, parallel downloads, HTTP/3 QUIC |
| 🔒 | **Privacy hardening** | Telemetry, AI features, P3A, wallet, rewards, sync — all disabled |
| 🧹 | **Cache cleanup** | GPUCache, ShaderCache, GrShaderCache, GraphiteDawnCache and more |
| 💾 | **Auto backup** | `Local State` and `Preferences` backed up to Desktop before any change |
| 📄 | **Report file** | Full timestamped log saved to Desktop after every run |
| 🧪 | **Dry-run mode** | Preview every action without touching anything |
| 🖥️ | **Locale-aware** | Uses `xdg-user-dir` — finds `~/Masaüstü`, `~/Desktop`, `~/Schreibtisch` etc. automatically |

---

## 🖥️ Supported Distributions

| Distro Family | Package Manager | Examples |
|---|---|---|
| Debian / Ubuntu | `apt` | Ubuntu, Zorin OS, Linux Mint, Pop!\_OS, elementary OS, Kali |
| Fedora / RHEL | `dnf` | Fedora, RHEL, Rocky Linux, AlmaLinux |
| openSUSE | `zypper` | openSUSE Leap, Tumbleweed |
| Arch | `pacman` | Arch Linux, Manjaro, EndeavourOS, Garuda |
| Any (Flatpak) | `flatpak` | All distros with Flatpak support |
| Any (Snap) | `snap` | Ubuntu and derivatives |

---

## 🚀 Usage

```bash
# Clone the repository
git clone https://github.com/hamzagulesci/DebloatYourBrowser.git
cd DebloatYourBrowser

# Make the script executable
chmod +x debloat.sh

# Run with root (required for policy file creation)
sudo ./debloat.sh

# --- Optional: preview all changes without modifying anything ---
sudo ./debloat.sh --dry-run
```

At startup you will see two prompts:

```
Select language:
  [1] Türkçe
  [2] English

Select browser:
  [1] Brave Browser
  [2] Google Chrome
```

Everything else is fully automatic.

---

## 📋 What It Does

The script runs 9 steps in sequence. Every action is logged and written to a report file on your Desktop.

### Step 0 — Detect installation type
Probes for `native` (apt/dnf/pacman/zypper), `flatpak`, `snap`, and `appimage` installs in that order. Resolves the correct User Data path and system Policy directory for the detected install type.

### Step 1 — Close the browser
Terminates all browser processes before modifying any files.

> **Note:** The script uses `pkill -x` (exact process name match) — not `pkill -f`. This is intentional: `-f` scans full command-line arguments and would match the script's own filename, killing itself. `-x` matches the process binary name only and is safe.

### Step 2 — Backup
Copies `Local State` and `Preferences` to a timestamped folder on your Desktop **before any modification**. See [Backup & Restore](#-backup--restore) for full details.

### Step 3 — Group Policy JSON
Writes a JSON policy file to the system-level policy directory. Policies applied via this method are **enforced at the browser engine level** and cannot be toggled off through the browser UI.

| Browser | Policy path |
|---|---|
| Brave | `/etc/brave/policies/managed/debloat.json` |
| Chrome | `/etc/opt/chrome/policies/managed/debloat.json` |

> **Flatpak note:** The Flatpak sandbox does not allow access to `/etc/` from inside the container. Policy is automatically skipped for Flatpak installs. Flags and Preferences are still applied.

<details>
<summary><strong>Brave — policies applied</strong></summary>

| Policy key | Effect |
|---|---|
| `BraveRewardsDisabled: true` | Disables BAT Rewards entirely |
| `BraveWalletDisabled: true` | Removes crypto wallet |
| `BraveVPNDisabled: true` | Removes VPN upsell |
| `BraveTalkDisabled: true` | Disables Brave Talk (video calls) |
| `BraveAIChatEnabled: false` | Disables Leo AI assistant |
| `BraveWebDiscoveryEnabled: false` | Stops web discovery ping |
| `BraveStatsPingEnabled: false` | Stops anonymous stats ping |
| `BraveP3AEnabled: false` | Disables P3A product analytics |
| `BravePlaylistEnabled: false` | Disables Playlist feature |
| `BraveReduceLanguageEnabled: true` | Reduces language fingerprinting |
| `MetricsReportingEnabled: false` | Disables crash/usage reporting |
| `UrlKeyedAnonymizedDataCollectionEnabled: false` | Disables URL-keyed telemetry |
| `BackgroundModeEnabled: false` | Prevents running in background |
| `SearchSuggestEnabled: false` | Disables search suggestions |
| `DnsPrefetchingEnabled: false` | Disables DNS prefetch |
| `TranslateEnabled: false` | Disables translation prompt |
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
| `PrivacySandbox*: false` | Disables all Privacy Sandbox APIs (FLoC/Topics/etc.) |

</details>

<details>
<summary><strong>Chrome — policies applied</strong></summary>

| Policy key | Effect |
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
| `GoogleSearchSidePanelEnabled: false` | Removes Search side panel |
| `MetricsReportingEnabled: false` | Disables crash/usage reporting |
| `BackgroundModeEnabled: false` | Prevents running in background |
| `ShowCastIconInToolbar: false` | Removes Cast icon |
| `EnableMediaRouter: false` | Disables Cast / Chromecast |
| `PrivacySandbox*: false` | Disables all Privacy Sandbox APIs |
| *(+ all shared policies above)* | Password, autofill, geolocation, etc. |

</details>

### Step 4 — Performance & privacy flags (`chrome://flags`)
Writes directly to `Local State` using Python's `json` module with **BOM-free UTF-8** encoding.

> **Why BOM-free matters:** Python's default `open(..., 'w')` and many tools on Linux write UTF-8 correctly, but on some setups a BOM (byte-order mark) can be prepended. Chrome/Brave treats a BOM-prefixed `Local State` as invalid and silently resets it on next launch — causing all flag changes to disappear. The script explicitly prevents this.

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
| `ignore-gpu-blocklist` | Force GPU acceleration even if GPU is on the blocklist |
| `brave-debounce` | *(Brave only)* URL debounce — strips tracking redirects |
| `brave-forget-first-party-storage` | *(Brave)* First-party storage clearing |

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
| `webrtc-hide-local-ips-with-mdns` | mDNS IP obfuscation (already off in Brave) |
| *(Chrome only)* `chrome-ai`, `glic-rollout`, `compose-nudge`, `compose-proactive-nudge`, `chrome-labs`, `ntp-comprehensive-theming`, `password-manager-redesign` | All Gemini / AI UI elements |

</details>

### Step 5 — Preferences
Edits `Default/Preferences` using Python JSON. Targets Brave-specific NTP (New Tab Page) options, sidebar visibility, wallet/rewards toolbar buttons, and shared browser preferences.

### Step 6 — Fix file permissions
Restores `Local State` and `Preferences` ownership back to the real user, since the script runs as root.

### Step 7 — Update info
Prints the correct update command for the detected install type.

### Step 8 — Cache cleanup
Removes stale shader and GPU caches. Typical space recovered: **100 MB – 800 MB**.

### Step 9 — Report
Saves a full timestamped log to your Desktop:
`BrowserDebloat_Rapor_YYYYMMDD_HHMMSS.txt`

---

## 💾 Backup & Restore

### Where is the backup?

Every run automatically backs up two files to your **Desktop** in a timestamped folder, **before any changes are made**:

```
~/Desktop/BrowserDebloat_Backup_20260228_214318/
  ├── Local State     ← stores chrome://flags and browser state
  └── Preferences     ← stores all browser preferences
```

> **Locale note:** On Turkish Linux systems, the Desktop is at `~/Masaüstü/`. On English systems it is `~/Desktop/`. The script detects this automatically using `xdg-user-dir DESKTOP`, so the backup always lands in the correct visible Desktop folder regardless of your system language.

---

### Finding your User Data path

The exact path is printed during the script run and saved in the report. Reference table:

| Browser | Install type | User Data path |
|---|---|---|
| Brave | native (apt/dnf/pacman) | `~/.config/BraveSoftware/Brave-Browser/` |
| Brave | flatpak | `~/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser/` |
| Brave | snap | `~/snap/brave/current/.config/BraveSoftware/Brave-Browser/` |
| Chrome | native | `~/.config/google-chrome/` |
| Chrome | flatpak | `~/.var/app/com.google.Chrome/config/google-chrome/` |

---

### Full restore procedure

**1. Close the browser completely.**
Check that no browser process is running:
```bash
pgrep -x brave-browser   # should return nothing
pgrep -x google-chrome   # should return nothing
```

**2. Restore `Local State` (flags).**
`Local State` lives directly inside User Data (not inside a profile subfolder):
```bash
# Example for Brave (native install) — adjust path to match your report
cp ~/Desktop/BrowserDebloat_Backup_20260228_214318/"Local State" \
   ~/.config/BraveSoftware/Brave-Browser/"Local State"
```

**3. Restore `Preferences`.**
`Preferences` lives inside the `Default` profile folder:
```bash
# Example for Brave (native install)
cp ~/Desktop/BrowserDebloat_Backup_20260228_214318/Preferences \
   ~/.config/BraveSoftware/Brave-Browser/Default/Preferences
```

**4. Remove the policy file.**
The backup only covers `Local State` and `Preferences`. The Group Policy file is written separately and must be deleted manually to fully revert:
```bash
# Brave
sudo rm /etc/brave/policies/managed/debloat.json

# Chrome
sudo rm /etc/opt/chrome/policies/managed/debloat.json
```
Without this step, policy-controlled settings (Rewards, Wallet, Sync, etc.) will remain enforced even after restoring the other files.

**5. Open the browser.** All settings will be restored to their pre-script state.

---

### Full reset (nuclear option)
If restoring the backup files is not sufficient and you want a completely clean browser:
```bash
# ⚠️ WARNING: This deletes ALL history, bookmarks, extensions, cookies, and saved passwords.
# Make sure you have exported anything important before doing this.

rm -rf ~/.config/BraveSoftware/Brave-Browser/   # Brave native
rm -rf ~/.config/google-chrome/                 # Chrome native
```

---

## 🛠️ Troubleshooting

### "Your browser is managed by your organization"

**This is expected and normal.** It confirms the Group Policy file is active. The browser works identically to normal; only the configured policies are enforced. To remove this message, delete the policy file (see Restore step 4 above).

---

### YouTube or videos show a white / black screen

The script enables aggressive GPU acceleration flags for better performance. On certain hardware — especially older GPUs, NVIDIA Optimus (hybrid graphics), or some Intel configurations — hardware acceleration can cause video rendering issues.

**Fix — disable hardware acceleration:**

**Brave:** `brave://settings/system`
→ **"Use hardware acceleration when available"** → toggle **OFF** → click **Relaunch**

**Chrome:** `chrome://settings/system`
→ **"Use graphics acceleration when available"** → toggle **OFF** → click **Relaunch**

> If this fixes the issue, the problem is caused by one or more of these flags: `ignore-gpu-blocklist`, `enable-vulkan`, `enable-skia-graphite`. You can selectively disable them at `brave://flags` or `chrome://flags` while keeping the rest. The GPU blocklist exists for good reason — it prevents known-problematic GPU/driver combinations from causing rendering bugs.

---

### Policy not appearing in `brave://policy` or `chrome://policy`

1. Open the policy page and click **"Reload policies"**
2. Confirm the file exists and is readable:
   ```bash
   cat /etc/brave/policies/managed/debloat.json          # Brave
   cat /etc/opt/chrome/policies/managed/debloat.json     # Chrome
   ```
3. Check permissions — the file must be owned by root and readable:
   ```bash
   ls -la /etc/brave/policies/managed/
   # Expected: -rw-r--r-- 1 root root ... debloat.json
   ```
4. **Flatpak limitation:** Policy files at `/etc/` are inaccessible inside the Flatpak sandbox. This is a fundamental Flatpak security constraint, not a bug in this script. Flags and Preferences are still applied.
5. **Snap limitation:** May require connecting the system-files plug:
   ```bash
   sudo snap connect brave:system-files
   ```

---

### Flags not applied after running the script

If `brave://flags` or `chrome://flags` still shows default values:

1. **Ensure the browser was fully closed** before running the script. A running browser holds `Local State` open and will overwrite it on exit.
2. Check for lock files indicating the browser is still running:
   ```bash
   ls ~/.config/BraveSoftware/Brave-Browser/
   # Must NOT contain: SingletonLock, SingletonSocket
   ```
3. Rerun the script after confirming the browser is closed.

---

### Permission error writing policy file

The script requires `sudo` to write to `/etc/`. Verify:
```bash
sudo ./debloat.sh          # must be run with sudo
id                         # confirm you have sudo access
```

---

## 📁 Repository Structure

```
DebloatYourBrowser/
├── debloat.sh      ← Main script (Brave + Chrome, Turkish/English)
├── README.md       ← This file
└── LICENSE         ← MIT License
```

---

## 🔑 Requirements

| Requirement | Version | Notes |
|---|---|---|
| `bash` | 4.0+ | Pre-installed on all modern Linux distros |
| `python3` | 3.6+ | Used for JSON editing — pre-installed on virtually all distros |
| `sudo` / root | — | Required for writing policy files to `/etc/` |
| `xdg-user-dirs` | any | For locale-aware Desktop path — pre-installed on most desktop distros |

---

## ⚠️ Known Limitations

| Limitation | Details |
|---|---|
| **Flatpak policy** | `/etc/` is outside the Flatpak sandbox. Policy is skipped; flags and preferences still apply. |
| **Chrome telemetry** | Some Chrome telemetry channels cannot be fully disabled by policy — this is a Google design decision. The script applies the maximum available restrictions. |
| **Flag persistence** | Flags may revert after major browser version updates. Re-run the script after major updates if needed. |
| **Multiple profiles** | Only the `Default` profile is modified. Additional profiles are not touched. |
| **Snap policy** | May require `sudo snap connect brave:system-files` to allow policy directory access. |

---

## 📜 License

[MIT License](LICENSE) — free to use, modify, and distribute.

---

## 🔬 Research & Sources

Policy keys were researched and verified against:

- [Privacy Guides Community — Brave Group Policy (Jan 2026)](https://discuss.privacyguides.net/t/are-there-undocumented-group-policy-options-in-brave-browser/34092)
- [brave/brave-core — policy definitions source (GitHub)](https://github.com/brave/brave-core/tree/master/components/policy/resources/templates/policy_definitions/BraveSoftware)
- [Google Chrome Enterprise Policy Reference](https://chromeenterprise.google/policies/)

---

<div align="center">

Made for the community. Use at your own risk.

[github.com/hamzagulesci/DebloatYourBrowser](https://github.com/hamzagulesci/DebloatYourBrowser)

</div>
