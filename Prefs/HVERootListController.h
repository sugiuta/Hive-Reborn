#import <Preferences/PSSpecifier.h>
#import <Preferences/PSListController.h>
#import <CepheiPrefs/HBRootListController.h>
#import <CepheiPrefs/HBAppearanceSettings.h>
#import <spawn.h>

@interface HVERootListController : HBRootListController
    @property (nonatomic, retain) UIBarButtonItem *respringButton;
    - (void)respring:(id)sender;
@end
