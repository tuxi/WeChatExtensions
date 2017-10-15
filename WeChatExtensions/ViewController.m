//
//  ViewController.m
//  WeChatExtensions
//
//  Created by Swae on 2017/10/8.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "ViewController.h"
#import "XYSuspensionMenu.h"
#import "ExceptionUtils.h"
#import "FoldersViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    SuspensionMenuWindow *menuView = [[SuspensionMenuWindow alloc] initWithFrame:CGRectMake(0, 0, 300, 300) itemSize:CGSizeMake(50, 50)];
    [menuView.centerButton setImage:[UIImage imageNamed:@"wechatout_callbutton"] forState:UIControlStateNormal];
    menuView.shouldOpenWhenViewWillAppear = NO;
    menuView.shouldHiddenCenterButtonWhenOpen = YES;
    menuView.shouldCloseWhenDeviceOrientationDidChange = YES;
    HypotenuseAction *item = [HypotenuseAction actionWithType:1 handler:^(HypotenuseAction * action, SuspensionMenuView * menuView) {
         NSLog(@"%@", menuView);
        [ExceptionUtils openTestWindow];
        [menuView close];
    }];
    [menuView addAction:item];
    [item.hypotenuseButton setTitle:@"Debug\n window" forState:UIControlStateNormal];
    
    HypotenuseAction *item1 = [HypotenuseAction actionWithType:1 handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * menuView) {
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

//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(),  ^{
//        UIViewController *vc = [[UIApplication sharedApplication].delegate.window rootViewController];
//        CGFloat SUSPENSIONVIEW_WH = 60;
//        CGRect frame = CGRectMake(CGRectGetWidth([UIScreen mainScreen].bounds) - SUSPENSIONVIEW_WH, CGRectGetHeight([UIScreen mainScreen].bounds)-SUSPENSIONVIEW_WH-SUSPENSIONVIEW_WH, SUSPENSIONVIEW_WH, SUSPENSIONVIEW_WH);
//        SuspensionView *sv = [vc showSuspensionViewWithFrame:frame];
//        sv.leanEdgeInsets = UIEdgeInsetsMake(20, 0, 20, 0);
//        sv.clickCallBack = ^{
//            [ExceptionUtils openTestWindow];
//        };
//        sv.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
//        [vc setSuspensionImageWithImageNamed:@"Icon" forState:UIControlStateNormal];
//    });
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
