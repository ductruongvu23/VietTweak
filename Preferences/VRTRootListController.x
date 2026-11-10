// VRTRootListController.x
// The settings UI for VietTweak. Provides:
//   - master on/off switch
//   - verbose logging toggle
//   - "dump untranslated strings" toggle
//   - reload dictionary button (broadcasts VietTweakReloadMap)
//   - open user dictionary file (via open:// URL or copy path)
//   - reset user dictionary
//   - respring button
//   - about cell

#import "VRTRootListController.h"
#import <spawn.h>

@interface VRTRootListController ()
@end

@implementation VRTRootListController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = @"VietTweak";
    }
    return self;
}

// PSListController reads the specifiers from a plist whose name matches the
// controller class. We override to make sure the right file is picked up
// even when the bundle is loaded outside Preferences.app's normal lookup.
- (NSString *)specifiersPlist {
    return @"VRTRootListController";
}

// --- Actions --------------------------------------------------------------

- (void)reloadDictionary {
    // Tell the running tweak (in Preferences.app) to drop the cached map.
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"VietTweakReloadMap" object:nil];

    UIAlertController *a = [UIAlertController
        alertControllerWithTitle:@"VietTweak"
                         message:@"Đã tải lại từ điển bản dịch."
                  preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"OK"
                                          style:UIAlertActionStyleDefault
                                        handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)openUserDictionary {
    NSString *path =
        @"/var/jb/var/mobile/Library/Preferences/com.viettweak.user.json";
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        // Seed it with the bundled default so the user has something to edit.
        NSString *bundled =
            @"/var/jb/Library/PreferenceBundles/VietTweakPrefs.bundle/translations.json";
        if ([[NSFileManager defaultManager] fileExistsAtPath:bundled]) {
            [NSString stringWithContentsOfFile:bundled
                                   encoding:NSUTF8StringEncoding
                                      error:nil];
            [[NSFileManager defaultManager] copyItemAtPath:bundled
                                                     toPath:path
                                                      error:nil];
        } else {
            [@"{}" writeToFile:path atomically:YES
                    encoding:NSUTF8StringEncoding error:nil];
        }
    }

    UIAlertController *a = [UIAlertController
        alertControllerWithTitle:@"Từ điển người dùng"
                         message:path
                  preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Sao chép đường dẫn"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction *_) {
        UIPasteboard.generalPasteboard.string = path;
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Mở bằng Filza"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction *_) {
        [UIApplication.sharedApplication openURL:
            [NSURL URLWithString:[@"filza://view" stringByAppendingString:path]]
                                        options:@{}
                              completionHandler:nil];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"OK"
                                          style:UIAlertActionStyleCancel
                                        handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)resetDictionary {
    UIAlertController *a = [UIAlertController
        alertControllerWithTitle:@"Đặt lại"
                         message:@"Xóa từ điển người dùng? Chỉ bản dịch mặc định được giữ lại."
                  preferredStyle:UIAlertControllerStyleActionSheet];
    [a addAction:[UIAlertAction actionWithTitle:@"Đặt lại"
                                          style:UIAlertActionStyleDestructive
                                        handler:^(UIAlertAction *_) {
        NSString *path =
            @"/var/jb/var/mobile/Library/Preferences/com.viettweak.user.json";
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        [[NSNotificationCenter defaultCenter]
            postNotificationName:@"VietTweakReloadMap" object:nil];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Hủy"
                                          style:UIAlertActionStyleCancel
                                        handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)respring {
    // system() is unavailable in the iOS SDK
    pid_t pid;
    const char *argv[] = {"killall", "-9", "SpringBoard", NULL};
    posix_spawn(&pid, "/var/jb/usr/bin/killall", NULL, NULL, (char *const *)argv, NULL);
}

- (void)openGitHub {
    [UIApplication.sharedApplication openURL:
        [NSURL URLWithString:@"https://github.com/"]
                                    options:@{} completionHandler:nil];
}

@end
