#import "AppDelegate.h"

extern void SACLockScreenImmediate();

static NSString *const MASCustomShortcutKey = @"customShortcut";
static NSString *const MASCustomShortcutEnabledKey = @"customShortcutEnabled";

static void *MASObservingContext = &MASObservingContext;

@interface AppDelegate ()
@property (unsafe_unretained) IBOutlet NSWindow *preferenceWindow;
@property(strong) IBOutlet MASShortcutView *customShortcutView;
@property(unsafe_unretained) IBOutlet NSMenu *menu;
@end

@implementation AppDelegate

- (void) awakeFromNib
{
    [super awakeFromNib];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    BOOL showPrefs = [defaults objectForKey:MASCustomShortcutKey] == nil;

    if (showPrefs) {
        MASShortcut *firstLaunchShortcut = [MASShortcut shortcutWithKeyCode:kVK_Escape modifierFlags:NSEventModifierFlagCommand];
        NSData *firstLaunchShortcutData = [NSKeyedArchiver archivedDataWithRootObject:firstLaunchShortcut];

        [defaults registerDefaults:@{
                MASCustomShortcutEnabledKey : @YES,
                MASCustomShortcutKey : firstLaunchShortcutData
        }];
    }

    [_customShortcutView setAssociatedUserDefaultsKey:MASCustomShortcutKey];

    [defaults addObserver:self forKeyPath:MASCustomShortcutEnabledKey
        options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
        context:MASObservingContext];

    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusBar.title = @"\U0001F512";
    self.statusBar.menu = self.menu;
    self.statusBar.highlightMode = YES;

    if (showPrefs) {
       [self showPreferences:nil];
    }
}

- (IBAction)lockComputer:(id)sender
{
    if (_preferenceWindow.visible) {
        [_preferenceWindow setIsVisible:NO];
    }
    SACLockScreenImmediate();
}

- (IBAction)showPreferences:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
    [_preferenceWindow makeKeyAndOrderFront:sender];
}

- (void) observeValueForKeyPath: (NSString*) keyPath ofObject: (id) object change: (NSDictionary*) change context: (void*) context
{
    if (context != MASObservingContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    [[MASShortcutBinder sharedBinder] bindShortcutWithDefaultsKey:MASCustomShortcutKey toAction:^{
        [self lockComputer:nil];
    }];
}

#pragma mark NSApplicationDelegate

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication*) sender
{
    return NO;
}

@end
