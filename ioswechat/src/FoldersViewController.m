//
//  FoldersViewController.m
//  FileBrowser
//
//  Created by Ossey on 2017/6/30.
//  Copyright © 2017年 Ossey. All rights reserved.
//


#import "FoldersViewController.h"
#import "OSFileManager.h"
#import "MBProgressHUD.h"
#import "NSString+FileExtend.h"
#import "DirectoryWatcher.h"

static void * FileProgressObserverContext = &FileProgressObserverContext;

#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Warc-retain-cycles"

@interface FileAttributeItem : NSObject

@property (nonatomic, copy) NSString *fullPath;
@property (nonatomic, assign) NSUInteger subFileCount;

@end


@interface FileTableViewCell : UITableViewCell

@property (nonatomic, strong) FileAttributeItem *fileModel;

@end


@interface FilePreviewViewController : UIViewController {
    UITextView *_textView;
    UIImageView *_imageView;
}

@property (nonatomic, copy) NSString *filePath;

- (instancetype)initWithPath:(NSString *)file;

@end

#pragma mark *** FoldersViewController ***


#ifdef __IPHONE_9_0
@interface FoldersViewController () <UIViewControllerPreviewingDelegate>
#else
@interface FoldersViewController ()
#endif

{
    DirectoryWatcher *_currentFolderHelper;
    DirectoryWatcher *_documentFolderHelper;
}


@property (nonatomic, strong) UILongPressGestureRecognizer *longPress;
@property (nonatomic, copy) void (^longPressCallBack)(NSIndexPath *indexPath);
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) UIProgressView *progressBar;
@property (nonatomic, strong) UILabel *pathLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIButton *selectorButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, copy) NSString *selectorFilenNewName;
@property (nonatomic, strong) NSOperationQueue *loadFileQueue;
@property (nonatomic, strong) OSFileManager *fileManager;
@property (nonatomic, strong) MBProgressHUD *hud;

@end

@implementation FoldersViewController


////////////////////////////////////////////////////////////////////////
#pragma mark - Initialize
////////////////////////////////////////////////////////////////////////

