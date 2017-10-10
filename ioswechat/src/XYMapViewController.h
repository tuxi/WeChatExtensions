//
//  XYMapViewController.h
//  WeChatExtensions
//
//  Created by Swae on 2017/10/11.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XYMapViewController : UIViewController

@property (nonatomic, strong) UIView *backBGView;
@property (nonatomic, strong) UILabel *addressLabel;
@property (nonatomic, strong) UILabel *longitudeLabel;//经度
@property (nonatomic, strong) UILabel *latitudeLabel;//纬度

@property (nonatomic, strong) UIButton *currentLocationBtn;

@end
