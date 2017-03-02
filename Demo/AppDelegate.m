#import "AppDelegate.h"

extern void SACLockScreenImmediate();

static NSString *const MASCustomShortcutKey = @"customShortcut";
static NSString *const MASCustomShortcutEnabledKey = @"customShortcutEnabled";
static NSString *const MASHardcodedShortcutEnabledKey = @"hardcodedShortcutEnabled";

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

	// Most apps need default shortcut, delete these lines if this is not your case
	MASShortcut *firstLaunchShortcut = [MASShortcut shortcutWithKeyCode:kVK_Escape modifierFlags:NSEventModifierFlagCommand];
	NSData *firstLaunchShortcutData = [NSKeyedArchiver archivedDataWithRootObject:firstLaunchShortcut];

    // Register default values to be used for the first app start
    [defaults registerDefaults:@{
        MASCustomShortcutEnabledKey : @YES,
		MASCustomShortcutKey : firstLaunchShortcutData
    }];

    // Bind the shortcut recorder view’s value to user defaults.
    // Run “defaults read com.shpakovski.mac.Demo” to see what’s stored
    // in user defaults.
    [_customShortcutView setAssociatedUserDefaultsKey:MASCustomShortcutKey];

    // Enable or disable the recorder view according to the first checkbox state
    [_customShortcutView bind:@"enabled" toObject:defaults
        withKeyPath:MASCustomShortcutEnabledKey options:nil];

    // Watch user defaults for changes in the checkbox states
    [defaults addObserver:self forKeyPath:MASCustomShortcutEnabledKey
        options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
        context:MASObservingContext];

    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    self.statusBar.title = @"L";

    // you can also set an image
    //self.statusBar.image =

    self.statusBar.menu = self.menu;
    self.statusBar.highlightMode = YES;
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

// Handle changes in user defaults. We have to check keyPath here to see which of the
// two checkboxes was changed. This is not very elegant, in practice you could use something
// like https://github.com/facebook/KVOController with a nicer API.
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
