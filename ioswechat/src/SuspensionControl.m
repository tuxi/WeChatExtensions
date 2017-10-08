//
//  SuspensionView.m
//  SuspensionView
//
//  Created by Ossey on 17/2/25.
//  Copyright © 2017年 Ossey All rights reserved.
//

#import "SuspensionControl.h"
#import <objc/runtime.h>

#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic ignored "-Wunused-property-ivar"

#define kSCREENT_HEIGHT         [UIScreen mainScreen].bounds.size.height
#define kSCREENT_WIDTH          [UIScreen mainScreen].bounds.size.width
#define OS_MAX_CORNER_RADIUS    MIN(CGRectGetWidth(self.bounds) * 0.5, CGRectGetHeight(self.bounds) * 0.5)
#define OS_MAX_BORDER_WIDTH     OS_MAX_CORNER_RADIUS
#define OS_PADDING_VALUE        0.29
#define OS_MIN_SCREEN_SIZE      MIN(kSCREENT_WIDTH, kSCREENT_HEIGHT)
#define OS_MAX_MENUVIEW_SIZE    CGSizeMake(MIN(MAX(MAX(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)), 280.0), OS_MIN_SCREEN_SIZE), MIN(MAX(MAX(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)), 280.0), OS_MIN_SCREEN_SIZE))

typedef NS_ENUM(NSInteger, OSButtonStyle) {
    OSButtonStyleDefault,
    OSButtonStyleSubTitle,
    OSButtonStyleCentralImage,
    OSButtonStyleImageWithSubtitle
};


static CGRect CGRectEdgeInset(CGRect rect, UIEdgeInsets insets)
{
    return CGRectMake(CGRectGetMinX(rect) + insets.left,
                      CGRectGetMinY(rect) + insets.top,
                      CGRectGetWidth(rect) - insets.left - insets.right,
                      CGRectGetHeight(rect) - insets.top - insets.bottom);
}

#pragma mark *** MenuBarHypotenuseButton ***

@interface MenuBarHypotenuseButton : OSCustomButton

@end


@interface HypotenuseAction ()
@property (nonatomic, strong) MenuBarHypotenuseButton *hypotenuseButton;
- (void)removeFromSuperview;
@end

#pragma mark *** OSLabelContentView ***

@interface OSLabelContentView : UIView

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, assign) BOOL usingMaskView;

@end

@implementation OSLabelContentView

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] init];
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.adjustsFontSizeToFitWidth = YES;
        _textLabel.minimumScaleFactor = 0.1;
        _textLabel.numberOfLines = 2;
        _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        if (_usingMaskView) {
            if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
                self.maskView = _textLabel;
            } else {
                self.layer.mask = _textLabel.layer;
            }
        }
        
    }
    return _textLabel;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    if (_usingMaskView) {
        self.textLabel.frame = self.bounds;
    }
}

@end

#pragma mark *** OSImageConentView ***
@interface OSImageConentView : UIView

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) BOOL usingMaskView;

@end

@implementation OSImageConentView

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.backgroundColor = [UIColor clearColor];
        [self addSubview:_imageView];
        if (_usingMaskView) {
            if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
                self.maskView = _imageView;
            } else {
                self.layer.mask = _imageView.layer;
            }
        }
        
    }
    return _imageView;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    if (_usingMaskView) {
        self.imageView.frame = self.bounds;
    }
    
}

@end

#pragma mark *** OSCustomButton ***

@interface OSCustomButton ()

@property (nonatomic, assign, getter=isTrackingInside) BOOL trackingInside;
@property (nonatomic, strong) UIView *foregroundView;
@property (nonatomic, strong) OSLabelContentView *titleContentView;
@property (nonatomic, strong) OSLabelContentView *detailContentView;
@property (nonatomic, strong) OSImageConentView *imageContentView;
@property (nonatomic, assign) OSButtonStyle buttonStyle;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, strong) UIImage *image;

@end


@implementation OSCustomButton
{
    /// 保存修改背景颜色之前的背景颜色
    UIColor *_backgroundColorCache;
    
}

@synthesize
contentColor = _contentColor,
foregroundColor = _foregroundColor,
titleLabel = _titleLabel,
detailLabel = _detailLabel,
imageView = _imageView;

////////////////////////////////////////////////////////////////////////
#pragma mark - initialize
////////////////////////////////////////////////////////////////////////

+ (instancetype)buttonWithType:(OSButtonType)buttonType  {
    return [[self alloc] initWithFrame:CGRectZero buttonType:buttonType];
}

- (instancetype)initWithFrame:(CGRect)frame buttonType:(OSButtonType)type {
    if (self = [self initWithFrame:frame]) {
        self.buttonType = type;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.masksToBounds = YES;
        _restoreSelectedState = YES;
        _trackingInside = NO;
        _cornerRadius = 0.0;
        _borderWidth = 0.0;
        _contentEdgeInsets = UIEdgeInsetsZero;
        _fadeInOutOnDisplay = YES;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Public
////////////////////////////////////////////////////////////////////////

- (void)setTitleColor:(nullable UIColor *)color forState:(UIControlState)state {
    _titleContentView.textLabel.textColor = color;
}


- (void)setTitle:(NSString *)title forState:(UIControlState)state {
    if (_title == title) {
        return;
    }
    _title = title;
    [self setNeedsLayout];
    self.titleLabel.text = title;
    [self.titleLabel sizeToFit];
}
- (void)setSubtitle:(NSString *)subtitle forState:(UIControlState)state {
    if (_subtitle == subtitle) {
        return;
    }
    _subtitle = subtitle;
    [self setNeedsLayout];
    self.detailLabel.text = subtitle;
    [self.detailLabel sizeToFit];
}
- (void)setImage:(UIImage *)image forState:(UIControlState)state {
    if (_image == image) {
        return;
    }
    _image = image;
    [self setNeedsLayout];
    self.imageView.image = image;
}


////////////////////////////////////////////////////////////////////////
#pragma mark - layout
////////////////////////////////////////////////////////////////////////

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self setButtonType:self.buttonType];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat cornerRadius = self.layer.cornerRadius = MAX(MIN(OS_MAX_CORNER_RADIUS, self.cornerRadius), 0);
    CGFloat borderWidth = self.layer.borderWidth = MAX(MIN(OS_MAX_BORDER_WIDTH, self.borderWidth), 0);
    
    _borderWidth = borderWidth;
    _cornerRadius = cornerRadius;
    
    CGFloat layoutBorderWidth = borderWidth == 0.0 ? 0.0 : borderWidth - 0.1;
    self.foregroundView.frame = CGRectMake(layoutBorderWidth,
                                           layoutBorderWidth,
                                           CGRectGetWidth(self.bounds) - layoutBorderWidth * 2,
                                           CGRectGetHeight(self.bounds) - layoutBorderWidth * 2);
    self.foregroundView.layer.cornerRadius = cornerRadius - borderWidth;
    switch (self.buttonStyle)
    {
        case OSButtonStyleDefault:
        {
            if (_imageContentView.usingMaskView) {
                _imageContentView.frame = CGRectNull;
                [_imageContentView removeFromSuperview];
            } else {
                _imageContentView.imageView.frame = CGRectNull;
                [_imageContentView.imageView removeFromSuperview];
            }
            if (_detailContentView.usingMaskView) {
                _detailContentView.frame = CGRectNull;
                [_detailContentView removeFromSuperview];
            } else {
                _detailContentView.textLabel.frame = CGRectNull;
                [_detailContentView.textLabel removeFromSuperview];
            }
            if (_titleContentView.usingMaskView) {
                _titleContentView.frame = [self boxingRect];
            } else {
                _titleContentView.textLabel.frame = [self boxingRect];
            }
        }
            break;
            
        case OSButtonStyleSubTitle:
        {
            CGRect boxRect = [self boxingRect];
            if (_imageContentView.usingMaskView) {
                _imageContentView.frame = CGRectNull;
                [_imageContentView removeFromSuperview];
            } else {
                _imageContentView.imageView.frame = CGRectNull;
                [_imageContentView.imageView removeFromSuperview];
            }
            if (_detailContentView.usingMaskView) {
                self.detailContentView.frame = CGRectMake(boxRect.origin.x,
                                                          CGRectGetMaxY(self.titleContentView.frame),
                                                          CGRectGetWidth(boxRect),
                                                          CGRectGetHeight(boxRect) * 0.2);
            } else {
                self.detailContentView.textLabel.frame = CGRectMake(boxRect.origin.x,
                                                                    CGRectGetMaxY(self.titleContentView.frame),
                                                                    CGRectGetWidth(boxRect),
                                                                    CGRectGetHeight(boxRect) * 0.2);
            }
            if (_titleContentView.usingMaskView) {
                self.titleContentView.frame = CGRectMake(boxRect.origin.x,
                                                         boxRect.origin.y,
                                                         CGRectGetWidth(boxRect),
                                                         CGRectGetHeight(boxRect) * 0.8);
            } else {
                self.titleContentView.textLabel.frame = CGRectMake(boxRect.origin.x,
                                                                   boxRect.origin.y,
                                                                   CGRectGetWidth(boxRect),
                                                                   CGRectGetHeight(boxRect) * 0.8);
            }
            
            
        }
            break;
            
        case OSButtonStyleCentralImage:
        {
            if (_imageContentView.usingMaskView) {
                self.imageContentView.frame = [self boxingRect];
            } else {
                self.imageContentView.imageView.frame = [self boxingRect];
            }
            if (_detailContentView.usingMaskView) {
                _detailContentView.frame = CGRectNull;
                [_detailContentView removeFromSuperview];
            } else {
                _detailContentView.textLabel.frame = CGRectNull;
                [_detailContentView.textLabel removeFromSuperview];
            }
            if (_titleContentView.usingMaskView) {
                _titleContentView.frame = CGRectNull;
                [_titleContentView removeFromSuperview];
            } else {
                _titleContentView.textLabel.frame = CGRectNull;
                [_titleContentView.textLabel removeFromSuperview];
            }
            
        }
            break;
            
        case OSButtonStyleImageWithSubtitle:
        default:
        {
            CGRect boxRect = [self boxingRect];
            
            if (_imageContentView.usingMaskView) {
                self.imageContentView.frame = CGRectMake(boxRect.origin.x,
                                                         boxRect.origin.y,
                                                         CGRectGetWidth(boxRect),
                                                         CGRectGetHeight(boxRect) * 0.8);
            } else {
                self.imageContentView.imageView.frame = CGRectMake(boxRect.origin.x,
                                                                   boxRect.origin.y,
                                                                   CGRectGetWidth(boxRect),
                                                                   CGRectGetHeight(boxRect) * 0.8);
            }
            if (_detailContentView.usingMaskView) {
                self.detailContentView.frame = CGRectMake(boxRect.origin.x,
                                                          CGRectGetMaxY(self.imageContentView.frame),
                                                          CGRectGetWidth(boxRect),
                                                          CGRectGetHeight(boxRect) * 0.2);
            } else {
                self.detailContentView.textLabel.frame = CGRectMake(boxRect.origin.x,
                                                                    CGRectGetMaxY(self.imageContentView.frame),
                                                                    CGRectGetWidth(boxRect),
                                                                    CGRectGetHeight(boxRect) * 0.2);
            }
            if (_titleContentView.usingMaskView) {
                _titleContentView.frame = CGRectNull;
                [_titleContentView removeFromSuperview];
            } else {
                _titleContentView.textLabel.frame = CGRectNull;
                [_titleContentView.textLabel removeFromSuperview];
            }
        }
            break;
    }
    
}

