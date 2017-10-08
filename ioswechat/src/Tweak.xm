
#import "XYExtensionsViewController.h"
#import "WeChatHeaders.h"
#import "XYExtensionMoudle.h"


%hook NewSettingViewController
- (void)reloadTableData {
    %orig;
    MMTableViewInfo *tableViewInfo = MSHookIvar<id>(self, "m_tableViewInfo");
    MMTableViewSectionInfo *sectionInfo = [%c(MMTableViewSectionInfo) sectionInfoDefaut];
    MMTableViewCellInfo *settingCell = [%c(MMTableViewCellInfo) normalCellForSel:@selector(setting) target:self title:@"扩展" accessoryType:1];
    [sectionInfo addCell:settingCell];
    [tableViewInfo insertSection:sectionInfo At:0];
    MMTableView *tableView = [tableViewInfo getTableView];
    [tableView reloadData];
}

%new
- (void)setting {
    XYExtensionsViewController *extensionVc = [[XYExtensionsViewController alloc] init];
    [self.navigationController PushViewController:extensionVc animated:YES];
}
%end

%hook WCDeviceStepObject
- (NSInteger)m7StepCount {
    NSInteger stepCount = %orig;
    NSInteger newStepCount = [[XYExtensionMoudle sharedInstance] stepCount];
    BOOL changeStepEnable = [[XYExtensionMoudle sharedInstance] shouldChangeStep];

    return changeStepEnable ? newStepCount : stepCount;
}

- (NSInteger)hkStepCount {
    NSInteger stepCount = %orig;
    NSInteger newStepCount = [[XYExtensionMoudle sharedInstance] stepCount];
    BOOL changeStepEnable = [[XYExtensionMoudle sharedInstance] shouldChangeStep];

    return changeStepEnable ? newStepCount : stepCount;
}

%end
