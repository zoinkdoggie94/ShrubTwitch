// ShrubTwitch native extras. Local-only data; no service, trackers or background polling.
#import "Settings/st-features.h"
#import "Core/tpK-channel-resolver.h"
#import "Chat/tpK-chat-appearance-config.h"
#import "UI/tpK-oled-mode.h"

static NSString *const STBookmarksKey = @"shrub_bookmarks_12";
static NSString *const STNotesKey = @"shrub_channel_notes_12";
static NSString *const STProfilesKey = @"shrub_channel_profiles_12";
static NSString *const STFocusEnabledKey = @"shrub_focus_enabled";
static NSString *const STFocusKeywordsKey = @"shrub_focus_keywords";

static NSUserDefaults *STDefaults(void) { return NSUserDefaults.standardUserDefaults; }
static UIColor *STAccent(void) { return [UIColor colorWithRed:.38 green:.92 blue:.55 alpha:1]; }
static NSString *STChannel(void) {
    TPKChannelContext *context = TPKCurrentChannelContext();
    NSString *name = context.channelName.length ? context.channelName : context.displayName;
    // Reject non-channel placeholder strings, as these are used in URLs and keys.
    if (![name isKindOfClass:NSString.class]) return nil;
    name = name.lowercaseString;
    NSCharacterSet *invalid = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789_"] invertedSet];
    if (!name.length || name.length > 45 || [name rangeOfCharacterFromSet:invalid].location != NSNotFound) return nil;
    return name;
}
static NSMutableDictionary *STDictionary(NSString *key) {
    NSDictionary *value = [STDefaults() dictionaryForKey:key];
    return value ? [value mutableCopy] : [NSMutableDictionary dictionary];
}
static NSMutableArray<NSString *> *STBookmarks(void) {
    NSArray *saved = [STDefaults() arrayForKey:STBookmarksKey];
    NSMutableArray *out = [NSMutableArray array];
    for (id value in saved) if ([value isKindOfClass:NSString.class]) [out addObject:value];
    return out;
}
static void STSaveBookmark(NSString *name) {
    if (!name.length) return;
    NSMutableArray *bookmarks = STBookmarks();
    if (![bookmarks containsObject:name]) [bookmarks insertObject:name atIndex:0];
    [STDefaults() setObject:bookmarks forKey:STBookmarksKey];
}
static void STShowAlert(UIViewController *presenter, NSString *title, NSString *message) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [presenter presentViewController:alert animated:YES completion:nil];
}
static void STSetProfile(NSString *channel, NSString *preset) {
    if (!channel.length) return;
    NSMutableDictionary *profiles = STDictionary(STProfilesKey);
    if (preset.length) profiles[channel] = preset;
    else [profiles removeObjectForKey:channel];
    [STDefaults() setObject:profiles forKey:STProfilesKey];
}
static void STApplyChannelProfile(void) {
    NSString *channel = STChannel();
    if (!channel.length) return;
    NSString *preset = STDictionary(STProfilesKey)[channel];
    if (![preset isKindOfClass:NSString.class]) return;
    TPKChatAppearanceConfig *config = [TPKChatAppearanceConfig sharedConfig];
    if ([preset isEqualToString:@"compact"]) {
        if (config.messageFontSize != 13.0) config.messageFontSize = 13.0;
        if (config.lineSpacing != 0.0) config.lineSpacing = 0.0;
    } else if ([preset isEqualToString:@"comfortable"]) {
        if (config.messageFontSize != 17.0) config.messageFontSize = 17.0;
        if (config.lineSpacing != 4.0) config.lineSpacing = 4.0;
    }
}
void STSetupChannelProfiles(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // Follow the existing channel resolver; do not inject another Twitch hook.
        [NSNotificationCenter.defaultCenter addObserverForName:TPKChannelResolverDidChangeNotification
            object:[TPKChannelResolver sharedResolver] queue:NSOperationQueue.mainQueue
            usingBlock:^(NSNotification *note) { STApplyChannelProfile(); }];
        STApplyChannelProfile();
    });
}
static void STEditNote(UIViewController *presenter) {
    NSString *channel = STChannel();
    if (!channel) { STShowAlert(presenter, @"No active channel", @"Open a stream first, then return here to write a channel note."); return; }
    NSMutableDictionary *notes = STDictionary(STNotesKey);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Note: %@",channel]
        message:@"Private note stored on this device." preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"Your note";
        field.text = [notes[channel] isKindOfClass:NSString.class] ? notes[channel] : @"";
        field.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *value = alert.textFields.firstObject.text ?: @"";
        if (value.length > 500) value = [value substringToIndex:500];
        if (value.length) notes[channel] = value;
        else [notes removeObjectForKey:channel];
        [STDefaults() setObject:notes forKey:STNotesKey];
    }]];
    [presenter presentViewController:alert animated:YES completion:nil];
}
static void STConfigurePage(UITableViewController *page, NSString *title) {
    page.title = title;
    page.tableView.backgroundColor = [UIColor colorWithRed:.055 green:.06 blue:.075 alpha:1];
    page.tableView.separatorColor = [UIColor colorWithWhite:.23 alpha:1];
    page.navigationController.navigationBar.tintColor = STAccent();
}
static UITableViewCell *STCell(NSString *title, NSString *detail) {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.backgroundColor = [UIColor colorWithRed:.10 green:.115 blue:.14 alpha:1];
    cell.textLabel.textColor = UIColor.whiteColor;
    cell.detailTextLabel.textColor = [UIColor colorWithWhite:.68 alpha:1];
    cell.textLabel.text = title;
    cell.detailTextLabel.text = detail;
    cell.detailTextLabel.numberOfLines = 2;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

@implementation STChannelToolsController
- (instancetype)init { return [super initWithStyle:UITableViewStyleInsetGrouped]; }
- (void)viewDidLoad { [super viewDidLoad]; STConfigurePage(self, @"Stream Profiles & Notes"); }
- (void)viewWillAppear:(BOOL)animated { [super viewWillAppear:animated]; [self.tableView reloadData]; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 5; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)ip {
    NSString *channel = STChannel();
    switch (ip.row) {
        case 0: return STCell(@"Current channel", channel ?: @"Open a stream to use channel tools");
        case 1: return STCell(@"Compact chat profile", @"13 pt messages; minimal spacing");
        case 2: return STCell(@"Comfortable chat profile", @"17 pt messages; extra spacing");
        case 3: return STCell(@"Remove channel profile", @"Stop auto-applying chat density for this channel");
        default: return STCell(@"Private channel note", @"Save or edit a note for the current streamer");
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tableView deselectRowAtIndexPath:ip animated:YES];
    NSString *channel = STChannel();
    if (ip.row == 4) { STEditNote(self); return; }
    if (ip.row == 0) return;
    if (!channel) { STShowAlert(self, @"No active channel", @"Enter a stream before saving a profile."); return; }
    if (ip.row == 1) STSetProfile(channel, @"compact");
    else if (ip.row == 2) STSetProfile(channel, @"comfortable");
    else STSetProfile(channel, nil);
    if (ip.row != 3) STApplyChannelProfile();
    STShowAlert(self, @"Profile saved", ip.row == 3 ? @"The saved channel profile is removed. Your current chat appearance stays unchanged until you edit it." : @"This channel's chat density will be applied automatically when you return to it.");
}
@end

@implementation STChatFocusController
- (instancetype)init { return [super initWithStyle:UITableViewStyleInsetGrouped]; }
- (void)viewDidLoad { [super viewDidLoad]; STConfigurePage(self, @"Chat Focus Mode"); }
- (void)viewWillAppear:(BOOL)animated { [super viewWillAppear:animated]; [self.tableView reloadData]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 3; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)ip {
    if (ip.row == 0) return STCell(@"Keyword filtering", [STDefaults() boolForKey:STFocusEnabledKey] ? @"Enabled for custom chat" : @"Disabled");
    if (ip.row == 1) return STCell(@"Muted keywords", @"Comma-separated keywords; up to 12 words");
    return STCell(@"Clear muted keywords", @"Remove local filters and show all messages again");
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tableView deselectRowAtIndexPath:ip animated:YES];
    if (ip.row == 0) {
        [STDefaults() setBool:![STDefaults() boolForKey:STFocusEnabledKey] forKey:STFocusEnabledKey];
    } else if (ip.row == 2) {
        [STDefaults() removeObjectForKey:STFocusKeywordsKey];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Muted words"
            message:@"Hide matching regular messages in ShrubTwitch's custom chat only. Not a Twitch moderation action."
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
            field.text = [[STDefaults() stringArrayForKey:STFocusKeywordsKey] componentsJoinedByString:@", "];
            field.placeholder = @"spoiler, spam, example";
        }];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSMutableArray *keywords = [NSMutableArray array];
            for (NSString *piece in [alert.textFields.firstObject.text componentsSeparatedByString:@","]) {
                NSString *word = [[piece stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] lowercaseString];
                if (word.length && word.length <= 50 && ![keywords containsObject:word]) [keywords addObject:word];
                if (keywords.count >= 12) break;
            }
            [STDefaults() setObject:keywords forKey:STFocusKeywordsKey];
            [NSNotificationCenter.defaultCenter postNotificationName:@"STChatFocusChanged" object:nil];
            [self.tableView reloadData];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    [NSNotificationCenter.defaultCenter postNotificationName:@"STChatFocusChanged" object:nil];
    [self.tableView reloadData];
}
@end