- (OSButtonStyle)buttonStyle {
    if ([self shouldDisplayImageView] && ![self shouldDisplayTitleLabel] && [self shouldDisplayDetailLabel]) {
        return OSButtonStyleImageWithSubtitle;
    } else if ([self shouldDisplayImageView] && ![self shouldDisplayTitleLabel] && ![self shouldDisplayDetailLabel]) {
        return OSButtonStyleCentralImage;
    } else if (![self shouldDisplayImageView] && [self shouldDisplayTitleLabel] && [self shouldDisplayDetailLabel]) {
        return OSButtonStyleSubTitle;
    } else if (![self shouldDisplayImageView] && [self shouldDisplayTitleLabel] && ![self shouldDisplayDetailLabel]) {
        return OSButtonStyleDefault;
    }
    return OSButtonStyleDefault;
}

- (CGRect)boxingRect {
    CGRect internalRect = CGRectInset(self.bounds,
                                      self.layer.cornerRadius * OS_PADDING_VALUE + self.layer.borderWidth,
                                      self.layer.cornerRadius * OS_PADDING_VALUE + self.layer.borderWidth);
    return CGRectEdgeInset(internalRect, self.contentEdgeInsets);
}

- (BOOL)shouldDisplayTitleLabel {
    return _titleLabel && _titleLabel.text.length;
}

- (BOOL)shouldDisplayDetailLabel {
    return _detailLabel && _detailLabel.text.length;
}

- (BOOL)shouldDisplayImageView {
    return _imageView && _imageView.image;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Set get
////////////////////////////////////////////////////////////////////////

- (UIColor *)contentColor {
    return _buttonType == OSButtonTypeDefault ? nil : _contentColor ?: self.tintColor;
}

- (UIColor *)foregroundColor {
    return _buttonType == OSButtonTypeDefault ? [UIColor clearColor] : _foregroundColor ?: [UIColor whiteColor];
}

- (UIView *)foregroundView {
    if (!_foregroundView && _buttonType != OSButtonTypeDefault) {
        _foregroundView = [[UIView alloc] initWithFrame:CGRectNull];
        _foregroundView.backgroundColor = self.foregroundColor;
        _foregroundView.layer.masksToBounds = YES;
        [self addSubview:_foregroundView];
    }
    return _foregroundView;
}

- (OSLabelContentView *)titleContentView {
    if (!_titleContentView) {
        _titleContentView = [[OSLabelContentView alloc] initWithFrame:CGRectNull];
        _titleContentView.backgroundColor = self.contentColor;
        _titleContentView.usingMaskView = _buttonType != OSButtonTypeDefault;
        _titleContentView.layer.masksToBounds = YES;
        if (_titleContentView.usingMaskView) {
            [self insertSubview:_titleContentView aboveSubview:self.foregroundView];
        } else {
            [self addSubview:_titleContentView.textLabel];
        }
    }
    return _titleContentView;
}

- (OSLabelContentView *)detailContentView {
    if (!_detailContentView) {
        _detailContentView = [[OSLabelContentView alloc] initWithFrame:CGRectNull];
        _detailContentView.backgroundColor = self.contentColor;
        _detailContentView.usingMaskView = _buttonType != OSButtonTypeDefault;
        _detailContentView.layer.masksToBounds = YES;
        if (_detailContentView.usingMaskView) {
            [self insertSubview:_detailContentView aboveSubview:self.foregroundView];
        } else {
            [self addSubview:_detailContentView.textLabel];
        }
    }
    return _detailContentView;
}

- (OSImageConentView *)imageContentView {
    if (!_imageContentView) {
        _imageContentView = [[OSImageConentView alloc] initWithFrame:CGRectNull];
        _imageContentView.usingMaskView = _buttonType != OSButtonTypeDefault;
        _imageContentView.backgroundColor = self.contentColor;
        _imageContentView.layer.masksToBounds = YES;
        if (_imageContentView.usingMaskView) {
            [self insertSubview:_imageContentView aboveSubview:self.foregroundView];
        } else {
            [self addSubview:_imageContentView.imageView];
        }
    }
    return _imageContentView;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    if (_cornerRadius == cornerRadius) {
        return;
    }
    _cornerRadius = cornerRadius;
    [self setNeedsLayout];
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    if (_borderWidth == borderWidth) {
        return;
    }
    _borderWidth = borderWidth;
    [self setNeedsLayout];
}

- (void)setBorderColor:(UIColor *)borderColor {
    _borderColor = borderColor;
    self.layer.borderColor = borderColor.CGColor;
}

- (void)setContentColor:(UIColor *)contentColor {
    _contentColor = contentColor;
    self.titleContentView.backgroundColor = contentColor;
    self.detailContentView.backgroundColor = contentColor;
    self.imageContentView.backgroundColor = contentColor;
}

- (void)setForegroundColor:(UIColor *)foregroundColor {
    _foregroundColor = foregroundColor;
    self.foregroundView.backgroundColor = foregroundColor;
}

- (UILabel *)titleLabel {
    return _titleLabel = self.titleContentView.textLabel;
}

- (UILabel *)detailLabel {
    return _detailLabel = self.detailContentView.textLabel;
}

- (UIImageView *)imageView {
    return _imageView = self.imageContentView.imageView;
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    [UIView animateWithDuration:0.3 delay:0.0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.foregroundView.alpha = enabled ? 1.0 : 0.5;
                     }
                     completion:nil];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    dispatch_block_t fadeInBlock = ^{
        if (self.contentAnimateColor) {
            self.titleContentView.backgroundColor = self.contentAnimateColor;
            self.detailContentView.backgroundColor = self.contentAnimateColor;
            self.imageContentView.backgroundColor = self.contentAnimateColor;
        }
        
        if (self.borderAnimateColor && self.foregroundAnimateColor && self.borderAnimateColor == self.foregroundAnimateColor) {
            _backgroundColorCache = self.backgroundColor;
            self.foregroundView.backgroundColor = [UIColor clearColor];
            self.backgroundColor = self.borderAnimateColor;
            return;
        }
        
        if (self.borderAnimateColor) {
            self.layer.borderColor = self.borderAnimateColor.CGColor;
        }
        
        if (self.foregroundAnimateColor) {
            self.foregroundView.backgroundColor = self.foregroundAnimateColor;
        }
    };
    if (self.fadeInOutOnDisplay) {
        
        dispatch_block_t fadeInBlock = ^ {
            self.titleContentView.backgroundColor = self.contentColor;
            self.detailContentView.backgroundColor = self.contentColor;
            self.imageContentView.backgroundColor = self.contentColor;
            
            if (self.borderAnimateColor && self.foregroundAnimateColor && self.borderAnimateColor == self.foregroundAnimateColor) {
                self.foregroundView.backgroundColor = self.foregroundColor;
                self.backgroundColor = _backgroundColorCache;
                _backgroundColorCache = nil;
            }
            
            self.foregroundView.backgroundColor = self.foregroundColor;
            self.layer.borderColor = self.borderColor.CGColor;
        };
        if (selected) {
            [UIView animateWithDuration:0.3 delay:0.0
                                options:UIViewAnimationOptionAllowUserInteraction
                             animations:fadeInBlock
                             completion:nil];
        } else {
            [UIView animateWithDuration:0.3 delay:0.0
                                options:UIViewAnimationOptionAllowUserInteraction
                             animations:fadeInBlock
                             completion:nil];
        }
    } else {
        if (selected) {
            fadeInBlock();
        } else {
            fadeInBlock();
        }
    }
}

- (void)setButtonType:(OSButtonType)buttonType {
    _buttonType = buttonType;
    if (buttonType == OSButtonType1) {
        self.cornerRadius = OS_MAX_BORDER_WIDTH;
        self.borderColor  = [UIColor clearColor];
        self.contentColor = [UIColor blackColor];
        self.contentAnimateColor = [UIColor whiteColor];
        self.foregroundColor = [UIColor whiteColor];
        self.foregroundAnimateColor = [UIColor clearColor];
    } else if (buttonType == OSButtonType2) {
        self.cornerRadius = OS_MAX_BORDER_WIDTH;
        self.borderWidth = 1.5;
        self.restoreSelectedState = NO;
        self.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        self.borderAnimateColor = [UIColor colorWithRed:120/255.0 green:1.0/255.0 blue:1.0/255.0 alpha:1.0];
        self.contentColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        self.contentAnimateColor = [UIColor colorWithRed:220/255.0 green:1.0/255.0 blue:1.0/255.0 alpha:1.0];
        self.foregroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
        self.backgroundColor = [UIColor clearColor];
    } else if (buttonType == OSButtonType3) {
        self.cornerRadius = OS_MAX_BORDER_WIDTH;
        self.borderWidth  = 2;
        self.restoreSelectedState = NO;
        self.borderColor = [UIColor clearColor];
        self.borderAnimateColor = [UIColor whiteColor];
        self.contentColor = [UIColor whiteColor];
        self.contentAnimateColor = [UIColor colorWithRed:1.0/255.0 green:1.0/255.0 blue:255.0/255.0 alpha:1.0];;
        self.foregroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        self.foregroundAnimateColor = [UIColor whiteColor];
    } else if (buttonType == OSButtonType4 ){
        self.contentAnimateColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        self.foregroundColor = [UIColor clearColor];
        self.foregroundAnimateColor = [UIColor clearColor];
    } else {
        if (_imageContentView) {
            _imageContentView.backgroundColor = [UIColor clearColor];
            _imageContentView.imageView.backgroundColor = [UIColor clearColor];
        }
    }
    
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Touchs
////////////////////////////////////////////////////////////////////////

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    UIView *touchView = [super hitTest:point withEvent:event];
    if ([self pointInside:point withEvent:event]) {
        return self;
    }
    return touchView;
}

/// 返回值:YES 接受用户通过addTarget:action:forControlEvents添加的事件继续处理。
/// 返回值:NO  则屏蔽用户添加的任何事件
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    self.trackingInside = YES;
    self.selected = !self.isSelected;
    return [super beginTrackingWithTouch:touch withEvent:event];
}

/// 判断是否保持追踪当前的触摸事件,这里根据得到的位置来判断是否正处于button的范围内，进而发送对应的事件
/// 控制OSButton的selected属性
- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    BOOL wasTrackingInside = self.isTrackingInside;
    self.trackingInside = [self isTouchInside];
    /*
     if (wasTrackingInside && !self.isTrackingInside) {
     self.selected = !self.isSelected;
     } else if (!wasTrackingInside && self.isTrackingInside) {
     self.selected = !self.isSelected;
     }
     */
    if (wasTrackingInside != self.isTrackingInside) {
        self.selected = !self.isSelected;
    }
    return [super continueTrackingWithTouch:touch withEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    self.trackingInside = [self isTouchInside];
    if (self.isTrackingInside && self.restoreSelectedState) {
        self.selected = !self.isSelected;
    }
    self.trackingInside = NO;
    [super endTrackingWithTouch:touch withEvent:event];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    self.trackingInside = [self isTouchInside];
    if (self.trackingInside) {
        self.selected = !self.isSelected;
    }
    self.trackingInside = NO;
    [super cancelTrackingWithEvent:event];
}


@end

#pragma mark *** SuspensionView ***

static NSString * const PreviousCenterXKey = @"previousCenterX";
static NSString * const PreviousCenterYKey = @"previousCenterY";

@interface SuspensionView ()

@property (nonatomic, assign) CGPoint previousCenter;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, assign) BOOL isMoving;

@end

@implementation SuspensionView

@synthesize previousCenter = _previousCenter;

////////////////////////////////////////////////////////////////////////
#pragma mark - initialize
////////////////////////////////////////////////////////////////////////


- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self _suspensionViewSetup];
        [self addActions];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self _suspensionViewSetup];
        [self addActions];
    }
    return self;
}

