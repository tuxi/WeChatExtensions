//
//  XYExtensionMoudle.h
//  WeChatPlugin
//
//  Created by Swae on 2017/10/8.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XYExtensionMoudle : NSObject

@property (nonatomic, class, strong) XYExtensionMoudle *sharedInstance;

/// 是否修改微信运动步数
@property (nonatomic, assign) BOOL shouldChangeStep;
/// 记录微信运动步数的值
@property (nonatomic, assign) NSInteger stepCount;

@end
