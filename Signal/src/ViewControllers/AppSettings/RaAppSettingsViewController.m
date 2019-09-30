//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "RaAppSettingsViewController.h"
#import "AppSettingsViewController.h"
#import "AboutTableViewController.h"
#import "AdvancedSettingsTableViewController.h"
#import "DebugUITableViewController.h"
#import "NotificationSettingsViewController.h"
#import "OWSBackup.h"
#import "OWSBackupSettingsViewController.h"
#import "OWSLinkedDevicesTableViewController.h"
#import "OWSNavigationController.h"
#import "PrivacySettingsTableViewController.h"
#import "ProfileViewController.h"
#import "RegistrationUtils.h"
#import "RAAPP-Swift.h"
#import <SignalMessaging/Environment.h>
#import <SignalMessaging/OWSContactsManager.h>
#import <SignalMessaging/UIUtil.h>
#import <SignalServiceKit/TSAccountManager.h>
#import <SignalServiceKit/TSSocketManager.h>
#import "UIColor+OWS.h"
#import "UIFont+OWS.h"
#import "UIView+OWS.h"
#import "Theme.h"

@interface RaAppSettingsViewController ()

@property (nonatomic, readonly) OWSContactsManager *contactsManager;
@property (nonatomic, nullable) OWSInviteFlow *inviteFlow;

@end

#pragma mark -

@implementation RaAppSettingsViewController

/**
 * We always present the settings controller modally, from within an OWSNavigationController
 */
+ (OWSNavigationController *)inModalNavigationController
{
    RaAppSettingsViewController *viewController = [RaAppSettingsViewController new];
    OWSNavigationController *navController =
        [[OWSNavigationController alloc] initWithRootViewController:viewController];

    return navController;
}

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return self;
    }

    _contactsManager = Environment.shared.contactsManager;

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return self;
    }

    _contactsManager = Environment.shared.contactsManager;

    return self;
}

- (void)loadView
{
    self.tableView.opaque = NO;
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor redColor]; // Theme.backgroundColor;
    self.tableViewStyle = UITableViewStylePlain;
    [super loadView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationItem setHidesBackButton:YES];

    OWSAssertDebug([self.navigationController isKindOfClass:[OWSNavigationController class]]);

    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                      target:self
                                                      action:@selector(dismissWasPressed:)
                                     accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"dismiss")];
    [self updateRightBarButtonForTheme];
    [self observeNotifications];

    self.title = NSLocalizedString(@"SETTINGS_NAV_BAR_TITLE", @"Title for settings activity");

    [self updateTableContents];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self updateTableContents];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table Contents

- (void)updateTableContents
{
    OWSTableContents *contents = [OWSTableContents new];

    __weak RaAppSettingsViewController *weakSelf = self;

#ifdef INTERNAL
    OWSTableSection *internalSection = [OWSTableSection new];
    [section addItem:[OWSTableItem softCenterLabelItemWithText:@"Internal Build"]];
    [contents addSection:internalSection];
#endif
    
    
    [contents addSection:[self makeProfileSection]];
    [contents addSection:[self makeSettingsSection]];
    
    OWSTableSection *section = [OWSTableSection new];
   

    //TODO: Lokalisierung
    [section addItem:[OWSTableItem disclosureItemWithText:@"SMS und MMS"
                                            accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"privacy")
                                                        actionBlock:^{
                                                            [weakSelf showLanguage];}]];
    
    [section addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"SETTINGS_NOTIFICATIONS", nil)
     accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"notifications")
                 actionBlock:^{
                     [weakSelf showNotifications];
                 }]];
    
    [section addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"SETTINGS_PRIVACY_TITLE",
                                                              @"Settings table view cell label")
                                  accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"privacy")
                                              actionBlock:^{
                                                  [weakSelf showPrivacy];
                                              }]];
    