- (void)_suspensionViewSetup {
    
    self.autoLeanEdge = YES;
    self.leanEdgeInsets = UIEdgeInsetsMake(20, 0, 0, 0);
    self.invalidHidden = NO;
    self.isMoving = NO;
    self.usingSpringWithDamping = 0.8; // 范围的为0.0f到1.0f，数值越小「弹簧」的振动效果越明显
    self.initialSpringVelocity = 3.0; // 表示初始的速度，数值越大一开始移动越快
    self.shouldLeanToPreviousPositionWhenAppStart = YES;
    CGFloat centerX = [[NSUserDefaults standardUserDefaults] doubleForKey:PreviousCenterXKey];
    CGFloat centerY = [[NSUserDefaults standardUserDefaults] doubleForKey:PreviousCenterYKey];
    if (centerX > 0 || centerY > 0) {
        self.previousCenter = CGPointMake(centerX, centerY);
    } else {
        self.previousCenter = self.center;
    }
    
}


- (void)addActions {
    
    self.userInteractionEnabled = YES;
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(_locationChange:)];
    pan.delaysTouchesBegan = YES;
    [self addGestureRecognizer:pan];
    _panGestureRecognizer = pan;
    
    [self addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Public
////////////////////////////////////////////////////////////////////////


- (void)leanFinishCallBack:(void (^)(CGPoint centerPoint))callback {
    self.leanFinishCallBack = callback;
}

- (void)setHidden:(BOOL)hidden {
    if (self.invalidHidden) {
        return;
    }
    [super setHidden:hidden];
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
    
    self.clickCallBack = nil;
    self.leanFinishCallBack = nil;
    self.delegate = nil;
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Position
////////////////////////////////////////////////////////////////////////

- (void)_locationChange:(UIPanGestureRecognizer *)p {
    // 获取到的是手指点击屏幕实时的坐标点, 此种获取坐标更新suspension的center会导致，开始移动时suspension会跳动一下
    //     CGPoint translatedCenter = [p locationInView:[UIApplication sharedApplication].delegate.window];
    
    UIWindow *w = [SuspensionControl windowForKey:self.key];
    UIView *targetView = p.view;
    // 在没有window时坐标转换错误，导致无法移动, 此处需要判断
    if (w) {
        targetView = [UIApplication sharedApplication].delegate.window;
    }
    
    // 获取到的是手指移动后，在相对坐标中的偏移量，此种情况完美
    CGPoint translation = [p translationInView:[UIApplication sharedApplication].delegate.window];
    CGPoint panViewCenter = [self convertPoint:p.view.center toView:targetView];
    CGPoint translatedCenter = CGPointMake(panViewCenter.x + translation.x, panViewCenter.y + translation.y);
    // 重置偏移量
    [p setTranslation:CGPointZero inView:[UIApplication sharedApplication].delegate.window];
    
    if (p.state == UIGestureRecognizerStateBegan) {
        
    } else if(p.state == UIGestureRecognizerStateChanged) {
        [self movingWithPoint:translatedCenter];
        
    } else if(p.state == UIGestureRecognizerStateEnded
              || p.state == UIGestureRecognizerStateCancelled) {
        
        if (!self.isAutoLeanEdge) {
            return;
        }
        CGPoint newTargetPoint = [self _checkTargetPosition:translatedCenter];
        [self autoLeanToTargetPosition:newTargetPoint];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(suspensionView:locationChange:)]) {
        [self.delegate suspensionView:self locationChange:p];
        return;
    }
    
    if (self.locationChange) {
        self.locationChange(translatedCenter);
    }
}


/// 手指移动时，移动视图
- (void)movingWithPoint:(CGPoint)point {
    
    UIWindow *w = [SuspensionControl windowForKey:self.key];
    if (w) {
        w.center = CGPointMake(point.x, point.y);
    } else {
        self.center = CGPointMake(point.x, point.y);
    }
    _isMoving = YES;
}

- (void)checkTargetPosition {
    
    if (self.shouldLeanToPreviousPositionWhenAppStart) {
        CGPoint newTargetPoint = [self _checkTargetPosition:self.previousCenter];
        [self autoLeanToTargetPosition:newTargetPoint];
    } else {
        CGPoint currentPoint = [self convertPoint:self.center toView:[UIApplication sharedApplication].delegate.window];
        CGPoint newTargetPoint = [self _checkTargetPosition:currentPoint];
        [self autoLeanToTargetPosition:newTargetPoint];
    }
    
}

/// 根据传入的位置检查处理最终依靠到边缘的位置
- (CGPoint)_checkTargetPosition:(CGPoint)panPoint {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(leanToNewTragetPosionForSuspensionView:)]) {
        self.previousCenter = [self.delegate leanToNewTragetPosionForSuspensionView:self];
        return self.previousCenter;
    }
    
    CGFloat touchWidth = self.frame.size.width;
    CGFloat touchHeight = self.frame.size.height;
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    
    CGFloat left = fabs(panPoint.x);
    CGFloat right = fabs(screenWidth - left);
    CGFloat top = fabs(panPoint.y);
    CGFloat bottom = fabs(screenHeight - top);
    
    CGFloat minSpace = 0;
    if (self.leanEdgeType == SuspensionViewLeanEdgeTypeHorizontal) {
        minSpace = MIN(left, right);
    }
    else if (self.leanEdgeType == SuspensionViewLeanEdgeTypeEachSide) {
        minSpace = MIN(MIN(MIN(top, left), bottom), right);
    }
    CGPoint newTargetPoint = CGPointZero;
    CGFloat targetY = 0;
    
    if (panPoint.y < self.leanEdgeInsets.top + touchHeight / 2.0 + self.leanEdgeInsets.top) {
        targetY = self.leanEdgeInsets.top + touchHeight / 2.0 + self.leanEdgeInsets.top;
    }
    else if (panPoint.y > (screenHeight - touchHeight / 2.0 - self.leanEdgeInsets.bottom)) {
        targetY = screenHeight - touchHeight / 2.0 - self.leanEdgeInsets.bottom;
    }
    else{
        targetY = panPoint.y;
    }
    
    if (minSpace == left) {
        newTargetPoint = CGPointMake(touchWidth / 2 + self.leanEdgeInsets.left, targetY);
    }
    if (minSpace == right) {
        newTargetPoint = CGPointMake(screenWidth - touchWidth / 2 - self.leanEdgeInsets.right, targetY);
    }
    if (minSpace == top) {
        newTargetPoint = CGPointMake(panPoint.x, touchHeight / 2 + self.leanEdgeInsets.top);
    }
    if (minSpace == bottom) {
        newTargetPoint = CGPointMake(panPoint.x, screenHeight - touchHeight / 2 - self.leanEdgeInsets.bottom);
    }
    // 记录当前的center
    self.previousCenter = newTargetPoint;
    
    return newTargetPoint;
}


- (void)moveToPreviousLeanPosition {
    
    [self autoLeanToTargetPosition:self.previousCenter];
}

/// 移动移动到屏幕中心位置
- (void)moveToScreentCenter {
    
    [self autoLeanToTargetPosition:[UIApplication sharedApplication].delegate.window.center];
}

/// 自动移动到边缘，此方法在手指松开后会自动移动到目标位置
- (void)autoLeanToTargetPosition:(CGPoint)point {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(suspensionView:willAutoLeanToTargetPosition:)]) {
        [self.delegate suspensionView:self willAutoLeanToTargetPosition:point];
    }
    [UIView animateWithDuration:0.3
                          delay:0.1
         usingSpringWithDamping:self.usingSpringWithDamping
          initialSpringVelocity:self.initialSpringVelocity
                        options:UIViewAnimationOptionCurveEaseIn |
     UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         UIWindow *w = [SuspensionControl windowForKey:self.key];
                         if (w) {
                             w.center = point;
                         } else {
                             self.center = point;
                         }
                         
                     } completion:^(BOOL finished) {
                         if (finished) {
                             
                             [self autoLeanToTargetPositionCompletion:point];
                             _isMoving = NO;
                         }
                     }];
}

- (void)autoLeanToTargetPositionCompletion:(CGPoint)currentPosition {
    if (self.delegate && [self.delegate respondsToSelector:@selector(suspensionView:didAutoLeanToTargetPosition:)]) {
        [self.delegate suspensionView:self didAutoLeanToTargetPosition:currentPosition];
        return;
    }
    if (self.leanFinishCallBack) {
        self.leanFinishCallBack(currentPosition);
    }
}

