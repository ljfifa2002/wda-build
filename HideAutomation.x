// HideAutomation.x — suppress the "Automation Running" overlay that iOS shows
// when WebDriverAgent / XCTest is active. Injects into SpringBoard only.

#import <UIKit/UIKit.h>

// Confirm injection: write /tmp/hideauto_loaded on every SpringBoard launch.
// Check with: ls /tmp/hideauto_loaded (exists = dylib injected successfully)
%ctor {
    NSLog(@"[HideAutomation] loaded into SpringBoard");
    [@"1" writeToFile:@"/tmp/hideauto_loaded" atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

// iOS 14-15: SBXCTestBannerController manages the automation status bar banner.
%hook SBXCTestBannerController
- (void)setVisible:(BOOL)visible { /* no-op */ }
- (void)showBanner { /* no-op */ }
- (void)_showBanner { /* no-op */ }
- (void)_updateBannerVisibility { /* no-op */ }
%end

// iOS 15-16: SBXCTestAssistant drives automation state in SpringBoard.
%hook SBXCTestAssistant
- (void)testRunnerPIDDidChange:(int)pid { /* no-op */ }
- (void)_updateXCTestBanner { /* no-op */ }
- (void)setRunnerPID:(int)pid { /* no-op */ }
%end

// Broader UIWindow fallback: block any window SpringBoard creates for automation.
// Use a wider window-level range and check the full window description, not just rootVC.
%hook UIWindow
- (void)setHidden:(BOOL)hidden {
    if (!hidden && self.windowLevel >= 990 && self.windowLevel <= 1200) {
        NSString *desc = [NSString stringWithFormat:@"%@%@",
            NSStringFromClass(self.class),
            NSStringFromClass(self.rootViewController.class) ?: @""];
        if ([desc rangeOfString:@"XCTest" options:NSCaseInsensitiveSearch].location != NSNotFound ||
            [desc rangeOfString:@"Automation" options:NSCaseInsensitiveSearch].location != NSNotFound ||
            [desc rangeOfString:@"Banner" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            NSLog(@"[HideAutomation] suppressed window: %@", desc);
            return;
        }
    }
    %orig;
}
- (void)setAlpha:(CGFloat)alpha {
    if (alpha > 0 && self.windowLevel >= 990 && self.windowLevel <= 1200) {
        NSString *desc = NSStringFromClass(self.rootViewController.class) ?: @"";
        if ([desc rangeOfString:@"XCTest" options:NSCaseInsensitiveSearch].location != NSNotFound ||
            [desc rangeOfString:@"Automation" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return;
        }
    }
    %orig;
}
%end