//TODO: Lokalisierung
    
    NSLocale *locale = [NSLocale currentLocale];

    NSString *language = [locale displayNameForKey:NSLocaleIdentifier
                                             value:[locale localeIdentifier]];
    
    
    [section addItem:[OWSTableItem disclosureItemWithText:@"Sprache" detailText:language
    accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"privacy")
                actionBlock:^{
                    [weakSelf showLanguage];
                }]];
    
    //TODO: Lokalisierung
    
    [section addItem:[OWSTableItem disclosureItemWithText:@"Unterhaltungen und Medieninhalte"
                                               accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"privacy")
                                                           actionBlock:^{
                                                               [weakSelf showConversation];
                                                           }]];
    
    [section addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"LINKED_DEVICES_TITLE",
                                                              @"Menu item and navbar title for the device manager")
                                  accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"linked_devices")
                                              actionBlock:^{
                                                  [weakSelf showLinkedDevices];
                                              }]];
    
    //TODO: Lokalisierung
      
     [section addItem:[OWSTableItem disclosureItemWithText:@"RA-Nachrichten und -Anrufe"
                                                 accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"privacy")
                                                             actionBlock:^{
                                                                 [weakSelf showMessagesCalls];
                                                             }]];
    
     [contents addSection:section];
    
     [contents addSection:[self makeSupportSection]];
    
    
    section = [OWSTableSection new];
    
    //TODO: Lokalisierung
    [section addItem:[OWSTableItem disclosureItemWithText:@"Hilfe erhalten"
                                       accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"notifications")
                                                   actionBlock:^{
                                                       [weakSelf showSupport];
                                                   }]];
    //TODO: Lokalisierung
    [section addItem:[OWSTableItem disclosureItemWithText:@"Geben Sie uns Feedback"
                                       accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"notifications")
                                                   actionBlock:^{
                                                       [weakSelf showFeedback];
                                                   }]];
    
    [contents addSection:section];
    
    [contents addSection:[self makePrivacySection]];
    
    section = [OWSTableSection new];
    
    //TODO: Lokalisierung
    [section addItem:[OWSTableItem disclosureItemWithText:@"Nutzungsbedingungen"
    accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"notifications")
                actionBlock:^{
                    [weakSelf showTermsOfUse];
                }]];
    
    //TODO: Lokalisierung
      [section addItem:[OWSTableItem disclosureItemWithText:@"AGB"
      accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"notifications")
                  actionBlock:^{
                      [weakSelf showAGB];
                  }]];
    
     if (TSAccountManager.sharedInstance.isDeregistered) {
           [section addItem:[self destructiveButtonItemWithTitle:NSLocalizedString(@"SETTINGS_REREGISTER_BUTTON",
                                                                     @"Label for re-registration button.")
                                         accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"reregister")
                                                        selector:@selector(reregisterUser)
                                                           color:[UIColor ows_materialBlueColor]]];
           [section addItem:[self destructiveButtonItemWithTitle:NSLocalizedString(@"SETTINGS_DELETE_DATA_BUTTON",
                                                                     @"Label for 'delete data' button.")
                                         accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"delete_data")
                                                        selector:@selector(deleteUnregisterUserData)
                                                           color:[UIColor ows_destructiveRedColor]]];
       } else {
           [section
               addItem:[self destructiveButtonItemWithTitle:NSLocalizedString(@"SETTINGS_DELETE_ACCOUNT_BUTTON", @"")
                                    accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"delete_account")
                                                   selector:@selector(unregisterUser)
                                                      color:[UIColor ows_destructiveRedColor]]];
       }

    [contents addSection:section];
    
    [contents addSection:[self makeFooterSection]];

    self.contents = contents;
}

- (OWSTableItem *)destructiveButtonItemWithTitle:(NSString *)title
                         accessibilityIdentifier:(NSString *)accessibilityIdentifier
                                        selector:(SEL)selector
                                           color:(UIColor *)color
{
    __weak RaAppSettingsViewController *weakSelf = self;
   return [OWSTableItem
        itemWithCustomCellBlock:^{
            UITableViewCell *cell = [OWSTableItem newCell];
            cell.preservesSuperviewLayoutMargins = YES;
            cell.contentView.preservesSuperviewLayoutMargins = YES;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            const CGFloat kButtonHeight = 40.f;
            OWSFlatButton *button = [OWSFlatButton buttonWithTitle:title
                                                              font:[OWSFlatButton fontForHeight:kButtonHeight]
                                                        titleColor:[UIColor whiteColor]
                                                   backgroundColor:color
                                                            target:weakSelf
                                                          selector:selector];
            [cell.contentView addSubview:button];
            [button autoSetDimension:ALDimensionHeight toSize:kButtonHeight];
            [button autoVCenterInSuperview];
            [button autoPinLeadingAndTrailingToSuperviewMargin];
            button.accessibilityIdentifier = accessibilityIdentifier;

            return cell;
        }
                customRowHeight:90.f
                    actionBlock:nil];
}

