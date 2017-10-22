//
//  OSUnlockBackgroundView.h
//  FileDownloader
//
//  Created by Swae on 2017/10/22.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SmilePasswordContainerView.h"

/**
 解锁控制器的view
 */

@interface OSUnlockBackgroundView : UIView

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIButton *touchIDBtn;
@property (nonatomic, strong) SmilePasswordContainerView *passwordView;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UILabel *descLabel;

@end

