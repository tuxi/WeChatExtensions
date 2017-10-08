//
//  SuspensionView.h
//  SuspensionView
//
//  Created by Ossey on 17/2/25.
//  Copyright © 2017年 Ossey All rights reserved.
//


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SuspensionView, SuspensionMenuView, MenuBarHypotenuseButton, HypotenuseAction;

typedef NS_ENUM(NSInteger, OSButtonType) {
    OSButtonTypeDefault,
    OSButtonType1,
    OSButtonType2,
    OSButtonType3,
    OSButtonType4
};

#pragma mark *** Protocol ***

@protocol SuspensionViewDelegate <NSObject>

@optional
- (void)suspensionViewClickedButton:(SuspensionView *)suspensionView;
- (void)suspensionView:(SuspensionView *)suspensionView locationChange:(UIPanGestureRecognizer *)pan;
- (CGPoint)leanToNewTragetPosionForSuspensionView:(SuspensionView *)suspensionView;
- (void)suspensionView:(SuspensionView *)suspensionView didAutoLeanToTargetPosition:(CGPoint)position;
- (void)suspensionView:(SuspensionView *)suspensionView willAutoLeanToTargetPosition:(CGPoint)position;

@end

@protocol SuspensionMenuViewDelegate <NSObject>

@optional
- (void)suspensionMenuView:(SuspensionMenuView *)suspensionMenuView clickedHypotenuseButtonAtIndex:(NSInteger)buttonIndex;
- (void)suspensionMenuView:(SuspensionMenuView *)suspensionMenuView clickedMoreButtonAtIndex:(NSInteger)buttonIndex fromHypotenuseItem:(HypotenuseAction *)hypotenuseItem;
- (void)suspensionMenuView:(SuspensionMenuView *)suspensionMenuView clickedCenterButton:(SuspensionView *)centerButton;
- (void)suspensionMenuViewDidOpened:(SuspensionMenuView *)suspensionMenuView;
- (void)suspensionMenuViewDidClose:(SuspensionMenuView *)suspensionMenuView;
- (void)suspensionMenuView:(SuspensionMenuView *)suspensionMenuView centerButtonLocationChange:(UIPanGestureRecognizer *)pan;


@end

#pragma mark *** OSCustomButton ***

@interface OSCustomButton : UIControl

@property (nonatomic, assign) OSButtonType buttonType;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, strong) UIColor *contentColor;
@property (nonatomic, strong) UIColor *foregroundColor;
@property (nonatomic, strong) UIColor *borderAnimateColor;
@property (nonatomic, strong) UIColor *contentAnimateColor;
@property (nonatomic, strong) UIColor *foregroundAnimateColor;
@property (nonatomic, assign) BOOL restoreSelectedState;
@property (nonatomic, assign) BOOL fadeInOutOnDisplay;
@property (nonatomic, readonly, strong) UILabel *titleLabel;
@property (nonatomic, readonly, strong) UILabel *detailLabel;
@property (nonatomic, readonly, strong) UIImageView *imageView;
@property (nonatomic, assign) UIEdgeInsets contentEdgeInsets;

- (instancetype)initWithFrame:(CGRect)frame;
+ (instancetype)buttonWithType:(OSButtonType)buttonType;
- (void)setTitle:(NSString *)title forState:(UIControlState)state;
- (void)setSubtitle:(NSString *)subtitle forState:(UIControlState)state;
- (void)setImage:(UIImage *)image forState:(UIControlState)state;
- (void)setTitleColor:(nullable UIColor *)color forState:(UIControlState)state;

@end

typedef NS_ENUM(NSUInteger, SuspensionViewLeanEdgeType) {
    SuspensionViewLeanEdgeTypeHorizontal = 1,
    SuspensionViewLeanEdgeTypeEachSide
};

#pragma mark *** SuspensionView ***

@interface SuspensionView : OSCustomButton

@property (nonatomic, assign, nullable) id<SuspensionViewDelegate> delegate;

@property (nonatomic, assign) BOOL isOnce;

@property (nonatomic, assign) SuspensionViewLeanEdgeType leanEdgeType;
@property (nonatomic, assign) UIEdgeInsets leanEdgeInsets;
@property (nonatomic, assign) BOOL invalidHidden;
@property (nonatomic, assign, readonly) BOOL isMoving;
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, assign) CGFloat usingSpringWithDamping;
@property (nonatomic, assign) CGFloat initialSpringVelocity;
@property (nonatomic, copy, nullable) void (^locationChange)(CGPoint currentPoint);
@property (nonatomic, copy, nullable) void (^ leanFinishCallBack)(CGPoint centerPoint);
@property (nonatomic, assign, getter=isAutoLeanEdge) BOOL autoLeanEdge;
@property (nonatomic, copy, nullable) void (^clickCallBack)(void);
@property (nonatomic, assign) BOOL shouldLeanToPreviousPositionWhenAppStart;

