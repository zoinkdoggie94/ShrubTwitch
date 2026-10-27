#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Original ShrubTwitch additions; retain old tpk_ ABI/preferences for migration.
FOUNDATION_EXPORT void STSetupChannelProfiles(void);
FOUNDATION_EXPORT void STPresentQuickPanel(UIViewController *presenter, UIBarButtonItem *anchor);

@interface STChannelToolsController : UITableViewController
@end
@interface STChatFocusController : UITableViewController
@end
@interface STBookmarksController : UITableViewController
@end
