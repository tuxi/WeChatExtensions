//
//  SuspensionView.h
//  SuspensionView
//
//  Created by Ossey on 17/2/25.
//  Copyright © 2017年 Ossey All rights reserved.
//


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SuspensionViewLeanEdgeType) {
    SuspensionViewLeanEdgeTypeHorizontal = 1,
    SuspensionViewLeanEdgeTypeEachSide
};

@class SuspensionView, SuspensionMenuView, MenuBarHypotenuseButton, HypotenuseAction;

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

@protocol XYSuspensionWindowProtocol <NSObject>
- (UIWindow *)xy_window;
- (void)xy_removeWindow;
@end

#pragma mark *** SuspensionView ***

@interface SuspensionView : UIButton <XYSuspensionWindowProtocol>

#if ! __has_feature(objc_arc)
@property (nonatomic, assign, nullable) id<SuspensionViewDelegate> delegate;
@property (nonatomic, assign, readonly) UIPanGestureRecognizer *panGestureRecognizer;
#else
@property (nonatomic, weak, readonly) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, weak, nullable) id<SuspensionViewDelegate> delegate;
#endif

@property (nonatomic, assign) SuspensionViewLeanEdgeType leanEdgeType;
@property (nonatomic, assign) UIEdgeInsets leanEdgeInsets;
@property (nonatomic, assign) BOOL invalidHidden;
@property (nonatomic, assign, readonly) BOOL isMoving;
@property (nonatomic, assign) CGFloat usingSpringWithDamping;
@property (nonatomic, assign) CGFloat initialSpringVelocity;
@property (nonatomic, copy, nullable) void (^locationChange)(CGPoint currentPoint);
@property (nonatomic, copy, nullable) void (^ leanFinishCallBack)(CGPoint centerPoint);
@property (nonatomic, assign, getter=isAutoLeanEdge) BOOL autoLeanEdge;
@property (nonatomic, copy, nullable) void (^clickCallBack)(void);
@property (nonatomic, assign) BOOL shouldLeanToPreviousPositionWhenAppStart;

- (void)moveToDisplayCenter;
- (void)moveToPreviousLeanPosition;
- (void)checkTargetPosition;

/// 界面方向发生改变，子类可重写此方法，进行布局
- (void)didChangeInterfaceOrientation:(UIInterfaceOrientation)orientation;

@end

#pragma mark *** UIResponder (SuspensionView) ***

@interface UIResponder (SuspensionView)
@property (nonatomic, nonnull) SuspensionView *suspensionView;
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

+ (instancetype)showWithFrame:(CGRect)frame;

@end

#pragma mark *** SuspensionMenuView ***

@interface SuspensionMenuView : UIView <XYSuspensionWindowProtocol>
#if ! __has_feature(objc_arc)
@property (nonatomic, assign, nullable) id<SuspensionMenuViewDelegate> delegate;
@property (nonatomic, assign, readonly) UIImageView *backgroundImageView;
@property (nonatomic, assign, readonly) HypotenuseAction *currentResponderItem;
#else
@property (nonatomic, weak, nullable) id<SuspensionMenuViewDelegate> delegate;
@property (nonatomic, weak, readonly) UIImageView *backgroundImageView;
@property (nonatomic, weak, readonly) HypotenuseAction *currentResponderItem;
#endif
@property (nonatomic, strong, readonly) SuspensionView *centerButton;
@property (nonatomic, copy) void (^ _Nullable menuBarClickBlock)(NSInteger index);
@property (nonatomic, copy) void (^ _Nullable moreButtonClickBlock)(NSInteger index);
@property (nonatomic, assign) BOOL shouldLeanToScreenCenterWhenOpened;
@property (nonatomic, strong, readonly) NSArray<HypotenuseAction *> *menuBarItems;
@property (nonatomic, assign) CGFloat usingSpringWithDamping;
@property (nonatomic, assign) CGFloat initialSpringVelocity;
@property (nonatomic, assign) BOOL shouldHiddenCenterButtonWhenOpen;
@property (nonatomic, assign) BOOL shouldCloseWhenDeviceOrientationDidChange;
@property (nonatomic, strong, readonly) UIWindow *xy_window;

- (instancetype)initWithFrame:(CGRect)frame itemSize:(CGSize)itemSize NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

- (void)showWithCompetion:(void (^ _Nullable)(void))competion;

- (void)addAction:(HypotenuseAction *)action;

- (void)showViewController:(UIViewController *)viewController animated:(BOOL)animated;

- (void)open;
- (void)openWithCompetion:(void (^ _Nullable)(BOOL finished))competion;
- (void)close;
- (void)closeWithCompetion:(void (^ _Nullable)(BOOL finished))competion;
@end

#pragma mark *** SuspensionMenuWindow ***

@interface SuspensionMenuWindow : SuspensionMenuView

@property (nonatomic, assign) BOOL shouldOpenWhenViewWillAppear;

+ (instancetype)menuWindowWithFrame:(CGRect)frame itemSize:(CGSize)itemSize;

@end

#pragma mark *** HypotenuseAction ***

@interface HypotenuseAction : NSObject

@property (nonatomic, strong, readonly) UIButton *hypotenuseButton;
@property (nonatomic, strong, readonly) NSArray<HypotenuseAction *> *moreHypotenusItems;
@property (nonatomic, assign) CGRect orginRect;
+ (instancetype)actionWithType:(UIButtonType)buttonType
                       handler:(void (^__nullable)(HypotenuseAction *action, SuspensionMenuView *menuView))handler;
- (void)addMoreAction:(HypotenuseAction *)action;

@end

#pragma mark *** UIWindow (SuspensionWindow) ***

@interface UIWindow (SuspensionWindow)

@property (nonatomic, strong, nullable) SuspensionView *suspensionView;
@property (nonatomic, strong, nullable) SuspensionMenuView *suspensionMenuView;

@end

@interface UIApplication (SuspensionWindowExtension)

- (nullable SuspensionMenuWindow *)xy_suspensionMenuWindow;

@end

NS_ASSUME_NONNULL_END