- (instancetype)initWithRootDirectory:(NSString *)path {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _fileManager = [OSFileManager defaultManager];
        self.rootDirectory = path;
        _displayHiddenFiles = NO;
        self.title = [self.rootDirectory lastPathComponent];
        _loadFileQueue = [NSOperationQueue new];
        UIButton *selectorBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        self.selectorButton = selectorBtn;
        [selectorBtn setTitle:@"add" forState:UIControlStateNormal];
        [selectorBtn setTitleColor:[UIColor redColor]
                          forState:UIControlStateNormal];
        [selectorBtn sizeToFit];
        [selectorBtn addTarget:self
                        action:@selector(chooseSandBoxDocumentFiles)
              forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *rightBarButton2 = [[UIBarButtonItem alloc] initWithCustomView:selectorBtn];
        self.navigationItem.rightBarButtonItems = @[rightBarButton2];
        
//        __weak typeof(self) weakSelf = self;
        NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        _currentFolderHelper = [DirectoryWatcher watchFolderWithPath:self.rootDirectory directoryDidChange:^(DirectoryWatcher *folderWatcher) {
            [self reloadFiles];
        }];
        
        if (![self.rootDirectory isEqualToString:documentPath]) {
            _documentFolderHelper = [DirectoryWatcher watchFolderWithPath:documentPath directoryDidChange:^(DirectoryWatcher *folderWatcher) {
                [self reloadFiles];
            }];
        }
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
//    __weak typeof(self) weakSelf = self;
    [self loadFile:self.rootDirectory completion:^(NSArray *fileItems) {
        self.files = fileItems.copy;
        [self.tableView reloadData];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self check3DTouch];
    self.pathLabel.text = self.rootDirectory;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)setupUI {
    UIBarButtonItem *leftBarItem = self.navigationItem.leftBarButtonItem;
    UIButton *leftBarButton = leftBarItem.customView;
    [leftBarButton setTitle:@"back" forState:UIControlStateNormal];
    [leftBarButton setImage:nil forState:UIControlStateNormal];
    [leftBarButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.pathLabel];
    [self.view addSubview:self.progressBar];
    self.pathLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressBar.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSDictionary *viewsDictionary = @{@"pathLabel" : self.pathLabel, @"tableView": self.tableView, @"progressBar": self.progressBar};
    
    NSArray *constraints = @[
                             [NSLayoutConstraint constraintsWithVisualFormat:@"|[tableView]|" options:NSLayoutFormatAlignAllLeading | NSLayoutFormatAlignAllRight metrics:nil views:viewsDictionary],
                             [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|" options:kNilOptions metrics:nil views:viewsDictionary],
                             [NSLayoutConstraint constraintsWithVisualFormat:@"|-10-[pathLabel]-10-|" options:NSLayoutFormatAlignAllLeading | NSLayoutFormatAlignAllRight metrics:nil views:viewsDictionary],
                             [NSLayoutConstraint constraintsWithVisualFormat:@"V:[pathLabel]-1-|" options:kNilOptions metrics:nil views:viewsDictionary],
                             [NSLayoutConstraint constraintsWithVisualFormat:@"|[progressBar]|" options:NSLayoutFormatAlignAllLeading | NSLayoutFormatAlignAllRight metrics:nil views:viewsDictionary],
                             @[
                                 [NSLayoutConstraint constraintWithItem:self.progressBar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.tableView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-0.5]
                                 ]
                             ];
    [self.view addConstraints:[constraints valueForKeyPath:@"@unionOfArrays.self"]];
}


- (void)setSelectorMode:(BOOL)selectorMode {
    if (_selectorMode == selectorMode) {
        return;
    }
    _selectorMode = selectorMode;
    if (selectorMode) {
        if (self.selectorFiles.count > 0) {
            [self.selectorFiles removeAllObjects];
        }
        UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.deleteButton = deleteButton;
        [deleteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [deleteButton setTitle:@"delete" forState:UIControlStateNormal];
        [deleteButton sizeToFit];
        [deleteButton addTarget:self action:@selector(deleteFileFromSelectorFiles) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *rightBarButton1 = [[UIBarButtonItem alloc] initWithCustomView:deleteButton];
        
        [self.selectorButton setTitle:@"ok" forState:UIControlStateNormal];
        UIBarButtonItem *rightBarButton2 = [[UIBarButtonItem alloc]initWithCustomView:self.selectorButton];
        self.navigationItem.rightBarButtonItems = @[rightBarButton1, rightBarButton2];
        // 编辑模式的时候可以多选
        self.tableView.allowsMultipleSelectionDuringEditing = YES;
        
    } else {
        UIButton *selectorBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        self.selectorButton = selectorBtn;
        [selectorBtn setTitle:@"add" forState:UIControlStateNormal];
        [selectorBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [selectorBtn sizeToFit];
        [selectorBtn addTarget:self action:@selector(chooseSandBoxDocumentFiles) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *rightBarButton2 = [[UIBarButtonItem alloc] initWithCustomView:selectorBtn];
        self.navigationItem.rightBarButtonItems = @[rightBarButton2];
    }
    [self.tableView setEditing:selectorMode animated:YES];
    
}

- (void)loadFile:(NSString *)directoryPath completion:(void (^)(NSArray *fileItems))completion {
    [_loadFileQueue addOperationWithBlock:^{
        
        NSError *error = nil;
        NSArray *tempFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];
        if (error) {
            NSLog(@"Error: %@", error);
        }
        NSArray *files = [self sortedFiles:tempFiles];
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:files.count];
        [files enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            FileAttributeItem *model = [FileAttributeItem new];
            NSString *fullPath = [directoryPath stringByAppendingPathComponent:obj];
            model.fullPath = fullPath;
            NSError *error = nil;
            NSArray *subFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPath error:&error];
            if (!error) {
                if (!_displayHiddenFiles) {
                    subFiles = [self removeHiddenFilesFromFiles:subFiles];
                }
                model.subFileCount = subFiles.count;
            }
            
            [array addObject:model];
        }];
        
        if (!_displayHiddenFiles) {
            array = [[self removeHiddenFilesFromFiles:array] mutableCopy];
        }
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(array);
            });
        }
    }];
}

