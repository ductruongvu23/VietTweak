# VietTweak

> Dịch giao diện cài đặt của các tweak khác sang tiếng Việt.

VietTweak translates the settings pages of your other jailbreak tweaks into Vietnamese. It runs only inside the **Settings** app, swaps English text for Vietnamese on the fly, and uses a plain JSON dictionary you can extend yourself, with no respring needed.

- **Supports**: iOS 15.0 and later, rootless jailbreaks (Dopamine, palera1n, NekoJB)
- **Depends on**: `mobilesubstrate` (or ElleKit), `preferenceloader`
- **Scope**: Settings app only, other apps are untouched

## Install

### From the repo (recommended)

Add this source in Sileo or Zebra, then install **VietTweak**. Updates come through your package manager.

```
https://ductruongvu23.github.io/VietTweak/
```

### Manually

1. Download the latest `.deb` from [Releases](../../releases/latest).
2. Install it with Sileo, Zebra or Filza, or over SSH:
   ```bash
   dpkg -i com.viettweak.translate_1.0.0_iphoneos-arm64.deb
   ```
3. Respring.
4. Open **Settings → VietTweak** and turn on **"Bật dịch"** (Enable). The tweak stays off until you flip this switch once.

## Usage

Open any tweak's settings page after turning VietTweak on. Text with a known translation shows up in Vietnamese right away.

### Options

| Option | What it does |
| --- | --- |
| Bật dịch | Master switch |
| Ghi log chi tiết | Logs untranslated strings to syslog |
| Lưu chuỗi chưa dịch | Saves untranslated strings to `com.viettweak.misses.txt` |
| Tải lại bản dịch | Reloads the dictionary, no respring needed |
| Mở từ điển người dùng | Copies the path of your dictionary, or opens it in Filza |
| Đặt lại từ điển người dùng | Deletes your dictionary, keeps only the built-in one |
| Khởi động lại giao diện | Respring |

### Translating a tweak that isn't covered yet

1. In **Settings → VietTweak**, turn on **"Lưu chuỗi chưa dịch"**.
2. Open the settings pages of the tweaks you want translated.
3. Every string with no translation is saved to
   `/var/jb/var/mobile/Library/Preferences/com.viettweak.misses.txt`.
4. Copy those strings into your dictionary (below) together with their Vietnamese text.
5. Tap **"Tải lại bản dịch"**, and the new translations apply immediately.

### Dictionary

Two sources are merged on load, and your own dictionary wins over the built-in one:

| Source | Path on device |
| --- | --- |
| Built-in | `/var/jb/Library/PreferenceBundles/VietTweakPrefs.bundle/translations.json` |
| Yours (editable) | `/var/jb/var/mobile/Library/Preferences/com.viettweak.user.json` |

Format:

```json
{
    "Enabled": "Đã bật",
    "Respring": "Khởi động lại giao diện"
}
```

If there is no exact match, the lookup falls back to a case-insensitive match.

To add translations for everyone, edit `translations.json` in this repo and open a pull request.

## Build

### GitHub Actions (no local Theos needed)

Every push to `main` builds the `.deb` via `.github/workflows/build.yml`. Download it from the run's **Artifacts** (`VietTweak-deb`).

To publish a release, bump `Version:` in `control`, then push a tag:

```bash
git tag v1.0.1
git push origin v1.0.1
```

CI creates a GitHub Release with the `.deb` attached, then rebuilds the APT repo from every release and deploys it to GitHub Pages (`repo` job). To rebuild the repo without a new tag, run the workflow manually from the Actions tab.

The workflow:
- runs on `ubuntu-latest`
- installs `ldid` (Procursus build), Theos and the Linux iOS toolchain
- fetches iPhoneOS16.5.sdk from `theos/sdks`
- runs `make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless`

### Local build (macOS / Linux / WSL)

Requires [Theos](https://theos.dev/docs/installation) with iPhoneOS16.5.sdk in `$THEOS/sdks`.

```bash
make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
```

Output: `packages/com.viettweak.translate_<version>_iphoneos-arm64.deb`

## How it works

`VietTweak.plist` loads the dylib only into Settings. There it hooks `UILabel` (`setText:`, `setAttributedText:`), `UIButton` (`setTitle:forState:`) and `UINavigationItem` (`setTitle:`). Each string is looked up in the merged dictionary and replaced if a translation exists.

## Project layout

```
VietTweak/
├── Makefile                          # builds tweak + settings bundle (rootless)
├── control                           # .deb metadata
├── VietTweak.plist                   # filter: load into Settings only
├── Tweak.x                           # Logos hooks + dictionary lookup
├── translations.json                 # built-in English → Vietnamese dictionary
├── Preferences/
│   ├── VRTRootListController.h/.x    # settings page UI + actions
│   └── VietTweakPrefs.plist          # the "VietTweak" row in Settings
└── Resources/
    ├── Info.plist                    # settings bundle info
    ├── VRTRootListController.plist   # settings page items
    └── VietTweakPrefs*.png           # icon 1x/2x/3x
```

## Troubleshooting

| Problem | Fix |
| --- | --- |
| No VietTweak row in Settings | Make sure PreferenceLoader is installed, then respring. |
| Nothing gets translated | Open the VietTweak page and turn on "Bật dịch" (off by default). |
| Some strings stay in English | Turn on "Lưu chuỗi chưa dịch" to see the exact source text, then add it to your dictionary. |
| VietTweak page is blank | Check that `VietTweakPrefs.bundle/VRTRootListController.plist` exists on the device. |

## License

MIT.
