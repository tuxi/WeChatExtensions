//
//  OSFileManager.m
//  OSFileManager
//
//  Created by Ossey on 2017/7/22.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileManager.h"
#include "copyfile.h"

#define TIME_REMAINING_SMOOTHING_FACTOR 0.2f
#pragma clang diagnostic ignored "-Wunused-property-ivar"

static void *FileProgressObserverContext = &FileProgressObserverContext;

@interface OSFileManager ()

@property (nonatomic, strong) NSMutableArray<id<OSFileOperation>> *operations;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSProgress *totalProgress;

@end

@interface OSFileOperation : NSOperation <OSFileOperation>

@property (nonatomic, copy) NSURL *sourceURL;
@property (nonatomic, copy) NSURL *dstURL;
@property (nonatomic, assign) OSFileInteger sourceTotalBytes;
@property (nonatomic, assign) OSFileInteger receivedCopiedBytes;
@property (nonatomic, assign) NSTimeInterval secondsRemaining;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, copy, readonly) NSString *fileName;
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) NSProgress *progress;

@property (nonatomic, getter = isFinished) BOOL finished;
@property (nonatomic, getter = isExecuting) BOOL executing;
@property (nonatomic, getter = isCancelled) BOOL cancelled;

@property (nonatomic, assign) OSFileWriteStatus writeState;
@property (nonatomic, strong) NSNumber *progressValue;

@property (nonatomic, copy) OSFileOperationCompletionHandler completionHandler;
@property (nonatomic, copy) OSFileOperationProgress progressBlock;

int copyFileCallBack(
 int what,
 int stage,
 copyfile_state_t state,
 const char *source,
 const char *destination,
 void *context);

@end

@implementation OSFileManager

////////////////////////////////////////////////////////////////////////
#pragma mark - initialized
////////////////////////////////////////////////////////////////////////


+ (OSFileManager *)defaultManager {
    static OSFileManager *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [OSFileManager new];
    });
    return _instance;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        _operationQueue = [NSOperationQueue new];
        _maxConcurrentOperationCount = 2;
        _operationQueue.maxConcurrentOperationCount = _maxConcurrentOperationCount;
        _operations = [NSMutableArray array];
        _totalProgress = [NSProgress progressWithTotalUnitCount:0];
        [_totalProgress addObserver:self
                        forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                           options:NSKeyValueObservingOptionInitial
                           context:FileProgressObserverContext];
        
    }
    return self;
}

- (void)setMaxConcurrentOperationCount:(NSInteger)maxConcurrentOperationCount {
    _maxConcurrentOperationCount = MIN(0, maxConcurrentOperationCount);
    self.operationQueue.maxConcurrentOperationCount = maxConcurrentOperationCount;
}


- (NSUInteger)pendingOperationCount {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFinished == NO"];
    return _pendingOperationCount = [self.operations filteredArrayUsingPredicate:predicate].count;
}

- (NSNumber *)totalProgressValue {
    return @(self.totalProgress.fractionCompleted);
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == FileProgressObserverContext && object == self.totalProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.totalProgressBlock) {
                self.totalProgressBlock(self.totalProgress);
            }
        });
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc {
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
    [self.totalProgress removeObserver:self
                            forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                               context:FileProgressObserverContext];
}