- (void)orientationDidChange:(NSNotification *)note {
    if (self.isAutoLeanEdge) {
        /// 屏幕旋转时检测下最终依靠的位置，防止出现屏幕旋转记录的previousCenter未更新坐标时，导致按钮不见了
        CGPoint currentPoint = [self convertPoint:self.center toView:[UIApplication sharedApplication].delegate.window];
        
        [self _checkTargetPosition:currentPoint];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
////////////////////////////////////////////////////////////////////////

- (void)btnClick:(id)sender {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(suspensionViewClickedButton:)]) {
        [self.delegate suspensionViewClickedButton:self];
        return;
    }
    
    if (self.clickCallBack) {
        self.clickCallBack();
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - setter  getter
////////////////////////////////////////////////////////////////////////

- (SuspensionViewLeanEdgeType)leanEdgeType {
    return _leanEdgeType ?: SuspensionViewLeanEdgeTypeEachSide;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"%s", __func__);
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

- (NSString *)key {
    return _isOnce ? [[SuspensionControl shareInstance] keyWithIdentifier:NSStringFromClass([self class])] : [super key];
}

- (void)setPreviousCenter:(CGPoint)previousCenter {
    _previousCenter = previousCenter;
    [[NSUserDefaults standardUserDefaults] setDouble:previousCenter.x forKey:PreviousCenterXKey];
    [[NSUserDefaults standardUserDefaults] setDouble:previousCenter.y forKey:PreviousCenterYKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

#pragma mark *** UIResponder (SuspensionView) ***

@interface UIResponder ()

@property (nonatomic) SuspensionView *suspensionView;

@end

@implementation UIResponder (SuspensionView)

- (SuspensionView *)showSuspensionViewWithFrame:(CGRect)frame {
    
    UIView *view = [self getSelfView];
    if (!view) {
        return nil;
    }
    if (!self.suspensionView && !self.suspensionView.superview) {
        SuspensionView *suspensionView = [[SuspensionView alloc] initWithFrame:frame];
        self.suspensionView = suspensionView;
        self.suspensionView.clipsToBounds = YES;
        [view addSubview:suspensionView];
    }
    else if (self.suspensionView && !self.suspensionView.superview) {
        [view addSubview:self.suspensionView];
    }
    
    [view bringSubviewToFront:self.suspensionView];
    return self.suspensionView;
}

- (UIView *)getSelfView {
    BOOL result = [self isKindOfClass:[UIViewController class]] || [self isKindOfClass:[UIView class]];
    if (!result) {
        NSAssert(result, @"Error: The current class should be UIViewController or UIView or their subclass");
        return nil;
    }
    UIView *view = nil;
    if ([self isKindOfClass:[UIViewController class]]) {
        UIViewController *vc = (UIViewController *)self;
        view = vc.view;
    } else if ([self isKindOfClass:[UIView class]]) {
        view = (UIView *)self;
    }
    return view;
}


- (void)dismissSuspensionView:(void (^)(void))block {
    
    [self.suspensionView removeFromSuperview];
    self.suspensionView = nil;
    if (block) {
        block();
    }
}

- (void)setHiddenSuspension:(BOOL)flag {
    self.suspensionView.hidden = flag;
}
- (BOOL)isHiddenSuspension {
    return self.suspensionView.isHidden;
}
- (void)setSuspensionTitle:(NSString *)title forState:(UIControlState)state {
    [self.suspensionView setTitle:title forState:UIControlStateNormal];
}
- (void)setSuspensionImage:(UIImage *)image forState:(UIControlState)state {
    [self.suspensionView setImage:image forState:UIControlStateNormal];
}
- (void)setSuspensionImageWithImageNamed:(NSString *)name forState:(UIControlState)state {
    [self setSuspensionImage:[UIImage imageNamed:name] forState:state];
}

- (void)setSuspensionBackgroundColor:(UIColor *)color cornerRadius:(CGFloat)cornerRadius {
    [self.suspensionView setBackgroundColor:color];
    if (cornerRadius) {
        self.suspensionView.layer.cornerRadius = cornerRadius;
        self.suspensionView.layer.masksToBounds = YES;
    }
}

- (SuspensionView *)suspensionView {
    return objc_getAssociatedObject(self, @selector(suspensionView));
}

- (void)setSuspensionView:(SuspensionView *)suspensionView {
    objc_setAssociatedObject(self, @selector(suspensionView), suspensionView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark *** SuspensionMenuController ***

@interface SuspensionMenuController : UIViewController

- (instancetype)initWithMenuView:(SuspensionMenuView *)menuView ;

@property (nonatomic, strong) SuspensionMenuWindow *menuView;

@end

#pragma mark *** SuspensionWindow ***

@implementation SuspensionWindow

////////////////////////////////////////////////////////////////////////
#pragma mark - Public methods
////////////////////////////////////////////////////////////////////////


+ (instancetype)showOnce:(BOOL)isOnce frame:(CGRect)frame {
    
    SuspensionWindow *s = [[self alloc] initWithFrame:frame];
    s.leanEdgeType = SuspensionViewLeanEdgeTypeEachSide;
    s.isOnce = isOnce;
    [s _moveToSuperview];
    
    return s;
}

- (void)removeFromSuperview {
    self.clickCallBack = nil;
    self.leanFinishCallBack = nil;
    [SuspensionControl removeWindowForKey:self.key];
    [super removeFromSuperview];
}

+ (void)releaseAll {
    
    NSDictionary *temp = [[SuspensionControl windows] mutableCopy];
    [temp enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, UIWindow * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.suspensionView && !obj.suspensionMenuView) {
            [SuspensionControl removeWindow:obj];
        }
    }];
    temp = nil;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private methods
////////////////////////////////////////////////////////////////////////


- (void)_moveToSuperview {
    
    UIWindow *suspensionWindow = [[UIWindow alloc] initWithFrame:self.frame];
    
#ifdef DEBUG
    suspensionWindow.windowLevel = CGFLOAT_MAX+10;
#else
    suspensionWindow.windowLevel = UIWindowLevelAlert * 3;
#endif
    
    UIViewController *vc = [UIViewController new];
    suspensionWindow.rootViewController = vc;
    
    [suspensionWindow.layer setMasksToBounds:YES];
    
    [SuspensionControl setWindow:suspensionWindow forKey:self.key];
    self.frame = CGRectMake(0,
                            0,
                            self.frame.size.width,
                            self.frame.size.height);
    self.clipsToBounds = YES;
    
    [vc.view addSubview:self];
    
    suspensionWindow.suspensionView = self;
    
    suspensionWindow.hidden = NO;
}

@end

static const NSUInteger menuBarButtonBaseTag = 100;
static const NSUInteger moreBarButtonBaseTag = 200;

@interface SuspensionMenuView () <SuspensionViewDelegate> {
@private
    struct {
        CGFloat _defaultTriangleHypotenuse; // 默认关闭时的三角斜边
        CGFloat _minBounceOfTriangleHypotenuse; // 当第一次显示完成后的三角斜边
        CGFloat _maxBounceOfTriangleHypotenuse; // 当显示时要展开的三角斜边
        CGFloat _maxTriangleHypotenuse; // 最大三角斜边，当第一次刚出现时三角斜边
        CGRect  _memuBarButtonOriginFrame; // 每一个菜单上按钮的原始frame 除中心的按钮 关闭时也可使用,重叠
        BOOL _isOpened;  // 是否已经显示
        BOOL _isClosed; // 是否已经消失
        BOOL _isFiristOpened;      // 是否第一次显示
        CGSize _menuWindowSize;
        CGSize _centerWindowSize;
    } _viewFlags;
    
    
}

@property (nonatomic, strong) SuspensionView *centerButton;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIVisualEffectView *visualEffectView;
@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, strong) HypotenuseAction *currentDisplayMoreItem;
/// 保证currentDisplayMoreItems在栈顶，menuBarItems在栈底
@property (nonatomic, strong) NSMutableArray<HypotenuseAction *> *stackDisplayedItems;
/// 存储的为调用testPushViewController时的HypotenuseAction和跳转的viewController，保证第二次点击时pop并从此字典中移除
@property (nonatomic, strong) NSDictionary<NSNumber *, NSString *> *testPushViewControllerDictionary;
@property (nonatomic, strong) HypotenuseAction *currentClickHypotenuseItem;
@property (nonatomic, strong) NSMutableArray<HypotenuseAction *> *menuBarItems;
@property (nonatomic, copy) void (^ _Nullable openCompletion)(void);
@property (nonatomic, copy) void (^ _Nullable closeCompletion)(void);

@end

#pragma mark *** SuspensionMenuView ***

@implementation SuspensionMenuView

@synthesize
centerButton = _centerButton,
stackDisplayedItems = _stackDisplayedItems,
menuBarItems = _menuBarItems;



////////////////////////////////////////////////////////////////////////
#pragma mark - Public Methods
////////////////////////////////////////////////////////////////////////

- (instancetype)initWithFrame:(CGRect)frame itemSize:(CGSize)itemSize {
    if (self = [super initWithFrame:frame]) {
        [self _suspensionMenuViewSetup];
        [self setItemSize:itemSize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    NSAssert(NO, @"use - initWithFrame:itemSize:");
    @throw nil;
    
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self _suspensionMenuViewSetup];
    }
    return self;
}


- (void)setMenuBarItems:(NSArray<HypotenuseAction *> *)menuBarItems itemSize:(CGSize)itemSize {
    self.menuBarItems = [menuBarItems mutableCopy];
    [self setItemSize:itemSize];
}

- (void)addAction:(HypotenuseAction *)action {
    if (!action) {
        return;
    }
    if (!_menuBarItems) {
        _menuBarItems = [NSMutableArray array];
    }
    [_menuBarItems addObject:action];
}

- (void)showWithCompetion:(void (^ _Nullable)(void))competion {
    [self setMenuBarItems:self.menuBarItems itemSize:self.itemSize];
    self.openCompletion = competion;
    
}


- (void)setItemSize:(CGSize)itemSize {
    _viewFlags._menuWindowSize = self.frame.size;
    _itemSize = CGSizeMake(MIN(MAX(MIN(itemSize.width, itemSize.height), 50.0), 80),
                           MIN(MAX(MIN(itemSize.width, itemSize.height), 50.0), 80));
    _viewFlags._centerWindowSize = _itemSize;
    
    [self setupLayout];
}

- (void)setCurrentDisplayMoreItem:(HypotenuseAction *)currentDisplayMoreItem {
    _currentDisplayMoreItem = currentDisplayMoreItem;
    
    NSUInteger foundIdx = [self.stackDisplayedItems indexOfObjectPassingTest:^BOOL(HypotenuseAction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj isEqual:currentDisplayMoreItem];
    }];
    if (foundIdx != NSNotFound) {
        [self.stackDisplayedItems removeObjectAtIndex:foundIdx];
    }
    [self.stackDisplayedItems addObject:currentDisplayMoreItem];
    static NSInteger idx = 0;
    for (HypotenuseAction *item in currentDisplayMoreItem.moreHypotenusItems) {
        [item.hypotenuseButton setOpaque:NO];
        [item.hypotenuseButton setTag:moreBarButtonBaseTag + idx];
        [item.hypotenuseButton addTarget:self action:@selector(moreBarButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [item.hypotenuseButton setAlpha:0.0];
        [self addSubview:item.hypotenuseButton];
        [item.hypotenuseButton setFrame:_viewFlags._memuBarButtonOriginFrame];
        idx++;
    }
}



- (void)setMenuBarItems:(NSArray<HypotenuseAction *> *)menuBarItems {
    
    if (_menuBarItems != menuBarItems) {
        [self.stackDisplayedItems removeAllObjects];
    }
    _menuBarItems = [menuBarItems mutableCopy];
    
    NSInteger idx = 0;
    for (HypotenuseAction *item in menuBarItems) {
        [item.hypotenuseButton setOpaque:NO];
        [item.hypotenuseButton setTag:menuBarButtonBaseTag+idx];
        [item.hypotenuseButton addTarget:self action:@selector(menuBarButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [item.hypotenuseButton setAlpha:0.0];
        [self addSubview:item.hypotenuseButton];
        [item.hypotenuseButton setFrame:_viewFlags._memuBarButtonOriginFrame];
        idx++;
    }
}

- (void)testPushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSParameterAssert(viewController);
    viewController.hidesBottomBarWhenPushed = YES;
    if ([[self topViewController] isMemberOfClass:[viewController class]]) {
        [[self topViewController].navigationController popViewControllerAnimated:YES];
        [self close];
        self.testPushViewControllerDictionary = nil;
        return;
    } else {
        
        NSMutableArray *vcs = [[self topViewController].navigationController.viewControllers mutableCopy];
        NSUInteger founVcIndex = [vcs indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj class] == [viewController class];
        }];
        if (vcs && founVcIndex != NSNotFound) {
            UIViewController *targetVc = vcs[founVcIndex];
            [[self topViewController].navigationController popToViewController:targetVc animated:YES];
            self.testPushViewControllerDictionary = nil;
            [self close];
            return;
        }
    }
    
    if (_currentClickHypotenuseItem && viewController) {
        // 取
        NSString *vcProAddress = self.testPushViewControllerDictionary.allValues.lastObject;
        if (vcProAddress.length) {
            NSMutableArray *vcs = [[self topViewController].navigationController.viewControllers mutableCopy];
            NSUInteger founVcIndex = [vcs indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                return [[NSString stringWithFormat:@"%p", obj] isEqualToString:vcProAddress];
            }];
            Class founVcClass;
            if (vcs && founVcIndex != NSNotFound) {
                founVcClass = [[vcs objectAtIndex:founVcIndex] class];
                if (founVcIndex > 0) {
                    UIViewController *targetVc = vcs[founVcIndex - 1];
                    [[self topViewController].navigationController popToViewController:targetVc animated:animated];
                } else {
                    [[self topViewController].navigationController popToRootViewControllerAnimated:animated];
                }
                self.testPushViewControllerDictionary = nil;
                [self close];
                if (founVcClass == [viewController class]) {
                    return;
                }
            }
        }
        
    }
    
    void(^pushAnimationsCompetionsBlockForViewController)(BOOL isFinished) = ^(BOOL isFinished) {
        if ([self topViewController].navigationController == 0x0) {
            if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1 && animated) {
                [[self topViewController] showDetailViewController:viewController sender:self];
            }
            else {
                [[self topViewController] presentViewController:viewController animated:animated completion:NULL];
            }
        }
        else {
            if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1 && animated) {
                [[self topViewController].navigationController showViewController:viewController sender:self];
            } else {
                [[self topViewController].navigationController pushViewController:viewController animated:animated];
            }
            UIWindow *menuWindow = [SuspensionControl windowForKey:self.key];
            CGRect menuFrame =  menuWindow.frame;
            menuFrame.size = CGSizeZero;
            menuWindow.frame = menuFrame;
            _viewFlags._isClosed = YES;
            _viewFlags._isOpened = NO;
            [self _closeCompetion];
            // 存
            NSNumber *btnTag = @([_currentClickHypotenuseItem.hypotenuseButton tag]);
            if (!btnTag) {
                return;
            }
            self.testPushViewControllerDictionary = @{btnTag: [NSString stringWithFormat:@"%p", viewController]};
        }
    };
    
    void (^pushAnimationsBlock)(void) = ^ {
        if (self.shouldHiddenCenterButtonWhenOpen) {
            UIWindow *centerWindow = [SuspensionControl windowForKey:self.centerButton.key];
            CGRect centerFrame =  centerWindow.frame;
            centerFrame.size = _viewFlags._centerWindowSize;
            centerWindow.frame = centerFrame;
            centerWindow.alpha = 1.0;
        }
        [self updateMenuBarButtonLayoutWithTriangleHypotenuse:_viewFlags._maxTriangleHypotenuse hypotenuseItems:self.menuBarItems];
        [self setAlpha:0.0];
        for (UIControl *btn in self.subviews) {
            if ([btn isKindOfClass:NSClassFromString(@"MenuBarHypotenuseButton")]) {
                [btn setAlpha:0.0];
            }
        }
        [self.centerButton moveToPreviousLeanPosition];
    };
    
    [UIView animateWithDuration:0.3
                          delay:0.0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                     animations:pushAnimationsBlock
                     completion:pushAnimationsCompetionsBlockForViewController];
}



- (void)_openWithNeedCurveEaseInOut:(BOOL)isCurveEaseInOut {
    if (_viewFlags._isOpened) return;
    self.centerButton.usingSpringWithDamping = 0.8;
    self.centerButton.initialSpringVelocity = 20;
    if (_viewFlags._isFiristOpened) {
        [self updateMenuBarButtonLayoutWithTriangleHypotenuse:_viewFlags._maxTriangleHypotenuse hypotenuseItems:self.menuBarItems];
    }
    
    if (_shouldLeanToScreenCenterWhenOpened) {
        [self.centerButton moveToScreentCenter];
    }
    
    [self centerButton];
    [self _updateMenuViewCenterWithIsOpened:YES];
    
    if (self.shouldHiddenCenterButtonWhenOpen) {
        UIWindow *centerWindow = [SuspensionControl windowForKey:self.centerButton.key];
        CGRect centerFrame =  centerWindow.frame;
        centerFrame.size = CGSizeZero;
        centerWindow.frame = centerFrame;
        centerWindow.alpha = 0.0;
    }
    
    void (^openCompletionBlock)(BOOL finished) = ^(BOOL finished) {
        // 此处动画结束时,menuWindow的bounds为CGRectZero了,原因是动画时间相错
        //                         NSLog(@"%@", NSStringFromCGRect(menuWindow.frame));
        //                         if (menuWindow.frame.size.width == 0 || menuWindow.frame.size.height == 0) {
        //                             NSLog(@"为0了");
        //                             [self _updateMenuViewCenterWithIsOpened:YES];
        //                         }
        [UIView animateWithDuration:0.1
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             [self updateMenuBarButtonLayoutWithTriangleHypotenuse:_viewFlags._defaultTriangleHypotenuse hypotenuseItems:self.menuBarItems];
                         }
                         completion:^(BOOL finished) {
                             _viewFlags._isOpened = YES;
                             _viewFlags._isClosed = NO;
                             _viewFlags._isFiristOpened = NO;
                             [self _openCompetion];
                             if (self.menuBarItems) {
                                 for (HypotenuseAction *item in self.menuBarItems) {
                                     item.orginRect = item.hypotenuseButton.frame;
                                 }
                             }
                         }];
    };
    NSTimeInterval usingSpringWithDamping = self.usingSpringWithDamping;
    NSTimeInterval initialSpringVelocity = self.initialSpringVelocity;
    if (!isCurveEaseInOut) {
        openCompletionBlock = nil;
        usingSpringWithDamping = 0.65;
        initialSpringVelocity = 2.0;
    }
    
    void(^openAnimationsBlockWithNeedCurveEaseInOut)(void) = ^ {
        UIWindow *menuWindow = [SuspensionControl windowForKey:self.key];
        [menuWindow setAlpha:1.0];
        [self setAlpha:1.0];
        
        for (UIView *view in self.subviews) {
            if ([view isKindOfClass:NSClassFromString(@"MenuBarHypotenuseButton")]) {
                [view setAlpha:1.0];
            }
        }
        
        // 更新menu bar 的 布局
        CGFloat triangleHypotenuse = 0.0;
        if (!isCurveEaseInOut) {
            triangleHypotenuse = _viewFlags._defaultTriangleHypotenuse;
        } else {
            if (_viewFlags._isFiristOpened) {
                triangleHypotenuse = _viewFlags._minBounceOfTriangleHypotenuse;
            } else {
                triangleHypotenuse = _viewFlags._maxBounceOfTriangleHypotenuse;
            }
        }
        
        [self updateMenuBarButtonLayoutWithTriangleHypotenuse:triangleHypotenuse hypotenuseItems:self.menuBarItems];
    };
    
    [UIView animateWithDuration:0.4
                          delay:0.0
         usingSpringWithDamping:usingSpringWithDamping
          initialSpringVelocity:initialSpringVelocity
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                     animations:openAnimationsBlockWithNeedCurveEaseInOut
                     completion:openCompletionBlock];
}

