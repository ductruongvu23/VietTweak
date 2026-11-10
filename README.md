# VietTweak

Dịch giao diện cài đặt của các tweak khác sang tiếng Việt.

VietTweak là tweak cho jailbreak rootless. Nó chạy bên trong app **Cài đặt** (Preferences.app), chặn các lệnh đặt chữ (`UILabel`, `UIButton`, `UINavigationItem`) và thay chuỗi tiếng Anh bằng bản dịch tiếng Việt lấy từ một từ điển JSON.

- **Hỗ trợ**: iOS 15.0 trở lên, jailbreak rootless (Dopamine, palera1n, NekoJB)
- **Phụ thuộc**: `mobilesubstrate` (hoặc ElleKit), `preferenceloader`
- **Chỉ chạy trong app Cài đặt**, không ảnh hưởng app khác

## Cài đặt

1. Tải file `.deb` mới nhất ở trang [Releases](../../releases/latest).
2. Mở bằng Sileo / Zebra / Filza để cài, hoặc qua SSH:
   ```bash
   dpkg -i com.viettweak.translate_1.0.0_iphoneos-arm64.deb
   ```
3. Respring.
4. Vào **Cài đặt → VietTweak** và bật **"Bật dịch"**. Tweak mặc định đang tắt cho tới khi bạn bật công tắc này lần đầu.

## Tùy chọn trong Cài đặt

| Tùy chọn | Tác dụng |
| --- | --- |
| Bật dịch | Công tắc chính |
| Ghi log chi tiết | Ghi các chuỗi chưa dịch ra syslog |
| Lưu chuỗi chưa dịch | Ghi các chuỗi chưa có bản dịch vào `com.viettweak.misses.txt` |
| Tải lại bản dịch | Đọc lại từ điển, không cần respring |
| Mở từ điển người dùng | Sao chép đường dẫn hoặc mở bằng Filza |
| Đặt lại từ điển người dùng | Xóa từ điển người dùng, chỉ giữ bản dịch mặc định |
| Khởi động lại giao diện | Respring |

## Từ điển bản dịch

Có hai nguồn, được gộp khi tải (từ điển người dùng ghi đè từ điển mặc định):

| Nguồn | Đường dẫn trên máy |
| --- | --- |
| Mặc định (đi kèm tweak) | `/var/jb/Library/PreferenceBundles/VietTweakPrefs.bundle/translations.json` |
| Người dùng (tự sửa được) | `/var/jb/var/mobile/Library/Preferences/com.viettweak.user.json` |

Định dạng:

```json
{
    "Enabled": "Đã bật",
    "Respring": "Khởi động lại giao diện"
}
```

Nếu không tìm thấy khóa khớp chính xác, tweak sẽ thử khớp không phân biệt hoa thường.

### Thêm bản dịch cho tweak khác

1. Trong **Cài đặt → VietTweak**, bật **"Lưu chuỗi chưa dịch"**.
2. Mở trang cài đặt của các tweak muốn dịch.
3. Các chuỗi chưa dịch được ghi vào `/var/jb/var/mobile/Library/Preferences/com.viettweak.misses.txt`.
4. Chép chúng vào `com.viettweak.user.json` kèm bản dịch.
5. Bấm **"Tải lại bản dịch"**, bản dịch có hiệu lực ngay.

Muốn thêm bản dịch mặc định cho mọi người: sửa `translations.json` rồi gửi PR.

## Build

### GitHub Actions (không cần cài Theos)

Mỗi lần push lên `main`, workflow `.github/workflows/build.yml` sẽ build file `.deb`. File nằm ở mục **Artifacts** của lần chạy (`VietTweak-deb`).

Để tạo release: tăng `Version:` trong `control`, rồi gắn tag:

```bash
git tag v1.0.1
git push origin v1.0.1
```

CI sẽ tự tạo GitHub Release kèm file `.deb`.

Workflow sẽ:
- chạy trên `ubuntu-latest`
- cài `ldid` (bản Procursus) và Theos, kèm iOS toolchain cho Linux
- tải iPhoneOS16.5.sdk từ `theos/sdks`
- chạy `make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless`

### Build trên máy (macOS / Linux / WSL)

Cần cài sẵn [Theos](https://theos.dev/docs/installation) và iPhoneOS16.5.sdk trong `$THEOS/sdks`.

```bash
make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
```

Kết quả: `packages/com.viettweak.translate_<version>_iphoneos-arm64.deb`

## Cấu trúc thư mục

```
VietTweak/
├── Makefile                          # build tweak + bundle cài đặt (rootless)
├── control                           # thông tin gói .deb
├── VietTweak.plist                   # bộ lọc: chỉ nạp vào app Cài đặt
├── Tweak.x                           # hook Logos + tra từ điển
├── translations.json                 # từ điển Anh → Việt mặc định
├── Preferences/
│   ├── VRTRootListController.h/.x    # giao diện + các nút trong trang cài đặt
│   └── VietTweakPrefs.plist          # dòng "VietTweak" trong Cài đặt
└── Resources/
    ├── Info.plist                    # khai báo bundle cài đặt
    ├── VRTRootListController.plist   # danh sách mục trong trang cài đặt
    └── VietTweakPrefs*.png           # icon 1x/2x/3x
```

## Xử lý sự cố

| Hiện tượng | Cách xử lý |
| --- | --- |
| Không thấy dòng VietTweak trong Cài đặt | Kiểm tra đã cài PreferenceLoader, respring lại. |
| Không dịch gì cả | Vào trang VietTweak, bật "Bật dịch" (mặc định đang tắt). |
| Một số chuỗi không dịch | Bật "Lưu chuỗi chưa dịch" để xem chuỗi gốc chính xác, rồi thêm vào từ điển người dùng. |
| Trang cài đặt trắng trơn | Kiểm tra `VietTweakPrefs.bundle/VRTRootListController.plist` có trên máy. |

## Giấy phép

MIT.