- (void)setDisplayHiddenFiles:(BOOL)displayHiddenFiles {
    if (_displayHiddenFiles == displayHiddenFiles) {
        return;
    }
    _displayHiddenFiles = displayHiddenFiles;
//    __weak typeof(self) weakSelf = self;
    [self loadFile:self.rootDirectory completion:^(NSArray *fileItems) {
        self.files = fileItems.copy;
        [self.tableView reloadData];
    }];
}

- (NSArray *)removeHiddenFilesFromFiles:(NSArray *)files {
    @synchronized (self) {
        NSMutableArray *tempFiles = [files mutableCopy];
        NSIndexSet *indexSet = [tempFiles indexesOfObjectsPassingTest:^BOOL(FileAttributeItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[FileAttributeItem class]]) {
                return [obj.fullPath.lastPathComponent hasPrefix:@"."];
            } else if ([obj isKindOfClass:[NSString class]]) {
                NSString *path = (NSString *)obj;
                return [path.lastPathComponent hasPrefix:@"."];
            }
            return NO;
        }];
        [tempFiles removeObjectsAtIndexes:indexSet];
        return tempFiles;
    }
    
}


- (void)reloadFiles {
//    __weak typeof(self) weakSelf = self;
    [self loadFile:self.rootDirectory completion:^(NSArray *fileItems) {
        self.files = fileItems.copy;
        [self.tableView reloadData];
    }];
    
}

- (void)deleteFileFromSelectorFiles {
    [self.selectorFiles enumerateObjectsUsingBlock:^(FileAttributeItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *fullPath = obj.fullPath;
        NSError *removeError = nil;
        [[NSFileManager defaultManager] removeItemAtPath:fullPath error:&removeError];
        if (removeError) {
            NSLog(@"Error: remove error[%@]", removeError.localizedDescription);
        }
    }];
}

- (void)chooseSandBoxDocumentFiles {
    
    if ([self.selectorButton.currentTitle isEqualToString:@"add"]) {
        // 跳转到沙盒document目录下的文件，并将选择的文件copy到当前目录下
        FoldersViewController *vc = [[FoldersViewController alloc] initWithRootDirectory:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject];
        vc.selectorMode = YES;
//        __weak typeof(self) weakSelf = self;
        [self.navigationController showViewController:vc sender:self];
        
        vc.selectorFilsCompetionHandler = ^(NSArray *selectorFiles) {
            
            [self copyFiles:selectorFiles toRootDirectory:self.rootDirectory];
        };
    } else {
        
        
        [self.navigationController popViewControllerAnimated:YES];
        
        if (self.selectorFilsCompetionHandler) {
            void (^selectorFilsCompetionHandler)(NSArray *fileItems) = self.selectorFilsCompetionHandler;
            self.selectorFilsCompetionHandler = nil;
            selectorFilsCompetionHandler(self.selectorFiles);
        }
    }
    
}

