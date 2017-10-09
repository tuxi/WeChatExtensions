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

#pragma mark *** 微信扩展控制器 ***

@interface XYExtensionsViewController ()

@property (nonatomic, strong) MMTableViewInfo *wx_tableViewInfo;

@end

@implementation XYExtensionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self reloadTableViewData];
    [self setupUI];
    
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

/// 更改经纬度cell
- (void)addModifyCell {
    
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