- (void)resetProgress {
    BOOL hasActiveFlag = [self operations].count;
    if (hasActiveFlag == NO) {
        @try {
            [self.totalProgress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
        } @catch (NSException *exception) {
            NSLog(@"Error: Repeated removeObserver(keyPath = fractionCompleted)");
        } @finally {
            
        }
        
        self.totalProgress = [NSProgress progressWithTotalUnitCount:0];
        [self.totalProgress addObserver:self
                            forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                               options:NSKeyValueObservingOptionInitial
                               context:FileProgressObserverContext];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (void)addOperationsObject:(OSFileOperation *)operation {
    [_operations addObject:operation];
    [_operationQueue addOperation:operation];
}
- (void)addOperations:(NSArray *)operations {
    [_operations addObjectsFromArray:operations];
    [_operationQueue addOperations:operations waitUntilFinished:NO];
}
- (void)removeOperationsObject:(OSFileOperation *)operation {
    [_operations removeObject:operation];
}
- (void)removeObjectFromOperationsAtIndex:(NSUInteger)index {
    [_operations removeObjectAtIndex:index];
}

- (OSFileOperation *)operationWithSourceURL:(NSURL *)srcURL dstRL:(NSURL *)dstURL {
   NSUInteger foundIdx = [_operations indexOfObjectPassingTest:^BOOL(id<OSFileOperation>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL res = [obj.sourceURL.path isEqualToString:srcURL.path] && [obj.dstURL.path isEqualToString:dstURL.path];
        if (res) {
            *stop = YES;
        }
        return res;
    }];
    if (foundIdx != NSNotFound) {
        return [_operations objectAtIndex:foundIdx];
    }
    return nil;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Public methods
////////////////////////////////////////////////////////////////////////


- (id<OSFileOperation>)copyItemAtURL:(NSURL *)srcURL
                toURL:(NSURL *)dstURL
             progress:(OSFileOperationProgress)progress
    completionHandler:(OSFileOperationCompletionHandler)handler {
    
    [self resetProgress];
    self.totalProgress.totalUnitCount++;
    [self.totalProgress becomeCurrentWithPendingUnitCount:1];
    OSFileOperation *fileOperation = [[OSFileOperation alloc] initWithSourceURL:srcURL
                                                                         desURL:dstURL
                                                                       progress:progress
                                                              completionHandler:handler];
    [self.totalProgress resignCurrent];
    
    if (fileOperation.isFinished) {
        return nil;
    }
    
    [self addOperationsObject:fileOperation];
    
//    __weak OSFileOperation *weakOperation = fileOperation;
    OSFileOperation *weakOperation = fileOperation;
    fileOperation.completionBlock = ^{
        [self performSelectorOnMainThread:@selector(removeOperationsObject:)
                               withObject:weakOperation
                            waitUntilDone:NO];
    };
    return fileOperation;

}



- (id<OSFileOperation>)moveItemAtURL:(NSURL *)srcURL
                toURL:(NSURL *)dstURL
             progress:(OSFileOperationProgress)progress
    completionHandler:(OSFileOperationCompletionHandler)handler {
    
    [self resetProgress];
    
    self.totalProgress.totalUnitCount++;
    [self.totalProgress becomeCurrentWithPendingUnitCount:1];
    OSFileOperation *fileOperation = [[OSFileOperation alloc] initWithSourceURL:srcURL
                                                                         desURL:dstURL
                                                                       progress:progress
                                                              completionHandler:handler];
    [self.totalProgress resignCurrent];
    
    if (fileOperation.isFinished) {
        return nil;
    }
    
    [self addOperationsObject:fileOperation];
    
//    __weak OSFileOperation *weakOperation = fileOperation;
    OSFileOperation *weakOperation = fileOperation;
    fileOperation.completionBlock = ^{
        if (weakOperation.isFinished && !weakOperation.error) {
            NSError *removeError = nil;
            [[NSFileManager new] removeItemAtURL:weakOperation.sourceURL error:&removeError];
            if (removeError) {
                NSLog(@"Error: remove file error:%@", removeError.localizedDescription);
            }
        }
        [self performSelectorOnMainThread:@selector(removeOperationsObject:)
                               withObject:weakOperation
                            waitUntilDone:NO];
    };
    return fileOperation;
}

- (void)cancelAllOperation {
    [_operationQueue cancelAllOperations];
    [_operations removeAllObjects];
}

@end

@implementation OSFileOperation
{
    copyfile_state_t _copyfileState;
    NSTimeInterval _startTimeStamp;
    NSTimeInterval _previousProgressTimeStamp;
    NSString *_previousOperationFilePath;
    OSFileInteger _previousReceivedCopiedBytes;
    
}

@synthesize executing = _executing;
@synthesize finished = _finished;
@synthesize cancelled = _cancelled;

- (instancetype)initWithSourceURL:(NSURL *)sourceURL
                           desURL:(NSURL *)desURL
                         progress:(OSFileOperationProgress)progress
                completionHandler:(OSFileOperationCompletionHandler)completionHandler {
    if (self = [super init]) {
        _sourceURL = sourceURL;
        _dstURL = desURL;
        _sourceTotalBytes = 0;
        _receivedCopiedBytes = 0;
        _secondsRemaining = 0;
        _fileManager = [NSFileManager new];
        _completionHandler = completionHandler;
        _progressBlock = progress;
        
        NSProgress *naviteProgress = [[NSProgress alloc] initWithParent:[NSProgress currentProgress]
                                                         userInfo:nil];
        naviteProgress.kind = NSProgressKindFile;
        [naviteProgress setUserInfoObject:NSProgressFileOperationKindKey
                             forKey:NSProgressFileOperationKindCopying];
        [naviteProgress setUserInfoObject:self.sourceURL forKey:NSStringFromSelector(@selector(sourceURL))];
        naviteProgress.cancellable = NO;
        naviteProgress.pausable = NO;
        naviteProgress.totalUnitCount = NSURLSessionTransferSizeUnknown;
        naviteProgress.completedUnitCount = 0;
        self.progress = naviteProgress;
        
        NSError *error = nil;
        self.sourceTotalBytes = [self caclulateFileToatalSizeByFilePath:_sourceURL.path error:&error];
        self.error = error;
        if (error) {
            [self finish];
        }
    }
    return self;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:NSStringFromSelector(@selector(progressValue))]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[
                                                           NSStringFromSelector(@selector(sourceTotalBytes)),
                                                           NSStringFromSelector(@selector(receivedCopiedBytes))]];
    }
    else if ([key isEqualToString:NSStringFromSelector(@selector(fileName))]) {
        keyPaths = [keyPaths setByAddingObject:NSStringFromSelector(@selector(sourceURL))];
    }
    return keyPaths;
    
}

- (BOOL)isConcurrent {
    return YES;
}


- (NSString *)fileName {
    return self.sourceURL.lastPathComponent;
}


- (void)start {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        [self willChangeValueForKey:@"isExecuting"];
        self.executing = YES;
        self.writeState = OSFileWriteExecuting;
        [self didChangeValueForKey:@"isExecuting"];
        
        BOOL isExist = [_fileManager fileExistsAtPath:[self.dstURL.path stringByAppendingPathComponent:self.sourceURL.lastPathComponent]];
        if (isExist) {
            self.error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteFileExistsError userInfo:@{@"NSErrorUserInfoKey": @"File exist"}];
            [self finish];
            return;
        }
        
        _previousProgressTimeStamp = _startTimeStamp = [[NSDate date] timeIntervalSince1970];
        
        _copyfileState = copyfile_state_alloc();

        copyfile_state_set(_copyfileState, COPYFILE_STATE_STATUS_CB, &copyFileCallBack);
        copyfile_state_set(_copyfileState, COPYFILE_STATE_STATUS_CTX, (__bridge void *)self);
        const char *scourcePath = self.sourceURL.path.UTF8String;
        const char *dstPath = self.dstURL.path.UTF8String;
        // 执行copy文件，此方法会阻塞当前线程，直到文件拷贝完成为止
        int resCode = copyfile(scourcePath, dstPath, _copyfileState, [self flags]);
        /*
        // copy完成后，若进度不为1，再次检测下本地的文件
        if (self.progress.fractionCompleted != 1.0 && resCode == 0) {
            NSError *error = nil;
           self.receivedCopiedBytes = [self caclulateFileToatalSizeByFilePath:_dstURL.path error:&error];
            if (!error) {
                [self updateProgress];
            }
        }
        */
        if (resCode != 0 && ![self isCancelled]) {
            NSString *errorMessage = [NSString stringWithCString:strerror(errno) encoding:NSUTF8StringEncoding];
            self.error = [NSError errorWithDomain:NSCocoaErrorDomain code:resCode userInfo:@{NSFilePathErrorKey: errorMessage}];
            NSLog(@"%@", errorMessage);
        }
        copyfile_state_free(_copyfileState);
        [self finish];
    });
}

