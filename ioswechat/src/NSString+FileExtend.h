//
//  NSString+FileExtend.h
//  FileBrowser
//
//  Created by Ossey on 2017/7/19.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (FileExtend)

/// 对文件夹中的文件按照日期排序
- (NSArray *)getFilesByModDateWithDisplayHiddenFiles:(BOOL)flag;
+ (NSString *)transformedFileSizeValue:(NSNumber *)value;
+ (NSString *)stringWithRemainingTime:(NSInteger)secs;
- (unsigned long long)fileSize;
/// 修改文件时间
- (BOOL)updateFileModificationDateForFilePath;


@end
