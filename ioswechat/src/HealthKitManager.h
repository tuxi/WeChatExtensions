//
//  HealthKitManager.h
//  WeChatExtensions
//
//  Created by Swae on 2017/10/11.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIDevice.h>
#import <HealthKit/HealthKit.h>

#define HKVersion [[[UIDevice currentDevice] systemVersion] doubleValue]
#define CustomHealthErrorDomain @"com.sdqt.healthError"

@interface HealthKitManager : NSObject

@property (nonatomic, strong) HKHealthStore *healthStore;

+ (id)shareInstance;

- (void)authorizeHealthKit:(void(^)(BOOL success, NSError *error))compltion;

- (void)getStepCount:(void(^)(double value, NSError *error))completion;

- (void)getDistance:(void(^)(double value, NSError *error))completion;


@end