- (MBProgressHUD *)hud {
    if (!_hud) {
        _hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:YES];
        [_hud.button setTitle:NSLocalizedString(@"Cancel", @"HUD cancel button title") forState:UIControlStateNormal];
        _hud.mode = MBProgressHUDModeDeterminate;
        [_hud.button addTarget:self action:@selector(cancelFileOperation:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _hud;
}

- (void)copyFiles:(NSArray<FileAttributeItem *> *)fileItems toRootDirectory:(NSString *)rootPath {
    if (!fileItems.count) {
        return;
    }
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        [fileItems enumerateObjectsUsingBlock:^(FileAttributeItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSString *desPath = [rootPath stringByAppendingPathComponent:[obj.fullPath lastPathComponent]];
            if ([desPath isEqualToString:obj.fullPath]) {
                NSLog(@"路径相同");
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.hud.labelText = @"路径相同";
                });
                return;
            }
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:desPath]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.hud.labelText = @"存在相同文件，正在移除原文件";
                });
                NSError *removeError = nil;
                [[NSFileManager defaultManager] removeItemAtPath:desPath error:&removeError];
                if (removeError) {
                    NSLog(@"Error: %@", removeError.localizedDescription);
                }
            }
        }];
    }];
    
    NSMutableArray *hudDetailTextArray = @[].mutableCopy;
    
    void (^hudDetailTextCallBack)(NSString *detailText, NSInteger index) = ^(NSString *detailText, NSInteger index){
        @synchronized (hudDetailTextArray) {
            [hudDetailTextArray replaceObjectAtIndex:index withObject:detailText];
        }
    };
    
    
    operation.completionBlock = ^{
        [fileItems enumerateObjectsUsingBlock:^(FileAttributeItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [hudDetailTextArray addObject:@(idx).stringValue];
            NSString *desPath = [rootPath stringByAppendingPathComponent:[obj.fullPath lastPathComponent]];
            NSURL *desURL = [NSURL fileURLWithPath:desPath];
            
            __unused id<OSFileOperation> fileOperation = [_fileManager copyItemAtURL:[NSURL fileURLWithPath:obj.fullPath] toURL:desURL progress:^(NSProgress *progress) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *completionSize = [NSString transformedFileSizeValue:@(progress.completedUnitCount)];
                    NSString *totalSize = [NSString transformedFileSizeValue:@(progress.totalUnitCount)];
                    NSString *prcent = [FoldersViewController percentageString:progress.fractionCompleted];
                    NSString *detailText = [NSString stringWithFormat:@"%@  %@/%@", prcent, completionSize, totalSize];
                    hudDetailTextCallBack(detailText, idx);
                });
            } completionHandler:^(id<OSFileOperation> fileOperation, NSError *error) {
                
            }];
        }];
    };
    
    
    
    [_loadFileQueue addOperation:operation];
    
//    __weak typeof(self) weakSelf = self;
    
    _fileManager.totalProgressBlock = ^(NSProgress *progress) {
//        __strong typeof(weakSelf) strongSelf = weakSelf;
        self.hud.labelText = [NSString stringWithFormat:@"total:%@  %lld/%lld", [FoldersViewController percentageString:progress.fractionCompleted], progress.completedUnitCount, progress.totalUnitCount];
        self.progressBar.progress = progress.fractionCompleted;
        self.hud.progress = progress.fractionCompleted;
        @synchronized (hudDetailTextArray) {
            NSString *detailStr = [hudDetailTextArray componentsJoinedByString:@",\n"];
            self.hud.detailsLabel.text = detailStr;
            
        }
        if (progress.fractionCompleted >= 1.0 || progress.completedUnitCount >= progress.totalUnitCount) {
            self.hud.labelText = @"copy success";
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].delegate.window animated:YES];
                self.hud = nil;
            });
        }
    };
}


- (void)cancelFileOperation:(id)sender {
    [_fileManager cancelAllOperation];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].delegate.window animated:YES];
        self.hud = nil;
    });
}

/// Apple 官方提供的浮点型换算为百分比的方法，但是CFNumberFormatterRef不必多次malloc，会造成内存飙升
+ (NSString *)percentageString:(float)percent {
    static CFLocaleRef currentLocale = NULL;
    static CFNumberFormatterRef numberFormatter = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        currentLocale = CFLocaleCopyCurrent();
        numberFormatter = CFNumberFormatterCreate(NULL, currentLocale, kCFNumberFormatterPercentStyle);
    });
    CFNumberRef number = CFNumberCreate(NULL, kCFNumberFloatType, &percent);
    CFStringRef numberString = CFNumberFormatterCreateStringWithNumber(NULL, numberFormatter, number);
    CFRelease(number);
    CFRelease(numberString);
    return (__bridge NSString *)numberString;
}

- (void)check3DTouch {
    /// 检测是否有3d touch 功能
    if ([self respondsToSelector:@selector(traitCollection)]) {
        if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
            if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
                // 支持3D Touch
                if ([self respondsToSelector:@selector(registerForPreviewingWithDelegate:sourceView:)]) {
                    [self registerForPreviewingWithDelegate:self sourceView:self.view];
                    self.longPress.enabled = NO;
                }
            } else {
                // 不支持3D Touch
                self.longPress.enabled = YES;
            }
        }
    }
}


