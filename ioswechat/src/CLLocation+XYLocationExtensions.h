//
//  CLLocation+XYLocationExtensions.h
//  WeChatExtensions
//
//  Created by Swae on 2017/10/28.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface CLLocation (XYLocationExtensions)

/// 获取默认的坐标
- (CLLocationCoordinate2D)xy_originalCoordinate;

@end