- (void)open {
    [self _openWithNeedCurveEaseInOut:YES];
    
}

- (void)close {
    [self _closeWithTriggerPanGesture:NO];
}

- (void)_openCompetion {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(suspensionMenuViewDidOpened:)]) {
        [self.delegate suspensionMenuViewDidOpened:self];
        return;
    }
    
    if (self.openCompletion) {
        self.openCompletion();
    }
}

/// 执行close，并根据当前是否触发了拖动手势，确定是否在让SuapensionWindow执行移动边缘的操作，防止移除时乱窜
- (void)_closeWithTriggerPanGesture:(BOOL)isTriggerPanGesture {
    
    if (_viewFlags._isClosed)
        return;
    
    self.centerButton.usingSpringWithDamping = 0.5;
    self.centerButton.initialSpringVelocity = 10;
    if (self.shouldHiddenCenterButtonWhenOpen) {
        UIWindow *centerWindow = [SuspensionControl windowForKey:self.centerButton.key];
        CGRect centerFrame =  centerWindow.frame;
        centerFrame.size = _viewFlags._centerWindowSize;
        centerWindow.frame = centerFrame;
        centerWindow.alpha = 1.0;
    }
    
    void (^closeAnimationsBlockWityIsTriggerPanGesture)(void) = ^ {
        [self setAlpha:0.0];
        for (UIView *view in self.subviews) {
            [view setFrame:_viewFlags._memuBarButtonOriginFrame];
            if ([view isKindOfClass:NSClassFromString(@"MenuBarHypotenuseButton")]) {
                [view setAlpha:0.0];
            }
        }
        
        if (!isTriggerPanGesture) {
            [self.centerButton moveToPreviousLeanPosition];
        }
    };
    
    void (^closeCompletionBlock)(BOOL finished) = ^(BOOL finished) {
        UIWindow *menuWindow = [SuspensionControl windowForKey:self.key];
        
        [UIView animateWithDuration:0.1 animations:^{
            [menuWindow setAlpha:0.0];
            // 让其frame为zero，为了防止其隐藏后所在的位置无法响应事件
        } completion:^(BOOL finished) {
            CGRect menuFrame =  menuWindow.frame;
            menuFrame.size = CGSizeZero;
            menuWindow.frame = menuFrame;
            _viewFlags._isClosed = YES;
            _viewFlags._isOpened  = NO;
            [self _closeCompetion];
        } ];
    };
    
    [UIView animateWithDuration:0.3
                          delay:0.0
         usingSpringWithDamping:self.usingSpringWithDamping
          initialSpringVelocity:self.initialSpringVelocity
                        options:UIViewAnimationCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                     animations:closeAnimationsBlockWityIsTriggerPanGesture
                     completion:closeCompletionBlock];
}



- (void)_closeCompetion {
    
    [self removeAllMoreButtons];
    if (self.delegate && [self.delegate respondsToSelector:@selector(suspensionMenuViewDidClose:)]) {
        [self.delegate suspensionMenuViewDidClose:self];
        return;
    }
    if (self.closeCompletion) {
        self.closeCompletion();
    }
}

- (void)removeAllMoreButtons {
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"MenuBarHypotenuseButton")]) {
            if (view.tag >= moreBarButtonBaseTag) {
                [view removeFromSuperview];
            }
        }
    }
    _currentDisplayMoreItem = nil;
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Lazy
////////////////////////////////////////////////////////////////////////


- (SuspensionView *)centerButton {
    if (_centerButton == nil) {
        // 创建中心按钮
        CGRect centerButtonFrame = CGRectMake((CGRectGetWidth(self.frame) - _viewFlags._centerWindowSize.width) * 0.5,
                                              (CGRectGetHeight(self.frame) - _viewFlags._centerWindowSize.height) * 0.5,
                                              _viewFlags._centerWindowSize.width,
                                              _viewFlags._centerWindowSize.height);
        
        CGRect centerRec = [self convertRect:centerButtonFrame toView:[UIApplication sharedApplication].delegate.window];
        
        SuspensionView *centerButton = (SuspensionWindow *)[NSClassFromString(@"_MenuBarCenterButton") showOnce:YES frame:centerRec];
        centerButton.autoLeanEdge = YES;
        centerButton.delegate = self;
        
        _centerButton = centerButton;
        
    }
    return _centerButton;
}



- (UIImageView *)backgroundImageView {
    if (_backgroundImageView == nil) {
        UIImageView *imageView = [NSClassFromString(@"_MenuViewBackgroundImageView") new];
        _backgroundImageView = imageView;
        imageView.userInteractionEnabled = YES;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:imageView];
        [self insertSubview:imageView atIndex:0];
        imageView.frame = self.bounds;
        [self visualEffectView];
    }
    return _backgroundImageView;
}

- (UIVisualEffectView *)visualEffectView {
    if (_visualEffectView == nil) {
        UIBlurEffect *blurEffrct =[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffrct];
        visualEffectView.frame = self.bounds;
        visualEffectView.alpha = 1.0;
        [self addSubview:visualEffectView];
        _visualEffectView = visualEffectView;
        visualEffectView.userInteractionEnabled = NO;
    }
    if (_backgroundImageView) {
        [self insertSubview:_visualEffectView aboveSubview:_backgroundImageView];
    } else {
        [self insertSubview:_visualEffectView atIndex:0];
    }
    return _visualEffectView;
}

- (NSMutableArray<HypotenuseAction *> *)stackDisplayedItems {
    if (!_stackDisplayedItems) {
        _stackDisplayedItems = [NSMutableArray array];
    }
    return _stackDisplayedItems;
}

- (NSDictionary<NSNumber *, NSString*> *)testPushViewControllerDictionary {
    if (!_testPushViewControllerDictionary) {
        _testPushViewControllerDictionary = [NSMutableDictionary dictionary];
    }
    return _testPushViewControllerDictionary;
}


