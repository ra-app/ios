//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "Theme.h"
#import "UIColor+OWS.h"
#import "UIUtil.h"
#import <SignalServiceKit/NSNotificationCenter+OWS.h>
#import <SignalServiceKit/OWSPrimaryStorage.h>
#import <SignalServiceKit/YapDatabaseConnection+OWS.h>

NS_ASSUME_NONNULL_BEGIN

NSString *const ThemeDidChangeNotification = @"ThemeDidChangeNotification";

NSString *const ThemeCollection = @"ThemeCollection";
NSString *const ThemeKeyThemeEnabled = @"ThemeKeyThemeEnabled";

@implementation Theme

+ (BOOL)isDarkThemeEnabled
{
    OWSAssertIsOnMainThread();

    if (!CurrentAppContext().isMainApp) {
        // Ignore theme in app extensions.
        return NO;
    }

    return [OWSPrimaryStorage.sharedManager.dbReadConnection boolForKey:ThemeKeyThemeEnabled
                                                           inCollection:ThemeCollection
                                                           defaultValue:NO];
}

+ (void)setIsDarkThemeEnabled:(BOOL)value
{
    OWSAssertIsOnMainThread();

    [OWSPrimaryStorage.sharedManager.dbReadWriteConnection setBool:value
                                                            forKey:ThemeKeyThemeEnabled
                                                      inCollection:ThemeCollection];

    [UIUtil setupSignalAppearence];

    [UIView performWithoutAnimation:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ThemeDidChangeNotification object:nil userInfo:nil];
    }];
}

+ (UIColor *)backgroundColor
{
    return (Theme.isDarkThemeEnabled ? UIColor.ows_gray95Color : UIColor.ows_whiteColor);
}

+ (UIColor *)offBackgroundColor
{
    return (
        Theme.isDarkThemeEnabled ? [UIColor colorWithWhite:0.2f alpha:1.f] : [UIColor colorWithWhite:0.94f alpha:1.f]);
}

+ (UIColor *)primaryColor
{
    return (Theme.isDarkThemeEnabled ? UIColor.ows_gray05Color : UIColor.ows_gray90Color);
}

+ (UIColor *)secondaryColor
{
    return (Theme.isDarkThemeEnabled ? UIColor.ows_gray25Color : UIColor.ows_gray60Color);
}

+ (UIColor *)boldColor
{
    return (Theme.isDarkThemeEnabled ? UIColor.ows_whiteColor : UIColor.blackColor);
}

+ (UIColor *)middleGrayColor
{
    return [UIColor colorWithWhite:0.5f alpha:1.f];
}

+ (UIColor *)placeholderColor
{
    return (Theme.isDarkThemeEnabled ? UIColor.ows_gray45Color : UIColor.ows_gray45Color);
}

+ (UIColor *)hairlineColor
{
    return (Theme.isDarkThemeEnabled ? UIColor.ows_gray75Color : UIColor.ows_gray25Color);
}

#pragma mark - Global App Colors

+ (UIColor *)navbarBackgroundColor
{
    return (Theme.isDarkThemeEnabled ? UIColor.ows_blackColor : UIColor.ows_whiteColor);
}

+ (UIColor *)navbarIconColor
{
    return (Theme.isDarkThemeEnabled ? UIColor.ows_gray25Color : UIColor.whiteColor);
}

+(UIColor *) toolbarIconColor {
    return (Theme.isDarkThemeEnabled ? UIColor.ows_gray25Color : UIColor.ows_gray25Color);
}

+ (UIColor *)navbarTitleColor
{
    return Theme.primaryColor;
}

+ (UIColor *)toolbarBackgroundColor
{
    return self.navbarBackgroundColor;
}

+ (UIColor *)cellSelectedColor
{
    return (Theme.isDarkThemeEnabled ? [UIColor colorWithWhite:0.2 alpha:1] : [UIColor colorWithWhite:0.92 alpha:1]);
}

+ (UIColor *)cellSeparatorColor
{
    return Theme.hairlineColor;
}

+ (UIColor *)conversationButtonBackgroundColor
{
    return (Theme.isDarkThemeEnabled ? [UIColor colorWithWhite:0.35f alpha:1.f] : UIColor.ows_gray02Color);
}

+ (UIBlurEffect *)barBlurEffect
{
    return Theme.isDarkThemeEnabled ? [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]
                                    : [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
}

+ (UIKeyboardAppearance)keyboardAppearance
{
    return Theme.isDarkThemeEnabled ? UIKeyboardAppearanceDark : UIKeyboardAppearanceDefault;
}

#pragma mark - Search Bar

+ (UIBarStyle)barStyle
{
    return Theme.isDarkThemeEnabled ? UIBarStyleBlack : UIBarStyleDefault;
}

+ (UIColor *)searchFieldBackgroundColor
{
    return Theme.isDarkThemeEnabled ? Theme.offBackgroundColor : UIColor.ows_gray05Color;
}

#pragma mark -

+ (UIColor *)toastForegroundColor
{
    return (Theme.isDarkThemeEnabled ? UIColor.ows_whiteColor : UIColor.ows_whiteColor);
}

+ (UIColor *)toastBackgroundColor
{
    return (Theme.isDarkThemeEnabled ? UIColor.ows_gray75Color : UIColor.ows_gray60Color);
}

@end

NS_ASSUME_NONNULL_END
