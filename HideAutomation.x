// HideAutomation.x — suppress the "Automation Running" overlay.
// v7: inject into WebDriverAgentRunner-Runner (not SpringBoard).
// The banner is rendered in the WDA XCTest runner process, not SpringBoard.

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

%ctor {
    NSLog(@"[HideAutomation] v7 loaded into WDA runner");
    [@"1" writeToFile:@"/tmp/hideauto_loaded" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [@"" writeToFile:@"/tmp/hideauto_labels.log" atomically:YES encoding:NSUTF8StringEncoding error:nil];

    // Dump all class names containing Banner/Automation/Overlay/Status for discovery.
    unsigned int count = 0;
    Class *all = objc_copyClassList(&count);
    NSMutableArray *relevant = [NSMutableArray array];
    for (unsigned int i = 0; i < count; i++) {
        NSString *name = NSStringFromClass(all[i]);
        if ([name containsString:@"Banner"]     ||
            [name containsString:@"Automation"] ||
            [name containsString:@"Overlay"]    ||
            [name containsString:@"Status"]     ||
            [name containsString:@"XCTest"]     ||
            [name containsString:@"Running"]) {
            [relevant addObject:name];
        }
    }
    free(all);
    [relevant sortUsingSelector:@selector(compare:)];
    NSString *out = [relevant componentsJoinedByString:@"\n"];
    [out writeToFile:@"/tmp/hideauto_classes.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"[HideAutomation] dumped %lu classes", (unsigned long)relevant.count);
}

// Catch any UILabel in the runner that shows "Automation" text.
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
        NSLog(@"[HideAutomation] banner label: %@", entry);
    }
    %orig;
}
%end

// Suppress any UIWindow with "Automation" or "Banner" in class name.
%hook UIWindow
- (void)setHidden:(BOOL)hidden {
    if (!hidden) {
        NSString *cls = NSStringFromClass(self.class);
        if ([cls containsString:@"Automation"] || [cls containsString:@"Banner"] ||
            [cls containsString:@"XCTest"]) {
            NSLog(@"[HideAutomation] suppressed window: %@", cls);
            return;
        }
    }
    %orig;
}
%end
