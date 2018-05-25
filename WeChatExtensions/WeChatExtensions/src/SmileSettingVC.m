//
//  SmileSettingVC.m
//  TouchID
//
//  Created by ryu-ushin on 5/25/15.
//  Copyright (c) 2015 rain. All rights reserved.
//

#import "SmileSettingVC.h"
#import "SmileAuthenticator.h"
#import "SmilePasswordContainerView.h"
#import "OSUnlockBackgroundView.h"

@interface SmileSettingVC () <UITextFieldDelegate, SmileContainerLayoutDelegate>

@property (nonatomic, strong) OSUnlockBackgroundView *unlockBackgroundView;

@end

@implementation SmileSettingVC{
    BOOL _needTouchID;
    BOOL _isAnimating;
    NSInteger _inputCount;
    NSString *_bufferPassword;
    NSString *_newPassword;
    NSInteger _passLength;
    NSInteger _failCount;
}

#pragma mark - SmileContainerLayoutDelegate
-(void)smileContainerLayoutSubview{
    self.unlockBackgroundView.passwordView.smilePasswordView.dotCount = self.unlockBackgroundView.passwordField.text.length;
}

- (void)touchesEndedOnPasswordContainerView:(SmilePasswordContainerView *)passwordContainerView {
    
    [self.unlockBackgroundView.passwordField becomeFirstResponder];
}

- (void)dismissSelf:(id)sender {
    
    [[SmileAuthenticator sharedInstance] authViewControllerWillDismissed];
    
    [self dismissViewControllerAnimated:YES completion:^{
        [[SmileAuthenticator sharedInstance] authViewControllerDidDismissed];
    }];
}

- (void)useTouchID:(id)sender {
    [self.unlockBackgroundView.passwordField resignFirstResponder];
    [self touchIDHandle];
}

#pragma mark - TouchID handle
-(void)touchIDHandle{
    switch ([SmileAuthenticator sharedInstance].securityType) {
        case INPUT_ONCE:
            
            [self touchIDForINPUT_ONCE];
            
            break;
            
        case INPUT_THREE:
            
            [self touchIDForINPUT_THREE];
            
            break;
            
        case INPUT_TOUCHID:
            
            [self touchIDForINPUT_TOUCHID];
            
            break;
            
        default:
            break;
    }
}

-(void)showKeyboard{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.unlockBackgroundView.passwordField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.05];
    });
}

-(void)touchIDForINPUT_TOUCHID{
    [SmileAuthenticator sharedInstance].localizedReason = NSLocalizedString(@"轻触指纹", nil);
    [[SmileAuthenticator sharedInstance] authenticateWithSuccess:^{
        [[SmileAuthenticator sharedInstance] touchID_OR_PasswordAuthSuccess];
        self.unlockBackgroundView.passwordView.smilePasswordView.dotCount = [SmileAuthenticator sharedInstance].passcodeDigit;
        [self performSelector:@selector(dismissSelf:) withObject:nil afterDelay:0.15];
    } andFailure:^(LAError errorCode) {
        [self showKeyboard];
    }];
}

-(void)touchIDForINPUT_ONCE{
    [SmileAuthenticator sharedInstance].localizedReason = NSLocalizedString(@"请输入密码或使用指纹解锁", nil);
    [[SmileAuthenticator sharedInstance] authenticateWithSuccess:^{
        [[SmileAuthenticator sharedInstance] touchID_OR_PasswordTurnOff];
        self.unlockBackgroundView.passwordView.smilePasswordView.dotCount = [SmileAuthenticator sharedInstance].passcodeDigit;
        [self performSelector:@selector(passwordCancleComplete) withObject:nil afterDelay:0.15];
    } andFailure:^(LAError errorCode) {
        [self showKeyboard];
    }];
}