////////////////////////////////////////////////////////////////////////
#pragma mark - 3D Touch Delegate
////////////////////////////////////////////////////////////////////////

#ifdef __IPHONE_9_0
- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    // 需要将location在self.view上的坐标转换到tableView上，才能从tableView上获取到当前indexPath
    CGPoint targetLocation = [self.view convertPoint:location toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:targetLocation];
    _indexPath = indexPath;
    UIViewController *vc = [self previewControllerByIndexPath:indexPath];
    // 预览区域大小(可不设置)
    vc.preferredContentSize = CGSizeMake(0, 320);
    return vc;
}



- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self showViewController:viewControllerToCommit sender:self];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    
    [self check3DTouch];
}

#endif


////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDataSource
////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FileTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([FileTableViewCell class])];
    if (cell == nil) {
        cell = [[FileTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:NSStringFromClass([FileTableViewCell class])];
    }
    
    cell.fileModel = self.files[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    
    self.indexPath = indexPath;
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"more operation" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"share" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self shareAction];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"info" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
        [self infoAction];
        
    }]];
    [self presentViewController:alert animated:YES completion:nil];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.selectorMode == YES) {
        [self.selectorFiles addObject:self.files[indexPath.row]];
    } else {
        self.indexPath = indexPath;
        UIViewController *vc = [self previewControllerByIndexPath:indexPath];
        [self jumpToDetailControllerToViewController:vc atIndexPath:indexPath];
    }
}



- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    //从选中中取消
    if (self.selectorFiles.count > 0) {
        [self.selectorFiles removeObject:self.files[indexPath.row]];
    }
    
}

- (void)jumpToDetailControllerToViewController:(UIViewController *)viewController atIndexPath:(NSIndexPath *)indexPath {
    NSString *newPath = self.files[indexPath.row].fullPath;
    BOOL isDirectory;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:newPath isDirectory:&isDirectory];
    NSURL *url = [NSURL fileURLWithPath:newPath];
    if (fileExists) {
        if (isDirectory) {
            FoldersViewController *vc = (FoldersViewController *)viewController;
            [self.navigationController showViewController:vc sender:self];
            
        } else if (![QLPreviewController canPreviewItem:url]) {
            FilePreviewViewController *preview = (FilePreviewViewController *)viewController;
            preview.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"back" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClick)];
            UINavigationController *detailNavController = [[UINavigationController alloc] initWithRootViewController:preview];
            
            [self.navigationController showDetailViewController:detailNavController sender:self];
        } else {
            
            QLPreviewController *preview = (QLPreviewController *)viewController;
            preview.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"back" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClick)];
            UINavigationController *detailNavController = [[UINavigationController alloc] initWithRootViewController:preview];
            [self.navigationController showDetailViewController:detailNavController sender:self];
        }
    }
}


- (UIViewController *)previewControllerByIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath || !self.files.count) {
        return nil;
    }
    NSString *newPath = self.files[indexPath.row].fullPath;
    NSURL *url = [NSURL fileURLWithPath:newPath];
    BOOL isDirectory;
    BOOL fileExists = [[NSFileManager defaultManager ] fileExistsAtPath:newPath isDirectory:&isDirectory];
    UIViewController *vc = nil;
    if (fileExists) {
        if (isDirectory) {
            vc = [[FoldersViewController alloc] initWithRootDirectory:newPath];
            
        } else if (![QLPreviewController canPreviewItem:url]) {
            vc = [[FilePreviewViewController alloc] initWithPath:newPath];
        } else {
            QLPreviewController *preview= [[QLPreviewController alloc] init];
            preview.dataSource = self;
            vc = preview;
        }
    }
    return vc;
}

