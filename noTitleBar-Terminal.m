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
        [NSClassFromString(@"TTTabView")
            jr_swizzleMethod:@selector(contentRect)
                withMethod:@selector(noTitleBar_contentRect)
                    error:NULL];
        [NSClassFromString(@"TTTabView")
            jr_swizzleMethod:@selector(contentSizeForFrameSize:)
                withMethod:@selector(noTitleBar_contentSizeForFrameSize:)
                    error:NULL];
        [NSClassFromString(@"TTTabView")
            jr_swizzleMethod:@selector(frameSizeForContentSize:)
                withMethod:@selector(noTitleBar_frameSizeForContentSize:)
                    error:NULL];
        [NSClassFromString(@"TTSplitView")
            jr_swizzleMethod:@selector(contentSizeForLogicalContentSize:)
                withMethod:@selector(noTitleBar_contentSizeForLogicalContentSize:)
                    error:NULL];
        [NSClassFromString(@"TTSplitView")
            jr_swizzleMethod:@selector(windowWillChangeFullScreen:)
                withMethod:@selector(noTitleBar_windowWillChangeFullScreen:)
                    error:NULL];
        [NSClassFromString(@"TTSplitView")
            jr_swizzleMethod:@selector(viewDidMoveToWindow)
                withMethod:@selector(noTitleBar_viewDidMoveToWindow)
                    error:NULL];
        [NSClassFromString(@"TTWindowController")
            jr_swizzleMethod:@selector(contentSize)
                withMethod:@selector(noTitleBar_contentSize)
                    error:NULL];
        [NSClassFromString(@"TTWindowController")
            jr_swizzleMethod:@selector(tabView:didSelectTabViewItem:)
                withMethod:@selector(noTitleBar_tabView:didSelectTabViewItem:)
                    error:NULL];
        [NSClassFromString(@"TTWindowController")
            jr_swizzleMethod:@selector(tabView:didCloseTabViewItem:)
                withMethod:@selector(noTitleBar_tabView:didCloseTabViewItem:)
                    error:NULL];
        [NSClassFromString(@"TTWindowController")
            jr_swizzleMethod:@selector(makeTabWithProfile:customFont:command:runAsShell:restorable:workingDirectory:sessionClass:restoreSession:)
                withMethod:@selector(noTitleBar_makeTabWithProfile:customFont:command:runAsShell:restorable:workingDirectory:sessionClass:restoreSession:)
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
    //     // Add padding around terminal view
    NSView *contentView = terminalWindow.contentView;
    NSView *tabView = [contentView subviews][0];
    NSView *splitView = [tabView subviews][1];
    TTPane *paneView = [splitView subviews][0];
    id bgColor = [[[paneView view] profile] valueForKey:@"BackgroundColor"];

    NSRect framewanted;
    framewanted.origin.x = 0;
    framewanted.origin.y = terminalWindow.frame.size.height - 22;
    framewanted.size.width = terminalWindow.frame.size.width;
    framewanted.size.height = 22;
    NSView *testview = [[NSView alloc] initWithFrame:framewanted];
    [testview setWantsLayer:YES];
    [testview setAutoresizingMask:NSViewMinYMargin | NSViewMaxXMargin | NSViewWidthSizable | NSViewMinXMargin];
    [testview.layer setBackgroundColor:[bgColor CGColor]];
    testview.layer.cornerRadius = 5.0;
    [terminalWindow.contentView.superview addSubview:testview positioned:NSWindowAbove relativeTo:nil];
    framewanted.origin.x = 0;
    framewanted.origin.y = terminalWindow.frame.size.height - 22;
    framewanted.size.width = terminalWindow.frame.size.width;
    framewanted.size.height = 5;
    NSView *testview2 = [[NSView alloc] initWithFrame:framewanted];
    [testview2 setWantsLayer:YES];
    [testview2 setAutoresizingMask:NSViewMinYMargin | NSViewMaxXMargin | NSViewWidthSizable | NSViewMinXMargin];
    [testview2.layer setBackgroundColor:[bgColor CGColor]];
    [terminalWindow.contentView.superview addSubview:testview2 positioned:NSWindowAbove relativeTo:nil];

    NSResponder *savedResponder = terminalWindow.firstResponder;
    terminalWindow.styleMask = (NSClosableWindowMask |
            NSMiniaturizableWindowMask |
            NSResizableWindowMask |
            NSTitledWindowMask);

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
    NSView *contentView = terminalWindow.contentView;
    NSView *tabView = [contentView subviews][0];
    NSView *splitView = [tabView subviews][1];
    TTPane *paneView = [splitView subviews][0];
    id bgColor = [[[paneView view] profile] valueForKey:@"BackgroundColor"];
    terminalWindow.backgroundColor = bgColor;


    NSRect contentViewFrame = CGRectInset(contentView.superview.bounds, HMARGIN, VMARGIN);
    [contentView setFrame:NSMakeRect(contentViewFrame.origin.x,
            contentViewFrame.origin.y - 1, contentViewFrame.size.width,
            contentViewFrame.size.height + 20)];
    NSRect tabViewFrame = CGRectInset(tabView.superview.bounds, HMARGIN, VMARGIN);
    [tabView setFrame:NSMakeRect(tabViewFrame.origin.x - HMARGIN,
            tabViewFrame.origin.y - (VMARGIN + VCENTERING - 1),
            tabViewFrame.size.width, tabViewFrame.size.height + 20)];
    NSRect tabViewBounds = [tabView bounds];
    [tabView setBoundsOrigin:NSMakePoint(tabViewBounds.origin.x, tabViewBounds.origin.y - VCENTERING)];
}

