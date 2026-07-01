// HideAutomation.x — suppress the "Automation Running" overlay.
// Root cause (iOS 15.8.7): the banner lives inside SBRecordingIndicatorWindow
// (level=1120), NOT in a dedicated XCTest window. This is the same window
// used for the screen-recording dot; on automation-only test devices we
// suppress it entirely.

#import <UIKit/UIKit.h>

%ctor {
    NSLog(@"[HideAutomation] v4 loaded into SpringBoard");
    [@"1" writeToFile:@"/tmp/hideauto_loaded" atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

// Keep SBXCTestBannerController hooks as belt-and-suspenders for older iOS.
%hook SBXCTestBannerController
- (void)setVisible:(BOOL)v       { }
- (void)showBanner               { }
- (void)_showBanner              { }
- (void)_updateBannerVisibility  { }
- (void)setBannerVisible:(BOOL)v { }
%end

%hook SBXCTestAssistant
- (void)testRunnerPIDDidChange:(int)pid { }
- (void)_updateXCTestBanner            { }
%end

// iOS 15: "Automation Running" banner appears inside SBRecordingIndicatorWindow.
// Suppress that window from becoming visible at all.
%hook UIWindow
- (void)setHidden:(BOOL)hidden {
    if (!hidden) {
        NSString *winCls = NSStringFromClass(self.class);
        if ([winCls containsString:@"RecordingIndicator"] ||
            [winCls containsString:@"XCTest"] ||
            [winCls containsString:@"Automation"]) {
            NSLog(@"[HideAutomation] suppressed: %@", winCls);
            return; // keep hidden
        }
    }
    %orig;
}
%end