-(OWSTableSection*)makeProfileSection
{
 
    OWSTableSection *section = [OWSTableSection new];
    
    __weak RaAppSettingsViewController *weakSelf = self;

    
    [section addItem:[OWSTableItem itemWithCustomCellBlock:^{
           return [weakSelf profileHeaderCell];
        }
                            customRowHeight:100.f
                            actionBlock:^{
                                [weakSelf showProfile];
                            }]];
    
    return section;
}

-(OWSTableSection*)makePrivacySection
{
        OWSTableSection *section = [OWSTableSection new];

        //TODO: Lokalisierung
        section.customHeaderView = [self customSectionHeaderWithText:@"DATENSCHUTZ" andInset:16];
        section.customHeaderHeight = [NSNumber numberWithInt:40];

        return section;
    
}

-(OWSTableSection*)makeSupportSection
{
    OWSTableSection *section = [OWSTableSection new];

    //TODO: Lokalisierung
    section.customHeaderView = [self customSectionHeaderWithText:@"UNTERSTÜTZUNG" andInset:16];
    section.customHeaderHeight = [NSNumber numberWithInt:50];

    return section;
}


-(OWSTableSection*)makeFooterSection
{
    OWSTableSection *section = [OWSTableSection new];
       
    //TODO: Lokalisierung
    section.customHeaderView = [self customSectionFooterWithText:@"© 2018 OfficeApp | Version 1.8.20" andInset:16];
    section.customHeaderHeight = [NSNumber numberWithInt:60];
           
       
    return section;
    
}

-(OWSTableSection*)makeSettingsSection
{
    OWSTableSection *section = [OWSTableSection new];
    
    section.customHeaderView = [self customSectionHeaderWithText:[NSLocalizedString(@"OPEN_SETTINGS_BUTTON", @"Settings") uppercaseString] andInset:0];
    section.customHeaderHeight = [NSNumber numberWithInt:40];
        
    
    return section;
    
}

- (UIView *)customSectionFooterWithText:(NSString*)text andInset:(CGFloat)inset
{
    UIView *mainSectionHeader = [UIView new];
    UIView *threadInfoView = [UIView containerView];
    mainSectionHeader.backgroundColor = [Theme backgroundColor];
    [mainSectionHeader addSubview:threadInfoView];
    [threadInfoView autoPinEdgeToSuperviewEdge:ALEdgeTop];

    [threadInfoView autoPinWidthToSuperviewWithMargin:16.f];
    [threadInfoView autoPinHeightToSuperviewWithMargin:16.f];
    
    UILabel *threadTitleLabel = [UILabel new];
    threadTitleLabel.backgroundColor = [UIColor clearColor];
    threadTitleLabel.textAlignment = NSTextAlignmentCenter;
    threadTitleLabel.text = text;
    threadTitleLabel.textColor = [Theme sectionHeaderTextColor];
    threadTitleLabel.font = [UIFont ows_footerFontWithSize:13];
    threadTitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [threadInfoView addSubview:threadTitleLabel];
    [threadTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:inset];
    [threadTitleLabel autoPinWidthToSuperview];
        
    return mainSectionHeader;
    
}

