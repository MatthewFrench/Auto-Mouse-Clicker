//
//  AppDelegate.m
//  Fluffy Pug
//
//  Created by Matthew French on 5/25/15.
//  Copyright (c) 2015 Matthew French. All rights reserved.
//

#import "AppDelegate.h"

@interface WindowListApplierData : NSObject
{
}

@property (strong, nonatomic) NSMutableArray * outputArray;
@property int order;

@end

@implementation WindowListApplierData

-(instancetype)initWindowListData:(NSMutableArray *)array
{
    self = [super init];
    
    self.outputArray = array;
    self.order = 0;
    
    return self;
}

@end



@implementation AppDelegate

- (void)timerLogic {
    if (leagueGameState->leaguePID != -1) {
        if (difftime(time(0), lastTime) >= 9.0 && [autoTapTKey state] == NSOnState) {
            lastTime = time(0);
            tapTKey();
        }
    }
    if (difftime(time(0), windowLastTime) >= 4.0) {
        windowLastTime = time(0);
        [self updateWindowList];
    }
    
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [_window orderFront: nil];
    [NSApp activateIgnoringOtherApps:YES];
    
    
    [[NSProcessInfo processInfo] disableAutomaticTermination:@"Good Reason"];
    
    if ([[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)]) {
        self->_activity = [[NSProcessInfo processInfo] beginActivityWithOptions:0x00FFFFFF reason:@"receiving messages"];
    }
    
    // Insert code here to initialize your application
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0 //2000.0
                                             target:self
                                           selector:@selector(timerLogic)
                                           userInfo:nil
                                            repeats:YES];
    
    leagueGameState = new LeagueGameState();
    
    [self updateWindowList];
    lastTime = time(0);
    windowLastTime = time(0);
}








- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}
-(void)updateWindowList
{
    // Ask the window server for the list of windows.
    CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID);
    
    // Copy the returned list, further pruned, to another list. This also adds some bookkeeping
    // information to the list as well as
    NSMutableArray * prunedWindowList = [NSMutableArray array];
    WindowListApplierData *windowListData = [[WindowListApplierData alloc] initWindowListData:prunedWindowList];
    
    CFArrayApplyFunction(windowList, CFRangeMake(0, CFArrayGetCount(windowList)), &WindowListApplierFunction, (__bridge void *)(windowListData));
    CFRelease(windowList);
    
    //for (int i = 0; i < [prunedWindowList count]; i++) {
    //    NSLog(@"Data at %d is %@", i, [prunedWindowList objectAtIndex:i]);
    //}
    leagueGameState->leaguePID = -1;
    if ([prunedWindowList count] > 0) {
        NSDictionary* info = [prunedWindowList firstObject];
        NSNumber *pid = info[kAppPIDKey];
        leagueGameState->leaguePID = [pid intValue];
        NSNumber* xOrigin = info[kWindowOriginXKey];
        NSNumber* yOrigin = info[kWindowOriginYKey];
        NSNumber* width = info[kWindowWidthKey];
        NSNumber* height = info[kWindowHeightKey];
        leagueGameState->leagueSize = CGRectMake([xOrigin floatValue], [yOrigin floatValue], [width floatValue], [height floatValue]);
    }
}


#pragma mark Window List & Window Image Methods

NSString *kAppNameKey = @"applicationName";	// Application Name
NSString *kAppPIDKey = @"applicationPID";	// Application PID
NSString *kWindowOriginXKey = @"windowOriginX";
NSString *kWindowOriginYKey = @"windowOriginY";
NSString *kWindowWidthKey = @"windowWidth";
NSString *kWindowHeightKey = @"windowHeight";
NSString *kWindowIDKey = @"windowID";			// Window ID
NSString *kWindowLevelKey = @"windowLevel";	// Window Level
NSString *kWindowOrderKey = @"windowOrder";	// The overall front-to-back ordering of the windows as returned by the window server

void WindowListApplierFunction(const void *inputDictionary, void *context);
void WindowListApplierFunction(const void *inputDictionary, void *context)
{
    NSDictionary *entry = (__bridge NSDictionary*)inputDictionary;
    WindowListApplierData *data = (__bridge WindowListApplierData*)context;
    
    // The flags that we pass to CGWindowListCopyWindowInfo will automatically filter out most undesirable windows.
    // However, it is possible that we will get back a window that we cannot read from, so we'll filter those out manually.
    int sharingState = [entry[(__bridge id)kCGWindowSharingState] intValue];
    if(sharingState != kCGWindowSharingNone)
    {
        NSMutableDictionary *outputEntry = [NSMutableDictionary dictionary];
        // Grab the application name, but since it's optional we need to check before we can use it.
        NSString *applicationName = entry[(__bridge id)kCGWindowOwnerName];
        if(applicationName != NULL && [applicationName isEqualToString:@"League Of Legends"])
        {
            // PID is required so we assume it's present.
            //NSString *nameAndPID = [NSString stringWithFormat:@"%@ (%@)", applicationName, entry[(id)kCGWindowOwnerPID]];
            
            outputEntry[kAppNameKey] = applicationName;
        }
        else
        {
            return;
            // The application name was not provided, so we use a fake application name to designate this.
            // PID is required so we assume it's present.
            //NSString *nameAndPID = [NSString stringWithFormat:@"((unknown)) (%@)", entry[(id)kCGWindowOwnerPID]];
            //outputEntry[kAppNameKey] = @"unknown";
        }
        
        // Grab the Window Bounds, it's a dictionary in the array, but we want to display it as a string
        CGRect bounds;
        CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)entry[(__bridge id)kCGWindowBounds], &bounds);
        //NSString *originString = [NSString stringWithFormat:@"%.0f/%.0f", bounds.origin.x, bounds.origin.y];
        outputEntry[kWindowOriginXKey] = [NSNumber numberWithInt:bounds.origin.x];
        outputEntry[kWindowOriginYKey] = [NSNumber numberWithInt:bounds.origin.y];
        outputEntry[kAppPIDKey] = entry[(__bridge id)kCGWindowOwnerPID];
        
        //NSString *sizeString = [NSString stringWithFormat:@"%.0f*%.0f", bounds.size.width, bounds.size.height];
        //outputEntry[kWindowSizeKey] = sizeString;
        
        outputEntry[kWindowWidthKey] = [NSNumber numberWithDouble:bounds.size.width];
        outputEntry[kWindowHeightKey] = [NSNumber numberWithDouble:bounds.size.height];
        if (bounds.size.width < 30 || bounds.size.height < 30) {
            return;
        }
        
        // Grab the Window ID & Window Level. Both are required, so just copy from one to the other
        outputEntry[kWindowIDKey] = entry[(__bridge id)kCGWindowNumber];
        outputEntry[kWindowLevelKey] = entry[(__bridge id)kCGWindowLayer];
        
        // Finally, we are passed the windows in order from front to back by the window server
        // Should the user sort the window list we want to retain that order so that screen shots
        // look correct no matter what selection they make, or what order the items are in. We do this
        // by maintaining a window order key that we'll apply later.
        outputEntry[kWindowOrderKey] = @(data.order);
        data.order++;
        
        [data.outputArray addObject:outputEntry];
    }
}


@end
