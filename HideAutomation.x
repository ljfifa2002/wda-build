// HideAutomation.x — suppress the "Automation Running" overlay that iOS shows
// when WebDriverAgent / XCTest is active. Injects into SpringBoard only.
// Hooks multiple candidate classes so it works across iOS 14-16 without changes.

#import <UIKit/UIKit.h>

// iOS 14-15: SBXCTestBannerController manages the automation status bar banner.
%hook SBXCTestBannerController
- (void)setVisible:(BOOL)visible { /* no-op — keep banner hidden */ }
- (void)showBanner { /* no-op */ }
- (void)_showBanner { /* no-op */ }
%end

// iOS 15-16: SBXCTestAssistant drives automation state in SpringBoard.
// Suppressing the "runner did start" callback prevents the banner from appearing.
%hook SBXCTestAssistant
- (void)testRunnerPIDDidChange:(int)pid { /* no-op */ }
- (void)_updateXCTestBanner { /* no-op */ }
%end

// Fallback: intercept any UIWindow whose windowLevel matches the overlay level
// (~1001 used by SpringBoard alert windows) that has "automation" in its description.
%hook UIWindow
- (void)setHidden:(BOOL)hidden {
    // Only intercept windows that SpringBoard pushes for automation status.
    // A windowLevel of 1001 is the SpringBoard alert tier; skip all others.
    if (!hidden && self.windowLevel >= 1000 && self.windowLevel < 1100) {
        NSString *desc = [self.rootViewController.class description];
        if (desc && ([desc rangeOfString:@"XCTest" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                     [desc rangeOfString:@"Automation" options:NSCaseInsensitiveSearch].location != NSNotFound)) {
            return; // suppress
        }
    }
    %orig;
}
%end
