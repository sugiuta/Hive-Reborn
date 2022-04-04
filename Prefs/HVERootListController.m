
#import "HVERootListController.h"

@implementation HVERootListController

    - (NSArray *)specifiers {
        if (!_specifiers) {
            _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
        }
        return _specifiers;
    }

    - (instancetype)init {
        self = [super init];
        if (self) {
            UIColor *defaultColor = [UIColor colorWithRed:27/255.0 green:131/255.0 blue:196/255.0 alpha:1.0];
            HBAppearanceSettings *appearanceSettings = [[HBAppearanceSettings alloc] init];
            appearanceSettings.tintColor = defaultColor;
            appearanceSettings.tableViewCellSeparatorColor = [UIColor clearColor];
            self.hb_appearanceSettings = appearanceSettings;
            self.respringButton = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStylePlain target:self action:@selector(respring:)];
            self.respringButton.tintColor = defaultColor;
            self.navigationItem.rightBarButtonItem = self.respringButton;
        }
        return self;
    }

    - (void)respring:(id)sender {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Confirmation" message:@"Do you want to respring?" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            pid_t pid;
            const char* args[] = {"sbreload", NULL};
            posix_spawn(&pid, "/usr/bin/sbreload", NULL, NULL, (char* const*)args, NULL);
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    }

    - (UITableViewStyle)tableViewStyle {
        if (@available(iOS 13.0, *))
            return UITableViewStyleInsetGrouped;
        return UITableViewStyleGrouped;
    }

@end