@implementation STBookmarksController
- (instancetype)init { return [super initWithStyle:UITableViewStyleInsetGrouped]; }
- (void)viewDidLoad {
    [super viewDidLoad]; STConfigurePage(self, @"ShrubBookmarks");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addCurrent)];
}
- (void)viewWillAppear:(BOOL)animated { [super viewWillAppear:animated]; [self.tableView reloadData]; }
- (void)addCurrent {
    NSString *channel = STChannel();
    if (!channel) { STShowAlert(self, @"No active channel", @"Open a stream to bookmark it."); return; }
    STSaveBookmark(channel); [self.tableView reloadData];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return STBookmarks().count; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)ip {
    NSArray *bookmarks = STBookmarks();
    return STCell(bookmarks[ip.row], @"Open channel on Twitch");
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tableView deselectRowAtIndexPath:ip animated:YES];
    NSArray *bookmarks = STBookmarks();
    if (ip.row >= bookmarks.count) return;
    NSString *channel = bookmarks[ip.row];
    NSURL *url = [NSURL URLWithString:[@"https://www.twitch.tv/" stringByAppendingString:channel]];
    if (url) [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)ip {
    if (style != UITableViewCellEditingStyleDelete) return;
    NSMutableArray *bookmarks = STBookmarks();
    if (ip.row >= bookmarks.count) return;
    [bookmarks removeObjectAtIndex:ip.row];
    [STDefaults() setObject:bookmarks forKey:STBookmarksKey];
    [tableView deleteRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationAutomatic];
}
@end

void STPresentQuickPanel(UIViewController *presenter, UIBarButtonItem *anchor) {
    NSString *channel = STChannel();
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"ShrubTwitch Quick Panel"
        message:channel ? [@"Watching: " stringByAppendingString:channel] : @"Open a stream for channel tools"
        preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:TPKOLEDModeEnabled() ? @"Disable OLED mode" : @"Enable OLED mode"
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { TPKOLEDModeSetEnabled(!TPKOLEDModeEnabled()); }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Bookmark current channel"
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if (channel) STSaveBookmark(channel);
            else STShowAlert(presenter, @"No active channel", @"Open a stream first.");
        }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Channel note"
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { STEditNote(presenter); }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Chat Focus Mode"
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [presenter.navigationController pushViewController:[[STChatFocusController alloc] init] animated:YES];
        }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    // Required on iPad: action sheets must be attached to a popover anchor.
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.barButtonItem = anchor;
        if (!anchor) { sheet.popoverPresentationController.sourceView = presenter.view;
            sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(presenter.view.bounds), 0, 1, 1); }
    }
    [presenter presentViewController:sheet animated:YES completion:nil];
}
