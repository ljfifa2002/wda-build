// HideAutomation.x — suppress the "Automation Running" overlay.
// v3: diagnostic mode — writes window info to /tmp/hideauto_windows.log
// so we can identify the exact class/level the banner uses.

#import <UIKit/UIKit.h>

%ctor {
    NSLog(@"[HideAutomation] v3 loaded into SpringBoard");
    [@"1" writeToFile:@"/tmp/hideauto_loaded" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    // Clear previous diagnostic log on each SpringBoard start.
    [@"" writeToFile:@"/tmp/hideauto_windows.log" atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

// Helper: append a line to the diagnostic log file.
static void logWindow(NSString *event, UIWindow *w) {
    NSString *line = [NSString stringWithFormat:@"%@ level=%.0f cls=%@ rvc=%@\n",
        event, w.windowLevel,
        NSStringFromClass(w.class),
        NSStringFromClass(w.rootViewController.class) ?: @"nil"];
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:@"/tmp/hideauto_windows.log"];
    if (!fh) {
        [line writeToFile:@"/tmp/hideauto_windows.log" atomically:NO encoding:NSUTF8StringEncoding error:nil];
    } else {
        [fh seekToEndOfFile];
        [fh writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
        [fh closeFile];
    }
}

// Log AND suppress SBXCTestBannerController — try every plausible method name.
%hook SBXCTestBannerController
- (void)setVisible:(BOOL)v      { NSLog(@"[HideAutomation] SBXCTestBannerController setVisible:%d", v); }
- (void)showBanner              { NSLog(@"[HideAutomation] SBXCTestBannerController showBanner"); }
- (void)_showBanner             { NSLog(@"[HideAutomation] SBXCTestBannerController _showBanner"); }
- (void)_updateBannerVisibility { NSLog(@"[HideAutomation] SBXCTestBannerController _updateBannerVisibility"); }
- (void)setBannerVisible:(BOOL)v{ NSLog(@"[HideAutomation] SBXCTestBannerController setBannerVisible:%d", v); }
- (void)_presentBanner          { NSLog(@"[HideAutomation] SBXCTestBannerController _presentBanner"); }
%end

%hook SBXCTestAssistant
- (void)testRunnerPIDDidChange:(int)pid { NSLog(@"[HideAutomation] SBXCTestAssistant testRunnerPIDDidChange:%d", pid); }
- (void)_updateXCTestBanner     { NSLog(@"[HideAutomation] SBXCTestAssistant _updateXCTestBanner"); }
- (void)setRunnerPID:(int)pid   { NSLog(@"[HideAutomation] SBXCTestAssistant setRunnerPID:%d", pid); }
%end

// Log ALL UIWindow show/hide events with level > 100 so we can find the banner window.
// After the banner appears run: cat /tmp/hideauto_windows.log
%hook UIWindow
- (void)setHidden:(BOOL)hidden {
    if (self.windowLevel > 100) {
        logWindow(hidden ? @"HIDE" : @"SHOW", self);
    }
    %orig;
}
- (void)makeKeyAndVisible {
    if (self.windowLevel > 100) {
        logWindow(@"makeKeyAndVisible", self);
    }
    %orig;
}
%end
