//
//  XYExtensionMoudle.m
//  WeChatPlugin
//
//  Created by Swae on 2017/10/8.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "XYExtensionMoudle.h"

static NSString * const XYShouldChangeStepKey = @"ChangeStepEnableKey";
static NSString * const XYStepCount = @"DeviceStepKey";

@implementation XYExtensionMoudle

@dynamic sharedInstance;

+ (XYExtensionMoudle *)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self.alloc init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.shouldChangeStep = [[NSUserDefaults standardUserDefaults] boolForKey:XYShouldChangeStepKey];
        self.stepCount = [[NSUserDefaults standardUserDefaults] integerForKey:XYStepCount];
        
    }
    return self;
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

@end