- (void)_suspensionMenuViewSetup {
    
    _viewFlags._isOpened  = NO;
    _viewFlags._isClosed = YES;
    _viewFlags._isFiristOpened = YES;
    _shouldLeanToScreenCenterWhenOpened = NO;
    _usingSpringWithDamping = 0.6;
    _initialSpringVelocity = 0.0;
    _shouldHiddenCenterButtonWhenOpen = NO;
    _shouldCloseWhenDeviceOrientationDidChange = NO;
    _menuBarItems = [NSMutableArray array];
    
    self.autoresizingMask = UIViewAutoresizingNone;
    self.layer.cornerRadius = 12.8;
    [self.layer setMasksToBounds:YES];
    [self setClipsToBounds:YES];
    [self visualEffectView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
}

- (void)setupLayout {
    
    // 设置三角斜边
    _viewFlags._defaultTriangleHypotenuse = (_viewFlags._menuWindowSize.width - _itemSize.width) * 0.5;
    _viewFlags._minBounceOfTriangleHypotenuse = _viewFlags._defaultTriangleHypotenuse - 12.0;
    _viewFlags._maxBounceOfTriangleHypotenuse = _viewFlags._defaultTriangleHypotenuse + 12.0;
    _viewFlags._maxTriangleHypotenuse = kSCREENT_HEIGHT * 0.5;
    
    // 计算menu 上 按钮的 原始 frame 当close 时 回到原始位置
    CGFloat originX = (_viewFlags._menuWindowSize.width - _viewFlags._centerWindowSize.width) * 0.5;
    _viewFlags._memuBarButtonOriginFrame = CGRectMake(originX,
                                                      originX,
                                                      _viewFlags._centerWindowSize.width,
                                                      _viewFlags._centerWindowSize.height);
    [self setNeedsLayout];
}


- (void)setFrame:(CGRect)frame {
    [super setFrame:CGRectMake(frame.origin.x,
                               frame.origin.y,
                               OS_MAX_MENUVIEW_SIZE.width,
                               OS_MAX_MENUVIEW_SIZE.height)];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
////////////////////////////////////////////////////////////////////////


// 中心 button 点击事件
- (void)centerBarButtonClick:(id)senter {
    _viewFlags._isClosed ? [self open] : [self close];
}

// 斜边的 button 点击事件 button tag 如下图:
//
// TAG:        1       1   2      1   2     1   2     1 2 3     1 2 3
//            \|/       \|/        \|/       \|/       \|/       \|/
// COUNT: 1) --|--  2) --|--   3) --|--  4) --|--  5) --|--  6) --|--
//            /|\       /|\        /|\       /|\       /|\       /|\
// TAG:                             3       3   4     4   5     4 5 6
//
- (void)menuBarButtonClick:(id)sender {
    
    // 获取当前点击的button是否有更多button需要展示
    NSUInteger foundMenuButtonIdx = [self.menuBarItems indexOfObjectPassingTest:^BOOL(HypotenuseAction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return sender == obj.hypotenuseButton;
    }];
    
    if (foundMenuButtonIdx == NSNotFound) {
        return;
    }
    
    HypotenuseAction *item = self.menuBarItems[foundMenuButtonIdx];
    _currentClickHypotenuseItem = item;
    if (item.moreHypotenusItems.count) {
        [self moreButtonClickWithHypotenuseItem:item];
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(suspensionMenuView:clickedHypotenuseButtonAtIndex:)]) {
        [self.delegate suspensionMenuView:self clickedHypotenuseButtonAtIndex:foundMenuButtonIdx];
        return;
    }
    if (_menuBarClickBlock) {
        _menuBarClickBlock(foundMenuButtonIdx);
    }
    
}

- (void)moreBarButtonClick:(id)sender {
    
    NSUInteger foundMoreButtonIdx = [self.currentDisplayMoreItem.moreHypotenusItems indexOfObjectPassingTest:^BOOL(HypotenuseAction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return sender == obj.hypotenuseButton;
    }];
    
    if (foundMoreButtonIdx == NSNotFound) {
        return;
    }
    
    
    HypotenuseAction *item = [self.currentDisplayMoreItem.moreHypotenusItems objectAtIndex:foundMoreButtonIdx];
    _currentClickHypotenuseItem = item;
    
    if (item.moreHypotenusItems.count) {
        [self moreButtonClickWithHypotenuseItem:item];
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(suspensionMenuView:clickedMoreButtonAtIndex:fromHypotenuseItem:)]) {
        [self.delegate suspensionMenuView:self clickedMoreButtonAtIndex:foundMoreButtonIdx fromHypotenuseItem:item];
    } else if (self.moreButtonClickBlock) {
        self.moreButtonClickBlock(foundMoreButtonIdx);
    }
    
}

- (void)moreButtonClickWithHypotenuseItem:(HypotenuseAction *)item {
    if (_viewFlags._isClosed) {
        return;
    }
    
    /// 隐藏当前显示着的button，显示需要展示的more button
    void (^closeCurrentDisplayButtonAnimationsBlock)(void) = ^ {
        for (HypotenuseAction *item in self.currentDisplayMoreItem.moreHypotenusItems) {
            item.orginRect = item.hypotenuseButton.frame;
        }
        for (UIView *view in self.subviews) {
            if ([view isKindOfClass:NSClassFromString(@"MenuBarHypotenuseButton")]) {
                [view setAlpha:0.0];
                [view setFrame:CGRectZero];
            }
        }
        
    };
    
    void (^openMoreButtonAnimationsBlockWithItem)(BOOL finished) = ^(BOOL finished) {
        [self openMoreButtonsWithItem:item];
    };
    
    // 将当前在显示的斜边按钮隐藏掉，展示moreButton需要展示的按钮
    [UIView animateWithDuration:0.3
                          delay:0.0
         usingSpringWithDamping:self.usingSpringWithDamping
          initialSpringVelocity:self.initialSpringVelocity
                        options:UIViewAnimationCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                     animations:closeCurrentDisplayButtonAnimationsBlock
                     completion:openMoreButtonAnimationsBlockWithItem];
}





#pragma mark *** More button animation ***

- (void)openMoreButtonsWithItem:(HypotenuseAction *)item {
    
    self.currentDisplayMoreItem = item;
    [UIView animateWithDuration:0.3
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:10
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         
                         UIWindow *menuWindow = [SuspensionControl windowForKey:self.key];
                         [menuWindow setAlpha:1.0];
                         [self setAlpha:1.0];
                         
                         for (HypotenuseAction *moreItem in item.moreHypotenusItems) {
                             if (moreItem.hypotenuseButton) {
                                 [moreItem.hypotenuseButton setAlpha:1.0];
                             }
                         }
                         
                         [self updateMenuBarButtonLayoutWithTriangleHypotenuse:_viewFlags._defaultTriangleHypotenuse hypotenuseItems:item.moreHypotenusItems];
                     }
                     completion:nil];
}



- (void)closeMoreButtonsWithItem:(HypotenuseAction *)item animationCompletion:(void (^)(void))completion {
    
    [UIView animateWithDuration:0.2
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:10
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         
                         for (HypotenuseAction *moreItem in item.moreHypotenusItems) {
                             moreItem.hypotenuseButton.frame = item.orginRect;
                             moreItem.hypotenuseButton.alpha = 0.03;
                         }
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             for (HypotenuseAction *moreItem in item.moreHypotenusItems) {
                                 [moreItem removeFromSuperview];
                             }
                             if (completion) {
                                 completion();
                             }
                         }
                     }];
    
}
#pragma mark *** Notify ***


- (void)orientationDidChange:(NSNotification *)note {
    if (self.shouldCloseWhenDeviceOrientationDidChange) {
        _viewFlags._isClosed = NO;
        [self _closeWithTriggerPanGesture:YES];
        [self.centerButton checkTargetPosition];
        return;
    }
    [self _updateMenuViewCenterWithIsOpened:_viewFlags._isOpened];
    
}
////////////////////////////////////////////////////////////////////////
#pragma mark - SuspensionViewDelegate
////////////////////////////////////////////////////////////////////////

- (void)suspensionViewClickedButton:(SuspensionView *)suspensionView {
    [self centerBarButtonClick:suspensionView];
    if (self.delegate && [self.delegate respondsToSelector:@selector(suspensionMenuView:clickedCenterButton:)]) {
        [self.delegate suspensionMenuView:self clickedCenterButton:suspensionView];
    }
}