+ (void)resetPadding:(NSWindow *)terminalWindow {
    NSView *contentView = terminalWindow.contentView;
    NSView *tabView = [contentView subviews][0];
    [contentView setFrame:contentView.superview.bounds];
    [tabView setFrame:tabView.superview.bounds];
    NSRect test3 = [tabView bounds];
    [tabView setBoundsOrigin:NSMakePoint(test3.origin.x, test3.origin.y + VCENTERING)];
}

+ (void)restoreSize:(NSWindow *)terminalWindow fromFullScreen:(BOOL)fullscreen{
    int scalingFactor = 2;
    BOOL animate = YES;
    if (fullscreen) {
        scalingFactor = 4;
        animate = YES;
    }

    NSRect oldFrame = terminalWindow.frame;
    oldFrame.size.width += HMARGIN * scalingFactor;
    oldFrame.size.height += VMARGIN * scalingFactor;
    oldFrame.origin.y -= VMARGIN * scalingFactor;
    [terminalWindow setFrame:oldFrame display:YES animate:animate];
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
            [noTitleBarTerminal restoreSize:possibleWindow fromFullScreen:NO];
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

/*
 * Setup padding and window customization for newly created windows
 */
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
    [noTitleBarTerminal restoreSize:winController.window fromFullScreen:NO];
    return winController;
}

@end

@implementation NSView(TTSplitView)

- (struct CGSize)noTitleBar_contentSizeForLogicalContentSize:(NSSize)size {
    NSSize test = [self noTitleBar_contentSizeForLogicalContentSize:size];
    /* test.height -= 40; */
    return test;
}

/*
 * Terminal window don't register for NSWindowDidExitFullScreenNotification so we
 * do it manually
 */
- (void)noTitleBar_viewDidMoveToWindow {
    [self noTitleBar_viewDidMoveToWindow];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillChangeFullScreen:) name:NSWindowDidExitFullScreenNotification object:[self window]];
}

/*
 * Reset padding and window customization when going fullscreen,
 * restore padding, window customization and size when going back to standard window
 */
- (void)noTitleBar_windowWillChangeFullScreen:(NSNotification *)notif {
    [self noTitleBar_windowWillChangeFullScreen:notif];
    if ([notif.name isEqualToString:NSWindowDidEnterFullScreenNotification]) {
        [noTitleBarTerminal resetPadding:notif.object];
        [noTitleBarTerminal showTitleBar:notif.object];
    }
    else if ([notif.name isEqualToString:NSWindowDidExitFullScreenNotification]) {
        [noTitleBarTerminal setUpPadding:notif.object];
        [noTitleBarTerminal setUpWindow:notif.object];
        [noTitleBarTerminal hideTitleBar:notif.object];
        [noTitleBarTerminal restoreSize:notif.object fromFullScreen:YES];
    }
}

@end

