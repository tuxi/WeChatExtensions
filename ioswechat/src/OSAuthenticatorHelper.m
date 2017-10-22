//
//  OSAuthenticatorHelper.m
//  FileDownloader
//
//  Created by Swae on 2017/10/22.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSAuthenticatorHelper.h"


@implementation OSAuthenticatorHelper {
    UIImageView *_coverImageView;
    
}


@dynamic sharedInstance;

+ (OSAuthenticatorHelper *)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = self.new;
    });
    return instance;
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Public
////////////////////////////////////////////////////////////////////////

- (void)initAuthenticator {
    [self configureForFirstLaunchAddCoverImage];
    
    [SmileAuthenticator sharedInstance].rootVC = [UIApplication sharedApplication].delegate.window.rootViewController;
    [SmileAuthenticator sharedInstance].passcodeDigit = 4;
    [SmileAuthenticator sharedInstance].tintColor = [[UIColor greenColor] colorWithAlphaComponent:0.8];
    [SmileAuthenticator sharedInstance].touchIDIconName = @"my_Touch_ID";
    //    [SmileAuthenticator sharedInstance].appLogoName = @"my_Logo";
    [SmileAuthenticator sharedInstance].navibarTranslucent = YES;
    [SmileAuthenticator sharedInstance].backgroundImage = [UIImage imageWithContentsOfFile:[self backgroundImagePath]];
}

- (void)applicationDidBecomeActiveWithRemoveCoverImageView {
    if ([SmileAuthenticator hasPassword]) {
        //if now is authenticated, remove the cover image.
        if([SmileAuthenticator sharedInstance].isAuthenticated){
            [self removeCoverImageView];
        }
    }
}

- (void)applicationWillResignActiveWithShowCoverImageView {
    if ([SmileAuthenticator hasPassword] && [SmileAuthenticator sharedInstance].isShowingAuthVC == NO) {
        [self showCoverImageView];
    }
}

- (void)configureForFirstLaunchAddCoverImage{
    //add observer UIWindowDidBecomeKeyNotification for the first launch add the cover image for protecting the user's data.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowDidBecomeVisible:)
                                                 name:UIWindowDidBecomeKeyNotification
                                               object:nil];
    //add observer SmileTouchID_Presented_AuthVC_Notification for only remove cover image when the the AuthVC has been presented.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeCoverImageView) name:SmileTouchID_Presented_AuthVC_Notification object:nil];
}

-(void)windowDidBecomeVisible:(NSNotification*)notif{
    if ([SmileAuthenticator hasPassword]) {
        //iOS automatically snapshot screen, so if has password, use the _coverImageView cover the UIWindow for protecting user data.
        [self addCoverImageView];
        //remove the observer, because we just need it for the app first launch.
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIWindowDidBecomeKeyNotification object:nil];
    }
}

-(void)addCoverImageView{
    _coverImageView = [[UIImageView alloc]initWithFrame:[[UIApplication sharedApplication].delegate.window bounds]];
    _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    UIImage *image = [UIImage imageWithContentsOfFile:[self backgroundImagePath]];
    [_coverImageView setImage:image];
    _coverImageView.alpha = 1.0;
    [[UIApplication sharedApplication].delegate.window addSubview:_coverImageView];
}

-(void)showCoverImageView{
    if (!_coverImageView) {
        [self addCoverImageView];
    }
    [UIView animateWithDuration:0.1 animations:^{
        _coverImageView.alpha = 1.0;
    }];
}

-(void)removeCoverImageView{
    if (_coverImageView) {
        [UIView animateWithDuration:0.1 animations:^{
            _coverImageView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [_coverImageView removeFromSuperview];
            _coverImageView = nil;
        }];
    }
}

- (void)SMILE_testHelperMethod{
    BOOL isCustomize = YES;
    
    if (isCustomize) {
        
        BOOL nightMode = NO;
        
        if (!nightMode) {
            //customize
            [SmileAuthenticator sharedInstance].passcodeDigit = 6;
            [SmileAuthenticator sharedInstance].tintColor = [[UIColor greenColor] colorWithAlphaComponent:0.8];
            [SmileAuthenticator sharedInstance].touchIDIconName = @"my_Touch_ID";
            //            [SmileAuthenticator sharedInstance].appLogoName = @"my_Logo";
            [SmileAuthenticator sharedInstance].navibarTranslucent = YES;
            UIImage *backgroundImage = [UIImage imageWithContentsOfFile:self.backgroundImagePath];
            [SmileAuthenticator sharedInstance].backgroundImage = backgroundImage;
        } else {
            [SmileAuthenticator sharedInstance].passcodeDigit = 6;
            [SmileAuthenticator sharedInstance].tintColor = [[UIColor greenColor] colorWithAlphaComponent:0.8];
            [SmileAuthenticator sharedInstance].touchIDIconName = @"my_Touch_ID";
            //            [SmileAuthenticator sharedInstance].appLogoName = @"my_Logo";
            [SmileAuthenticator sharedInstance].navibarTranslucent = NO;
            [SmileAuthenticator sharedInstance].nightMode = YES;
            UIImage *backgroundImage = [UIImage imageWithContentsOfFile:self.backgroundImagePath];
            [SmileAuthenticator sharedInstance].backgroundImage = backgroundImage;
        }
    }
}

- (NSString *)backgroundImagePath {
    NSString *imageFolder = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"backgroundImage"];
    BOOL isExist, isDirectory;
    isExist = [[NSFileManager defaultManager] fileExistsAtPath:imageFolder isDirectory:&isDirectory];
    if (!isExist || !isDirectory) {
        [[NSFileManager defaultManager] createDirectoryAtPath:imageFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *fullPath = [imageFolder stringByAppendingPathComponent:@"backgroundImage.png"];
    if (!fullPath.length) {
        return nil;
    }
    return fullPath;
}


- (void)saveImage:(UIImage *)currentImage {
    NSData *imageData = UIImagePNGRepresentation(currentImage);
    NSString *fullPath = [self backgroundImagePath];
    [self clearBackgroundImage];
    [imageData writeToFile:fullPath atomically:NO];
    
    /// 保存完成后重新给控件赋值
    UIImage *backgroundImage = [UIImage imageWithContentsOfFile:[self backgroundImagePath]];
    [SmileAuthenticator sharedInstance].backgroundImage = backgroundImage;
    [_coverImageView setImage:backgroundImage];
}

- (BOOL)hasBackgroundImage {
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self backgroundImagePath]]) {
        return YES;
    }
    return NO;
}

- (void)clearBackgroundImage {
    NSString *fullPath = [self backgroundImagePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
    }
    UIImage *backgroundImage = nil;
    [SmileAuthenticator sharedInstance].backgroundImage = backgroundImage;
    [_coverImageView setImage:backgroundImage];
}

@end