- (void)backButtonClick {
    UINavigationController * navigationController = (UINavigationController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    UIViewController *presentingViewController = nil;
    if ([navigationController isKindOfClass:[UINavigationController class]]) {
        presentingViewController = navigationController.topViewController.presentingViewController;
    }
    else if (self.navigationController) {
        presentingViewController = self.navigationController.topViewController.presentingViewController;
    }
    if (self.presentingViewController || presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)deleteFileAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.files.count) {
        return;
    }
    NSString *currentPath = self.files[indexPath.row].fullPath;
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:currentPath error:&error];
    if (error) {
        [[[UIAlertView alloc] initWithTitle:@"Remove error" message:nil delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil] show];
    }
    //    [self reloadFiles];
    NSMutableArray *arr = self.files.mutableCopy;
    [arr removeObjectAtIndex:indexPath.row];
    self.files = arr;
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)selectorAll {
    if (self.selectorFiles.count) {
        [self.selectorFiles removeAllObjects];
    }
    for (int i = 0; i < self.files.count; i++) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
        UITableViewCell *cell = (UITableViewCell *)[self.tableView cellForRowAtIndexPath:path];
        cell.selected = YES;
        [self.selectorFiles addObject:self.files[i]];//添加到选中列表
        
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDelegate
////////////////////////////////////////////////////////////////////////

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"delete";
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewRowAction *changeAction = [UITableViewRowAction rowActionWithStyle:(UITableViewRowActionStyleDefault) title:@"rename" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"rename" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"请输入需要修改的名字";
            [textField addTarget:self action:@selector(alertViewTextFieldtextChange:) forControlEvents:UIControlEventEditingChanged];
        }];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            if ([self.selectorFilenNewName containsString:@"/"]) {
                NSLog(@"文件名称不符合");
                return;
            }
            
            NSString *currentPath = self.files[indexPath.row].fullPath;
            NSString *newPath = [self.rootDirectory stringByAppendingPathComponent:self.selectorFilenNewName];
            BOOL res = [[NSFileManager defaultManager] fileExistsAtPath:newPath];
            if (res) {
                NSLog(@"存在同名的文件");
                return;
            }
            NSError *moveError = nil;
            [[NSFileManager defaultManager] moveItemAtPath:currentPath toPath:newPath error:&moveError];
            if (!moveError) {
                [newPath updateFileModificationDateForFilePath];
                NSString *selectorFullPath = [self.rootDirectory stringByAppendingPathComponent:self.selectorFilenNewName];
                FileAttributeItem *fileItem = self.files[indexPath.row];
                fileItem.fullPath = selectorFullPath;
            } else {
                NSLog(@"%@", moveError.localizedDescription);
            }
            self.selectorFilenNewName = nil;
            [self.tableView reloadData];
        }]];
        [self presentViewController:alert animated:true completion:nil];
    }];
    changeAction.backgroundColor = [UIColor orangeColor];
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:(UITableViewRowActionStyleDefault) title:@"delete" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确定删除吗" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self deleteFileAtIndexPath:indexPath];
        }]];
        [self presentViewController:alert animated:true completion:nil];
    }];
    deleteAction.backgroundColor = [UIColor redColor];
    
    UITableViewRowAction *copyAction = [UITableViewRowAction rowActionWithStyle:(UITableViewRowActionStyleDefault) title:@"copy" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        FileAttributeItem *item = self.files[indexPath.row];
        NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        [self copyFiles:@[item] toRootDirectory:documentsPath];
    }];
    copyAction.backgroundColor = [UIColor greenColor];
    return @[changeAction,deleteAction, copyAction];
}