- (void)moveToScreentCenter;
- (void)moveToPreviousLeanPosition;
- (void)checkTargetPosition;

@end

#pragma mark *** UIResponder (SuspensionView) ***

@interface UIResponder (SuspensionView)

- (SuspensionView *)showSuspensionViewWithFrame:(CGRect)frame;
- (void)dismissSuspensionView:(void (^)(void))block;
- (void)setHiddenSuspension:(BOOL)flag;
- (BOOL)isHiddenSuspension;
- (void)setSuspensionTitle:(NSString *)title forState:(UIControlState)state;
- (void)setSuspensionImage:(UIImage *)image forState:(UIControlState)state;
- (void)setSuspensionImageWithImageNamed:(NSString *)name forState:(UIControlState)state;
- (void)setSuspensionBackgroundColor:(UIColor *)color cornerRadius:(CGFloat)cornerRadius;
@end

#pragma mark *** SuspensionWindow ***

@interface SuspensionWindow : SuspensionView

+ (instancetype)showOnce:(BOOL)isOnce frame:(CGRect)frame;
- (void)removeFromSuperview;
+ (void)releaseAll;

@end

#pragma mark *** SuspensionMenuView ***

@interface SuspensionMenuView : UIView

@property (nonatomic, assign) id<SuspensionMenuViewDelegate> delegate;

@property (nonatomic, assign) BOOL isOnce;
@property (nonatomic, copy) void (^ _Nullable menuBarClickBlock)(NSInteger index);
@property (nonatomic, copy) void (^ _Nullable moreButtonClickBlock)(NSInteger index);
@property (nonatomic, assign) BOOL shouldLeanToScreenCenterWhenOpened;
@property (nonatomic, strong, readonly) NSArray<HypotenuseAction *> *menuBarItems;
@property (nonatomic, strong, readonly) SuspensionView *centerButton;
@property (nonatomic, strong, readonly) UIImageView *backgroundImageView;
@property (nonatomic, assign) CGFloat usingSpringWithDamping;
@property (nonatomic, assign) CGFloat initialSpringVelocity;
@property (nonatomic, assign) BOOL shouldHiddenCenterButtonWhenOpen;
@property (nonatomic, assign) BOOL shouldCloseWhenDeviceOrientationDidChange;

- (instancetype)initWithFrame:(CGRect)frame itemSize:(CGSize)itemSize NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

- (void)showWithCompetion:(void (^ _Nullable)(void))competion;

- (void)addAction:(HypotenuseAction *)action;

- (void)testPushViewController:(UIViewController *)viewController
                      animated:(BOOL)animated;
- (void)close;
- (void)open;
- (UIViewController *)topViewController;
@end

#pragma mark *** SuspensionMenuWindow ***

@interface SuspensionMenuWindow : SuspensionMenuView

@property (nonatomic, assign) BOOL shouldOpenWhenViewWillAppear;

- (void)removeFromSuperview;
+ (void)releaseAll;

@end

#pragma mark *** HypotenuseAction ***

@interface HypotenuseAction : NSObject

@property (nonatomic, strong, readonly) OSCustomButton *hypotenuseButton;
@property (nonatomic, strong, readonly) NSArray<HypotenuseAction *> *moreHypotenusItems;
@property (nonatomic, assign) CGRect orginRect;
@property (nullable, nonatomic, copy) void (^ actionHandler)(HypotenuseAction *action);
- (instancetype)initWithButtonType:(OSButtonType)buttonType;
+ (instancetype)actionWithType:(OSButtonType)buttonType
                       handler:(void (^__nullable)(HypotenuseAction *action))handler;
- (void)addMoreAction:(HypotenuseAction *)action;

@end

#pragma mark *** UIWindow (SuspensionWindow) ***

@interface UIWindow (SuspensionWindow)

@property (nonatomic, strong, nullable) SuspensionView *suspensionView;
@property (nonatomic, strong, nullable) SuspensionMenuView *suspensionMenuView;

@end

#pragma mark *** SuspensionControl ***

@interface SuspensionControl : NSObject

@property (nonatomic, strong, class, readonly) SuspensionControl *shareInstance;

+ (NSDictionary<NSString *, UIWindow *> *)windows;

+ (UIWindow *)windowForKey:(NSString *)key;
+ (void)setWindow:(UIWindow *)window forKey:(NSString *)key;
+ (void)removeWindowForKey:(NSString *)key;
+ (void)removeWindow:(UIWindow *)aWindow;
+ (void)removeAllWindows;

@end

#pragma mark *** NSObject (SuspensionKey) ***

@interface NSObject (SuspensionKey)

@property (nonatomic, copy) NSString *key;

- (NSString *)keyWithIdentifier:(NSString *)indetifier;

@end


NS_ASSUME_NONNULL_END
