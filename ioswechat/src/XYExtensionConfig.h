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

/// 是否修改微信运动步数，当打开此开关时:若添加的stepCount大于当前微信服务器保存的步数时，则会上传本次修改的stepCount，否则我们添加的stepCount无效(原因微信内部做了最小值处理)，且stepCount未再次更改时，微信运动的步数一直都不会发生改变，知道下次修改；
/// 当关闭此开关时，由于微信运动上传的最小值必须大于当前服务器保存的步数，所以关闭开关时会将(hkStepCount或m7StepCount)+上次添加的stepCount步数，微信运动会正常上传步数
@property (nonatomic, assign) BOOL shouldChangeStep;
/// 记录添加的微信运动步数的值，注意: 不能为负数，且添加完成后，下次添加的值只有更多时才会生效，添加后不能取消不能减少
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