- (void)alertViewTextFieldtextChange:(UITextField *)tf {
    self.selectorFilenNewName = tf.text;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - QLPreviewControllerDataSource
////////////////////////////////////////////////////////////////////////

- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item {
    
    return YES;
}

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return 1;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger) index {
    NSString *newPath = self.files[self.indexPath.row].fullPath;
    
    return [NSURL fileURLWithPath:newPath];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Sorted files
////////////////////////////////////////////////////////////////////////
- (NSArray *)sortedFiles:(NSArray *)files {
    return [files sortedArrayWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(NSString* file1, NSString* file2) {
        NSString *newPath1 = [self.rootDirectory stringByAppendingPathComponent:file1];
        NSString *newPath2 = [self.rootDirectory stringByAppendingPathComponent:file2];
        
        BOOL isDirectory1, isDirectory2;
        [[NSFileManager defaultManager ] fileExistsAtPath:newPath1 isDirectory:&isDirectory1];
        [[NSFileManager defaultManager ] fileExistsAtPath:newPath2 isDirectory:&isDirectory2];
        
        if (isDirectory1 && !isDirectory2) {
            return NSOrderedAscending;
        }
        
        return  NSOrderedDescending;
    }];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
////////////////////////////////////////////////////////////////////////

- (UILongPressGestureRecognizer *)longPress {
    
    if (!_longPress) {
        _longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(showPeek:)];
        [self.view addGestureRecognizer:_longPress];
    }
    return _longPress;
}

- (void)showPeek:(UILongPressGestureRecognizer *)longPress {
    if (longPress.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [longPress locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
        
        if (self.longPressCallBack) {
            self.longPressCallBack(indexPath);
        }
        
        self.longPress.enabled = NO;
        UIViewController *vc = [self previewControllerByIndexPath:indexPath];
        [self jumpToDetailControllerToViewController:vc atIndexPath:indexPath];
    }
}


- (void)infoAction {
    if (!self.indexPath) {
        return;
    }
    NSString *newPath = self.files[self.indexPath.row].fullPath;
    NSDictionary *fileAtt = [[NSFileManager defaultManager] attributesOfItemAtPath:newPath error:nil];
    
    NSMutableString *attstring = @"".mutableCopy;
    [fileAtt enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isEqualToString:NSFileSize]) {
            obj = [NSString transformedFileSizeValue:obj];
        }
        [attstring appendString:[NSString stringWithFormat:@"%@:%@\n", key, obj]];
    }];
    
    [[[UIAlertView alloc] initWithTitle:@"File info" message:attstring delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil] show];
    self.indexPath = nil;
}

- (void)shareAction {
    if (!self.indexPath) {
        return;
    }
    NSString *newPath = self.files[self.indexPath.row].fullPath;
    NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:newPath.lastPathComponent];
    NSError *error = nil;
    [[NSFileManager defaultManager] copyItemAtPath:newPath toPath:tmpPath error:&error];
    
    if (error) {
        NSLog(@"ERROR: %@", error);
    }
    UIActivityViewController *shareActivity = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:tmpPath]] applicationActivities:nil];
    
    shareActivity.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
    };
    [self.navigationController presentViewController:shareActivity animated:YES completion:nil];
    self.indexPath = nil;
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Lazy
////////////////////////////////////////////////////////////////////////

- (UILabel *)pathLabel {
    if (!_pathLabel) {
        _pathLabel = [[UILabel alloc] init];
        _pathLabel.numberOfLines = 0;
        _pathLabel.textColor = [UIColor grayColor];
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_4) {
            _pathLabel.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:1.0];
        } else {
            _pathLabel.font = [UIFont systemFontOfSize:12];
        }
    }
    return _pathLabel;
}

- (UIProgressView *)progressBar {
    if (!_progressBar) {
        _progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressBar.progress = 0.0;
        _progressBar.progressTintColor = [UIColor blueColor];
        _progressBar.layer.cornerRadius = 1.5f;
        _progressBar.clipsToBounds = YES;
        _progressBar.trackTintColor = [UIColor grayColor];
    }
    return _progressBar;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

- (NSMutableArray<FileAttributeItem *> *)selectorFiles {
    if (!_selectorFiles) {
        _selectorFiles = [NSMutableArray array];
    }
    return _selectorFiles;
}

- (void)dealloc {
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
    [_currentFolderHelper invalidate];
    [_documentFolderHelper invalidate];
    NSLog(@"%s", __func__);
}


@end



#pragma mark *** FilePreviewViewController ***



@implementation FilePreviewViewController

////////////////////////////////////////////////////////////////////////
#pragma mark - initialize
////////////////////////////////////////////////////////////////////////

- (instancetype)initWithPath:(NSString *)file {
    self = [super init];
    if (self) {
        _filePath = file;
        _textView = [[UITextView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _textView.editable = NO;
        _textView.backgroundColor = [UIColor whiteColor];
        
        _imageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        _imageView.backgroundColor = [UIColor whiteColor];
        
        [self loadFile:file];
        
    }
    return self;
}

#ifdef __IPHONE_9_0
- (NSArray<id<UIPreviewActionItem>> *)previewActionItems {
    
    BOOL isDirectory;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:self.filePath isDirectory:&isDirectory];
    if (!fileExists || isDirectory) {
        return nil;
    }
    
    UIPreviewAction *action1 = [UIPreviewAction actionWithTitle:@"info" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        [self infoAction];
    }];
    
    UIPreviewAction *action2 = [UIPreviewAction actionWithTitle:@"share" style:UIPreviewActionStyleDestructive handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        [self shareAction];
    }];
    
    NSArray *actions = @[action1, action2];
    
    // 将所有的actions 添加到group中
    UIPreviewActionGroup *group1 = [UIPreviewActionGroup actionGroupWithTitle:@"more operation" style:UIPreviewActionStyleDefault actions:actions];
    NSArray *group = @[group1];
    
    return group;
}
#endif

