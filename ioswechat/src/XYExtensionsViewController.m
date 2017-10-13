//
//  XYExtensionsViewController.m
//  WeChatPlugin
//
//  Created by Swae on 2017/10/8.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "XYExtensionsViewController.h"
#import <objc/message.h>
#import "WeChatHeaders.h"
#import "XYExtensionConfig.h"
#import "CaptainHook.h"
#import "XYMapViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "FoldersViewController.h"
#import "SuspensionControl.h"
#pragma mark *** 微信扩展控制器 ***

@interface XYExtensionsViewController ()

@property (nonatomic, strong) MMTableViewInfo *wx_tableViewInfo;

@end

@implementation XYExtensionsViewController

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self reloadTableViewData];
    [self setupUI];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadTableViewData];
}


- (void)setupUI {
    self.title = @"扩展";
    MMTableView *tableView = [self.wx_tableViewInfo getTableView];
    [self.view addSubview:tableView];
}

- (MMTableViewInfo *)wx_tableViewInfo {
    if (!_wx_tableViewInfo) {
        _wx_tableViewInfo = [[objc_getClass("MMTableViewInfo") alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStyleGrouped];
    }
    return _wx_tableViewInfo;
}

- (void)reloadTableViewData {
    MMTableViewInfo *tableViewInfo = (MMTableViewInfo *)self.wx_tableViewInfo;
    [tableViewInfo clearAllSection];
    
    [self addModifyWeChatSportsStepsCell];
    [self addModifyCoordinateCell];
    [self addOperationSandBoxCell];
    
    MMTableView *tableView = [self.wx_tableViewInfo getTableView];
    [tableView reloadData];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - 微信运动步数Cell
////////////////////////////////////////////////////////////////////////

- (void)addModifyWeChatSportsStepsCell {
    MMTableViewSectionInfo *sectionInfo = [objc_getClass("MMTableViewSectionInfo") sectionInfoHeader:@"" Footer:nil];
    [sectionInfo addCell:[self createStepSwitchCell]];
    
    BOOL shouldChangeStep = [[XYExtensionConfig sharedInstance] shouldChangeStep];
    if (shouldChangeStep) {
        [sectionInfo addCell:[self createStepCountCell]];
    }
    [self.wx_tableViewInfo addSection:sectionInfo];
}


- (MMTableViewCellInfo *)createStepSwitchCell {
    BOOL shouldAddStep = [[XYExtensionConfig sharedInstance] shouldChangeStep];
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo") switchCellForSel:@selector(setShouldChangeStep:) target:self title:@"修改微信运动步数" on:shouldAddStep];
    
    return cellInfo;
}

- (MMTableViewCellInfo *)createStepCountCell {
    NSInteger deviceStep = [[XYExtensionConfig sharedInstance] stepCount];
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo")  normalCellForSel:@selector(updateStepCount) target:self title:@"修改的步数" rightValue:[NSString stringWithFormat:@"%ld", (long)deviceStep] accessoryType:1];
    
    return cellInfo;
}

- (void)setShouldChangeStep:(UISwitch *)sw {
    
    [XYExtensionConfig sharedInstance].shouldChangeStep = sw.on;
    [self reloadTableViewData];
    
}

- (void)updateStepCount {
    NSInteger stepCount = [[XYExtensionConfig sharedInstance] stepCount];
    [self alertControllerWithTitle:@"修改微信运动步数"
                           message:@"本次修改的步数若为负数或且小于已上传的步数时无效，最大值为98800"
                           content:[NSString stringWithFormat:@"%ld", (long)stepCount]
                       placeholder:@"请输入需要修改的步数"
                      keyboardType:UIKeyboardTypeNumberPad
                               blk:^(UITextField *textField) {
                                   [[XYExtensionConfig sharedInstance] setStepCount:MAX(0, textField.text.integerValue)];
                                   [self reloadTableViewData];
                               }];

}

////////////////////////////////////////////////////////////////////////
#pragma mark - 更新经纬度信息
////////////////////////////////////////////////////////////////////////
- (void)addModifyCoordinateCell {
    MMTableViewSectionInfo *sectionInfo = [objc_getClass("MMTableViewSectionInfo") sectionInfoHeader:@"" Footer:nil];
    [sectionInfo addCell:[self createChangeCoordinateSwitchCell]];
    
    BOOL shouldChangeCoordinate = [[XYExtensionConfig sharedInstance] shouldChangeCoordinate];
    if (shouldChangeCoordinate) {
        [sectionInfo addCell:[self createadLatitudeCell]];
        [sectionInfo addCell:[self createadLongitudeCell]];
        [sectionInfo addCell:[self createMapViewCell]];
    }
    [self.wx_tableViewInfo addSection:sectionInfo];
}

- (MMTableViewCellInfo *)createadLatitudeCell {
    double latitude = [[XYExtensionConfig sharedInstance] latitude];
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo")  normalCellForSel:@selector(updateLatitude) target:self title:@"修改的经度(latitude)" rightValue:[NSString stringWithFormat:@"%f", latitude] accessoryType:1];
    
    return cellInfo;
}
    
- (MMTableViewCellInfo *)createadLongitudeCell {
    double longitude = [[XYExtensionConfig sharedInstance] longitude];
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo")  normalCellForSel:@selector(updateLongitude) target:self title:@"修改的纬度(longitude)" rightValue:[NSString stringWithFormat:@"%f", longitude] accessoryType:1];
    
    return cellInfo;
}

- (MMTableViewCellInfo *)createMapViewCell {
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo")  normalCellForSel:@selector(jumpToMapView) target:self title:@"进入地图页选择位置" accessoryType:1];
    return cellInfo;
}

- (void)jumpToMapView {
    XYMapViewController *mvc = [[XYMapViewController alloc] init];
    [self showViewController:mvc sender:self];
}

    
/// 更新经度
- (void)updateLatitude {
    
    double latitude = [[XYExtensionConfig sharedInstance] latitude];
    [self alertControllerWithTitle:@"修改经度(latitude)"
                           message:@"请同时修改经度和纬度，若其中一个小于0则无效，关于经纬度的获取可去高德地图或百度地区，并转换为Wgs84"
                           content:[NSString stringWithFormat:@"%f", latitude]
                       placeholder:@"请输入经度"
                      keyboardType:UIKeyboardTypeDecimalPad
                               blk:^(UITextField *textField) {
                                   [[XYExtensionConfig sharedInstance] setLatitude:MAX(0.0, textField.text.doubleValue)];
                                   [self reloadTableViewData];
                               }];
}
    
/// 更新纬度
- (void)updateLongitude {
    double longitude = [[XYExtensionConfig sharedInstance] longitude];
    [self alertControllerWithTitle:@"修改纬度(longitude)"
                           message:@""
                           content:[NSString stringWithFormat:@"%f", longitude]
                       placeholder:@"请输入纬度"
                      keyboardType:UIKeyboardTypeDecimalPad
                               blk:^(UITextField *textField) {
                                   [[XYExtensionConfig sharedInstance] setLongitude:MAX(0.0, textField.text.doubleValue)];
                                   [self reloadTableViewData];
                               }];
}
    
/// 创建是否更新经纬度cell
- (MMTableViewCellInfo *)createChangeCoordinateSwitchCell {
    BOOL shouldChangeCoordinate = [[XYExtensionConfig sharedInstance] shouldChangeCoordinate];
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo") switchCellForSel:@selector(setShouldChangeCoordinate:) target:self title:@"修改经纬度" on:shouldChangeCoordinate];
    
    return cellInfo;
}
    
    
- (void)setShouldChangeCoordinate:(UISwitch *)sw {
    
    [XYExtensionConfig sharedInstance].shouldChangeCoordinate = sw.on;
    [self reloadTableViewData];
    
}

////////////////////////////////////////////////////////////////////////
#pragma mark - 沙盒操作
////////////////////////////////////////////////////////////////////////
    
- (void)addOperationSandBoxCell {
    MMTableViewSectionInfo *sectionInfo = [objc_getClass("MMTableViewSectionInfo") sectionInfoHeader:@"" Footer:nil];
    [sectionInfo addCell:[self createOperationSandBoxCell]];
    [self.wx_tableViewInfo addSection:sectionInfo];
}
    
- (MMTableViewCellInfo *)createOperationSandBoxCell {
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo")  normalCellForSel:@selector(goToSandBox) target:self title:@"操作沙盒" accessoryType:1];
    
    return cellInfo;
}
    
- (void)goToSandBox {
    FoldersViewController *vc = [[FoldersViewController alloc] initWithRootDirectory:NSHomeDirectory()];
    vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"back" style:UIBarButtonItemStylePlain target:self action:NSSelectorFromString(@"backButtonClick")];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    [self showDetailViewController:navController sender:self];
}
- (void)backButtonClick {
    [self dismissViewControllerAnimated:YES completion:nil];
}
    
////////////////////////////////////////////////////////////////////////
#pragma mark - Alert
////////////////////////////////////////////////////////////////////////
- (void)alertControllerWithTitle:(NSString *)title content:(NSString *)content placeholder:(NSString *)placeholder blk:(void (^)(UITextField *))blk {
    [self alertControllerWithTitle:title message:nil content:content placeholder:placeholder blk:blk];
}

- (void)alertControllerWithTitle:(NSString *)title message:(NSString *)message content:(NSString *)content placeholder:(NSString *)placeholder blk:(void (^)(UITextField *))blk {
    [self alertControllerWithTitle:title message:message content:content placeholder:placeholder keyboardType:UIKeyboardTypeDefault blk:blk];
}
    
- (void)alertControllerWithTitle:(NSString *)title message:(NSString *)message okBlk:(void (^)(void))okBlk cancelBlk:(void (^)(void))cancelBlk  {
    UIAlertController *alertController = ({
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:title
                                    message:message
                                    preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                                  style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                    if (cancelBlk) {
                                                        cancelBlk();
                                                    }
                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                    if (okBlk) {
                                                        okBlk();
                                                    }
                                                }]];
        
        alert;
    });
    
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)alertControllerWithTitle:(NSString *)title message:(NSString *)message content:(NSString *)content placeholder:(NSString *)placeholder keyboardType:(UIKeyboardType)keyboardType blk:(void (^)(UITextField *))blk  {
    UIAlertController *alertController = ({
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:title
                                    message:message
                                    preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                    if (blk) {
                                                        blk(alert.textFields.firstObject);
                                                    }
                                                }]];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = placeholder;
            textField.text = content;
            textField.keyboardType = keyboardType;
        }];
        
        alert;
    });
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end