-(void)touchIDForINPUT_THREE{
    [SmileAuthenticator sharedInstance].localizedReason = NSLocalizedString(@"请输入密码或使用指纹解锁", nil);
    [[SmileAuthenticator sharedInstance] authenticateWithSuccess:^{
        self.unlockBackgroundView.passwordView.smilePasswordView.dotCount = [SmileAuthenticator sharedInstance].passcodeDigit;
        _inputCount ++;
        [self performSelector:@selector(enterNewPassword) withObject:nil afterDelay:0.15];
    } andFailure:^(LAError errorCode) {
        [self showKeyboard];
    }];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (_needTouchID) {
        [self useTouchID:nil];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.unlockBackgroundView];
    NSDictionary *subviewsDict = @{@"unlockBackgroundView": self.unlockBackgroundView};
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[unlockBackgroundView]|" options:kNilOptions metrics:nil views:subviewsDict]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[unlockBackgroundView]|" options:kNilOptions metrics:nil views:subviewsDict]];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissSelf:)];
    
    if ([SmileAuthenticator sharedInstance].navibarTranslucent) {
        [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        [self.navigationController.navigationBar setShadowImage:[UIImage new]];
        [self.navigationController.navigationBar setTranslucent:YES];
        self.navigationController.view.backgroundColor = [UIColor whiteColor];
    }
    
    if ([SmileAuthenticator sharedInstance].nightMode) {
        [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
        [self.unlockBackgroundView.passwordField setKeyboardAppearance:UIKeyboardAppearanceDark];
        self.view.backgroundColor = [UIColor blackColor];
        self.unlockBackgroundView.descLabel.textColor = [UIColor whiteColor];
    }
    
    if ([SmileAuthenticator sharedInstance].parallaxMode) {
        [self registerEffectForView:self.unlockBackgroundView.passwordView depth:15];
    }
    
    if ([SmileAuthenticator sharedInstance].descriptionTextColor) {
        self.unlockBackgroundView.descLabel.textColor = [SmileAuthenticator sharedInstance].descriptionTextColor;
    }
    
    if ([SmileAuthenticator sharedInstance].backgroundImage) {
        self.unlockBackgroundView.backgroundImageView.image = [SmileAuthenticator sharedInstance].backgroundImage;
    }
    
    self.unlockBackgroundView.passwordView.delegate = self;
    
    //for tint color
    if ([SmileAuthenticator sharedInstance].tintColor) {
        //        self.navigationController.navigationBar.tintColor = [SmileAuthenticator sharedInstance].tintColor;
    }
    
    //for touchid image
    UIImage *iconImage = [UIImage imageNamed:[SmileAuthenticator sharedInstance].touchIDIconName];
    [self.unlockBackgroundView.touchIDBtn setImage:iconImage forState:UIControlStateNormal];
    
    self.unlockBackgroundView.descLabel.text = [NSString stringWithFormat:NSLocalizedString(@"请输入密码或使用TouchID解锁", nil), (long)[SmileAuthenticator sharedInstance].passcodeDigit];
    
    switch ([SmileAuthenticator sharedInstance].securityType) {
        case INPUT_ONCE: {
            self.unlockBackgroundView.touchIDBtn.hidden = NO;
            self.navigationItem.title = [self getAppName];
            
            break;
        }
        case INPUT_TWICE: {
            
            self.navigationItem.title = [self getAppName];
            
            break;
        }
        case INPUT_THREE: {
            self.unlockBackgroundView.touchIDBtn.hidden = NO;
            self.navigationItem.title = [self getAppName];
            self.unlockBackgroundView.descLabel.text = [NSString stringWithFormat:NSLocalizedString(@"请输入密码", nil), (long)[SmileAuthenticator sharedInstance].passcodeDigit];
            
            break;
        }
        case INPUT_TOUCHID: {
            
            self.unlockBackgroundView.touchIDBtn.hidden = NO;
            
            if (![SmileAuthenticator sharedInstance].appLogoName.length) {
                self.navigationItem.title = [self getAppName];
            } else {
                self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[SmileAuthenticator sharedInstance].appLogoName]];
            }
            
            break;
        }
        default:
            break;
    }
    
    //hide bar button
    if ([SmileAuthenticator sharedInstance].securityType == INPUT_TOUCHID) {
        if (self.navigationItem.rightBarButtonItem) {
            [self.navigationItem.rightBarButtonItem setTintColor:[UIColor clearColor]];
            [self.navigationItem.rightBarButtonItem setEnabled:NO];
        }
        
        //begin check canAuthenticate
        NSError *error = nil;
        if ([SmileAuthenticator canAuthenticateWithError:&error]) {
            _needTouchID = YES;
        } else {
            self.unlockBackgroundView.touchIDBtn.hidden = YES;
            [self.unlockBackgroundView.passwordField becomeFirstResponder];
        }
        
    } else if ([SmileAuthenticator sharedInstance].securityType == INPUT_ONCE | [SmileAuthenticator sharedInstance].securityType == INPUT_THREE) {
        
        //begin check canAuthenticate
        NSError *error = nil;
        if ([SmileAuthenticator canAuthenticateWithError:&error]) {
            _needTouchID = YES;
        } else {
            self.unlockBackgroundView.touchIDBtn.hidden = YES;
            [self.unlockBackgroundView.passwordField becomeFirstResponder];
        }
    }
    
    else {
        [self.unlockBackgroundView.passwordField becomeFirstResponder];
    }
    
    self.unlockBackgroundView.passwordField.delegate = self;
    [self.unlockBackgroundView.passwordField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    _passLength =[SmileAuthenticator sharedInstance].passcodeDigit;
}

