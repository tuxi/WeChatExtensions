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
#pragma mark - 修改微信运动步数Cell
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
    BOOL shouldChangeStep = [[XYExtensionConfig sharedInstance] shouldChangeStep];
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo") switchCellForSel:@selector(setShouldChangeStep:) target:self title:@"是否修改微信运动步数" on:shouldChangeStep];
    
    return cellInfo;
}

- (MMTableViewCellInfo *)createStepCountCell {
    NSInteger deviceStep = [[XYExtensionConfig sharedInstance] stepCount];
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo")  normalCellForSel:@selector(updateStepCount) target:self title:@"微信运动步数" rightValue:[NSString stringWithFormat:@"%ld", (long)deviceStep] accessoryType:1];
    
    return cellInfo;
}

- (void)setShouldChangeStep:(UISwitch *)sw {
    [[XYExtensionConfig sharedInstance] setShouldChangeStep:sw.on];
    [self reloadTableViewData];
}

- (void)updateStepCount {
    NSInteger stepCount = [[XYExtensionConfig sharedInstance] stepCount];
    [self alertControllerWithTitle:@"微信运动设置"
                           message:@"步数需比之前设置的步数大才能生效，最大值为98800"
                           content:[NSString stringWithFormat:@"%ld", (long)stepCount]
                       placeholder:@"请输入步数"
                      keyboardType:UIKeyboardTypeNumberPad
                               blk:^(UITextField *textField) {
                                   [[XYExtensionConfig sharedInstance] setStepCount:textField.text.integerValue];
                                   [self reloadTableViewData];
                               }];

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


/*
 WCDeviceStepObject是微信运动步数的类，它里面有两个属性是获取微信运动步数的，我觉得它应该是根据 HealthKit 是否可用然后去取不同的属性,
 把他们两个的 get 方法都替换了，就可以解决我们修改微信步数问题了
 @property(nonatomic) unsigned long hkStepCount;
 @property(nonatomic) unsigned long m7StepCount;
 */
@class WCDeviceStepObject;

CHDeclareClass(WCDeviceStepObject);

CHOptimizedMethod(0, self, unsigned long, WCDeviceStepObject, m7StepCount) {
    NSInteger newStepCount = [[XYExtensionConfig sharedInstance] stepCount];
    BOOL changeStepEnable = [[XYExtensionConfig sharedInstance] shouldChangeStep];
    if (changeStepEnable && newStepCount > 0) {
        return newStepCount;
    }
    return CHSuper(0,WCDeviceStepObject,m7StepCount);
    
}

CHOptimizedMethod(0, self, unsigned long, WCDeviceStepObject, hkStepCount) {
    
    NSInteger newStepCount = [[XYExtensionConfig sharedInstance] stepCount];
    BOOL changeStepEnable = [[XYExtensionConfig sharedInstance] shouldChangeStep];
    if (changeStepEnable && newStepCount > 0) {
        return newStepCount;
    }
    return CHSuper(0,WCDeviceStepObject,m7StepCount);
}

CHConstructor {
    @autoreleasepool {
        
        CHLoadLateClass(WCDeviceStepObject);
        
        CHHook(0, WCDeviceStepObject, m7StepCount);
        CHHook(0, WCDeviceStepObject, hkStepCount);
    }
}