@implementation NSView(TTTabView)
- (struct CGRect)noTitleBar_contentRect {
    NSRect rect = [self noTitleBar_contentRect];
    /* rect.origin.y -= 20; */
    /* rect.size.height -= 120; */
    return rect;
}
@end

@implementation NSWindowController(TTWindowController)

- (struct CGSize)noTitleBar_contentSize {
    NSSize test = [self noTitleBar_contentSize];
    /* test.height += 50; */
    /* NSLog(@"PROVIAO dhdh"); */
    return test;
}


/*
 * Update the window color of the newly selected tabView to match with that view
 * background
 */
- (void)noTitleBar_tabView:(id)tabView didSelectTabViewItem:(TTTabViewItem *)tabViewItem {
    [self noTitleBar_tabView:tabView didSelectTabViewItem:tabViewItem];
    if(tabView) {
        id bgColor = [[[[[tabViewItem tabController] activePane] view] profile] valueForKey:@"BackgroundColor"];
        NSWindow *terminalWindow = [[[tabViewItem tabController] windowController] window];
        terminalWindow.backgroundColor = bgColor;
    }
}

/*
 * When tab bar appears or disappears we want to trigger a frame recalculation
 * to keep window the same size after all the padding changes. We creating a new
 * tab we also want to update the background color of the underlying window, since
 * didSelectTabViewItem: isn't triggered in that case
 */
- (void)noTitleBar_tabView:(id)tabView didCloseTabViewItem:(TTTabViewItem *)tabViewItem {
    [self noTitleBar_tabView:tabView didCloseTabViewItem:tabViewItem];
    if ((int)[tabView numberOfTabViewItems] == 1) {
        [noTitleBarTerminal restoreSize:[self window] fromFullScreen:NO];
    }
}

- (id)noTitleBar_makeTabWithProfile:(id) profile
                           customFont:(id) font
                              command:(id) command
                           runAsShell:(BOOL) runAsShell
                           restorable:(BOOL) restorable
                     workingDirectory:(id) workingDirectory
                         sessionClass:(id) sessionClass
                       restoreSession:(id) restoreSession
{
    id tab = [self noTitleBar_makeTabWithProfile:profile
                                      customFont:font
                                         command:command
                                      runAsShell:runAsShell
                                      restorable:restorable
                                workingDirectory:workingDirectory
                                    sessionClass:sessionClass
                                  restoreSession:restoreSession];
    id bgColor = [profile valueForKey:@"BackgroundColor"];
    NSWindow *terminalWindow = [self window];
    NSView *contentView = terminalWindow.contentView;
    NSView *tabView = [contentView subviews][0];
    terminalWindow.backgroundColor = bgColor;
    if(((int)[tabView numberOfTabViewItems]) == 2)
        [noTitleBarTerminal restoreSize:terminalWindow fromFullScreen:NO];
    else {
        NSRect rect = terminalWindow.frame;
        rect.size.width += 1;
        [terminalWindow setFrame:rect display:YES animate:YES];
    }
    return tab;
}

@end

@implementation NSTabViewItem(TTTabViewItem)

/*
 * Active tabViewItem has a transparent background and so uses
 * window default bg. Since we change the window color to support
 * padding, the tabView item would look bad, so we redraw it. This
 * isn't a complete reversing of the function, some functionalities
 * are missing like close button or activity indicator
 */
- (void)noTitleBar_drawTabViewItem:(NSRect)item {
    [self noTitleBar_drawTabViewItem:item];
    if (![self tabState]) {
        // fill bg
        [[NSColor ACTIVE_TAB_COLOR] set];
        NSRectFill(item);
        // topBorder rect bg
        NSRect border;
        border.origin.x    = item.origin.x;
        border.origin.y    = item.origin.y + item.size.height - 1;
        border.size.width  = item.size.width;
        border.size.height = 1;
        [[NSColor ACTIVE_TAB_COLOR_BORDER_TOP] set];
        NSRectFill(border);
        // botBorder rect bg
        border.origin.y    = item.origin.y;
        [[NSColor ACTIVE_TAB_COLOR_BORDER_BOT] set];
        NSRectFill(border);
        // label rect
        NSRect label;
        label.origin.x    = item.origin.x;
        label.origin.y    = item.origin.y - 4;
        label.size.width  = item.size.width;
        label.size.height = item.size.height;
        objc_msgSend(self, @selector(_drawLabel:), label);
    }
}

@end