- (void)cancel {
    @synchronized (self) {
        // 当非取消状态时，取消请求任务，并标记为取消
        if (self.isCancelled || self.isFinished) {
            [self finish];
        } else {
            [self willChangeValueForKey:@"isExecuting"];
            [self willChangeValueForKey:@"isCancelled"];
            self.executing = NO;
            [self willChangeValueForKey:@"isExecuting"];
            self.cancelled = YES;
            BOOL isExist = [_fileManager fileExistsAtPath:self.dstURL.path];
            if (isExist) {
                NSError *removeError = nil;
                [_fileManager removeItemAtURL:self.dstURL error:&removeError];
                if (removeError) {
                    NSLog(@"Error: cancel copy or move error:%@", removeError.localizedDescription);
                }
                self.error = removeError;
            }
            
            [self finish];
            [self didChangeValueForKey:@"isCancelled"];
            
        }
    }
    
    
}

- (OSFileInteger)caclulateFileToatalSizeByFilePath:(NSString *)filePath error:(NSError **)error {
    NSError *attributesError = nil;
    NSDictionary *attributeDict = [_fileManager attributesOfItemAtPath:filePath error:&attributesError];
    if (attributesError) {
        if (error) {
            *error = attributesError;
        }
        NSLog(@"Error: %@", attributesError);
        return -1;
    }
    
    BOOL isExist = NO, isDirectory = NO;
    OSFileInteger totalSize = 0;
    isExist = [_fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
    if (isDirectory) {
        NSArray *fileArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:filePath error:nil];
        NSEnumerator *fileEnumerator = [fileArray objectEnumerator];
        NSString *fileName = nil;
        OSFileInteger aFileSize = 0;
        while ((fileName = fileEnumerator.nextObject)) {
            NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[filePath stringByAppendingPathComponent:fileName] error:nil];
            aFileSize += fileDictionary.fileSize;
        }
        totalSize = aFileSize;
    } else {
        totalSize = [attributeDict fileSize];
    }
    
    return totalSize;
}

