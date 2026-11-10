# VietTweak

Dịch giao diện cài đặt của các tweak khác sang tiếng Việt.

VietTweak is a rootless jailbreak tweak that hooks `Preferences.app` and translates the UI text of other installed tweaks' preference bundles into Vietnamese. It works by intercepting `UILabel.setText:`, `UIButton.setTitle:forState:`, and `UINavigationItem.setTitle:` calls inside Preferences.app and replacing the original English string with a Vietnamese translation looked up from a JSON dictionary.

- **Target**: iOS 15+ rootless jailbreaks (Dopamine, palera1n, NekoJB)
- **Build system**: Theos + Logos
- **Preferences**: full PreferenceLoader bundle with master switch, verbose logging, dump-untranslated mode, reload button, respring button

## File layout

```
VietTweak/
├── Makefile                            # builds tweak + pref bundle, rootless
├── control                             # .deb metadata
├── VietTweak.plist                     # MobileSubstrate filter (Preferences.app only)
├── Tweak.x                             # Logos hooks + translation lookup
├── translations.json                   # default EN→VI dictionary (shipped in bundle)
└── Preferences/
    ├── VRTRootListController.h         # PSListController subclass
    ├── VRTRootListController.x         # settings UI + action methods
    ├── VRTRootListController.plist     # specifier table for the pane
    └── VietTweakPrefs.plist            # PreferenceLoader entry (root Settings row)
```

## How translation works

1. The MobileSubstrate filter (`VietTweak.plist`) loads the dylib **only** into `Preferences.app`. Other apps are not touched.
2. On every `UILabel.setText:` / `UIButton.setTitle:forState:` / `UINavigationItem.setTitle:` call, the hook:
   - Reads the master `enabled` switch from `com.viettweak.translate` (via CFPreferences).
   - Looks up the original string in the merged translation map (bundled default + user JSON).
   - Replaces the string if found; otherwise optionally logs the miss to `com.viettweak.misses.txt`.
3. The translation map is loaded once and is reloadable at runtime via the "Tải lại bản dịch" button — no respring needed.

## Translation dictionary

Two sources, merged at load time (user overrides default):

| File | Path | Purpose |
| --- | --- | --- |
| Bundled default | `/var/jb/Library/PreferenceBundles/VietTweakPrefs.bundle/translations.json` | ships with the tweak, ~100 common strings |
| User overrides | `/var/jb/var/mobile/Library/Preferences/com.viettweak.user.json` | editable from the device via Filza / iFile / SSH |

Format:
```json
{
    "Enabled": "Đã bật",
    "Respring": "Khởi động lại giao diện"
}
```

### Discovering new strings to translate

1. Open the VietTweak pane in Settings.
2. Turn on **"Lưu chuỗi chưa dịch"**.
3. Browse the preference panes of every other tweak installed on your device.
4. Every untranslated string the hook sees gets appended to:
   `/var/jb/var/mobile/Library/Preferences/com.viettweak.misses.txt`
5. Copy entries from that file into `com.viettweak.user.json` with their Vietnamese translations.
6. Tap **"Tải lại bản dịch"** in the VietTweak pane — translations apply immediately.

## Build

### Option A — GitHub Actions (no local Theos needed)

The repo ships with `.github/workflows/build.yml`. Just push to GitHub and CI builds the `.deb` for you:

1. Create a new GitHub repo (e.g. `VietTweak`).
2. Push the project:
   ```bash
   cd VietTweak
   git init
   git add .
   git commit -m "VietTweak 1.0.0"
   git branch -M main
   git remote add origin git@github.com:<your-user>/VietTweak.git
   git push -u origin main
   ```
3. Open the **Actions** tab on GitHub → watch the **Build VietTweak** workflow run.
4. When it finishes, click the run → scroll to **Artifacts** → download `VietTweak-deb` (a zip containing the `.deb`).

To publish a release: tag a commit.
```bash
git tag v1.0.0
git push origin v1.0.0
```
CI auto-creates a GitHub Release named `VietTweak 1.0.0` with the `.deb` attached.

The CI workflow:
- runs on `ubuntu-latest`
- installs clang, ldid, dpkg, fakeroot
- clones Theos into a cache (so subsequent builds are fast)
- downloads iPhoneOS16.5.sdk
- runs `make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless`
- uploads `com.viettweak.translate_*.deb` as an artifact
- on tag push, creates a GitHub Release with the `.deb` attached

### Option B — Local build (macOS / Linux / WSL)

Requirements: Theos installed, iOS 15.5+ SDK (or whatever your `$THEOS_SDKS` provides), `dpkg-deb`.

```bash
cd VietTweak
make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
```

Output: `packages/com.viettweak.translate_1.0.0_iphoneos-arm64.deb`

See the **How to build** walkthrough in the chat docs for full setup steps (Xcode CLI tools, ldid, dpkg, SDK install).

## Install

```bash
# Copy the .deb to the device, then:
dpkg -i /var/jb/var/root/com.viettweak.translate_1.0.0_iphoneos-arm64.deb
# Or push it through your package manager (Sileo / Zebra):
#   - Sileo: drag-and-drop the .deb
#   - or add a local file:// repo
```

Then **respring**. A new **VietTweak** row appears in Settings.

## Customisation

### Add more default translations
Edit `translations.json` at the project root before building. Keys are matched case-insensitively if the exact key isn't found.

### Add an icon
Drop a 29×29 / 58×58 `VietTweakPrefs.png` / `VietTweakPrefs@2x.png` into `Resources/`. The `Resources` folder is already declared in the Makefile via `VietTweakPrefs_RESOURCE_DIRS = Resources` and will be copied into `VietTweakPrefs.bundle`.

### Change the prefs domain
Search-and-replace `com.viettweak.translate` across `Tweak.x`, `VRTRootListController.plist`, and `control` if you want a different identifier.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| No "VietTweak" row in Settings | Verify `PreferenceLoader` is installed. Respring. Check `/var/jb/Library/PreferenceLoader/Preferences/VietTweakPrefs.plist` exists on device. |
| Strings not translated | Toggle the master switch off and on. Make sure the key in `translations.json` matches the exact string (case-insensitive fallback exists). |
| Prefs pane is white/empty | Verify `VRTRootListController.plist` was bundled — open `VietTweakPrefs.bundle/` on device and check. |
| `make package` fails on `Preferences` framework | Make sure your Theos SDK is iOS 15.5+. The private `Preferences.framework` headers must be present. |
| Hooks not loading at all | Confirm the .plist filter path on device: `/var/jb/Library/MobileSubstrate/DynamicLibraries/VietTweak.plist` should list `com.apple.Preferences`. |

## Licence

MIT. Use it, fork it, ship your own variant.
