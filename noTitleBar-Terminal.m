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

#define HMARGIN 16.0
#define VMARGIN 16.0
#define VCENTERING VMARGIN/4
#define ACTIVE_TAB_COLOR                colorWithRed:0.988 green:0.333 blue:0.333 alpha:1
#define ACTIVE_TAB_COLOR_BORDER_TOP     colorWithRed:0.722 green:0.157 blue:0.157 alpha:1
#define ACTIVE_TAB_COLOR_BORDER_BOT     colorWithRed:0.957 green:0.443 blue:0.443 alpha:1

@implementation noTitleBarTerminal

+ (void)load {
    [self sharedInstance];
    [self updateWindows];
}

+ (noTitleBarTerminal *)sharedInstance {
    static noTitleBarTerminal *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (noTitleBarTerminal *)init {
    if (self = [super init]) {
        [NSClassFromString(@"TTWindow")
            jr_swizzleMethod:@selector(validateMenuItem:)
                withMethod:@selector(noTitleBar_validateMenuItem:)
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
        [NSClassFromString(@"TTWindow")
            jr_swizzleMethod:@selector(performMiniaturize:)
                withMethod:@selector(noTitleBar_performMiniaturize:)
                    error:NULL];
        [NSClassFromString(@"TTApplication")
            jr_swizzleMethod:@selector(makeWindowControllerWithProfile:customFont:command:runAsShell:restorable:workingDirectory:)
                withMethod:@selector(noTitleBar_makeWindowControllerWithProfile:customFont:command:runAsShell:restorable:workingDirectory:)
                    error:NULL];
        [NSClassFromString(@"TTSplitView")
            jr_swizzleMethod:@selector(windowWillChangeFullScreen:)
                withMethod:@selector(noTitleBar_windowWillChangeFullScreen:)
                    error:NULL];
        [NSClassFromString(@"TTSplitView")
            jr_swizzleMethod:@selector(viewDidMoveToWindow)
                withMethod:@selector(noTitleBar_viewDidMoveToWindow)
                    error:NULL];
        [NSClassFromString(@"TTTabController")
            jr_swizzleMethod:@selector(setActivePane:)
                  withMethod:@selector(noTitleBar_setActivePane:)
                    error:NULL];
        [NSClassFromString(@"TTTabView")
            jr_swizzleMethod:@selector(selectTabViewItem:)
                  withMethod:@selector(noTitleBar_selectTabViewItem:)
                    error:NULL];
        [NSClassFromString(@"TTTabViewItem")
            jr_swizzleMethod:@selector(drawTabViewItem:)
                  withMethod:@selector(noTitleBar_drawTabViewItem:)
                    error:NULL];
    }
    return self;
}

+ (void)setUpWindow:(NSWindow *)terminalWindow {
    // This was a nightmare to debug... for some reason changing the
    // styleMask of a window also changes the firstResponder, losing
    // keyboard focus. We just save and restore it!
    NSResponder *savedResponder = terminalWindow.firstResponder;
    terminalWindow.styleMask = (NSClosableWindowMask |
            NSMiniaturizableWindowMask |
            NSResizableWindowMask |
            NSTitledWindowMask |
            NSFullSizeContentViewWindowMask);
    terminalWindow.movableByWindowBackground = YES;
    [terminalWindow makeFirstResponder:savedResponder];
}

+ (void)hideTitleBar:(NSWindow *)terminalWindow {
    terminalWindow.titlebarAppearsTransparent = YES;
    terminalWindow.titleVisibility = NSWindowTitleHidden;
    terminalWindow.showsToolbarButton = NO;
    [[terminalWindow standardWindowButton:NSWindowCloseButton] setHidden:YES];
    [[terminalWindow standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
    [[terminalWindow standardWindowButton:NSWindowZoomButton] setHidden:YES];
}

+ (void)showTitleBar:(NSWindow *)terminalWindow {
    terminalWindow.titlebarAppearsTransparent = NO;
    terminalWindow.titleVisibility = NSWindowTitleVisible;
    terminalWindow.showsToolbarButton = YES;
    [[terminalWindow standardWindowButton:NSWindowCloseButton] setHidden:NO];
    [[terminalWindow standardWindowButton:NSWindowMiniaturizeButton] setHidden:NO];
    [[terminalWindow standardWindowButton:NSWindowZoomButton] setHidden:NO];
}

+ (void)setUpPadding:(NSWindow *)terminalWindow {
    // Add padding around terminal view
    NSRect saved = terminalWindow.frame;
    NSView *contentView = terminalWindow.contentView;
    NSView *tabView = [contentView subviews][0];
    NSView *splitView = [tabView subviews][1];
    NSView *paneView = [splitView subviews][0];
    id bgColor = [[[paneView view] profile] valueForKey:@"BackgroundColor"];
    terminalWindow.backgroundColor = bgColor;

    NSRect test = CGRectInset(contentView.superview.bounds, HMARGIN, VMARGIN);
    [contentView setFrame:NSMakeRect(test.origin.x, test.origin.y - 1, test.size.width, test.size.height)];
    NSRect test2 = CGRectInset(tabView.superview.bounds, HMARGIN, VMARGIN);
    [tabView setFrame:NSMakeRect(test2.origin.x - HMARGIN, test2.origin.y - (VMARGIN + VCENTERING - 1), test2.size.width, test2.size.height)];
    NSRect test3 = [tabView bounds];
    [tabView setBoundsOrigin:NSMakePoint(test3.origin.x, test3.origin.y - VCENTERING)];
}

+ (void)resetPadding:(NSWindow *)terminalWindow {
    NSView *contentView = terminalWindow.contentView;
    NSView *tabView = [contentView subviews][0];
    [contentView setFrame:contentView.superview.bounds];
    [tabView setFrame:tabView.superview.bounds];
    NSRect test3 = [tabView bounds];
    [tabView setBoundsOrigin:NSMakePoint(test3.origin.x, test3.origin.y + VCENTERING)];
}

/*
 * Setup already created windows, since our bundle will
 * probably be loaded after the first window is created (SIMBL limitation)
 */
+ (void)updateWindows {
    Class windowMetaClass = NSClassFromString(@"TTWindow");
    Class applicationMetaClass = NSClassFromString(@"TTApplication");
    id currentApp = [applicationMetaClass sharedApplication];
    NSArray *windows = [currentApp windows];
    for (id possibleWindow in windows) {
        if ([possibleWindow  isKindOfClass:windowMetaClass]) {
            [noTitleBarTerminal setUpPadding:possibleWindow];
            [noTitleBarTerminal setUpWindow:possibleWindow];
            [noTitleBarTerminal hideTitleBar:possibleWindow];
            NSView *contentView = [possibleWindow contentView];
            NSView *tabView = [contentView subviews][0];
            NSView *splitView = [tabView subviews][1];
            [[NSNotificationCenter defaultCenter] addObserver:splitView selector:@selector(windowWillChangeFullScreen:) name:NSWindowDidExitFullScreenNotification object:[splitView window]];
        }
    }
}

@end

@implementation NSWindow(TTWindow)

/*
 * The 5 following methods must be added because Cocoa doesn't give focus and
 * main window status if the window doesn't have a title bar and disables some
 * menu items.
 * The first two are well documented around the web but the other ones are
 * necessary to restore some menu items that get deactivated.
 */
- (BOOL)noTitleBar_canBecomeKeyWindow {
    return YES;
}

- (BOOL)noTitleBar_canBecomeMainWindow {
    return YES;
}

- (BOOL)noTitleBar_validateMenuItem:(NSMenuItem *)menuItem {
    return ([menuItem action] == @selector(performClose:) ||
            [menuItem action] == @selector(performMiniaturize:)) ? YES :
        [self noTitleBar_validateMenuItem:menuItem];
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

- (void)noTitleBar_performMiniaturize:(id)sender {
    [self miniaturize:self];
}

@end

@implementation NSApplication(TTApplication)

- (NSWindowController *)noTitleBar_makeWindowControllerWithProfile:(id)profile
                                customFont:(id)font
                                   command:(id)command
                                runAsShell:(BOOL)a
                                restorable:(BOOL)b
                          workingDirectory:(NSString *)dir
{
    NSWindowController *winController = [self noTitleBar_makeWindowControllerWithProfile:profile
                                                                              customFont:font
                                                                                 command:command
                                                                              runAsShell:a
                                                                              restorable:b
                                                                        workingDirectory:dir];
    [noTitleBarTerminal setUpPadding:winController.window];
    [noTitleBarTerminal setUpWindow:winController.window];
    [noTitleBarTerminal hideTitleBar:winController.window];
    return winController;
}

@end

@implementation NSView(TTSplitView)

- (void)noTitleBar_viewDidMoveToWindow {
    [self noTitleBar_viewDidMoveToWindow];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillChangeFullScreen:) name:NSWindowDidExitFullScreenNotification object:[self window]];
}

- (void)noTitleBar_windowWillChangeFullScreen:(NSNotification *)notif {
    NSLog(@"Test %@", notif);
    if ([notif.name isEqualToString:NSWindowDidEnterFullScreenNotification]) {
        [noTitleBarTerminal resetPadding:notif.object];
        [noTitleBarTerminal showTitleBar:notif.object];
    }
    else if ([notif.name isEqualToString:NSWindowDidExitFullScreenNotification]) {
        [noTitleBarTerminal setUpPadding:notif.object];
        [noTitleBarTerminal setUpWindow:notif.object];
        [noTitleBarTerminal hideTitleBar:notif.object];
    }
    [self noTitleBar_windowWillChangeFullScreen:notif];
}

@end

@implementation NSObject(TTTabController)

- (void)noTitleBar_setActivePane:(id)pane {
    id bgColor = [[[pane view] profile] valueForKey:@"BackgroundColor"];
    NSWindow *terminalWindow = [[self windowController] window];
    terminalWindow.backgroundColor = bgColor;
    [self noTitleBar_setActivePane:pane];
}

@end

@implementation NSObject(TTTabView)

- (void)noTitleBar_selectTabViewItem:(id)item {
    id bgColor = [[[[[item tabController] activePane] view] profile] valueForKey:@"BackgroundColor"];
    NSWindow *terminalWindow = [[[item tabController] windowController] window];
    terminalWindow.backgroundColor = bgColor;
    [self noTitleBar_selectTabViewItem:item];
}

@end

@implementation NSObject(TTTabViewItem)

- (void)noTitleBar_drawTabViewItem:(NSRect)item {
    [self noTitleBar_drawTabViewItem:item];
    if (![self tabState]) {
        [[NSColor ACTIVE_TAB_COLOR] set];
        NSRect test = [(NSView *)[self tabView] bounds];
        NSRect rect1, rect2;
        rect1.origin.x    = item.origin.x;
        rect1.origin.y    = item.origin.y - 4;
        rect1.size.width  = item.size.width;
        rect1.size.height = item.size.height;
        rect2.origin.x    = item.origin.x;
        rect2.origin.y    = item.origin.y + item.size.height - 1;
        rect2.size.width  = item.size.width;
        rect2.size.height = 1;
        NSRectFill(item);
        [[NSColor ACTIVE_TAB_COLOR_BORDER_TOP] set];
        NSRectFill(rect2);
        rect2.origin.y    = item.origin.y;
        [[NSColor ACTIVE_TAB_COLOR_BORDER_BOT] set];
        NSRectFill(rect2);
        [self _drawLabel:rect1];
    }
}

@end
