//
//  noTitleBar-Terminal.m
//  noTitleBar-Terminal
//
//  Created by Enrico "cHoco" Ghirardi on 23/12/15.
//  Copyright (c) 2015 cHoco. All rights reserved.
//

#import "noTitleBar-Terminal.h"
#import "JRSwizzle/JRSwizzle.h"
#import <objc/objc-class.h>

@implementation noTitleBarTerminal

+ (void)load {
    [NSClassFromString(@"TTWindow")
        jr_swizzleMethod:@selector(initWithContentRect:styleMask:backing:defer:)
              withMethod:@selector(noTitleBar_initWithContentRect:styleMask:backing:defer:)
                   error:NULL];
    [NSClassFromString(@"TTWindow")
        jr_swizzleMethod:@selector(canBecomeKeyWindow)
              withMethod:@selector(noTitleBar_canBecomeKeyWindow)
                   error:NULL];
    [NSClassFromString(@"TTWindow")
        jr_swizzleMethod:@selector(canBecomeMainWindow)
              withMethod:@selector(noTitleBar_canBecomeMainWindow)
                   error:NULL];
    [NSClassFromString(@"TTWindow")
        jr_swizzleMethod:@selector(performClose:)
              withMethod:@selector(noTitleBar_performClose:)
                   error:NULL];
    [self updateWindows];
}

/*
 * Remove the titlebars of already created windows, since our bundle will
 * probably be loaded after the first window is created (SIMBL limitation)
 */
+ (void)updateWindows {
    Class windowMetaClass = NSClassFromString(@"TTWindow");
    Class applicationMetaClass = NSClassFromString(@"TTApplication");
    id currentApp = [applicationMetaClass sharedApplication];
    NSArray *windows = [currentApp windows];
    for (id possibleWindow in windows) {
        if ([possibleWindow  isKindOfClass:windowMetaClass]) {
            // This was a nightmare to debug... for some reason changing the
            // styleMask of a window also changes the firstResponder, losing
            // keyboard focus. We just save and restore it!
            id savedResponder = [possibleWindow firstResponder];
            [possibleWindow setStyleMask:(NSClosableWindowMask |
                    NSMiniaturizableWindowMask |
                    NSResizableWindowMask |
                    NSTexturedBackgroundWindowMask)];
            [possibleWindow makeFirstResponder:savedResponder];
        }
    }
}

@end

@implementation NSWindow(TTWindow)

/*
 * The 3 following methods must be added because Cocoa doesn't give focus and
 * main window status if the window doesn't have a title bar.
 * The first two are well documented around the web but the third one is
 * necessary to keep Command-W shortucut to close a window since it's disabled
 * without a titlebar
 */
- (BOOL)noTitleBar_canBecomeKeyWindow {
    return YES;
}

- (BOOL)noTitleBar_canBecomeMainWindow {
    return YES;
}

- (void)noTitleBar_performClose:(id)sender {
    BOOL shouldClose = YES;

    if ([[self delegate] respondsToSelector:@selector(windowShouldClose:)]) {
        shouldClose = [(id)[self delegate] windowShouldClose:sender];
    }
    if (shouldClose) {
        [self close];
    }
}

- (id)noTitleBar_initWithContentRect:(CGRect)rect
                           styleMask:(unsigned long long)style
                             backing:(unsigned long long)backing
                               defer:(char)defer
{
    return [self noTitleBar_initWithContentRect:rect
                                           styleMask:(NSClosableWindowMask |
                                                   NSMiniaturizableWindowMask |
                                                   NSResizableWindowMask |
                                                   NSTexturedBackgroundWindowMask)
                                           backing:backing
                                             defer:defer];
}

@end
