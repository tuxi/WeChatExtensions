//
//  OSAuthenticatorHelper.h
//  FileDownloader
//
//  Created by Swae on 2017/10/22.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SmileAuthenticator.h"


@interface OSAuthenticatorHelper : NSObject

@property (nonatomic, strong, class) OSAuthenticatorHelper *sharedInstance;

- (void)initAuthenticator;
- (void)applicationDidBecomeActiveWithRemoveCoverImageView;
- (void)applicationWillResignActiveWithShowCoverImageView;
- (void)saveImage:(UIImage *)currentImage;
- (BOOL)hasBackgroundImage;
- (void)clearBackgroundImage;

@end
