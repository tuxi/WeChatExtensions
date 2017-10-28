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
#import "XYLocationSearchViewController.h"

@interface ViewController () <XYLocationSearchViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *nameLab;
@property (weak, nonatomic) IBOutlet UILabel *addressLab;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.nameLab.textAlignment = NSTextAlignmentCenter;
    self.addressLab.textAlignment = NSTextAlignmentCenter;
    
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
    [item.hypotenuseButton setBackgroundColor:[UIColor whiteColor]];
    item.hypotenuseButton.layer.cornerRadius = 10.0;
    HypotenuseAction *item1 = [HypotenuseAction actionWithType:1 handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * menuView) {
        FoldersViewController *vc = [[FoldersViewController alloc] initWithRootDirectory:NSHomeDirectory()];
        vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"back" style:UIBarButtonItemStylePlain target:vc action:NSSelectorFromString(@"backButtonClick")];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
//        UIViewController *rootVc = [UIApplication sharedApplication].delegate.window.rootViewController;
        [menuView showViewController:navController animated:YES];
//        [rootVc showDetailViewController:navController sender:rootVc];
        [menuView close];
        
    }];
    [menuView addAction:item1];
    [item1.hypotenuseButton setTitle:@"操作\n 沙盒" forState:UIControlStateNormal];
    [item1.hypotenuseButton setBackgroundColor:[UIColor whiteColor]];
    item1.hypotenuseButton.layer.cornerRadius = 10.0;
    HypotenuseAction *item3 = [HypotenuseAction actionWithType:1 handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * menuView) {
        FoldersViewController *vc = [[FoldersViewController alloc] initWithRootDirectory:NSHomeDirectory()];
        vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"back" style:UIBarButtonItemStylePlain target:vc action:NSSelectorFromString(@"backButtonClick")];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
         [menuView showViewController:navController animated:YES];
        [menuView close];
        
    }];
    [menuView addAction:item3];
    [item3.hypotenuseButton setTitle:@"操作\n 沙盒" forState:UIControlStateNormal];
    [item3.hypotenuseButton setBackgroundColor:[UIColor whiteColor]];
    item3.hypotenuseButton.layer.cornerRadius = 10.0;
    [menuView showWithCompetion:NULL];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)gotoSearch:(id)sender {
    
    XYLocationSearchViewController *vc = [XYLocationSearchViewController new];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
//    [self presentViewController:vc animated:YES completion:NULL];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - XYLocationSearchViewControllerDelegate
////////////////////////////////////////////////////////////////////////
- (void)locationSearchViewController:(UIViewController *)sender didSelectLocationWithName:(NSString *)name address:(NSString *)address mapItem:(MKMapItem *)mapItm {
    self.nameLab.text = name;
    self.addressLab.text = address;
    
//    CGFloat l = mapItm.placemark.location.coordinate.longitude;
    [self.navigationController popViewControllerAnimated:YES];
//    [self.presentedViewController dismissViewControllerAnimated:YES completion:NULL];
}



@end