- (void)suspensionView:(SuspensionView *)suspensionView locationChange:(UIPanGestureRecognizer *)pan {
    CGPoint panPoint = [pan locationInView:[UIApplication sharedApplication].delegate.window];
    self.center = panPoint;
    if (pan.state == UIGestureRecognizerStateEnded ||
        pan.state == UIGestureRecognizerStateCancelled) {
        [suspensionView moveToPreviousLeanPosition];
    }
    if (pan.state == UIGestureRecognizerStateBegan) {
        [self _closeWithTriggerPanGesture:YES];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(suspensionMenuView:centerButtonLocationChange:)]) {
        [self.delegate suspensionMenuView:self centerButtonLocationChange:pan];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private methods
////////////////////////////////////////////////////////////////////////


- (void)_updateMenuViewCenterWithIsOpened:(BOOL)isOpened {
    if (!isOpened) {
        return;
    }
    
    UIWindow *menuWindow = [SuspensionControl windowForKey:self.key];
    menuWindow.frame = [UIScreen mainScreen].bounds;
    NSLog(@"%@", NSStringFromCGRect(menuWindow.frame));
    menuWindow.rootViewController.view.frame =  menuWindow.bounds;
    UIWindow *centerWindow = [SuspensionControl windowForKey:self.centerButton.key];
    
    CGRect centerFrame =  centerWindow.frame;
    if (!self.shouldHiddenCenterButtonWhenOpen) {
        centerFrame.size = CGSizeMake(_viewFlags._centerWindowSize.width,
                                      _viewFlags._centerWindowSize.height);
    }
    CGFloat centerWindowX = (kSCREENT_WIDTH - _viewFlags._centerWindowSize.width)*0.5;
    // CGFloat centerWindowY = (kSCREENT_HEIGHT - _viewFlags._centerWindowSize.height)*0.5;
    
    // 通过设置centerWindow的frame确定最终menuWindow的frame，以x轴居中，y轴最大偏移量不能超出屏幕
    CGFloat centerWindowMinY = (_viewFlags._menuWindowSize.height - _viewFlags._centerWindowSize.height) * 0.5 + MAX(self.centerButton.leanEdgeInsets.top, 5.0);
    CGFloat centerWindowMaxY = kSCREENT_HEIGHT - (_viewFlags._menuWindowSize.height + _viewFlags._centerWindowSize.height) * 0.5 - MAX(self.centerButton.leanEdgeInsets.bottom, 5.0);
    CGFloat currentCenterWindowY = centerFrame.origin.y;
    CGFloat centerWindowY = MIN(centerWindowMaxY, MAX(currentCenterWindowY, centerWindowMinY));
    centerFrame.origin = CGPointMake(centerWindowX,
                                     centerWindowY);
    centerWindow.frame = centerFrame;
    
    
    CGPoint newCenter = [centerWindow convertPoint:self.centerButton.center toView:[UIApplication sharedApplication].delegate.window];
    self.center = newCenter;
    
    if (_backgroundImageView) {
        self.backgroundImageView.frame = self.bounds;
        if (_visualEffectView) {
            [self insertSubview:_visualEffectView aboveSubview:_backgroundImageView];
        }
    }
    if (_visualEffectView) {
        self.visualEffectView.frame = self.bounds;
        if (!_backgroundImageView) {
            [self insertSubview:_visualEffectView atIndex:0];
        }
    }
}

- (void)setCenter:(CGPoint)center {
    [super setCenter:center];
}

/// 设置按钮的 位置
- (void)_setButton:(UIView *)button origin:(CGPoint)origin {
    
    if (button) {
        [button setFrame:CGRectMake(origin.x,
                                    origin.y,
                                    _viewFlags._centerWindowSize.width,
                                    _viewFlags._centerWindowSize.height)];
    }
}

// 斜边的button frame计算来自:https://github.com/Kjuly/KYCircleMenu
- (void)updateMenuBarButtonLayoutWithTriangleHypotenuse:(CGFloat)triangleHypotenuse hypotenuseItems:(NSArray<HypotenuseAction *> *)hypotenuseItems {
    //
    //  Triangle Values for Buttons' Position
    //
    //      /|      a: triangleA = c * cos(x)
    //   c / | b    b: triangleB = c * sin(x)
    //    /)x|      c: triangleHypotenuse  三角斜边
    //   -----      x: degree    度数
    //     a
    //
    // menuView的半径
    CGFloat menuWindowRadius = _viewFlags._menuWindowSize.width * 0.5;
    // centerButton的半径
    CGFloat centerWindowRadius = _viewFlags._centerWindowSize.width * 0.5;
    if (! triangleHypotenuse) {
        // 距离中心
        triangleHypotenuse = _viewFlags._defaultTriangleHypotenuse;
    }
    
    NSMutableArray<NSValue *> *pointList = [NSMutableArray arrayWithCapacity:1];
    
    //
    //      o       o   o      o   o     o   o     o o o     o o o
    //     \|/       \|/        \|/       \|/       \|/       \|/
    //  1 --|--   2 --|--    3 --|--   4 --|--   5 --|--   6 --|--
    //     /|\       /|\        /|\       /|\       /|\       /|\
    //                           o       o   o     o   o     o o o
    //
    if (hypotenuseItems.count == 1) {
        
        CGPoint point = CGPointMake(menuWindowRadius - centerWindowRadius,
                                    menuWindowRadius - triangleHypotenuse - centerWindowRadius);
        NSValue *pointValue = [NSValue valueWithCGPoint:point];
        
        [pointList addObject:pointValue];
        
    }
    
    if (hypotenuseItems.count == 2) {
        
        CGFloat degree    = M_PI / 4.0f; // = 45 * M_PI / 180 角度
        CGFloat triangleB = triangleHypotenuse * sinf(degree);
        CGFloat negativeValue = menuWindowRadius - triangleB - centerWindowRadius;
        CGFloat positiveValue = menuWindowRadius + triangleB - centerWindowRadius;
        
        CGPoint point1 = CGPointMake(negativeValue,
                                     negativeValue);
        CGPoint point2 = CGPointMake(positiveValue,
                                     negativeValue);
        NSValue *pointValue1 = [NSValue valueWithCGPoint:point1];
        NSValue *pointValue2 = [NSValue valueWithCGPoint:point2];
        [pointList addObject:pointValue1];
        [pointList addObject:pointValue2];
        
    }
    
    if (hypotenuseItems.count == 3) {
        // = 360.0f / self.buttonCount * M_PI / 180.0f;
        // E.g: if |buttonCount_ = 6|, then |degree = 60.0f * M_PI / 180.0f|;
        // CGFloat degree = 2 * M_PI / self.buttonCount;
        //
        CGFloat degree    = M_PI / 3.0f; // = 60 * M_PI / 180
        CGFloat triangleA = triangleHypotenuse * cosf(degree);
        CGFloat triangleB = triangleHypotenuse * sinf(degree);
        
        CGPoint point1 = CGPointMake(menuWindowRadius - triangleB - centerWindowRadius,
                                     menuWindowRadius - triangleA - centerWindowRadius);
        CGPoint point2 = CGPointMake(menuWindowRadius + triangleB - centerWindowRadius,
                                     menuWindowRadius - triangleA - centerWindowRadius);
        CGPoint point3 = CGPointMake(menuWindowRadius - centerWindowRadius,
                                     menuWindowRadius + triangleHypotenuse - centerWindowRadius);
        
        NSValue *pointValue1 = [NSValue valueWithCGPoint:point1];
        NSValue *pointValue2 = [NSValue valueWithCGPoint:point2];
        NSValue *pointValue3 = [NSValue valueWithCGPoint:point3];
        [pointList addObject:pointValue1];
        [pointList addObject:pointValue2];
        [pointList addObject:pointValue3];
        
    }
    if (hypotenuseItems.count == 4) {
        CGFloat degree    = M_PI / 4.0f; // = 45 * M_PI / 180
        CGFloat triangleB = triangleHypotenuse * sinf(degree);
        CGFloat negativeValue = menuWindowRadius - triangleB - centerWindowRadius;
        CGFloat positiveValue = menuWindowRadius + triangleB - centerWindowRadius;
        
        CGPoint point1 = CGPointMake(negativeValue,
                                     negativeValue);
        CGPoint point2 = CGPointMake(positiveValue,
                                     negativeValue);
        CGPoint point3 = CGPointMake(negativeValue,
                                     positiveValue);
        CGPoint point4 = CGPointMake(positiveValue,
                                     positiveValue);
        
        NSValue *pointValue1 = [NSValue valueWithCGPoint:point1];
        NSValue *pointValue2 = [NSValue valueWithCGPoint:point2];
        NSValue *pointValue3 = [NSValue valueWithCGPoint:point3];
        NSValue *pointValue4 = [NSValue valueWithCGPoint:point4];
        [pointList addObject:pointValue1];
        [pointList addObject:pointValue2];
        [pointList addObject:pointValue3];
        [pointList addObject:pointValue4];
        
    }
    
    if (hypotenuseItems.count == 5) {
        CGFloat degree      = 2 * M_PI / _menuBarItems.count ; //= M_PI / 3.0;// = M_PI / 20.5; // = 72 * M_PI / 180
        CGFloat triangleA = triangleHypotenuse * cosf(degree);
        CGFloat triangleB = triangleHypotenuse * sinf(degree);
        
        CGPoint point1 = CGPointMake(menuWindowRadius - triangleB - centerWindowRadius,
                                     menuWindowRadius - triangleA - centerWindowRadius);
        CGPoint point2 = CGPointMake(menuWindowRadius - centerWindowRadius,
                                     menuWindowRadius - triangleHypotenuse - centerWindowRadius);
        CGPoint point3 = CGPointMake(menuWindowRadius + triangleB - centerWindowRadius,
                                     menuWindowRadius - triangleA - centerWindowRadius);
        
        degree    = M_PI / 5.0f;  // = 36 * M_PI / 180
        triangleA = triangleHypotenuse * cosf(degree);
        triangleB = triangleHypotenuse * sinf(degree);
        
        CGPoint point4 = CGPointMake(menuWindowRadius - triangleB - centerWindowRadius,
                                     menuWindowRadius + triangleA - centerWindowRadius);
        CGPoint point5 = CGPointMake(menuWindowRadius + triangleB - centerWindowRadius,
                                     menuWindowRadius + triangleA - centerWindowRadius);
        
        NSValue *pointValue1 = [NSValue valueWithCGPoint:point1];
        NSValue *pointValue2 = [NSValue valueWithCGPoint:point2];
        NSValue *pointValue3 = [NSValue valueWithCGPoint:point3];
        NSValue *pointValue4 = [NSValue valueWithCGPoint:point4];
        NSValue *pointValue5 = [NSValue valueWithCGPoint:point5];
        
        [pointList addObject:pointValue1];
        [pointList addObject:pointValue2];
        [pointList addObject:pointValue3];
        [pointList addObject:pointValue4];
        [pointList addObject:pointValue5];
    }
    
    if (hypotenuseItems.count == 6) {
        CGFloat degree    = M_PI / 3.0f; // = 60 * M_PI / 180
        CGFloat triangleA = triangleHypotenuse * cosf(degree); // 斜边的余弦值
        CGFloat triangleB = triangleHypotenuse * sinf(degree); // 斜边正弦值
        
        CGPoint point1 = CGPointMake(menuWindowRadius - triangleB - centerWindowRadius,
                                     menuWindowRadius - triangleA - centerWindowRadius);
        CGPoint point2 = CGPointMake(menuWindowRadius - centerWindowRadius,
                                     menuWindowRadius - triangleHypotenuse - centerWindowRadius);
        CGPoint point3 = CGPointMake(menuWindowRadius + triangleB - centerWindowRadius,
                                     menuWindowRadius - triangleA - centerWindowRadius);
        CGPoint point4 = CGPointMake(menuWindowRadius - triangleB - centerWindowRadius,
                                     menuWindowRadius + triangleA - centerWindowRadius);
        CGPoint point5 = CGPointMake(menuWindowRadius - centerWindowRadius,
                                     menuWindowRadius + triangleHypotenuse - centerWindowRadius);
        CGPoint point6 = CGPointMake(menuWindowRadius + triangleB - centerWindowRadius,
                                     menuWindowRadius + triangleA - centerWindowRadius);
        
        NSValue *pointValue1 = [NSValue valueWithCGPoint:point1];
        NSValue *pointValue2 = [NSValue valueWithCGPoint:point2];
        NSValue *pointValue3 = [NSValue valueWithCGPoint:point3];
        NSValue *pointValue4 = [NSValue valueWithCGPoint:point4];
        NSValue *pointValue5 = [NSValue valueWithCGPoint:point5];
        NSValue *pointValue6 = [NSValue valueWithCGPoint:point6];
        
        [pointList addObject:pointValue1];
        [pointList addObject:pointValue2];
        [pointList addObject:pointValue3];
        [pointList addObject:pointValue4];
        [pointList addObject:pointValue5];
        [pointList addObject:pointValue6];
    }
    
    if (hypotenuseItems.count == 8) {
        CGFloat degree      = 2 * M_PI / (_menuBarItems.count * 1.0f);   // 计算度数
        CGFloat triangleA = triangleHypotenuse * cosf(degree);         // 斜边的余弦值
        CGFloat triangleB = triangleHypotenuse * sinf(degree);         // 斜边正弦值
        
        CGPoint point1 = CGPointMake(menuWindowRadius - triangleB - centerWindowRadius,
                                     menuWindowRadius - triangleA - centerWindowRadius);
        CGPoint point2 = CGPointMake(menuWindowRadius - centerWindowRadius,
                                     menuWindowRadius - triangleHypotenuse - centerWindowRadius);
        CGPoint point3 = CGPointMake(menuWindowRadius + triangleB - centerWindowRadius,
                                     menuWindowRadius - triangleA - centerWindowRadius);
        CGPoint point4 = CGPointMake(menuWindowRadius - triangleB - centerWindowRadius,
                                     menuWindowRadius + triangleA - centerWindowRadius);
        CGPoint point5 = CGPointMake(menuWindowRadius - centerWindowRadius,
                                     menuWindowRadius + triangleHypotenuse - centerWindowRadius);
        CGPoint point6 = CGPointMake(menuWindowRadius + triangleB - centerWindowRadius,
                                     menuWindowRadius + triangleA - centerWindowRadius);
        
        degree    = M_PI / 2.0f;  // = 36 * M_PI / 180
        triangleA = triangleHypotenuse * cosf(degree);
        triangleB = triangleHypotenuse * sinf(degree);
        CGPoint point7 = CGPointMake(menuWindowRadius + triangleB - centerWindowRadius,
                                     menuWindowRadius + triangleA - centerWindowRadius);
        CGPoint point8 = CGPointMake(menuWindowRadius - triangleB - centerWindowRadius,
                                     menuWindowRadius + triangleA - centerWindowRadius);
        
        NSValue *pointValue1 = [NSValue valueWithCGPoint:point1];
        NSValue *pointValue2 = [NSValue valueWithCGPoint:point2];
        NSValue *pointValue3 = [NSValue valueWithCGPoint:point3];
        NSValue *pointValue4 = [NSValue valueWithCGPoint:point4];
        NSValue *pointValue5 = [NSValue valueWithCGPoint:point5];
        NSValue *pointValue6 = [NSValue valueWithCGPoint:point6];
        NSValue *pointValue7 = [NSValue valueWithCGPoint:point7];
        NSValue *pointValue8 = [NSValue valueWithCGPoint:point8];
        
        [pointList addObject:pointValue1];
        [pointList addObject:pointValue2];
        [pointList addObject:pointValue3];
        [pointList addObject:pointValue4];
        [pointList addObject:pointValue5];
        [pointList addObject:pointValue6];
        [pointList addObject:pointValue7];
        [pointList addObject:pointValue8];
    }
    
    [pointList enumerateObjectsUsingBlock:^(NSValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self _setButton:hypotenuseItems[idx].hypotenuseButton origin:[obj CGPointValue]];
    }];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Other
////////////////////////////////////////////////////////////////////////


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_menuBarItems.count) {
        [_menuBarItems makeObjectsPerformSelector:@selector(removeFromSuperview)];
        _menuBarItems = nil;
    }
    _openCompletion = nil;
    _closeCompletion = nil;
    _testPushViewControllerDictionary = nil;
    _currentDisplayMoreItem = nil;
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

