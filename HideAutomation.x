// HideAutomation.x — v6: dump SpringBoard class names to find the real banner class.

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

%ctor {
    NSLog(@"[HideAutomation] v6 loaded into SpringBoard");
    [@"1" writeToFile:@"/tmp/hideauto_loaded" atomically:YES encoding:NSUTF8StringEncoding error:nil];

    // Dump all SpringBoard class names related to XCTest / Automation / Banner / Recording.
    // After SpringBoard starts, check: cat /tmp/hideauto_classes.txt
    unsigned int count = 0;
    const char **classes = objc_copyClassNamesForImage(
        "/System/Library/CoreServices/SpringBoard.app/SpringBoard", &count);
    NSMutableArray *relevant = [NSMutableArray array];
    for (unsigned int i = 0; i < count; i++) {
        NSString *name = @(classes[i]);
        if ([name containsString:@"XCTest"]     ||
            [name containsString:@"Automation"] ||
            [name containsString:@"Banner"]     ||
            [name containsString:@"Recording"]) {
            [relevant addObject:name];
        }
    }
    free(classes);
    [relevant sortUsingSelector:@selector(compare:)];
    NSString *out = [relevant componentsJoinedByString:@"\n"];
    [out writeToFile:@"/tmp/hideauto_classes.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"[HideAutomation] dumped %lu classes to /tmp/hideauto_classes.txt", (unsigned long)relevant.count);

    // Also hook UILabel setText: to find where "Automation" text is set.
    // Result logged to /tmp/hideauto_labels.log after banner appears.
    [@"" writeToFile:@"/tmp/hideauto_labels.log" atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

// Keep existing suppressions.
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

%hook SBRecordingIndicatorWindow
- (void)setHidden:(BOOL)hidden {
    if (!hidden) { return; } // suppress
    %orig;
}
- (void)makeKeyAndVisible { } // suppress
%end

// Find where "Automation" text is set — log the label's view hierarchy path.
%hook UILabel
- (void)setText:(NSString *)text {
    if (text && [text rangeOfString:@"Automation" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        NSString *entry = [NSString stringWithFormat:@"setText:%@ cls=%@ supercls=%@\n",
            text,
            NSStringFromClass(self.class),
            NSStringFromClass(self.superview.class)];
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:@"/tmp/hideauto_labels.log"];
        if (!fh) {
            [entry writeToFile:@"/tmp/hideauto_labels.log" atomically:NO encoding:NSUTF8StringEncoding error:nil];
        } else {
            [fh seekToEndOfFile];
            [fh writeData:[entry dataUsingEncoding:NSUTF8StringEncoding]];
            [fh closeFile];
        }
        NSLog(@"[HideAutomation] Automation label: %@", entry);
    }
    %orig;
}
%end
