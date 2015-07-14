//
//  AppDelegate.h
//  Fluffy Pug
//
//  Created by Matthew French on 5/25/15.
//  Copyright (c) 2015 Matthew French. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LeagueGameState.h"
#import <time.h>
#import "InteractiveEvents.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSTimer* timer;
    LeagueGameState* leagueGameState;
    
    IBOutlet NSButton* autoTapTKey;
    
    time_t lastTime, windowLastTime;
}

@property (strong) id activity;
@property (weak) IBOutlet NSWindow *window;
- (void)timerLogic;

@end

