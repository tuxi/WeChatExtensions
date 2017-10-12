//
//  NSObject+IvarList.m
//  NSObject
//
//  Created by Ossey on 2017/6/29.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "NSObject+IvarList.h"
#import <objc/runtime.h>

@implementation NSObject (IvarList)

- (NSDictionary *)alLPropertyToDictonary {
    NSMutableDictionary *dict = @{}.mutableCopy;
    unsigned int propsCount;
    objc_property_t *props = class_copyPropertyList([self class], &propsCount);
    for(int i = 0;i < propsCount; i++) {
        objc_property_t prop = props[i];
        id value = nil;
        
        @try {
            NSString *propName = [NSString stringWithUTF8String:property_getName(prop)];
            value = [[self valueForKey:propName] _objectToDictionaryByIavr:NO];
            if(value != nil) {
                [dict setObject:value forKey:propName];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"%@",exception);
        }
        
    }
    free(props);
    return dict;
}

- (NSDictionary *)allIvarToDictionary {
    NSMutableDictionary *dict = @{}.mutableCopy;
    unsigned int ivarsCount;
    // 获取所有成员变量，包括@interface下{}下声明的和@property声明的，
    // 注意和class_copyPropertyList还有区别的是class_copyPropertyList获取的成员变量名称不会在名称前面加"_"
    // class_copyIvarList获取的以@property声明的成员变量名会在前面加"_"，@interface下{}下声明的还是原名称，如果有就是原名称，不会再加"_"
    Ivar *ivars =class_copyIvarList([self class], &ivarsCount);
    for (NSInteger i = 0; i < ivarsCount; ++i) {
        Ivar ivar = ivars[i];
        id value = nil;
        @try {
            NSString *propName = [NSString stringWithUTF8String:ivar_getName(ivar)];
            // kvc的方式 通过属性名获取值, 并对value进行处理
            value = [[self valueForKey:propName] _objectToDictionaryByIavr:YES];
            if(value != nil) {
                // 成员变量名转为属性名（去掉下划线 _ ）
                if ([propName hasPrefix:@"_"]) {
                    propName = [propName substringFromIndex:1];
                }
                [dict setObject:value forKey:propName];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"%@",exception);
        }
        
    }
    free(ivars);
    return dict;
}

/// 处理数组或字典类型中的值
- (id)_objectToDictionaryByIavr:(BOOL)isIvar
{
    //    [NSBundle mainBundle]就是测试这个类是不是在沙盒里面。是的就是自定义的，不是就是系统的
    //    NSBundle *mainB = [NSBundle bundleForClass:[self class]];
    //    if (mainB == [NSBundle mainBundle]) { // 自定义的类
    //        if (isIvar) {
    //            return [self allIvarToDictionary];
    //        }
    //        return [self alLPropertyToDictonary];
    //    }
    
    // 系统类
    if([self isKindOfClass:[NSString class]]
       || [self isKindOfClass:[NSNumber class]]
       || [self isKindOfClass:[NSNull class]]) {
        return self;
    }
    
    if([self isKindOfClass:[NSArray class]]) {
        NSArray *objarr = (NSArray *)self;
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:objarr.count];
        for(int i = 0;i < objarr.count; i++) {
            [arr setObject:[[objarr objectAtIndex:i] _objectToDictionaryByIavr:isIvar] atIndexedSubscript:i];
        }
        return arr;
    }
    
    if([self isKindOfClass:[NSDictionary class]]) {
        NSDictionary *objdic = (NSDictionary *)self;
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:[objdic count]];
        for(NSString *key in objdic.allKeys) {
            [dic setObject:[[objdic objectForKey:key] _objectToDictionaryByIavr:isIvar] forKey:key];
        }
        return dic;
    }
    if (isIvar) {
        return [self allIvarToDictionary];
    }
    return [self alLPropertyToDictonary];
    
    
}


@end
