// VietTweak.Tweak.x
// Hooks UILabel/UITableViewCell text setters inside Preferences.app and
// replaces English strings with Vietnamese translations pulled from the
// translation dictionary that ships with the tweak (and is editable from
// the preference bundle).
//
// Targets: rootless jailbreaks (iOS 15+ — Dopamine / palera1n / NekoJB).

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// --- Preferences keys -----------------------------------------------------
static NSString *const kPrefsDomain = @"com.viettweak.translate";
static NSString *const kEnabledKey  = @"enabled";
static NSString *const kVerboseKey  = @"verbose";
static NSString *const kDumpKey     = @"dumpUntranslated";

// --- Translation store ----------------------------------------------------
static NSMutableDictionary *VTRTranslationMap(void) {
    static NSMutableDictionary *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = [NSMutableDictionary dictionary];

        // 1. Bundled default dictionary (lives inside VietTweakPrefs.bundle).
        NSString *bundled =
            @"/var/jb/Library/PreferenceBundles/VietTweakPrefs.bundle/translations.json";

        // 2. User overrides (edited from the prefs pane or via Filza).
        NSString *user =
            @"/var/jb/var/mobile/Library/Preferences/com.viettweak.user.json";

        if ([[NSFileManager defaultManager] fileExistsAtPath:bundled]) {
            NSData *d = [NSData dataWithContentsOfFile:bundled];
            NSDictionary *j = [NSJSONSerialization JSONObjectWithData:d
                                                              options:0
                                                                error:nil];
            [map addEntriesFromDictionary:j];
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:user]) {
            NSData *d = [NSData dataWithContentsOfFile:user];
            NSDictionary *j = [NSJSONSerialization JSONObjectWithData:d
                                                              options:0
                                                                error:nil];
            [map addEntriesFromDictionary:j]; // user overrides bundled
        }
    });
    return map;
}

// Force re-read after the user edits the JSON file from the prefs pane.
static void VTRReloadMap(void) {
    // The static map is dispatch_once-init'd; we replace its contents in place
    // so existing pointers keep working without re-running dispatch_once.
    NSMutableDictionary *map = VTRTranslationMap();
    [map removeAllObjects];

    NSString *bundled =
        @"/var/jb/Library/PreferenceBundles/VietTweakPrefs.bundle/translations.json";
    NSString *user =
        @"/var/jb/var/mobile/Library/Preferences/com.viettweak.user.json";

    if ([[NSFileManager defaultManager] fileExistsAtPath:bundled]) {
        NSData *d = [NSData dataWithContentsOfFile:bundled];
        NSDictionary *j = [NSJSONSerialization JSONObjectWithData:d
                                                          options:0
                                                            error:nil];
        [map addEntriesFromDictionary:j];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:user]) {
        NSData *d = [NSData dataWithContentsOfFile:user];
        NSDictionary *j = [NSJSONSerialization JSONObjectWithData:d
                                                          options:0
                                                            error:nil];
        [map addEntriesFromDictionary:j];
    }
}

// CFPreferences reads the rootless prefs domain — rootless tweaks must use
// the /var/jb prefix when reading CFPreferences, so we use the standard
// kCFPreferencesCurrentApplication domain name and rely on the rootless shim.
static BOOL VTRPrefsEnabled(void) {
    return [((__bridge NSNumber *)CFPreferencesCopyAppValue(
        (__bridge CFStringRef)kEnabledKey,
        (__bridge CFStringRef)kPrefsDomain)) boolValue];
}

static BOOL VTRPrefsVerbose(void) {
    return [((__bridge NSNumber *)CFPreferencesCopyAppValue(
        (__bridge CFStringRef)kVerboseKey,
        (__bridge CFStringRef)kPrefsDomain)) boolValue];
}

static BOOL VTRPrefsDump(void) {
    NSNumber *v = (__bridge NSNumber *)CFPreferencesCopyAppValue(
        (__bridge CFStringRef)kDumpKey,
        (__bridge CFStringRef)kPrefsDomain);
    return v ? [v boolValue] : NO;
}

// --- Translation helper ---------------------------------------------------
static NSString *VTRTranslate(NSString *input) {
    if (input.length == 0) return input;
    if (!VTRPrefsEnabled()) return input;

    // First, exact match.
    NSString *exact = VTRTranslationMap()[input];
    if (exact) return exact;

    // Then, case-insensitive match (titles often arrive capitalised).
    for (NSString *key in VTRTranslationMap()) {
        if ([key compare:input options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            return VTRTranslationMap()[key];
        }
    }

    // Optional: record the miss so the user can translate it later.
    if (VTRPrefsDump()) {
        static NSMutableSet *seen = nil;
        static dispatch_once_t once;
        dispatch_once(&once, ^{ seen = [NSMutableSet set]; });

        @synchronized(seen) {
            if (![seen containsObject:input]) {
                [seen addObject:input];
                NSString *path =
                    @"/var/jb/var/mobile/Library/Preferences/com.viettweak.misses.txt";
                NSString *line = [NSString stringWithFormat:@"%@\n", input];
                NSFileHandle *fh =
                    [NSFileHandle fileHandleForWritingAtPath:path];
                if (!fh) {
                    [line writeToFile:path atomically:YES
                          encoding:NSUTF8StringEncoding error:nil];
                } else {
                    [fh seekToEndOfFile];
                    [fh writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
                    [fh closeFile];
                }
            }
        }
    }

    if (VTRPrefsVerbose()) {
        NSLog(@"[VietTweak] miss: %@", input);
    }
    return input;
}

// --- Hooks ----------------------------------------------------------------

%hook UILabel

- (void)setText:(NSString *)text {
    if ([text isKindOfClass:[NSString class]]) {
        text = VTRTranslate(text);
    }
    %orig(text);
}

%end

// Buttons in spec cells use UIButton titleLabel — covers some tweak panes
// that build custom cells with buttons (e.g. "Respring", "Apply").
%hook UIButton

- (void)setTitle:(NSString *)title forState:(UIControlState)state {
    if ([title isKindOfClass:[NSString class]]) {
        title = VTRTranslate(title);
    }
    %orig(title, state);
}

%end

// Some preference cells render via attributed text — cover that path too.
%hook UILabel

- (void)setAttributedText:(NSAttributedString *)attributedText {
    if (attributedText.length > 0) {
        NSString *raw = attributedText.string;
        NSString *tr  = VTRTranslate(raw);
        if (![tr isEqualToString:raw]) {
            NSDictionary *attrs =
                [attributedText attributesAtIndex:0 effectiveRange:NULL];
            attributedText = [[NSAttributedString alloc]
                initWithString:tr attributes:attrs];
        }
    }
    %orig(attributedText);
}

%end

// Navigation bar / UINavigationItem titles
%hook UINavigationItem

- (void)setTitle:(NSString *)title {
    if ([title isKindOfClass:[NSString class]]) {
        title = VTRTranslate(title);
    }
    %orig(title);
}

%end

// Listen for the prefs-notification posted by VietTweakPrefs when the user
// reloads the dictionary, so we drop the cached map without a respring.
%ctor {
    [[NSNotificationCenter defaultCenter]
        addObserverForName:@"VietTweakReloadMap"
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification * _Nonnull note) {
        VTRReloadMap();
        NSLog(@"[VietTweak] translation map reloaded");
    }];

    NSLog(@"[VietTweak] loaded into %@", NSProcessInfo.processInfo.processName);
}
