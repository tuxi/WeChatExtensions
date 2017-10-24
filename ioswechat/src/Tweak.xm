
#import "XYExtensionsViewController.h"
#import "WeChatHeaders.h"
#import "ExceptionUtils.h"
#import "XYSuspensionMenu.h"
#import "FoldersViewController.h"
#import "OSAuthenticatorHelper.h"

@interface MainTabBarController : UITabBarController <SmileAuthenticatorDelegate>

@end


%hook MicroMessengerAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL res = %orig;
    [ExceptionUtils configExceptionHandler];
if ([UIDevice currentDevice].systemVersion.floatValue < 11.0f) {

/*
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(),  ^{
        UIViewController *vc = [[UIApplication sharedApplication].delegate.window rootViewController];
        CGFloat SUSPENSIONVIEW_WH = 60;
        CGRect frame = CGRectMake(CGRectGetWidth([UIScreen mainScreen].bounds) - SUSPENSIONVIEW_WH, CGRectGetHeight([UIScreen mainScreen].bounds)-SUSPENSIONVIEW_WH-SUSPENSIONVIEW_WH, SUSPENSIONVIEW_WH, SUSPENSIONVIEW_WH);
        SuspensionView *sv = [vc showSuspensionViewWithFrame:frame];
        sv.isOnce = YES;
        sv.leanEdgeInsets = UIEdgeInsetsMake(20, 0, 20, 0);
        sv.clickCallBack = ^{
            [ExceptionUtils openTestWindow];
        };
        sv.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        [vc setSuspensionImageWithImageNamed:@"Icon" forState:UIControlStateNormal];
    });
*/

}

    SuspensionMenuWindow *menuView = [[SuspensionMenuWindow alloc] initWithFrame:CGRectMake(0, 0, 300, 300) itemSize:CGSizeMake(50, 50)];
    [menuView.centerButton setImage:[UIImage imageNamed:@"wechatout_callbutton"] forState:UIControlStateNormal];
    menuView.shouldOpenWhenViewWillAppear = NO;
    menuView.shouldHiddenCenterButtonWhenOpen = YES;
    menuView.shouldCloseWhenDeviceOrientationDidChange = YES;

    HypotenuseAction *item = [HypotenuseAction actionWithType:1 handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
        NSLog(@"%@", menuView);
        [ExceptionUtils openTestWindow];
        [menuView close];
    }];
    [menuView addAction:item];
    [item.hypotenuseButton setTitle:@"Debug\n window" forState:UIControlStateNormal];
    [item.hypotenuseButton setBackgroundColor:[UIColor whiteColor]];
    item.hypotenuseButton.layer.cornerRadius = 10.0;
    HypotenuseAction *item1 = [HypotenuseAction actionWithType:1 handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
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

- (void)applicationWillResignActive:(UIApplication *)application {
    %orig;
    [[OSAuthenticatorHelper sharedInstance] applicationWillResignActiveWithShowCoverImageView];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig;
    [[OSAuthenticatorHelper sharedInstance] applicationDidBecomeActiveWithRemoveCoverImageView];
}
%end

%hook MMTabBarController

- (void)viewDidLoad {
    %orig;
    [SmileAuthenticator setDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if ([SmileAuthenticator hasPassword]) {
        [SmileAuthenticator sharedInstance].securityType = INPUT_TOUCHID;
        [[SmileAuthenticator sharedInstance] presentAuthViewControllerAnimated:NO];
    }
}

%new
- (void)AuthViewControllerDismissed:(UIViewController*)previousPresentedVC {

    if (previousPresentedVC) {
        [self presentViewController:previousPresentedVC animated:YES completion:nil];
    }
}

%end

%hook NewSettingViewController
- (void)reloadTableData {
    %orig;
    MMTableViewInfo *tableViewInfo = MSHookIvar<id>(self, "m_tableViewInfo");
    MMTableViewSectionInfo *sectionInfo = [%c(MMTableViewSectionInfo) sectionInfoDefaut];
    MMTableViewCellInfo *settingCell = [%c(MMTableViewCellInfo) normalCellForSel:@selector(extensionsVc) target:self title:@"扩展" accessoryType:1];
    [sectionInfo addCell:settingCell];
    [tableViewInfo insertSection:sectionInfo At:0];
    MMTableView *tableView = [tableViewInfo getTableView];
    [tableView reloadData];
}

%new
- (void)extensionsVc {
    XYExtensionsViewController *extensionVc = [[XYExtensionsViewController alloc] init];
    [self.navigationController PushViewController:extensionVc animated:YES];
}
%end

// Mark: 已在XYExtensionsViewController中使用CaptainHook hook了WCDeviceStepObject，这里就不必实现了
//%hook WCDeviceStepObject
//- (NSInteger)m7StepCount {
//    NSInteger stepCount = %orig;
//    NSInteger newStepCount = [[XYExtensionConfig sharedInstance] stepCount];
//    BOOL changeStepEnable = [[XYExtensionConfig sharedInstance] shouldChangeStep];
//
//    return changeStepEnable ? newStepCount : stepCount;
//}

//- (NSInteger)hkStepCount {
//    NSInteger stepCount = %orig;
//    NSInteger newStepCount = [[XYExtensionConfig sharedInstance] stepCount];
//    BOOL changeStepEnable = [[XYExtensionConfig sharedInstance] shouldChangeStep];
//
//  return changeStepEnable ? newStepCount : stepCount;
//}
//
//%end

