
#import "XYExtensionsViewController.h"
#import "WeChatHeaders.h"
#import "ExceptionUtils.h"

%hook MicroMessengerAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [ExceptionUtils configExceptionHandler];

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