- (void)finish {
    @synchronized (self) {
        
         if (self.isExecuting && !self.isFinished) {
            [self willChangeValueForKey:@"isExecuting"];
            [self willChangeValueForKey:@"isFinished"];
            self.executing = NO;
            self.finished = YES;
            if (self.error) {
                self.writeState = OSFileWriteFailure;
            } else {
                self.writeState = OSFileWriteFinished;
            }
            [self didChangeValueForKey:@"isFinished"];
            [self didChangeValueForKey:@"isExecuting"];
         }
         else if (self.isCancelled) {
             self.error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
             self.writeState = OSFileWriteCanceled;
         }
        
        self.progress.completedUnitCount = self.progress.totalUnitCount;
        self.completionHandler(self, self.error);
    }
}

- (copyfile_flags_t)flags {
    copyfile_flags_t flags = COPYFILE_ALL | COPYFILE_NOFOLLOW | COPYFILE_EXCL;
    
    BOOL isExist = NO, isDirectory = NO;
    isExist = [_fileManager fileExistsAtPath:self.sourceURL.path isDirectory:&isDirectory];
    if (isExist && isDirectory) {
        flags |= COPYFILE_RECURSIVE;
    }
    return flags;
}

int copyFileCallBack(int what, int stage, copyfile_state_t state, const char *path, const char *destination, void *context) {
    OSFileOperation *self = (__bridge OSFileOperation *)context;
    if (self.isCancelled) {
        NSLog(@"fil operation was cancelled");
        return COPYFILE_QUIT;
    }
    
    switch (what) {
        case COPYFILE_COPY_DATA:
            switch (stage) {
                case COPYFILE_PROGRESS: { // copy进度回调
                    // receivedCopiedBytes 回调每次一个文件已经copy到的大小
                    off_t receivedCopiedBytes = 0;
                    const int code = copyfile_state_get(state, COPYFILE_STATE_COPIED, &receivedCopiedBytes);
                    if (code == 0) {
                        [self updateStateWithCopiedBytes:receivedCopiedBytes sourcePath:@(path)];
                        [self updateProgress];
                    }
                    break;
                }
                case COPYFILE_ERR: {
                    return COPYFILE_QUIT;
                    break;
                }
                default:
                    break;
            }
            break;
        default:
            break;
    }
    return COPYFILE_CONTINUE;
}

- (void)updateStateWithCopiedBytes:(OSFileInteger)receivedCopiedBytes sourcePath:(NSString *)sourcePath {
    if (![_previousOperationFilePath isEqualToString:sourcePath]) {
        _previousReceivedCopiedBytes = 0;
        _previousOperationFilePath = [sourcePath copy];
    }
    
    // copiedBytesOffset 计算每次copy了多少
    OSFileInteger copiedBytesOffset = receivedCopiedBytes - _previousReceivedCopiedBytes;
    self.receivedCopiedBytes = _receivedCopiedBytes + copiedBytesOffset;
    
    _previousReceivedCopiedBytes = receivedCopiedBytes;
    
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    
    NSTimeInterval previousTransferRate = copiedBytesOffset / (now - _previousProgressTimeStamp);
    NSTimeInterval overallTransferRate = receivedCopiedBytes / (now - _startTimeStamp);
    NSTimeInterval averageTransferRate = TIME_REMAINING_SMOOTHING_FACTOR * previousTransferRate + ((1 - TIME_REMAINING_SMOOTHING_FACTOR) * overallTransferRate);
    self.secondsRemaining = (_sourceTotalBytes - receivedCopiedBytes) / averageTransferRate;
}

- (void)updateProgress {
    _progressValue = @(self.progress.fractionCompleted);
    if (_progressBlock) {
        _progressBlock(self.progress);
    }
}

- (void)setSourceTotalBytes:(OSFileInteger )sourceTotalBytes {
    _sourceTotalBytes = sourceTotalBytes;
    if (self.progress && sourceTotalBytes > 0) {
        self.progress.totalUnitCount = sourceTotalBytes;
    }
}

- (void)setReceivedCopiedBytes:(OSFileInteger)receivedCopiedBytes {
    _receivedCopiedBytes = receivedCopiedBytes;
    if (receivedCopiedBytes) {
        if (self.progress && self.sourceTotalBytes > 0) {
            self.progress.completedUnitCount = receivedCopiedBytes;
        }
    }
}

- (void)setWriteState:(OSFileWriteStatus)writeState {
    [self willChangeValueForKey:@"writeState"];
    _writeState = writeState;
    [self didChangeValueForKey:@"writeState"];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"OSFileOperation:\nsourceURL:%@\ndstURL:%@", self.sourceURL, self.dstURL];
}

@end
