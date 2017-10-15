//
//  XYExtensionConfig.m
//  WeChatPlugin
//
//  Created by Swae on 2017/10/8.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "XYExtensionConfig.h"

static NSString * const XYShouldChangeStepKey = @"ChangeStepEnableKey";
static NSString * const XYStepCount = @"DeviceStepKey";
static NSString * const XYShouldChangeCoordinateKey = @"ShouldChangeCoordinate";
static NSString * const XYLatitudeValueKey = @"latitude";
static NSString * const XYLongitudeValueKey = @"longitude";
static NSString * const XYStepDateKey = @"stepDate";

@implementation XYExtensionConfig {
    /// 记录微信步数的日期
    NSDate *_stepDate;
}

@dynamic sharedInstance;

+ (XYExtensionConfig *)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self.alloc init];
    });
    return instance;
}

- (BOOL)shouldChangeStep {
    return [[NSUserDefaults standardUserDefaults] boolForKey:XYShouldChangeStepKey];
}

- (void)setShouldChangeStep:(BOOL)shouldChangeStep {
    [[NSUserDefaults standardUserDefaults] setBool:shouldChangeStep forKey:XYShouldChangeStepKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)stepCount {
    if (![self isToday:_stepDate]) {
        [self setStepCount:0];
    }
    return [[NSUserDefaults standardUserDefaults] integerForKey:XYStepCount];
}

- (void)setStepCount:(NSInteger)stepCount {
    _stepDate = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setInteger:stepCount forKey:XYStepCount];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setStepDate:(NSDate *)stepDate {
    [[NSUserDefaults standardUserDefaults] setObject:stepDate forKey:XYStepDateKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDate *)stepDate {
    return [[NSUserDefaults standardUserDefaults] objectForKey:XYStepDateKey];
}

- (BOOL)shouldChangeCoordinate {
    return [[NSUserDefaults standardUserDefaults] boolForKey:XYShouldChangeCoordinateKey];
}

- (void)setShouldChangeCoordinate:(BOOL)shouldChangeCoordinate {
    [[NSUserDefaults standardUserDefaults] setBool:shouldChangeCoordinate forKey:XYShouldChangeCoordinateKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (double)latitude {
    return [[NSUserDefaults standardUserDefaults] doubleForKey:XYLatitudeValueKey];
}

- (void)setLatitude:(double)latitude {
    [[NSUserDefaults standardUserDefaults] setDouble:latitude forKey:XYLatitudeValueKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (double)longitude {
   return [[NSUserDefaults standardUserDefaults] doubleForKey:XYLongitudeValueKey];
}

- (void)setLongitude:(double)longitude {
    [[NSUserDefaults standardUserDefaults] setDouble:longitude forKey:XYLongitudeValueKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isToday:(NSDate *)date {
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    int unit = NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear ;
    NSDateComponents *nowCmps = [calendar components:unit fromDate:[NSDate date]];
    NSDateComponents *selfCmps = [calendar components:unit fromDate:date];
    return (selfCmps.year == nowCmps.year) && (selfCmps.month == nowCmps.month) && (selfCmps.day == nowCmps.day);
}

@end
