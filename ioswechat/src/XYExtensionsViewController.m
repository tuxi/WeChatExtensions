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
#import "XYSuspensionMenu.h"
#import "SmileAuthenticator.h"
#import "OSAuthenticatorHelper.h"
#import "CLLocation+XYLocationExtensions.h"

#pragma mark *** 微信扩展控制器 ***

@interface XYExtensionsViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) MMTableViewInfo *wx_tableViewInfo;
@property (nonatomic, strong) UIImagePickerController *pickerViewController;

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
    [self addPasswordCell];
    
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
                           message:@"本次修改的步数若为负数或且小于已上传的步数时无效，最大值为98800，且只在当天有效"
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
#pragma mark - 设置启动密码
////////////////////////////////////////////////////////////////////////

- (void)addPasswordCell {
    MMTableViewSectionInfo *sectionInfo = [objc_getClass("MMTableViewSectionInfo") sectionInfoHeader:@"" Footer:nil];
    [sectionInfo addCell:[self createSetPasswordCell]];
    BOOL hasPssword = [SmileAuthenticator hasPassword];
    if (hasPssword) {
        [sectionInfo addCell:[self createChangePasswordCell]];
        [sectionInfo addCell:[self createUnlockBackgroundImageCell]];
        BOOL hasBackgroundImage = [[OSAuthenticatorHelper sharedInstance] hasBackgroundImage];
        if (hasBackgroundImage) {
            [sectionInfo addCell:[self createClearUnlockBackgroundImageCell]];
        }
        
    }
    [self.wx_tableViewInfo addSection:sectionInfo];
}

- (MMTableViewCellInfo *)createSetPasswordCell {
    BOOL hasPassword = [SmileAuthenticator hasPassword];
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo") switchCellForSel:@selector(passwordSwitch:) target:self title:@"设置启动密码" on:hasPassword];
    
    return cellInfo;
}

- (MMTableViewCellInfo *)createChangePasswordCell {
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo") normalCellForSel:@selector(changePassword:) target:self title:@"修改密码" accessoryType:1];
    
    return cellInfo;
}

- (MMTableViewCellInfo *)createUnlockBackgroundImageCell {
    
    NSString *title = @"修改解锁页背景图片";
    MMTableViewCellInfo *cellInfo = nil;
    BOOL hasBackgroundImage = [[OSAuthenticatorHelper sharedInstance] hasBackgroundImage];
    if (!hasBackgroundImage) {
        cellInfo = [objc_getClass("MMTableViewCellInfo") switchCellForSel:@selector(setUnlockBackgroundImage:) target:self title:title on:hasBackgroundImage];
    }
    else {
       cellInfo = [objc_getClass("MMTableViewCellInfo") normalCellForSel:@selector(setUnlockBackgroundImage:) target:self title:title accessoryType:1];
    }
    
    
    return cellInfo;
}


- (MMTableViewCellInfo *)createClearUnlockBackgroundImageCell {
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo") normalCellForSel:@selector(clearBackgroundImage:) target:self title:@"清除解锁背景图片" accessoryType:1];
    
    return cellInfo;
}

/// 清除背景图片
- (void)clearBackgroundImage:(id)obj {
    [[OSAuthenticatorHelper sharedInstance] clearBackgroundImage];
    [self reloadTableViewData];
}

- (void)changePassword:(id)sender {
    [SmileAuthenticator sharedInstance].securityType = INPUT_THREE;
    [[SmileAuthenticator sharedInstance] presentAuthViewControllerAnimated:TRUE showNavigation:TRUE];
}

- (void)passwordSwitch:(UISwitch *)passwordSwitch {
    if (passwordSwitch.on) {
        [SmileAuthenticator sharedInstance].securityType = INPUT_TWICE;
    } else {
        [SmileAuthenticator sharedInstance].securityType = INPUT_ONCE;
    }
    
    [[SmileAuthenticator sharedInstance] presentAuthViewControllerAnimated:TRUE showNavigation:TRUE];
    [self reloadTableViewData];
}

/// 设置解锁页背景图片
- (void)setUnlockBackgroundImage:(id)obj {
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"请选择图片来源" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    //从照相机拍照
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"照相机" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            self.pickerViewController = [[UIImagePickerController alloc] init];
            self.pickerViewController.delegate = self;//设置UIImagePickerController的代理，同时要遵循UIImagePickerControllerDelegate，UINavigationControllerDelegate协议
//            self.pickerViewController.allowsEditing = YES;//设置拍照之后图片是否可编辑，如果设置成可编辑的话会在代理方法返回的字典里面多一些键值。PS：如果在调用相机的时候允许照片可编辑，那么用户能编辑的照片的位置并不包括边角。
            self.pickerViewController.sourceType = UIImagePickerControllerSourceTypeCamera;//UIImagePicker选择器的数据来源，UIImagePickerControllerSourceTypeCamera说明数据来源于摄像头
            [self presentViewController:self.pickerViewController animated:YES completion:nil];
        }else{
            
            NSLog(@"哎呀,没有摄像头");
        }
        
    }];
    
    //从手机相册选取
    UIAlertAction *photoAction = [UIAlertAction actionWithTitle:@"相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
            self.pickerViewController = [[UIImagePickerController alloc]init];
            self.pickerViewController.delegate = self;
//            self.pickerViewController.allowsEditing = YES;//是否可以对原图进行编辑
            
            //设置图片选择器的数据来源为手机相册
            self.pickerViewController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self presentViewController:self.pickerViewController animated:YES completion:nil];
        }
        else{
            
            NSLog(@"图片库不可用");
            
        }
    }];
    
    //取消
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alertC addAction:cameraAction];
    [alertC addAction:photoAction];
    [alertC addAction:cancelAction];
    [self presentViewController:alertC animated:YES completion:nil];
    
    [self reloadTableViewData];
}

- (void)disclosureSwitchChanged:(UISwitch *)sw {
    [self passwordSwitch:sw];
}

#pragma mark - UIImagePickerControllerDelegate
/// 拍照/选择图片结束
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    //获取图片
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];//原始图片
//    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];//编辑后的图片
    
    [[OSAuthenticatorHelper sharedInstance] saveImage:image];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self reloadTableViewData];
}

/// 取消拍照/选择图片
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self reloadTableViewData];
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
