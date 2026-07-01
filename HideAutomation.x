// HideAutomation.x — suppress the "Automation Running" overlay.
// v5: directly hook SBRecordingIndicatorWindow (the actual iOS 15 banner window).

#import <UIKit/UIKit.h>

%ctor {
    NSLog(@"[HideAutomation] v5 loaded into SpringBoard");
    [@"1" writeToFile:@"/tmp/hideauto_loaded" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    // Clear diagnostic log so we only see entries from this SpringBoard session.
    [@"" writeToFile:@"/tmp/hideauto_windows.log" atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

// Belt-and-suspenders for older iOS versions.
%hook SBXCTestBannerController
- (void)setVisible:(BOOL)v      { }
- (void)showBanner              { }
- (void)_showBanner             { }
- (void)_updateBannerVisibility { }
%end

%hook SBXCTestAssistant
- (void)testRunnerPIDDidChange:(int)pid { }
- (void)_updateXCTestBanner            { }
%end

// iOS 15: "Automation Running" is shown inside SBRecordingIndicatorWindow.
// Hook this class directly — a %hook UIWindow cannot catch an overridden
// setHidden: defined in the subclass.
%hook SBRecordingIndicatorWindow
- (void)setHidden:(BOOL)hidden {
    if (!hidden) {
        NSLog(@"[HideAutomation] suppressed SBRecordingIndicatorWindow setHidden:NO");
        // Record suppression for diagnostics.
        NSString *entry = @"SUPPRESSED SBRecordingIndicatorWindow\n";
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:@"/tmp/hideauto_windows.log"];
        if (!fh) {
            [entry writeToFile:@"/tmp/hideauto_windows.log" atomically:NO encoding:NSUTF8StringEncoding error:nil];
        } else {
            [fh seekToEndOfFile];
            [fh writeData:[entry dataUsingEncoding:NSUTF8StringEncoding]];
            [fh closeFile];
        }
        return; // keep hidden
    }
    %orig;
}
- (void)makeKeyAndVisible {
    // Also suppress makeKeyAndVisible path.
    NSLog(@"[HideAutomation] suppressed SBRecordingIndicatorWindow makeKeyAndVisible");
    // Do NOT call %orig — window stays hidden.
}
%end
