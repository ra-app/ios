//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import <SignalMessaging/OWSViewController.h>

NS_ASSUME_NONNULL_BEGIN

@class HomeViewController;

typedef NS_ENUM(NSInteger, ProfileViewMode) {
    ProfileViewMode_AppSettings = 0,
    ProfileViewMode_Registration,
    ProfileViewMode_UpgradeOrNag,
};

@interface ProfileViewController : OWSViewController



- (instancetype)init NS_UNAVAILABLE;

+ (BOOL)shouldDisplayProfileViewOnLaunch;
//- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil andMode:(ProfileViewMode)profileViewMode;
+ (void)presentForAppSettings:(UINavigationController *)navigationController;
+ (void)presentForRegistration:(UINavigationController *)navigationController;
+ (void)presentForUpgradeOrNag:(HomeViewController *)fromViewController NS_SWIFT_NAME(presentForUpgradeOrNag(from:));

@end

NS_ASSUME_NONNULL_END