- (NSString *)getAppName {
    NSString *appCurName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    if (!appCurName.length) {
        appCurName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    }
    return appCurName;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - animation

-(void)slideAnimation{
    _isAnimating = YES;
    
    if (!self.unlockBackgroundView.touchIDBtn.hidden) {
        self.unlockBackgroundView.touchIDBtn.hidden = YES;
    }
    
    [self.unlockBackgroundView.passwordView.smilePasswordView slideToLeftAnimationWithCompletion:^{
        _isAnimating = NO;
        if(![self.unlockBackgroundView.passwordField isFirstResponder]){
            [self.unlockBackgroundView.passwordField becomeFirstResponder];
        };
    }];
    
}

-(void)shakeAnimation{
    _isAnimating = YES;
    [self.unlockBackgroundView.passwordView.smilePasswordView shakeAnimationWithCompletion:^{
        _isAnimating = NO;
    }];
}

#pragma mark - handle user input
-(void)clearText {
    self.unlockBackgroundView.passwordField.text = @"";
    self.unlockBackgroundView.passwordView.smilePasswordView.dotCount = 0;
}

-(void)passwordInputComplete{
    [[SmileAuthenticator sharedInstance] userSetPassword: _newPassword];
    [self dismissSelf:nil];
}

-(void)passwordCancleComplete{
    [SmileAuthenticator clearPassword];
    [self dismissSelf:nil];
}

-(void)passwordWrong{
    _inputCount = 0;
    
    [self clearText];
    
    _failCount++;
    
    [self shakeAnimation];
    
    [[SmileAuthenticator sharedInstance] touchID_OR_PasswordAuthFail:_failCount];
    
    self.unlockBackgroundView.descLabel.text = [NSString stringWithFormat:NSLocalizedString(@"输入的密码错误", nil), (long)_failCount];
}

-(void)passwordNotMatch{
    
    _inputCount = _inputCount -2;
    
    [self clearText];
    [self shakeAnimation];
    
    self.unlockBackgroundView.descLabel.text = NSLocalizedString(@"密码或指纹不匹配", nil);
}

-(void)reEnterPassword{
    
    _bufferPassword = _newPassword;
    [self clearText];
    
    [self slideAnimation];
    
    self.unlockBackgroundView.descLabel.text = [NSString stringWithFormat:NSLocalizedString(@"请输入密码或使用指纹确认", nil), (long)[SmileAuthenticator sharedInstance].passcodeDigit];
}

-(void)enterNewPassword{
    [self clearText];
    [self slideAnimation];
    self.unlockBackgroundView.descLabel.text = [NSString stringWithFormat:NSLocalizedString(@"请输入密码或使用指纹确认", nil), (long)[SmileAuthenticator sharedInstance].passcodeDigit];
}

-(void)handleINPUT_TOUCHID{
    if ([SmileAuthenticator isSamePassword:_newPassword]) {
        [[SmileAuthenticator sharedInstance] touchID_OR_PasswordAuthSuccess];
        [self passwordInputComplete];
    } else {
        [self passwordWrong];
    }
}

-(void)handleINPUT_ONCE{
    if ([SmileAuthenticator isSamePassword:_newPassword]) {
        [[SmileAuthenticator sharedInstance] touchID_OR_PasswordTurnOff];
        [self passwordCancleComplete];
    } else {
        [self passwordWrong];
    }
}

-(void)handleINPUT_TWICE{
    if (_inputCount == 1) {
        [self reEnterPassword];
    } else if (_inputCount == 2) {
        if ([_bufferPassword isEqualToString:_newPassword]) {
            [[SmileAuthenticator sharedInstance] touchID_OR_PasswordTurnOn];
            [self passwordInputComplete];
        } else {
            [self passwordNotMatch];
        }
    }
}

-(void)handleINPUT_THREE{
    if (_inputCount == 1) {
        if ([SmileAuthenticator isSamePassword:_newPassword]) {
            [self enterNewPassword];
        } else {
            [self passwordWrong];
        }
    } else if (_inputCount == 2) {
        [self reEnterPassword];
    } else if (_inputCount == 3) {
        if ([_bufferPassword isEqualToString:_newPassword]) {
            [[SmileAuthenticator sharedInstance] touchID_OR_PasswordChange];
            [self passwordInputComplete];
        } else {
            [self passwordNotMatch];
        }
    }
}

-(void)handleUserInput{
    switch ([SmileAuthenticator sharedInstance].securityType) {
        case INPUT_ONCE:
            
            [self handleINPUT_ONCE];
            
            break;
            
        case INPUT_TWICE:
            
            _inputCount++;
            
            [self handleINPUT_TWICE];
            
            break;
            
        case INPUT_THREE:
            
            _inputCount++;
            
            [self handleINPUT_THREE];
            
            break;
            
        case INPUT_TOUCHID:
            
            [self handleINPUT_TOUCHID];
            
            break;
            
        default:
            break;
    }
    
}

#pragma mark - UITextFieldDelegate

-(void)textFieldDidChange:(UITextField*)textField{
    
    self.unlockBackgroundView.passwordView.smilePasswordView.dotCount = textField.text.length;
    
    if (textField.text.length == _passLength) {
        
        _newPassword = textField.text;
        
        [self performSelector:@selector(handleUserInput) withObject:nil afterDelay:0.3];
    }
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    if (textField.text.length >= _passLength) {
        return NO;
    }
    
    return !_isAnimating;
}


#pragma mark - PrivateMethod - Parallax

- (void)registerEffectForView:(UIView *)aView depth:(CGFloat)depth;
{
    UIInterpolatingMotionEffect *effectX;
    UIInterpolatingMotionEffect *effectY;
    effectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                              type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    effectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                              type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    
    
    effectX.maximumRelativeValue = @(depth);
    effectX.minimumRelativeValue = @(-depth);
    effectY.maximumRelativeValue = @(depth);
    effectY.minimumRelativeValue = @(-depth);
    
    UIMotionEffectGroup *group = [[UIMotionEffectGroup alloc] init];
    group.motionEffects =@[effectX, effectY];
    
    [aView addMotionEffect:group] ;
}


- (OSUnlockBackgroundView *)unlockBackgroundView {
    if (!_unlockBackgroundView) {
        _unlockBackgroundView = [OSUnlockBackgroundView new];
        _unlockBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        _unlockBackgroundView.accessibilityIdentifier = NSStringFromSelector(_cmd);
        [_unlockBackgroundView.touchIDBtn addTarget:self action:@selector(useTouchID:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _unlockBackgroundView;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    [self.unlockBackgroundView.passwordField resignFirstResponder];
}
@end
