//
//  SuspensionView.m
//  SuspensionView
//
//  Created by Ossey on 17/2/25.
//  Copyright © 2017年 Ossey All rights reserved.
//

#import "XYSuspensionMenu.h"
#import <objc/runtime.h>

#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic ignored "-Wnonnull"

#define kSCREENT_HEIGHT         [UIScreen mainScreen].bounds.size.height
#define kSCREENT_WIDTH          [UIScreen mainScreen].bounds.size.width
#define OS_MIN_SCREEN_SIZE      MIN(kSCREENT_WIDTH, kSCREENT_HEIGHT)
#define OS_MAX_MENUVIEW_SIZE    CGSizeMake(MIN(MAX(MAX(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)), 280.0), OS_MIN_SCREEN_SIZE), MIN(MAX(MAX(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)), 280.0), OS_MIN_SCREEN_SIZE))

#pragma mark *** MenuBarHypotenuseButton ***

@interface MenuBarHypotenuseButton : UIButton

@end


@interface HypotenuseAction ()
@property (nonatomic, strong) MenuBarHypotenuseButton *hypotenuseButton;
- (void)removeFromSuperview;
@end


@implementation UIApplication (SuspensionWindowExtension)

- (void)setXy_suspensionMenuWindow:(SuspensionMenuWindow *)suspensionMenuWindow {
    objc_setAssociatedObject(self, @selector(xy_suspensionMenuWindow), suspensionMenuWindow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (SuspensionMenuWindow *)xy_suspensionMenuWindow {
    return objc_getAssociatedObject(self, _cmd);
}

@end

@interface HypotenuseAction ()
#if ! __has_feature(objc_arc)
@property (nonatomic, assign, nullable) SuspensionMenuView *suspensionMenuView;
#else
@property (nonatomic, weak, nullable) SuspensionMenuView *suspensionMenuView;
#endif
@property (nullable, nonatomic, copy) void (^ actionHandler)(HypotenuseAction *action, SuspensionMenuView *menuView);
@end

#pragma mark *** SuspensionView ***

static NSString * const PreviousCenterXKey = @"previousCenterX";
static NSString * const PreviousCenterYKey = @"previousCenterY";

@interface SuspensionView ()

@property (nonatomic, assign) CGPoint previousCenter;
#if ! __has_feature(objc_arc)
@property (nonatomic, assign) UIPanGestureRecognizer *panGestureRecognizer;
#else
@property (nonatomic, weak) UIPanGestureRecognizer *panGestureRecognizer;
#endif
@property (nonatomic, assign) BOOL isMoving;
@property (nonatomic, strong) UIWindow *xy_window;
/// 当屏幕旋转时反转坐标
@property (nonatomic, assign) BOOL needReversePoint;

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

- (void)xy_removeWindow {
    UIWindow *window = self.xy_window;
    if (!window) {
        return;
    }
    window.hidden = YES;
    if (window.rootViewController.presentedViewController) {
        [window.rootViewController.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    }
    window.hidden = YES;
    window.rootViewController = nil;
    self.xy_window = nil;
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
    
    UIWindow *w = self.xy_window;
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
        // 计算速度向量的长度，当他小于200时，滑行会很短
        CGPoint velocity = [p velocityInView:[UIApplication sharedApplication].delegate.window];
        // 计算速度向量的长度
        CGFloat magnitude = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));
        CGFloat slideMult = magnitude / 200;
        // 基于速度和速度因素计算一个终点
        float slideFactor = 0.1 * slideMult;
        CGPoint finalPoint = CGPointMake(panViewCenter.x + (velocity.x * slideFactor),  panViewCenter.y + (velocity.y * slideFactor));
        CGPoint newTargetPoint = [self _checkTargetPosition:finalPoint];
        // 滑行到终点
        [self autoLeanToTargetPosition:newTargetPoint slideFactor:slideFactor*2];
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
    
    UIWindow *w = self.xy_window;
    if (w) {
        w.center = CGPointMake(point.x, point.y);
    } else {
        self.center = CGPointMake(point.x, point.y);
    }
    _isMoving = YES;
}

- (void)checkTargetPosition {
    
    if (self.shouldLeanToPreviousPositionWhenAppStart && !self.needReversePoint) {
        CGPoint newTargetPoint = [self _checkTargetPosition:self.previousCenter];
        [self autoLeanToTargetPosition:newTargetPoint];
    } else {
        CGPoint currentPoint = [self convertPoint:self.center toView:[UIApplication sharedApplication].delegate.window];
        CGPoint newTargetPoint = [self _checkTargetPosition:CGPointMake(currentPoint.y, currentPoint.x)];
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
    // 计算当前距离上下左右的间距
    CGFloat left = MAX(self.leanEdgeInsets.left, MIN(panPoint.x, screenWidth - touchWidth - self.leanEdgeInsets.right));
    CGFloat right = screenWidth - left;
    CGFloat top = MAX(self.leanEdgeInsets.top, MIN(panPoint.y, screenHeight - touchHeight - self.leanEdgeInsets.bottom));
    CGFloat bottom = screenHeight - top;
    
    // 获取最小的间距(最小的间距为目标移动的位置)
    CGFloat minSpace = 0;
    if (self.leanEdgeType == SuspensionViewLeanEdgeTypeHorizontal) {
        minSpace = MIN(left, right);
    }
    else if (self.leanEdgeType == SuspensionViewLeanEdgeTypeEachSide) {
        minSpace = MIN(MIN(MIN(top, left), bottom), right);
    }
    CGPoint newTargetPoint = CGPointZero;
    CGFloat targetY = 0;
    
    if (panPoint.y < self.leanEdgeInsets.top + touchHeight*0.5 + self.leanEdgeInsets.top) {
        targetY = self.leanEdgeInsets.top + touchHeight*0.5 + self.leanEdgeInsets.top;
    }
    else if (panPoint.y > (screenHeight - touchHeight*0.5 - self.leanEdgeInsets.bottom)) {
        targetY = screenHeight - touchHeight*0.5 - self.leanEdgeInsets.bottom;
    }
    else {
        targetY = panPoint.y;
    }
    
    // 计算需要移动到中心点位置
    if (minSpace == left) {
        newTargetPoint = CGPointMake(touchWidth*0.5 + self.leanEdgeInsets.left, targetY);
    }
    else if (minSpace == right) {
        newTargetPoint = CGPointMake(screenWidth - touchWidth*0.5 - self.leanEdgeInsets.right, targetY);
    }
    else if (minSpace == top) {
        newTargetPoint = CGPointMake(left, touchHeight*0.5 + self.leanEdgeInsets.top);
    }
    else if (minSpace == bottom) {
        newTargetPoint = CGPointMake(left, screenHeight - touchHeight*0.5 - self.leanEdgeInsets.bottom);
    }
    // 记录当前的center
    self.previousCenter = newTargetPoint;
    
    return newTargetPoint;
}


- (void)moveToPreviousLeanPosition {
    
    [self autoLeanToTargetPosition:self.previousCenter];
}

/// 移动移动到屏幕中心位置
- (void)moveToDisplayCenter {
    
    [self autoLeanToTargetPosition:[UIApplication sharedApplication].delegate.window.center];
}


/// 自动移动到边缘，此方法在手指松开后会自动移动到目标位置
- (void)autoLeanToTargetPosition:(CGPoint)point {
    [self autoLeanToTargetPosition:point slideFactor:0.0];
}


/// 自动移动到边缘，此方法在手指松开后会自动移动到目标位置
- (void)autoLeanToTargetPosition:(CGPoint)point slideFactor:(CGFloat)slideFactor {
    point = [self _checkTargetPosition:point];
    if (self.delegate && [self.delegate respondsToSelector:@selector(suspensionView:willAutoLeanToTargetPosition:)]) {
        [self.delegate suspensionView:self willAutoLeanToTargetPosition:point];
    }
    [UIView animateWithDuration:0.3
                          delay:0.05
         usingSpringWithDamping:self.usingSpringWithDamping
          initialSpringVelocity:self.initialSpringVelocity
                        options:UIViewAnimationOptionCurveEaseIn |
     UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         UIWindow *w = self.xy_window;
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
    [self didChangeInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

- (void)didChangeInterfaceOrientation:(UIInterfaceOrientation)orientation {
    
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

- (void)setPreviousCenter:(CGPoint)previousCenter {
    _previousCenter = previousCenter;
    [[NSUserDefaults standardUserDefaults] setDouble:previousCenter.x forKey:PreviousCenterXKey];
    [[NSUserDefaults standardUserDefaults] setDouble:previousCenter.y forKey:PreviousCenterYKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

#pragma mark *** UIResponder (SuspensionView) ***

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

#if ! __has_feature(objc_arc)
@property (nonatomic, assign) SuspensionMenuWindow *menuView;
#else
@property (nonatomic, weak) SuspensionMenuWindow *menuView;
#endif

@end

#pragma mark *** SuspensionWindow ***

@implementation SuspensionWindow

////////////////////////////////////////////////////////////////////////
#pragma mark - Public methods
////////////////////////////////////////////////////////////////////////


+ (instancetype)showWithFrame:(CGRect)frame {
    
    SuspensionWindow *s = [[self alloc] initWithFrame:frame];
    s.leanEdgeType = SuspensionViewLeanEdgeTypeEachSide;
    [s __moveToSuperview];
    
    return s;
}

- (void)removeFromSuperview {
    self.clickCallBack = nil;
    self.leanFinishCallBack = nil;
    [self xy_removeWindow];
    [super removeFromSuperview];
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Private methods
////////////////////////////////////////////////////////////////////////


- (void)__moveToSuperview {
    
    UIWindow *suspensionWindow = [[UIWindow alloc] initWithFrame:self.frame];
    
    //#ifdef DEBUG
    suspensionWindow.windowLevel = CGFLOAT_MAX+10;
    //#else
    //    suspensionWindow.windowLevel = UIWindowLevelAlert * 3;
    //#endif
    
    UIViewController *vc = [UIViewController new];
    suspensionWindow.rootViewController = vc;
    
    [suspensionWindow.layer setMasksToBounds:YES];
    
    self.xy_window = suspensionWindow;
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

#if ! __has_feature(objc_arc)
@property (nonatomic, assign) UIImageView *backgroundImageView;
@property (nonatomic, assign) UIVisualEffectView *visualEffectView;
@property (nonatomic, assign) HypotenuseAction *currentResponderItem;
#else
@property (nonatomic, weak) UIImageView *backgroundImageView;
@property (nonatomic, weak) UIVisualEffectView *visualEffectView;
/// 当前处理事件的item
@property (nonatomic, weak) HypotenuseAction *currentResponderItem;
#endif
@property (nonatomic, strong) UIWindow *xy_window;
@property (nonatomic, strong) SuspensionView *centerButton;
@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, strong) HypotenuseAction *currentDisplayMoreItem;
/// 保证currentDisplayMoreItems在栈顶，menuBarItems在栈底
@property (nonatomic, strong) NSMutableArray<HypotenuseAction *> *stackDisplayedItems;
/// 存储的为调用showViewController时的HypotenuseAction和跳转的viewController，保证第二次点击时pop并从此字典中移除
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableArray<NSString *> *> *showViewControllerDictionary;
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
        _itemSize = itemSize;
        [self commonInit];
    }
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    NSAssert(NO, @"use - initWithFrame:itemSize:");
    @throw nil;
    
}

- (void)commonInit {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [self _suspensionMenuViewSetup];
    [self setItemSize:_itemSize];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}

- (void)xy_removeWindow {
    UIWindow *window = self.xy_window;
    if (!window) {
        return;
    }
    window.hidden = YES;
    if (window.rootViewController.presentedViewController) {
        [window.rootViewController.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    }
    window.hidden = YES;
    window.rootViewController = nil;
    self.xy_window = nil;
}


- (void)setMenuBarItems:(NSArray<HypotenuseAction *> *)menuBarItems itemSize:(CGSize)itemSize {
    self.menuBarItems = [menuBarItems mutableCopy];
    [self setItemSize:itemSize];
}

- (void)addAction:(HypotenuseAction *)action {
    if (!action) {
        return;
    }
    action.suspensionMenuView = self;
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
        [item.hypotenuseButton removeTarget:self action:@selector(moreBarButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [item.hypotenuseButton addTarget:self action:@selector(moreBarButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [item.hypotenuseButton setAlpha:0.0];
        item.suspensionMenuView = self;
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
        [item.hypotenuseButton removeTarget:self action:@selector(menuBarButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [item.hypotenuseButton addTarget:self action:@selector(menuBarButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [item.hypotenuseButton setAlpha:0.0];
        item.suspensionMenuView = self;
        [self addSubview:item.hypotenuseButton];
        [item.hypotenuseButton setFrame:_viewFlags._memuBarButtonOriginFrame];
        idx++;
    }
}

/// 显示viewController，对push或present进行处理，并处理viewController重复show的问题，显示完成后关闭mennWindow
- (void)showViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSParameterAssert(viewController);
    viewController.hidesBottomBarWhenPushed = YES;
    UIViewController *topVc = [self topViewController];
    NSNumber *vcKey = @([_currentResponderItem.hypotenuseButton tag]);
    NSMutableArray *currentClickVcAddress = [self.showViewControllerDictionary objectForKey:vcKey];
    if (!currentClickVcAddress) {
        currentClickVcAddress = [NSMutableArray array];
        [self.showViewControllerDictionary setObject:currentClickVcAddress forKey:vcKey];
    }
    //////////////////// 防止控制器重复push或present的处理 ////////////////////
    // 判断当前点击的btn，是否已经保存了控制器的内存地址，如果保存了，就移除，并return
    if (_currentResponderItem && viewController) {
        // 取出当前点击按钮保存的控制器的内存地址
        
        NSMutableArray *vcs = [topVc.navigationController.viewControllers mutableCopy];
        NSUInteger foundArressIdx = [currentClickVcAddress indexOfObjectWithOptions:NSEnumerationReverse passingTest:^BOOL(NSString *  _Nonnull address, NSUInteger idx, BOOL * _Nonnull stop) {
            return [[NSString stringWithFormat:@"%p", topVc] isEqualToString:address];
        }];
        if (currentClickVcAddress && foundArressIdx != NSNotFound) {
            if (topVc.navigationController.viewControllers.count > 1 && [topVc.navigationController.viewControllers lastObject] == topVc) {
                NSUInteger founVcIndex = [vcs indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    return topVc == obj;
                }];
                // 当topViewController 就是当前按钮点击后保存的控制器，那么就返回到topViewController的上一级
                if (founVcIndex > 0) {
                    UIViewController *targetVc = vcs[founVcIndex - 1];
                    [topVc.navigationController popToViewController:targetVc animated:animated];
                } else {
                    [topVc.navigationController popToRootViewControllerAnimated:animated];
                }
            } else {
                [topVc dismissViewControllerAnimated:animated completion:NULL];
            }
            [currentClickVcAddress removeObjectAtIndex:foundArressIdx];
            [self close];
            return;
        }
        else {
            if (topVc.navigationController && vcs.count) {
                for (UIViewController *vc in vcs) {
                    NSUInteger founVcIndex = [currentClickVcAddress indexOfObjectPassingTest:^BOOL(NSString *  _Nonnull address, NSUInteger idx, BOOL * _Nonnull stop) {
                        return [[NSString stringWithFormat:@"%p", vc] isEqualToString:address];
                    }];
                    
                    // 当topViewController 不是当前按钮点击后保存的控制器，那么就返回到topViewController
                    if (founVcIndex != NSNotFound) {
                        UIViewController *targetVc = vcs[founVcIndex];
                        [topVc.navigationController popToViewController:targetVc animated:animated];
                        [currentClickVcAddress removeObjectAtIndex:founVcIndex];
                        [self close];
                        return;
                    }
                }
            }
            else if (topVc.presentingViewController) {
                // 如果存在modal，就dismiss，但是这里不return，后续还要将viewController进行present(注意此时的topVc已经被dismiss释放，后面的present要使用它的上一级控制器，也就是topVc.presentingViewController才可以)
                [topVc dismissViewControllerAnimated:animated completion:NULL];
                [currentClickVcAddress removeObject:[NSString stringWithFormat:@"%p", topVc.presentingViewController]];
                topVc = topVc.presentingViewController;
            }
        }
        
    }
    
    
    //////////////////// 对控制器需要push或present的处理 ////////////////////
    void(^pushAnimationsCompetionsBlockForViewController)(BOOL isFinished) = ^(BOOL isFinished) {
        if (topVc.navigationController == 0x0 || [viewController isKindOfClass:[UINavigationController class]]) {
            // 当执行完dismissViewControllerAnimated后再执行showDetailViewController:报错如下:
            //Error: hose view is not in the window hierarchy,
            // 使用presentViewController:解决
            /*
             if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1 && animated) {
             [topVc showDetailViewController:viewController sender:topVc];
             }
             else {
             [topVc presentViewController:viewController animated:animated completion:NULL];
             }
             */
            [topVc presentViewController:viewController animated:animated completion:NULL];
        }
        else {
            if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1 && animated) {
                [topVc.navigationController showViewController:viewController sender:topVc];
            } else {
                [topVc.navigationController pushViewController:viewController animated:animated];
            }
        }
        // 存
        if (vcKey) {
            [currentClickVcAddress addObject:[NSString stringWithFormat:@"%p", viewController]];
            [self.showViewControllerDictionary setObject:currentClickVcAddress forKey:vcKey];
        }
    };
    
    
    //////////////////// push或present之前的布局更新 ////////////////////
    void (^pushAnimationsBlock)(void) = ^ {
        [self updateMenuBarButtonLayoutWithTriangleHypotenuse:_viewFlags._maxTriangleHypotenuse hypotenuseItems:self.menuBarItems];
    };
    
    // 执行close并显示viewController
    [self _closeWithTriggerPanGesture:NO animationBlock:pushAnimationsBlock closeCompletion:pushAnimationsCompetionsBlockForViewController];
    
}

- (void)_openWithNeedCurveEaseInOut:(BOOL)isCurveEaseInOut {
    [self _openWithNeedCurveEaseInOut:isCurveEaseInOut competion:NULL];
}

- (void)_openWithNeedCurveEaseInOut:(BOOL)isCurveEaseInOut competion:(void (^ _Nullable)(BOOL finished))openCompetion {
    if (_viewFlags._isOpened) return;
    self.centerButton.usingSpringWithDamping = 0.8;
    self.centerButton.initialSpringVelocity = 20;
    if (_viewFlags._isFiristOpened) {
        [self updateMenuBarButtonLayoutWithTriangleHypotenuse:_viewFlags._maxTriangleHypotenuse hypotenuseItems:self.menuBarItems];
    }
    
    if (_shouldLeanToScreenCenterWhenOpened) {
        [self.centerButton moveToDisplayCenter];
    }
    
    [self centerButton];
    [self _updateMenuViewCenterWithIsOpened:YES];
    
    if (self.shouldHiddenCenterButtonWhenOpen) {
        UIWindow *centerWindow = self.centerButton.xy_window;
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
                             if (openCompetion) {
                                 openCompetion(finished);
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
        UIWindow *menuWindow = self.xy_window;
        [menuWindow setAlpha:1.0];
        [self setAlpha:1.0];
        
        for (UIView *view in self.subviews) {
            if ([view isKindOfClass:[MenuBarHypotenuseButton class]]) {
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
    [self openWithCompetion:NULL];
}

- (void)openWithCompetion:(void (^)(BOOL finished))competion {
    [self _openWithNeedCurveEaseInOut:YES competion:competion];
    
}

- (void)close {
    [self _closeWithTriggerPanGesture:NO completion:NULL];
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

- (void)_closeWithTriggerPanGesture:(BOOL)isTriggerPanGesture animationBlock:(void (^)(void))animationBlock closeCompletion:(void (^)(BOOL finished))closeCompletion {
    if (_viewFlags._isClosed)
        return;
    
    self.centerButton.usingSpringWithDamping = 0.5;
    self.centerButton.initialSpringVelocity = 10;
    
    if (self.shouldHiddenCenterButtonWhenOpen) {
        // 显示centerWindow
        UIWindow *centerWindow = self.centerButton.xy_window;
        CGRect centerFrame =  centerWindow.frame;
        centerFrame.size = _viewFlags._centerWindowSize;
        centerWindow.frame = centerFrame;
        centerWindow.alpha = 1.0;
    }
    
    UIWindow *menuWindow = self.xy_window;
    
    void (^closeAnimationsBlockWithIsTriggerPanGesture)(void) = ^ {
        [self setAlpha:0.0];
        [menuWindow setAlpha:0.0];
        
        // 隐藏menuWindow，并让MenuBarHypotenuseButton全部恢复到原始位置
        for (UIView *view in self.subviews) {
            if ([view isKindOfClass:[MenuBarHypotenuseButton class]]) {
                [view setFrame:_viewFlags._memuBarButtonOriginFrame];
                [view setAlpha:0.0];
            }
        }
        
        if (!isTriggerPanGesture) {
            [self.centerButton moveToPreviousLeanPosition];
        }
        if (animationBlock) {
            animationBlock();
        }
    };
    
    void (^closeCompletionBlock)(BOOL finished) = ^(BOOL finished) {
        
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction animations:^{
            // 让其frame为zero，为了防止其隐藏后所在的位置无法响应事件
            CGRect menuFrame =  menuWindow.frame;
            menuFrame.size = CGSizeZero;
            menuWindow.frame = menuFrame;
        } completion:^(BOOL finished) {
            if (closeCompletion) {
                closeCompletion(finished);
            }
            _viewFlags._isClosed = YES;
            _viewFlags._isOpened  = NO;
            [self _closeCompetion];
        }];
    };
    
    [UIView animateWithDuration:0.3
                          delay:0.0
         usingSpringWithDamping:self.usingSpringWithDamping
          initialSpringVelocity:self.initialSpringVelocity
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                     animations:closeAnimationsBlockWithIsTriggerPanGesture
                     completion:closeCompletionBlock];
}

/// 执行close，并根据当前是否触发了拖动手势，确定是否在让SuapensionWindow执行移动边缘的操作，防止移除时乱窜
- (void)_closeWithTriggerPanGesture:(BOOL)isTriggerPanGesture completion:(void (^)(BOOL finished))closeCompletion {
    [self _closeWithTriggerPanGesture:isTriggerPanGesture animationBlock:NULL closeCompletion:closeCompletion];
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
        if ([view isKindOfClass:[MenuBarHypotenuseButton class]]) {
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
        
        SuspensionView *centerButton = (SuspensionWindow *)[NSClassFromString(@"_MenuBarCenterButton") showWithFrame:centerRec];
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

- (NSMutableDictionary<NSNumber *, NSMutableArray<NSString *> *> *)showViewControllerDictionary {
    if (!_showViewControllerDictionary) {
        _showViewControllerDictionary = [NSMutableDictionary dictionary];
    }
    return _showViewControllerDictionary;
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
    _currentResponderItem = item;
    if (item.moreHypotenusItems.count) {
        [self moreButtonClickWithHypotenuseItem:item];
        return;
    }
    else {
        if (item.actionHandler) {
            item.actionHandler(item, self);
        }
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
    _currentResponderItem = item;
    
    if (item.moreHypotenusItems.count) {
        [self moreButtonClickWithHypotenuseItem:item];
        return;
    }
    else {
        if (item.actionHandler) {
            item.actionHandler(item, self);
        }
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
            if ([view isKindOfClass:[MenuBarHypotenuseButton class]]) {
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
                         
                         UIWindow *menuWindow = self.xy_window;
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
        [self _closeWithTriggerPanGesture:YES completion:NULL];
        self.centerButton.needReversePoint = YES;
        [self.centerButton checkTargetPosition];
        self.centerButton.needReversePoint = NO;
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
        [self _closeWithTriggerPanGesture:YES completion:NULL];
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
    
    UIWindow *menuWindow = self.xy_window;
    menuWindow.frame = [UIScreen mainScreen].bounds;
    NSLog(@"%@", NSStringFromCGRect(menuWindow.frame));
    menuWindow.rootViewController.view.frame =  menuWindow.bounds;
    UIWindow *centerWindow = self.centerButton.xy_window;
    
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
    _showViewControllerDictionary = nil;
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

+ (instancetype)menuWindowWithFrame:(CGRect)frame itemSize:(CGSize)itemSize {
    SuspensionMenuWindow *sw = [UIApplication sharedApplication].xy_suspensionMenuWindow;
    if (!sw) {
        sw = [[SuspensionMenuWindow alloc] initWithFrame:frame itemSize:itemSize];
    }
    else {
        [sw close];
        [sw commonInit];
    }
    return sw;
}

- (instancetype)initWithFrame:(CGRect)frame itemSize:(CGSize)itemSize {
    if (self = [super initWithFrame:frame itemSize:itemSize]) {
        [self setAlpha:1.0];
        self.shouldOpenWhenViewWillAppear = YES;
    }
    return self;
}

- (void)setItemSize:(CGSize)itemSize {
    [super setItemSize:itemSize];
    [self __moveToSuperview];
    
    if (!self.shouldOpenWhenViewWillAppear) {
        [self.centerButton checkTargetPosition];
    }
}


- (void)removeFromSuperview {
    self.menuBarClickBlock = nil;
    [self xy_removeWindow];
    [super removeFromSuperview];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private methods
////////////////////////////////////////////////////////////////////////


- (void)__moveToSuperview {
    
    CGRect menuWindowBounds = [UIScreen mainScreen].bounds;
    if (!_shouldOpenWhenViewWillAppear) {
        menuWindowBounds = CGRectZero;
    }
    
    UIWindow *suspensionWindow = [[UIWindow alloc] initWithFrame:menuWindowBounds];
    //#ifdef DEBUG
    suspensionWindow.windowLevel = CGFLOAT_MAX;
    //    suspensionWindow.windowLevel = CGFLOAT_MAX+10;
    // iOS9前自定义的window设置下面，不会被键盘遮罩，iOS10不行了
    //    NSArray<UIWindow *> *widnows = [UIApplication sharedApplication].windows;
    //#else
    //    suspensionWindow.windowLevel = UIWindowLevelAlert * 2;
    //#endif
    
    UIViewController *vc = [[SuspensionMenuController alloc] initWithMenuView:self];
    
    suspensionWindow.rootViewController = vc;
    [suspensionWindow.layer setMasksToBounds:YES];
    
    self.xy_window = suspensionWindow;
    self.frame = CGRectMake((kSCREENT_WIDTH - self.frame.size.width) * 0.5,
                            (kSCREENT_HEIGHT - self.frame.size.height) * 0.5,
                            self.frame.size.width,
                            self.frame.size.height);
    self.clipsToBounds = YES;
    
    [vc.view addSubview:self];
    
    suspensionWindow.suspensionMenuView = self;
    
    suspensionWindow.hidden = NO;
    
}

- (void)showWithCompetion:(void (^)(void))competion {
    [super showWithCompetion:competion];
    [UIApplication sharedApplication].xy_suspensionMenuWindow = self;
}


@end

@interface HypotenuseAction ()

@property (nonatomic, strong) NSMutableArray<HypotenuseAction *> *moreHypotenusItems;
- (instancetype)initWithButtonType:(UIButtonType)buttonType;

@end

@implementation HypotenuseAction

- (instancetype)initWithButtonType:(UIButtonType)buttonType {
    if (self = [self init]) {
        self.hypotenuseButton = [MenuBarHypotenuseButton buttonWithType:buttonType];
        self.hypotenuseButton.layer.cornerRadius = 5.0;
        self.hypotenuseButton.layer.masksToBounds = YES;
    }
    return self;
}

+ (instancetype)actionWithType:(UIButtonType)buttonType handler:(void (^ __nullable)(HypotenuseAction *action, SuspensionMenuView *menuView))handler {
    HypotenuseAction *action = [[HypotenuseAction alloc] initWithButtonType:buttonType];
    action.actionHandler = handler;
    return action;
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
    self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor = 0.6;
    self.titleLabel.numberOfLines = 2;
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
        [self.menuView centerBarButtonClick:nil];
    }
    [self.nextResponder touchesEnded:touches withEvent:event];
}

@end


