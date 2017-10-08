//
//  XYExtensionConfig.h
//  WeChatPlugin
//
//  Created by Swae on 2017/10/8.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XYExtensionConfig : NSObject

@property (nonatomic, class, strong) XYExtensionConfig *sharedInstance;

/// 是否修改微信运动步数
@property (nonatomic, assign) BOOL shouldChangeStep;
/// 记录微信运动步数的值
@property (nonatomic, assign) NSInteger stepCount;

/// 是否修改经纬度
@property (nonatomic, assign) BOOL shouldChangeCoordinate;
/// 经度
@property (nonatomic, assign) double latitude;
/// 纬度
@property (nonatomic, assign) double longitude;
/// 在我们进行坐标选择的时候,需要使用原始的
@property (nonatomic, assign) BOOL useOriginalCordinate;

@end
