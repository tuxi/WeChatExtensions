//
//  ExceptionUtils.m
//  ExceptionUtils
//
//  Created by xiaoyuan on 17/3/25.
//  Copyright © 2017年 erlinyou.com. All rights reserved.
//

#import "ExceptionUtils.h"

#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"


@implementation ExceptionUtils

////////////////////////////////////////////////////////////////////////
#pragma mark - crashCatch
////////////////////////////////////////////////////////////////////////

+ (void)configExceptionHandler {
    
    NSSetUncaughtExceptionHandler(&UncaughtExceptionHandler);
    getExceptionFilePath();
    [self configSystemDebugWindow];
}

+ (void)configSystemDebugWindow {
    
    Class debugClass = NSClassFromString(@"UIDebuggingInformationOverlay");
    [debugClass performSelector:NSSelectorFromString(@"prepareDebuggingOverlay")];
}


void UncaughtExceptionHandler(NSException *exception) {
    [ExceptionUtils saveFileWithError:exception];
}


+ (void)saveFileWithError:(NSException*)exception{
    NSString *exLog = [NSString stringWithFormat:@"发生异常的时间: %@;\n软件版本: %@ \n系统版本: %@\n异常名称: %@;\n异常原因: %@;\n详细信息: %@;\n函数栈描述: \n%@;\n**********************华丽的分割线**********************\n", dateToString([NSDate date]), [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[UIDevice currentDevice]systemVersion],exception.name, exception.reason, exception.userInfo ,[exception.callStackSymbols componentsJoinedByString:@"\n"]];
    
    NSString *fpath = getExceptionFilePath();
    writeToFile(exLog, fpath);
    
}



+ (void)openTestWindow {

    Class someClass = NSClassFromString(@"UIDebuggingInformationOverlay");
    id obj = [someClass performSelector:NSSelectorFromString(@"overlay")];
    [obj performSelector:NSSelectorFromString(@"toggleVisibility")];
    
}

static NSString * dateToString(NSDate *date) {
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterFullStyle];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}

static void writeToFile(NSString *text, NSString *filePath) {

    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    [fileHandle seekToEndOfFile];
    NSData* stringData  = [text dataUsingEncoding:NSUTF8StringEncoding];
    [fileHandle writeData:stringData];
    [fileHandle synchronizeFile];
    [fileHandle closeFile];
}

NSString * getExceptionFilePath() {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"exceptionLog.txt"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
    }
    return path;
}

@end

