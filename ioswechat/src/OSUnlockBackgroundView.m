//
//  OSUnlockBackgroundView.m
//  FileDownloader
//
//  Created by Swae on 2017/10/22.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSUnlockBackgroundView.h"

@interface OSUnlockBackgroundView ()

@end

@implementation OSUnlockBackgroundView

#pragma mark *** Init ***

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    
    [self addSubview:self.passwordField]; // 让passwordField看不见
    [self addSubview:self.backgroundImageView];
    [self addSubview:self.touchIDBtn];
    [self addSubview:self.passwordView];
    [self addSubview:self.descLabel];
    
    [self makeConstraints];
}

- (void)makeConstraints {
    NSDictionary *subviewsDict = @{@"backgroundImageView": self.backgroundImageView, @"touchIDBtn": self.touchIDBtn, @"passwordView": self.passwordView, @"passwordField": self.passwordField, @"descLabel": self.descLabel};
    NSDictionary *metrics = @{};
    NSArray *backgroundImageViewConstrains = @[
                                               [NSLayoutConstraint constraintsWithVisualFormat:@"|[backgroundImageView]|" options:kNilOptions metrics:metrics views:subviewsDict],
                                               [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[backgroundImageView]|" options:kNilOptions metrics:metrics views:subviewsDict],
                                               ];
    [self addConstraints:[backgroundImageViewConstrains valueForKeyPath:@"@unionOfArrays.self"]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.touchIDBtn attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.passwordView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:20.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.touchIDBtn attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.passwordView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.passwordView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.passwordView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:0.08 constant:0.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.passwordView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.descLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.passwordField attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:16.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.passwordField attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-16.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.passwordField attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.descLabel attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.descLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.descLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.descLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:50.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.descLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:80.0]];
    
}


#pragma mark *** Lazy ***

- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [UIImageView new];
        _backgroundImageView.accessibilityIdentifier = NSStringFromSelector(_cmd);
        _backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _backgroundImageView.backgroundColor = [UIColor whiteColor];
    }
    return _backgroundImageView;
}

- (UIButton *)touchIDBtn {
    if (!_touchIDBtn) {
        _touchIDBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _touchIDBtn.translatesAutoresizingMaskIntoConstraints = NO;
        _touchIDBtn.accessibilityIdentifier = NSStringFromSelector(_cmd);
        _touchIDBtn.alpha = 0.35;
    }
    return _touchIDBtn;
}

- (SmilePasswordContainerView *)passwordView {
    if (!_passwordView) {
        _passwordView = [SmilePasswordContainerView new];
        _passwordView.accessibilityIdentifier = NSStringFromSelector(_cmd);
        _passwordView.translatesAutoresizingMaskIntoConstraints = NO;
        _passwordView.backgroundColor = [UIColor blueColor];
    }
    return _passwordView;
}

- (UITextField *)passwordField {
    if (!_passwordField) {
        _passwordField = [UITextField new];
        _passwordField.accessibilityIdentifier = NSStringFromSelector(_cmd);
        _passwordField.translatesAutoresizingMaskIntoConstraints = NO;
        _passwordField.keyboardType = UIKeyboardTypeNumberPad;
    }
    return _passwordField;
}

- (UILabel *)descLabel {
    if (!_descLabel) {
        _descLabel = [UILabel new];
        _descLabel.accessibilityIdentifier = NSStringFromSelector(_cmd);
        _descLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _descLabel.text = @"请输入四位密码";
        _descLabel.textAlignment = NSTextAlignmentCenter;
        _descLabel.backgroundColor = [UIColor clearColor];
    }
    return _descLabel;
}

@end

