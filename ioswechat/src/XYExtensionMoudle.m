//
//  XYExtensionMoudle.m
//  WeChatPlugin
//
//  Created by Swae on 2017/10/8.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "XYExtensionMoudle.h"

static NSString * const XYShouldChangeStepKey = @"KTKChangeStepEnableKey";
static NSString * const XYStepCount = @"kTKDeviceStepKey";

@implementation XYExtensionMoudle

@synthesize shouldChangeStep = _shouldChangeStep, stepCount = _stepCount;
@dynamic sharedInstance;

+ (XYExtensionMoudle *)sharedInstance {
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
    _shouldChangeStep = shouldChangeStep;
    [[NSUserDefaults standardUserDefaults] setBool:shouldChangeStep forKey:XYShouldChangeStepKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)stepCount {
    return [[NSUserDefaults standardUserDefaults] integerForKey:XYStepCount];
}

- (void)setStepCount:(NSInteger)stepCount {
    _stepCount = stepCount;
    [[NSUserDefaults standardUserDefaults] setInteger:stepCount forKey:XYStepCount];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
