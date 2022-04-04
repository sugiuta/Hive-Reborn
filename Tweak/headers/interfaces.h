#import <UIKit/UIKit.h>
#import <Cephei/HBPreferences.h>
#import "UIColor+Hex.h"

#define W [UIScreen mainScreen].bounds.size.width
#define H [UIScreen mainScreen].bounds.size.height

@interface UIView (Hive)
    - (id)_viewControllerForAncestor;
@end

@interface CSPasscodeViewController : UIViewController
@end

@interface SBUIPasscodeBiometricAuthenticationView : UIView
    - (void)_usePasscodeButtonHit;
@end

@interface SBUIPasscodeLockViewBase : UIView
    @property (nonatomic, strong, readwrite) SBUIPasscodeBiometricAuthenticationView *biometricAuthenticationView;
@end

@interface SBUIPasscodeLockViewWithKeypad : SBUIPasscodeLockViewBase
    @property (nonatomic,retain) UILabel *statusTitleView;
    - (id)_numberPad;
    - (void)passcodeLockNumberPad:(id)arg1 keyDown:(id)arg2;
    - (void)passcodeLockNumberPad:(id)arg1 keyUp:(id)arg2;
@end

@interface SBUIPasscodeLockViewSimpleFixedDigitKeypad : SBUIPasscodeLockViewWithKeypad
    - (void)createHive:(BOOL)animated;
@end

@interface SBUIPasscodeViewWithLockScreenStyle : UIView
@end

@interface SBPasscodeNumberPadButton : UIControl
@end

@interface SBPasscodeEntryTransientOverlayViewController : UIViewController
    - (void)createHive:(BOOL)animated;
@end

#pragma mark new classes
@interface HexagonView : UIView
    @property (nonatomic, readonly) UIBezierPath *path;
    @property (nonatomic, retain) UIColor *fillColor;
    - (instancetype)initWithOrigin:(CGPoint)o width:(CGFloat)w;
@end

@interface HexagonButton : UIButton {
    HexagonView *darkeningView;
    UILabel *numLbl;
    HexagonView *hexagon;
}
    @property (nonatomic, retain) UIColor *fillColor;
    @property (nonatomic) unsigned int buttonNo;
    - (instancetype)initWithOrigin:(CGPoint)o width:(CGFloat)w;
@end
#pragma mark end new classes