@implementation UIViewController (XYViewControllerPrivate)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(viewDidAppear:);
        SEL swizzledSelector = @selector(xy_viewDidAppear:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        if (success) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)xy_viewDidAppear:(BOOL)animated {
    [self xy_viewDidAppear:animated];
    if ([UIDevice currentDevice].systemVersion.floatValue < 11.0f) {
        if (self.suspensionView) {
            [self.view bringSubviewToFront:self.suspensionView];
        }
    }
 
}


@end
#pragma mark *** 用于修改微信内部经纬度的分类 ***

@implementation CLLocation (XYLocationExtensions)
    
+ (void)load {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        Class class = [self class];
        
        SEL originalSelector = @selector(coordinate);
        SEL swizzledSelector = @selector(xy_coordinate);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
            
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}
    
- (CLLocationCoordinate2D)xy_coordinate {
    
    CLLocationCoordinate2D oldCoordinate = [self xy_coordinate];
    BOOL shouldChangeCoordinate = [[XYExtensionConfig sharedInstance] shouldChangeCoordinate];
    if (!shouldChangeCoordinate) {
        return oldCoordinate;
    }
    
    double longitude = [[XYExtensionConfig sharedInstance] longitude];
    double latitude = [[XYExtensionConfig sharedInstance] latitude];
    if (latitude <= 0.0 || latitude <= 0.0) {
        return oldCoordinate;
    }
    
    oldCoordinate.latitude = latitude;
    oldCoordinate.longitude = longitude;
    
    return oldCoordinate;
    
}
@end

