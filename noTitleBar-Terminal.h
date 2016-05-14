//
//  noTitleBar-Terminal.h
//  noTitleBar-Terminal
//
//  Created by Enrico "cHoco" Ghirardi on 23/12/15.
//  Copyright (c) 2015 cHoco. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface noTitleBarTerminal : NSObject

+ (void)setUpWindow:(NSWindow *)terminalWindow;
+ (void)hideTitleBar:(NSWindow *)terminalWindow;
+ (void)showTitleBar:(NSWindow *)terminalWindow;
+ (void)setUpPadding:(NSWindow *)terminalWindow;
+ (void)resetPadding:(NSWindow *)terminalWindow;
+ (void)restoreSize:(NSWindow *)terminalWindow fromFullScreen:(BOOL)fullscreen;

@end

@interface TTView : NSView
- (id)profile;
@end

@interface TTPane : NSView
- (id)view;
@end

@interface TTTabController : NSObject
- (id)activePane;
- (id)windowController;
@end

@interface TTTabViewItem : NSTabViewItem
- (BOOL)tabState;
- (TTTabController *)tabController;
- (NSView *)tabView;
- (void)_drawLabel:(struct CGRect)rect;
@end