- (void)infoAction {
    
    NSDictionary *fileAtt = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:nil];
    
    NSMutableString *attstring = @"".mutableCopy;
    [fileAtt enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isEqualToString:NSFileSize]) {
            obj = [NSString transformedFileSizeValue:obj];
        }
        [attstring appendString:[NSString stringWithFormat:@"%@:%@\n", key, obj]];
    }];
    
    [[[UIAlertView alloc] initWithTitle:@"File info" message:attstring delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil] show];
}

- (void)shareAction {
    NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:self.filePath.lastPathComponent];
    NSError *error = nil;
    [[NSFileManager defaultManager] copyItemAtPath:self.filePath toPath:tmpPath error:&error];
    
    if (error) {
        NSLog(@"ERROR: %@", error);
    }
    UIActivityViewController *shareActivity = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:tmpPath]] applicationActivities:nil];
    
    shareActivity.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
    };
    [self.navigationController presentViewController:shareActivity animated:YES completion:nil];
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Other
////////////////////////////////////////////////////////////////////////

+ (NSArray *)fileExtensions {
    return @[@"plist",
             @"strings",
             @"xcconfig",
             @"version",
             @"archive",
             @"db",
             @"gps"];
}


- (void)loadFile:(NSString *)file {
    if ([file.pathExtension.lowercaseString isEqualToString:@"db"]) {
        // 可以读取数据库后展示
        [_textView setText:@"db"];
        self.view = _textView;
        
    }
    
    else if ([file.pathExtension.lowercaseString isEqualToString:@"xcconfig"] ||
             [file.pathExtension.lowercaseString isEqualToString:@"version"]) {
        NSString *d = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
        [_textView setText:d];
        self.view = _textView;
    }
    else {
        NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:file];
        [_textView setText:[d description]];
        self.view = _textView;
    }
    
    self.title = file.lastPathComponent;
}

@end



@implementation FileTableViewCell

- (void)setFileModel:(FileAttributeItem *)fileModel {
    _fileModel = fileModel;
    
    BOOL isDirectory;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:fileModel.fullPath isDirectory:&isDirectory];
    self.textLabel.text = [fileModel.fullPath lastPathComponent];
    //    self.detailTextLabel.text = fileModel.fileSize;
    self.detailTextLabel.text = nil;
    if (isDirectory) {
        self.imageView.image = [UIImage imageNamed:@"Folder"];
        self.detailTextLabel.text = [NSString stringWithFormat:@"%lu个文件", (unsigned long)fileModel.subFileCount];
    } else if ([fileModel.fullPath.pathExtension.lowercaseString isEqualToString:@"png"] ||
               [fileModel.fullPath.pathExtension.lowercaseString isEqualToString:@"jpg"]) {
        self.imageView.image = [UIImage imageNamed:@"Picture"];
        //        self.imageView.image = [UIImage imageWithContentsOfFile:path];
    } else {
        self.imageView.image = nil;
    }
    if (fileExists && !isDirectory) {
        self.accessoryType = UITableViewCellAccessoryDetailButton;
    } else {
        self.accessoryType = UITableViewCellAccessoryNone;
    }
}

@end

@implementation FileAttributeItem


@end
