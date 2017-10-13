
#import "XYExtensionsViewController.h"
#import "WeChatHeaders.h"
#import "ExceptionUtils.h"
#import "SuspensionControl.h"

%hook MicroMessengerAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [ExceptionUtils configExceptionHandler];
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
    return %orig;
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

