//
//  FoldersViewController.h
//  FileBrowser
//
//  Created by Ossey on 2017/6/30.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>

@class FileAttributeItem;

@interface FoldersViewController : UIViewController <QLPreviewControllerDataSource, UITableViewDelegate, UITableViewDataSource>

- (instancetype)initWithRootDirectory:(NSString *)path;

@property (nonatomic, strong) NSString *rootDirectory;
@property (nonatomic, strong) NSArray<FileAttributeItem *> *files;
@property (nonatomic, strong) NSMutableArray<FileAttributeItem *> *selectorFiles;
@property (nonatomic, assign) BOOL displayHiddenFiles;
@property (nonatomic, assign) BOOL selectorMode;
@property (nonatomic, copy) void (^selectorFilsCompetionHandler)(NSArray<FileAttributeItem *> *fileitems);

@end
