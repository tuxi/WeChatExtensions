#line 1 "/Users/xiaoyuan/Desktop/work/Github/WeChatExtensions/WeChatExtensions/WeChatExtensionsDylib/Logos/WeChatExtensionsDylib.xm"

#import "XYExtensionsViewController.h"
#import "WeChatHeaders.h"
#import "ExceptionUtils.h"
#import "XYSuspensionMenu.h"
#import "FoldersViewController.h"
#import "OSAuthenticatorHelper.h"

@interface MainTabBarController : UITabBarController <SmileAuthenticatorDelegate>

@end



#include <substrate.h>
#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif

@class MicroMessengerAppDelegate; @class MMTabBarController; @class MMTableViewSectionInfo; @class MMTableViewCellInfo; @class NewSettingViewController; 
static BOOL (*_logos_orig$_ungrouped$MicroMessengerAppDelegate$application$didFinishLaunchingWithOptions$)(_LOGOS_SELF_TYPE_NORMAL MicroMessengerAppDelegate* _LOGOS_SELF_CONST, SEL, UIApplication *, NSDictionary *); static BOOL _logos_method$_ungrouped$MicroMessengerAppDelegate$application$didFinishLaunchingWithOptions$(_LOGOS_SELF_TYPE_NORMAL MicroMessengerAppDelegate* _LOGOS_SELF_CONST, SEL, UIApplication *, NSDictionary *); static void (*_logos_orig$_ungrouped$MicroMessengerAppDelegate$applicationWillResignActive$)(_LOGOS_SELF_TYPE_NORMAL MicroMessengerAppDelegate* _LOGOS_SELF_CONST, SEL, UIApplication *); static void _logos_method$_ungrouped$MicroMessengerAppDelegate$applicationWillResignActive$(_LOGOS_SELF_TYPE_NORMAL MicroMessengerAppDelegate* _LOGOS_SELF_CONST, SEL, UIApplication *); static void (*_logos_orig$_ungrouped$MicroMessengerAppDelegate$applicationDidBecomeActive$)(_LOGOS_SELF_TYPE_NORMAL MicroMessengerAppDelegate* _LOGOS_SELF_CONST, SEL, UIApplication *); static void _logos_method$_ungrouped$MicroMessengerAppDelegate$applicationDidBecomeActive$(_LOGOS_SELF_TYPE_NORMAL MicroMessengerAppDelegate* _LOGOS_SELF_CONST, SEL, UIApplication *); static void (*_logos_orig$_ungrouped$MMTabBarController$viewDidLoad)(_LOGOS_SELF_TYPE_NORMAL MMTabBarController* _LOGOS_SELF_CONST, SEL); static void _logos_method$_ungrouped$MMTabBarController$viewDidLoad(_LOGOS_SELF_TYPE_NORMAL MMTabBarController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$_ungrouped$MMTabBarController$viewDidAppear$)(_LOGOS_SELF_TYPE_NORMAL MMTabBarController* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$_ungrouped$MMTabBarController$viewDidAppear$(_LOGOS_SELF_TYPE_NORMAL MMTabBarController* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$_ungrouped$MMTabBarController$AuthViewControllerDismissed$(_LOGOS_SELF_TYPE_NORMAL MMTabBarController* _LOGOS_SELF_CONST, SEL, UIViewController*); static void (*_logos_orig$_ungrouped$NewSettingViewController$reloadTableData)(_LOGOS_SELF_TYPE_NORMAL NewSettingViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$_ungrouped$NewSettingViewController$reloadTableData(_LOGOS_SELF_TYPE_NORMAL NewSettingViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$_ungrouped$NewSettingViewController$extensionsVc(_LOGOS_SELF_TYPE_NORMAL NewSettingViewController* _LOGOS_SELF_CONST, SEL); 
static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$MMTableViewSectionInfo(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("MMTableViewSectionInfo"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$MMTableViewCellInfo(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("MMTableViewCellInfo"); } return _klass; }
#line 14 "/Users/xiaoyuan/Desktop/work/Github/WeChatExtensions/WeChatExtensions/WeChatExtensionsDylib/Logos/WeChatExtensionsDylib.xm"


static BOOL _logos_method$_ungrouped$MicroMessengerAppDelegate$application$didFinishLaunchingWithOptions$(_LOGOS_SELF_TYPE_NORMAL MicroMessengerAppDelegate* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIApplication * application, NSDictionary * launchOptions) {
    BOOL res = _logos_orig$_ungrouped$MicroMessengerAppDelegate$application$didFinishLaunchingWithOptions$(self, _cmd, application, launchOptions);
    [ExceptionUtils configExceptionHandler];
if ([UIDevice currentDevice].systemVersion.floatValue < 11.0f) {

















}

    SuspensionMenuWindow *menuView = [[SuspensionMenuWindow alloc] initWithFrame:CGRectMake(0, 0, 300, 300) itemSize:CGSizeMake(50, 50)];
    [menuView.centerButton setImage:[UIImage imageNamed:@"wechatout_callbutton"] forState:UIControlStateNormal];
    menuView.shouldOpenWhenViewWillAppear = NO;
    menuView.shouldHiddenCenterButtonWhenOpen = YES;
    menuView.shouldCloseWhenDeviceOrientationDidChange = YES;

    HypotenuseAction *item = [HypotenuseAction actionWithType:UIButtonTypeSystem handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
        NSLog(@"%@", menuView);
        [ExceptionUtils openTestWindow];
        [menuView close];
    }];
    [menuView addAction:item];
    [item.hypotenuseButton setTitle:@"Debug\n window" forState:UIControlStateNormal];
    [item.hypotenuseButton setBackgroundColor:[UIColor whiteColor]];
    item.hypotenuseButton.layer.cornerRadius = 10.0;
    HypotenuseAction *item1 = [HypotenuseAction actionWithType:UIButtonTypeSystem handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
        FoldersViewController *vc = [[FoldersViewController alloc] initWithRootDirectory:NSHomeDirectory()];
        vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"back" style:UIBarButtonItemStylePlain target:vc action:NSSelectorFromString(@"backButtonClick")];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
        UIViewController *rootVc = [UIApplication sharedApplication].delegate.window.rootViewController;
        [rootVc showDetailViewController:navController sender:rootVc];
        [menuView close];

    }];
    [menuView addAction:item1];
    [item1.hypotenuseButton setTitle:@"操作\n 沙盒" forState:UIControlStateNormal];
    [menuView showWithCompetion:NULL];
    [item1.hypotenuseButton setBackgroundColor:[UIColor whiteColor]];
    item1.hypotenuseButton.layer.cornerRadius = 10.0;
    [[OSAuthenticatorHelper sharedInstance] initAuthenticator];
    return res;
}

static void _logos_method$_ungrouped$MicroMessengerAppDelegate$applicationWillResignActive$(_LOGOS_SELF_TYPE_NORMAL MicroMessengerAppDelegate* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIApplication * application) {
    _logos_orig$_ungrouped$MicroMessengerAppDelegate$applicationWillResignActive$(self, _cmd, application);
    [[OSAuthenticatorHelper sharedInstance] applicationWillResignActiveWithShowCoverImageView];
}

static void _logos_method$_ungrouped$MicroMessengerAppDelegate$applicationDidBecomeActive$(_LOGOS_SELF_TYPE_NORMAL MicroMessengerAppDelegate* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIApplication * application) {
    _logos_orig$_ungrouped$MicroMessengerAppDelegate$applicationDidBecomeActive$(self, _cmd, application);
    [[OSAuthenticatorHelper sharedInstance] applicationDidBecomeActiveWithRemoveCoverImageView];
}




static void _logos_method$_ungrouped$MMTabBarController$viewDidLoad(_LOGOS_SELF_TYPE_NORMAL MMTabBarController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$_ungrouped$MMTabBarController$viewDidLoad(self, _cmd);
    [SmileAuthenticator setDelegate:self];
}

static void _logos_method$_ungrouped$MMTabBarController$viewDidAppear$(_LOGOS_SELF_TYPE_NORMAL MMTabBarController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL animated) {
    _logos_orig$_ungrouped$MMTabBarController$viewDidAppear$(self, _cmd, animated);
    if ([SmileAuthenticator hasPassword]) {
        [SmileAuthenticator sharedInstance].securityType = INPUT_TOUCHID;
        [[SmileAuthenticator sharedInstance] presentAuthViewControllerAnimated:NO];
    }
}


static void _logos_method$_ungrouped$MMTabBarController$AuthViewControllerDismissed$(_LOGOS_SELF_TYPE_NORMAL MMTabBarController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIViewController* previousPresentedVC) {

    if (previousPresentedVC) {
        [self presentViewController:previousPresentedVC animated:YES completion:nil];
    }
}




static void _logos_method$_ungrouped$NewSettingViewController$reloadTableData(_LOGOS_SELF_TYPE_NORMAL NewSettingViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$_ungrouped$NewSettingViewController$reloadTableData(self, _cmd);
    MMTableViewInfo *tableViewInfo = MSHookIvar<id>(self, "m_tableViewInfo");
    MMTableViewSectionInfo *sectionInfo = [_logos_static_class_lookup$MMTableViewSectionInfo() sectionInfoDefaut];
    MMTableViewCellInfo *settingCell = [_logos_static_class_lookup$MMTableViewCellInfo() normalCellForSel:@selector(extensionsVc) target:self title:@"扩展" accessoryType:1];
    [sectionInfo addCell:settingCell];
    [tableViewInfo insertSection:sectionInfo At:0];
    MMTableView *tableView = [tableViewInfo getTableView];
    [tableView reloadData];
}


static void _logos_method$_ungrouped$NewSettingViewController$extensionsVc(_LOGOS_SELF_TYPE_NORMAL NewSettingViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    XYExtensionsViewController *extensionVc = [[XYExtensionsViewController alloc] init];
    [self.navigationController PushViewController:extensionVc animated:YES];
}






















static __attribute__((constructor)) void _logosLocalInit() {
{Class _logos_class$_ungrouped$MicroMessengerAppDelegate = objc_getClass("MicroMessengerAppDelegate"); MSHookMessageEx(_logos_class$_ungrouped$MicroMessengerAppDelegate, @selector(application:didFinishLaunchingWithOptions:), (IMP)&_logos_method$_ungrouped$MicroMessengerAppDelegate$application$didFinishLaunchingWithOptions$, (IMP*)&_logos_orig$_ungrouped$MicroMessengerAppDelegate$application$didFinishLaunchingWithOptions$);MSHookMessageEx(_logos_class$_ungrouped$MicroMessengerAppDelegate, @selector(applicationWillResignActive:), (IMP)&_logos_method$_ungrouped$MicroMessengerAppDelegate$applicationWillResignActive$, (IMP*)&_logos_orig$_ungrouped$MicroMessengerAppDelegate$applicationWillResignActive$);MSHookMessageEx(_logos_class$_ungrouped$MicroMessengerAppDelegate, @selector(applicationDidBecomeActive:), (IMP)&_logos_method$_ungrouped$MicroMessengerAppDelegate$applicationDidBecomeActive$, (IMP*)&_logos_orig$_ungrouped$MicroMessengerAppDelegate$applicationDidBecomeActive$);Class _logos_class$_ungrouped$MMTabBarController = objc_getClass("MMTabBarController"); MSHookMessageEx(_logos_class$_ungrouped$MMTabBarController, @selector(viewDidLoad), (IMP)&_logos_method$_ungrouped$MMTabBarController$viewDidLoad, (IMP*)&_logos_orig$_ungrouped$MMTabBarController$viewDidLoad);MSHookMessageEx(_logos_class$_ungrouped$MMTabBarController, @selector(viewDidAppear:), (IMP)&_logos_method$_ungrouped$MMTabBarController$viewDidAppear$, (IMP*)&_logos_orig$_ungrouped$MMTabBarController$viewDidAppear$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(UIViewController*), strlen(@encode(UIViewController*))); i += strlen(@encode(UIViewController*)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$_ungrouped$MMTabBarController, @selector(AuthViewControllerDismissed:), (IMP)&_logos_method$_ungrouped$MMTabBarController$AuthViewControllerDismissed$, _typeEncoding); }Class _logos_class$_ungrouped$NewSettingViewController = objc_getClass("NewSettingViewController"); MSHookMessageEx(_logos_class$_ungrouped$NewSettingViewController, @selector(reloadTableData), (IMP)&_logos_method$_ungrouped$NewSettingViewController$reloadTableData, (IMP*)&_logos_orig$_ungrouped$NewSettingViewController$reloadTableData);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$_ungrouped$NewSettingViewController, @selector(extensionsVc), (IMP)&_logos_method$_ungrouped$NewSettingViewController$extensionsVc, _typeEncoding); }} }
#line 147 "/Users/xiaoyuan/Desktop/work/Github/WeChatExtensions/WeChatExtensions/WeChatExtensionsDylib/Logos/WeChatExtensionsDylib.xm"