- (UIViewController *)topViewController {
    UIViewController *resultVC;
    resultVC = [self _topViewController:[[UIApplication sharedApplication].delegate.window rootViewController]];
    while (resultVC.presentedViewController) {
        resultVC = [self _topViewController:resultVC.presentedViewController];
    }
    return resultVC;
}

- (UIViewController *)_topViewController:(UIViewController *)vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self _topViewController:[(UINavigationController *)vc topViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self _topViewController:[(UITabBarController *)vc selectedViewController]];
    } else {
        return vc;
    }
    return nil;
}

- (NSString *)key {
    return _isOnce ? [[SuspensionControl shareInstance] keyWithIdentifier:NSStringFromClass([self class])] : [super key];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.currentDisplayMoreItem.moreHypotenusItems.count) {
        [self closeMoreButtonsWithItem:self.currentDisplayMoreItem animationCompletion:^{
            if (self.stackDisplayedItems.count) {
                [self.stackDisplayedItems removeObject:self.currentDisplayMoreItem];
                // 将当前在显示的斜边按钮隐藏掉，展示moreButton需要展示的按钮
                if (self.stackDisplayedItems.count) {
                    [self openMoreButtonsWithItem:self.stackDisplayedItems.lastObject];
                } else {
                    _viewFlags._isOpened = NO;
                    [self _openWithNeedCurveEaseInOut:NO];
                    
                    _currentDisplayMoreItem = nil;
                }
                
            }
        }];
    }
    
    if (!self.currentDisplayMoreItem) {
        [self close];
    }
    
    [self.nextResponder touchesEnded:touches withEvent:event];
}



@end


@implementation SuspensionMenuWindow

////////////////////////////////////////////////////////////////////////
#pragma mark - initialize
////////////////////////////////////////////////////////////////////////

- (instancetype)initWithFrame:(CGRect)frame itemSize:(CGSize)itemSize {
    if (self = [super initWithFrame:frame itemSize:itemSize]) {
        [self setAlpha:1.0];
        self.isOnce = YES;
        self.shouldOpenWhenViewWillAppear = YES;
    }
    return self;
}


- (void)setItemSize:(CGSize)itemSize {
    [super setItemSize:itemSize];
    [self _moveToSuperview];
    
    if (!self.shouldOpenWhenViewWillAppear) {
        [self.centerButton checkTargetPosition];
    }
}


- (void)removeFromSuperview {
    self.menuBarClickBlock = nil;
    [SuspensionControl removeWindowForKey:self.key];
    [super removeFromSuperview];
}

+ (void)releaseAll {
    
    NSDictionary *temp = [[SuspensionControl windows] mutableCopy];
    [temp enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, UIWindow * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.suspensionMenuView && obj.suspensionView) {
            [SuspensionControl removeWindow:obj];
            [SuspensionControl removeWindowForKey:obj.suspensionView.key];
        }
    }];
    temp = nil;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private methods
////////////////////////////////////////////////////////////////////////


- (void)_moveToSuperview {
    
    CGRect menuWindowBounds = [UIScreen mainScreen].bounds;
    if (!_shouldOpenWhenViewWillAppear) {
        menuWindowBounds = CGRectZero;
    }
    
    UIWindow *suspensionWindow = [[UIWindow alloc] initWithFrame:menuWindowBounds];
#ifdef DEBUG
    suspensionWindow.windowLevel = CGFLOAT_MAX;
    //    suspensionWindow.windowLevel = CGFLOAT_MAX+10;
    // iOS9前自定义的window设置下面，不会被键盘遮罩，iOS10不行了
    //    NSArray<UIWindow *> *widnows = [UIApplication sharedApplication].windows;
#else
    suspensionWindow.windowLevel = UIWindowLevelAlert * 2;
#endif
    
    UIViewController *vc = [[SuspensionMenuController alloc] initWithMenuView:self];
    
    suspensionWindow.rootViewController = vc;
    [suspensionWindow.layer setMasksToBounds:YES];
    
    [SuspensionControl setWindow:suspensionWindow forKey:self.key];
    self.frame = CGRectMake((kSCREENT_WIDTH - self.frame.size.width) * 0.5,
                            (kSCREENT_HEIGHT - self.frame.size.height) * 0.5,
                            self.frame.size.width,
                            self.frame.size.height);
    self.clipsToBounds = YES;
    
    [vc.view addSubview:self];
    
    suspensionWindow.suspensionMenuView = self;
    
    suspensionWindow.hidden = NO;
    
}

@end

@interface HypotenuseAction ()

@property (nonatomic, strong) NSMutableArray<HypotenuseAction *> *moreHypotenusItems;

@end

@implementation HypotenuseAction

- (instancetype)initWithButtonType:(OSButtonType)buttonType {
    if (self = [self init]) {
        self.hypotenuseButton.buttonType = buttonType;
    }
    return self;
}

+ (instancetype)actionWithType:(OSButtonType)buttonType handler:(void (^)(HypotenuseAction * _Nonnull))handler {
    HypotenuseAction *action = [[HypotenuseAction alloc] initWithButtonType:buttonType];
    action.actionHandler = handler;
    return action;
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.hypotenuseButton = [MenuBarHypotenuseButton buttonWithType:OSButtonType3];
        [self.hypotenuseButton addTarget:self action:@selector(hypotenuseButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)hypotenuseButtonClick:(id)sender {
    if (self.actionHandler) {
        self.actionHandler(self);
    }
}

- (void)removeFromSuperview {
    [self.hypotenuseButton removeFromSuperview];
    
}

- (void)addMoreAction:(HypotenuseAction *)action {
    NSParameterAssert(action);
    if (!action) {
        return;
    }
    if (!_moreHypotenusItems) {
        _moreHypotenusItems = [@[] mutableCopy];
    }
    [_moreHypotenusItems addObject:action];
}


- (void)dealloc {
    [self removeFromSuperview];
    _moreHypotenusItems = nil;
    _hypotenuseButton = nil;
    _actionHandler = nil;
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

@end

@implementation MenuBarHypotenuseButton
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _setup];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self _setup];
    }
    return self;
}
- (void)_setup {
    //    [self.titleLabel setFont:[UIFont systemFontOfSize:12 weight:1.0]];
    //    self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    //    self.titleLabel.textAlignment = NSTextAlignmentCenter;
}
@end

@interface _MenuBarCenterButton : SuspensionWindow
@end
@implementation _MenuBarCenterButton
@end

@interface _MenuViewBackgroundImageView : UIImageView
@end
@implementation _MenuViewBackgroundImageView
@end

@implementation UIWindow (SuspensionWindow)

- (void)setSuspensionView:(SuspensionView *)suspensionView {
    objc_setAssociatedObject(self, @selector(suspensionView), suspensionView, OBJC_ASSOCIATION_ASSIGN);
}

- (SuspensionView *)suspensionView {
    return objc_getAssociatedObject(self, @selector(suspensionView));
}

- (void)setSuspensionMenuView:(SuspensionMenuView * _Nullable)suspensionMenuView {
    objc_setAssociatedObject(self, @selector(suspensionMenuView), suspensionMenuView, OBJC_ASSOCIATION_ASSIGN);
}

- (SuspensionMenuView *)suspensionMenuView {
    return objc_getAssociatedObject(self, @selector(suspensionMenuView));
}
@end


@implementation SuspensionMenuController

- (instancetype)initWithMenuView:(SuspensionMenuWindow *)menuView {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _menuView = menuView;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.1];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_menuView.shouldOpenWhenViewWillAppear) {
        [self.menuView performSelector:@selector(open)
                            withObject:nil
                            afterDelay:0.3];
    }
}


- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint touchPoint = [touches.anyObject locationInView:self.view];
    // 拿到在self.view上但同时在menuView上的点
    touchPoint = [self.menuView.layer convertPoint:touchPoint fromLayer:self.view.layer];
    if (![self.menuView.layer containsPoint:touchPoint]) {
        [self.menuView close];
    }
    [self.nextResponder touchesEnded:touches withEvent:event];
}


@end

#pragma mark *** SuspensionControl ***

@interface SuspensionControl ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, UIWindow *> *windows;

@end

@implementation SuspensionControl

@dynamic shareInstance;

+ (UIWindow *)windowForKey:(NSString *)key {
    return [[SuspensionControl shareInstance].windows objectForKey:key];
}

+ (void)setWindow:(UIWindow *)window forKey:(NSString *)key {
    [[SuspensionControl shareInstance].windows setObject:window forKey:key];
}


+ (void)removeWindowForKey:(NSString *)key {
    UIWindow *window = [[SuspensionControl shareInstance].windows objectForKey:key];
    window.hidden = YES;
    if (window.rootViewController.presentedViewController) {
        [window.rootViewController.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    }
    window.hidden = YES;
    window.rootViewController = nil;
    [[SuspensionControl shareInstance].windows removeObjectForKey:key];
}


+ (void)removeAllWindows {
    for (UIWindow *window in [SuspensionControl shareInstance].windows.allValues) {
        window.hidden = YES;
        window.rootViewController = nil;
    }
    [[SuspensionControl shareInstance].windows removeAllObjects];
    [[UIApplication sharedApplication].delegate.window makeKeyAndVisible];
}

+ (void)removeWindow:(UIWindow *)aWindow {
    
    if (!aWindow) {
        return;
    }
    NSDictionary *temp = [[SuspensionControl shareInstance].windows mutableCopy];
    [temp enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, UIWindow * _Nonnull obj, BOOL * _Nonnull stop) {
        if (aWindow == obj) {
            [SuspensionControl removeWindowForKey:key];
        }
        *stop = YES;
    }];
    temp = nil;
    
}

+ (NSDictionary *)windows {
    return [SuspensionControl shareInstance].windows;
}



////////////////////////////////////////////////////////////////////////
#pragma mark - setter \ getter
////////////////////////////////////////////////////////////////////////
- (NSMutableDictionary<NSString *, UIWindow *> *)windows {
    if (!_windows) {
        _windows = [NSMutableDictionary dictionary];
    }
    return _windows;
}


+ (instancetype)shareInstance {
    
    static SuspensionControl *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}


@end

@implementation NSObject (SuspensionKey)

- (void)setKey:(NSString *)key {
    objc_setAssociatedObject(self, @selector(key), key, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)key {
    NSString *key = objc_getAssociatedObject(self, @selector(key));
    if (!key.length) {
        self.key = (key = self.description);
    }
    return key;
}

- (NSString *)keyWithIdentifier:(NSString *)identifier {
    return [self.key stringByAppendingString:identifier];
}


@end


