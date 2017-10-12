//
//  NSObject+IvarList.h
//  NSObject
//
//  Created by Ossey on 2017/6/29.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (IvarList)

/// 将调用者对象的所有成员属性转换为字典，包含@'interface'下声明的('_'已去除)
- (NSDictionary *)allIvarToDictionary;
/// 将调用者对象的所有成员属性转换为字典，不包含@'interface'下声明的
- (NSDictionary *)alLPropertyToDictonary;

@end