- (UIView *)customSectionHeaderWithText:(NSString*)text andInset:(CGFloat)inset
{
    UIView *mainSectionHeader = [UIView new];
    UIView *threadInfoView = [UIView containerView];
    mainSectionHeader.backgroundColor = [Theme backgroundColor];
    [mainSectionHeader addSubview:threadInfoView];
    [threadInfoView autoPinEdgeToSuperviewEdge:ALEdgeTop];

    [threadInfoView autoPinWidthToSuperviewWithMargin:16.f];
    [threadInfoView autoPinHeightToSuperviewWithMargin:16.f];
    
    UILabel *threadTitleLabel = [UILabel new];
    threadTitleLabel.backgroundColor = [UIColor clearColor];
    threadTitleLabel.text = text;
    threadTitleLabel.textColor = [Theme sectionHeaderTextColor];
    threadTitleLabel.font = [UIFont ows_semiboldFontWithSize:14];
    threadTitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [threadInfoView addSubview:threadTitleLabel];
    [threadTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:inset];
    [threadTitleLabel autoPinWidthToSuperview];
        
    return mainSectionHeader;
}
- (UITableViewCell *)profileHeaderCell
{
    UITableViewCell *cell = [OWSTableItem newCell];
    cell.preservesSuperviewLayoutMargins = YES;
    cell.contentView.preservesSuperviewLayoutMargins = YES;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [Theme backgroundColor];
    cell.contentView.backgroundColor = [Theme backgroundColor];

    UIImage *_Nullable localProfileAvatarImage = [OWSProfileManager.sharedManager localProfileAvatarImage];
    UIImage *avatarImage = (localProfileAvatarImage
            ?: [[[OWSContactAvatarBuilder alloc] initForLocalUserWithDiameter:kLargeAvatarSize] buildDefaultImage]);
    OWSAssertDebug(avatarImage);

    AvatarImageView *avatarView = [[AvatarImageView alloc] initWithImage:avatarImage];
    [cell.contentView addSubview:avatarView];
    [avatarView autoVCenterInSuperview];
    [avatarView autoPinLeadingToSuperviewMargin];
    [avatarView autoSetDimension:ALDimensionWidth toSize:kLargeAvatarSize];
    [avatarView autoSetDimension:ALDimensionHeight toSize:kLargeAvatarSize];

    if (!localProfileAvatarImage) {
        UIImage *cameraImage = [UIImage imageNamed:@"settings-avatar-camera"];
        UIImageView *cameraImageView = [[UIImageView alloc] initWithImage:cameraImage];
        [cell.contentView addSubview:cameraImageView];
        [cameraImageView autoPinTrailingToEdgeOfView:avatarView];
        [cameraImageView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:avatarView];
    }

    UIView *nameView = [UIView containerView];
    [cell.contentView addSubview:nameView];
    [nameView autoVCenterInSuperview];
    [nameView autoPinLeadingToTrailingEdgeOfView:avatarView offset:16.f];

    UILabel *titleLabel = [UILabel new];
    NSString *_Nullable localProfileName = [OWSProfileManager.sharedManager localProfileName];
    if (localProfileName.length > 0) {
        titleLabel.text = localProfileName;
        titleLabel.textColor = [Theme primaryColor];
        titleLabel.font = [UIFont ows_semiboldFontWithSize:17];
    } else {
        titleLabel.text = NSLocalizedString(
            @"APP_SETTINGS_EDIT_PROFILE_NAME_PROMPT", @"Text prompting user to edit their profile name.");
        titleLabel.textColor = [UIColor ows_materialBlueColor];
        titleLabel.font = [UIFont ows_semiboldFontWithSize:17];
    }
    titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [nameView addSubview:titleLabel];
    [titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [titleLabel autoPinWidthToSuperview];

    const CGFloat kSubtitlePointSize = 18.f;
    UILabel *subtitleLabel = [UILabel new];
    subtitleLabel.textColor = [Theme primaryColor];
    subtitleLabel.font = [UIFont ows_semiboldFontWithSize:17];// [UIFont ows_regularFontWithSize:kSubtitlePointSize];
    subtitleLabel.attributedText = [[NSAttributedString alloc]
        initWithString:[PhoneNumber bestEffortFormatPartialUserSpecifiedTextToLookLikeAPhoneNumber:[TSAccountManager
                                                                                                       localNumber]]];
    subtitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [nameView addSubview:subtitleLabel];
    [subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:titleLabel];
    [subtitleLabel autoPinLeadingToSuperviewMargin];
    [subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];

    UIImage *disclosureImage = [UIImage imageNamed:(CurrentAppContext().isRTL ? @"NavBarBack" : @"NavBarBackRTL")];
    OWSAssertDebug(disclosureImage);
    UIImageView *disclosureButton =
        [[UIImageView alloc] initWithImage:[disclosureImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    disclosureButton.tintColor = [UIColor colorWithRGBHex:0xcccccc];
    [cell.contentView addSubview:disclosureButton];
    [disclosureButton autoVCenterInSuperview];
    [disclosureButton autoPinTrailingToSuperviewMargin];
    [disclosureButton autoPinLeadingToTrailingEdgeOfView:nameView offset:16.f];
    [disclosureButton setContentCompressionResistancePriority:(UILayoutPriorityDefaultHigh + 1)
                                                      forAxis:UILayoutConstraintAxisHorizontal];

    cell.accessibilityIdentifier = ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"profile");

    return cell;
}

- (void)showInviteFlow
{
    OWSInviteFlow *inviteFlow = [[OWSInviteFlow alloc] initWithPresentingViewController:self];
    self.inviteFlow = inviteFlow;
    [inviteFlow presentWithIsAnimated:YES completion:nil];
}

- (void)showMessagesCalls
{
    NSLog(@"showConversation touched");
}

- (void)showConversation
{
    NSLog(@"showConversation touched");
}

- (void)showLanguage
{
    NSLog(@"showSMS_MMS touched");
}

- (void)showNotification
{
    NSLog(@"showSMS_MMS touched");
}

- (void)showSupport
{
    NSLog(@"showSupport touched");
}

- (void)showTermsOfUse
{
    NSLog(@"showTermsOfUse touched");
}

- (void)showAGB
{
    NSLog(@"showAGB touched");
}

- (void)showFeedback
{
    NSLog(@"showFeedback touched");
}

- (void)showPrivacy
{
    PrivacySettingsTableViewController *vc = [[PrivacySettingsTableViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showNotifications
{
    NotificationSettingsViewController *vc = [[NotificationSettingsViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showLinkedDevices
{
    OWSLinkedDevicesTableViewController *vc = [OWSLinkedDevicesTableViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showProfile
{
    [ProfileViewController presentForAppSettings:self.navigationController];
}

- (void)showAdvanced
{
    AdvancedSettingsTableViewController *vc = [[AdvancedSettingsTableViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showAbout
{
    AboutTableViewController *vc = [[AboutTableViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showBackup
{
    OWSBackupSettingsViewController *vc = [OWSBackupSettingsViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showDebugUI
{
    [DebugUITableViewController presentDebugUIFromViewController:self];
}

- (void)dismissWasPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Unregister & Re-register

- (void)unregisterUser
{
    [self showDeleteAccountUI:YES];
}

- (void)deleteUnregisterUserData
{
    [self showDeleteAccountUI:NO];
}

- (void)showDeleteAccountUI:(BOOL)isRegistered
{
    __weak RaAppSettingsViewController *weakSelf = self;

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:NSLocalizedString(@"CONFIRM_ACCOUNT_DESTRUCTION_TITLE", @"")
                                            message:NSLocalizedString(@"CONFIRM_ACCOUNT_DESTRUCTION_TEXT", @"")
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"PROCEED_BUTTON", @"")
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
                                                [weakSelf deleteAccount:isRegistered];
                                            }]];
    [alert addAction:[OWSAlerts cancelAction]];

    [self presentAlert:alert];
}

- (void)deleteAccount:(BOOL)isRegistered
{
    if (isRegistered) {
        [ModalActivityIndicatorViewController
            presentFromViewController:self
                            canCancel:NO
                      backgroundBlock:^(ModalActivityIndicatorViewController *modalActivityIndicator) {
                          [TSAccountManager
                              unregisterTextSecureWithSuccess:^{
                                  [SignalApp resetAppData];
                              }
                              failure:^(NSError *error) {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      [modalActivityIndicator dismissWithCompletion:^{
                                          [OWSAlerts
                                              showAlertWithTitle:NSLocalizedString(@"UNREGISTER_SIGNAL_FAIL", @"")];
                                      }];
                                  });
                              }];
                      }];
    } else {
        [SignalApp resetAppData];
    }
}

- (void)reregisterUser
{
    [RegistrationUtils showReregistrationUIFromViewController:self];
}

#pragma mark - Dark Theme

- (UIBarButtonItem *)darkThemeBarButton
{
    UIBarButtonItem *barButtonItem;
    if (Theme.isDarkThemeEnabled) {
        barButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_dark_theme_on"]
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(didPressDisableDarkTheme:)];
    } else {
        barButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_dark_theme_off"]
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(didPressEnableDarkTheme:)];
    }
    barButtonItem.accessibilityIdentifier = ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"dark_theme");
    return barButtonItem;
}

- (void)didPressEnableDarkTheme:(id)sender
{
    [Theme setIsDarkThemeEnabled:YES];
    [self updateRightBarButtonForTheme];
    [self updateTableContents];
}

- (void)didPressDisableDarkTheme:(id)sender
{
    [Theme setIsDarkThemeEnabled:NO];
    [self updateRightBarButtonForTheme];
    [self updateTableContents];
}

- (void)updateRightBarButtonForTheme
{
    self.navigationItem.rightBarButtonItem = [self darkThemeBarButton];
}

#pragma mark - Socket Status Notifications

- (void)observeNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(socketStateDidChange)
                                                 name:kNSNotification_OWSWebSocketStateDidChange
                                               object:nil];
}

- (void)socketStateDidChange
{
    OWSAssertIsOnMainThread();

    [self updateTableContents];
}

@end
