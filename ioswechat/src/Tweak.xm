
#import "XYExtensionsViewController.h"
#import "WeChatHeaders.h"
#import "XYExtensionConfig.h"
#import "SuspensionControl.h"
#import "SuspensionControl.h"
#import "FoldersViewController.h"

%hook MicroMessengerAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
SuspensionMenuWindow *menuView = [[SuspensionMenuWindow alloc] initWithFrame:CGRectMake(0, 0, 300, 300) itemSize:CGSizeMake(50, 50)];

[menuView.centerButton setImage:[UIImage imageNamed:@"Icon"] forState:UIControlStateNormal];
menuView.isOnce = YES;
menuView.shouldOpenWhenViewWillAppear = NO;
menuView.shouldHiddenCenterButtonWhenOpen = YES;
menuView.shouldCloseWhenDeviceOrientationDidChange = YES;
UIImage *image = [UIImage imageNamed:@"mm.jpg"];
menuView.backgroundImageView.image = image;

HypotenuseAction *item = nil;

{
item  = [HypotenuseAction actionWithType:OSButtonType1 handler:^(HypotenuseAction * _Nonnull action) {
NSString *path = NSHomeDirectory();
FoldersViewController *vc = [[FoldersViewController alloc] initWithRootDirectory:path];
vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"back" style:UIBarButtonItemStylePlain target:vc action:@selector(backButtonClick)];
UINavigationController *detailNavController = [[UINavigationController alloc] initWithRootViewController:vc];
[[menuView topViewController] showDetailViewController:detailNavController sender:[menuView topViewController]];
[menuView close];
}];
[item.hypotenuseButton setBackgroundColor:[UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:0.95]];
item.hypotenuseButton.layer.cornerRadius = 12.8;
[item.hypotenuseButton.layer setMasksToBounds:YES];
[item.hypotenuseButton setTitle:@"SandBox" forState:UIControlStateNormal];
}

{
item  = [HypotenuseAction actionWithType:OSButtonType1 handler:^(HypotenuseAction * _Nonnull action) {
XYExtensionsViewController *extensionVc = [[XYExtensionsViewController alloc] init];
[[menuView topViewController] showDetailViewController:extensionVc sender:[menuView topViewController]];
[menuView close];
}];
[item.hypotenuseButton setBackgroundColor:[UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:0.95]];
item.hypotenuseButton.layer.cornerRadius = 12.8;
[item.hypotenuseButton.layer setMasksToBounds:YES];
[item.hypotenuseButton setTitle:@"扩展" forState:UIControlStateNormal];
}


[menuView showWithCompetion:NULL];
    

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

/* Mark: 已在XYExtensionsViewController中使用CaptainHook hook了WCDeviceStepObject，这里就不必实现了
%hook WCDeviceStepObject
- (NSInteger)m7StepCount {
    NSInteger stepCount = %orig;
    NSInteger newStepCount = [[XYExtensionConfig sharedInstance] stepCount];
    BOOL changeStepEnable = [[XYExtensionConfig sharedInstance] shouldChangeStep];

    return changeStepEnable ? newStepCount : stepCount;
}

- (NSInteger)hkStepCount {
    NSInteger stepCount = %orig;
    NSInteger newStepCount = [[XYExtensionConfig sharedInstance] stepCount];
    BOOL changeStepEnable = [[XYExtensionConfig sharedInstance] shouldChangeStep];

    return changeStepEnable ? newStepCount : stepCount;
}

%end
*/