#pragma mark *** 微信运动步数修改 ***
/**
 本次修改的步数若为负数或且小于已上传的步数时无效，最大值为98800
 WCDeviceStepObject是微信运动步数的类，它里面有两个属性是获取微信运动步数的，我觉得它应该是根据 HealthKit 是否可用然后去取不同的属性,
 把他们两个的 get 方法都替换了，就可以解决我们修改微信步数问题了
 @property(nonatomic) unsigned long hkStepCount;
 @property(nonatomic) unsigned long m7StepCount;
 */
@class WCDeviceStepObject;

CHDeclareClass(WCDeviceStepObject);

CHOptimizedMethod(0, self, unsigned long, WCDeviceStepObject, m7StepCount) {
    unsigned long newStepCount = [[XYExtensionConfig sharedInstance] stepCount];
    BOOL shouldChangeStep = [[XYExtensionConfig sharedInstance] shouldChangeStep];
    if (shouldChangeStep && newStepCount > 0) {
        return newStepCount;
    }
    
    // 我发现每次关闭了`手动更改微信运动步数时`，微信运动的步数就不会发改变了
    // 猜测可能是微信内部做了判断: 比如当当前m7StepCount小于上次上传时，就不会上次了，所以这里累加下我们手动修改的步数
    unsigned long m7StepCount = CHSuper(0,WCDeviceStepObject, m7StepCount);
    return m7StepCount + MAX(0, newStepCount);
}

CHOptimizedMethod(0, self, unsigned long, WCDeviceStepObject, hkStepCount) {
    
    unsigned long newStepCount = [[XYExtensionConfig sharedInstance] stepCount];
    BOOL shouldChangeStep = [[XYExtensionConfig sharedInstance] shouldChangeStep];
    if (shouldChangeStep && newStepCount > 0) {
        return newStepCount;
    }
    
    unsigned long hkStepCount = CHSuper(0, WCDeviceStepObject, hkStepCount);
    return hkStepCount + MAX(0, hkStepCount);
}

CHConstructor {
    @autoreleasepool {
        
        CHLoadLateClass(WCDeviceStepObject);
        
        CHHook(0, WCDeviceStepObject, m7StepCount);
        CHHook(0, WCDeviceStepObject, hkStepCount);
    }
}
