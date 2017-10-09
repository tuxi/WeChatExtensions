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

@implementation XYExtensionConfig

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
    return [[NSUserDefaults standardUserDefaults] integerForKey:XYStepCount];
}

- (void)setStepCount:(NSInteger)stepCount {
    [[NSUserDefaults standardUserDefaults] setInteger:stepCount forKey:XYStepCount];
    [[NSUserDefaults standardUserDefaults] synchronize];
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

@end
