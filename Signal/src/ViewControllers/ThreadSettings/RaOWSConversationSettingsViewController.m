//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "RaOWSConversationSettingsViewController.h"
#import "BlockListUIUtils.h"
#import "ContactsViewHelper.h"
#import "FingerprintViewController.h"
#import "OWSAddToContactViewController.h"
#import "OWSBlockingManager.h"
#import "OWSSoundSettingsViewController.h"
#import "PhoneNumber.h"
#import "ShowGroupMembersViewController.h"
#import "RAAPP-Swift.h"
#import "UIFont+OWS.h"
#import "UIView+OWS.h"
#import "UpdateGroupViewController.h"
#import <ContactsUI/ContactsUI.h>
#import <Curve25519Kit/Curve25519.h>
#import <SignalCoreKit/NSDate+OWS.h>
#import <SignalMessaging/Environment.h>
#import <SignalMessaging/OWSAvatarBuilder.h>
#import <SignalMessaging/OWSContactsManager.h>
#import <SignalMessaging/OWSProfileManager.h>
#import <SignalMessaging/OWSSounds.h>
#import <SignalMessaging/SignalMessaging-Swift.h>
#import <SignalMessaging/UIUtil.h>
#import <SignalServiceKit/OWSDisappearingConfigurationUpdateInfoMessage.h>
#import <SignalServiceKit/OWSDisappearingMessagesConfiguration.h>
#import <SignalServiceKit/OWSMessageSender.h>
#import <SignalServiceKit/OWSPrimaryStorage.h>
#import <SignalServiceKit/OWSUserProfile.h>
#import <SignalServiceKit/TSGroupThread.h>
#import <SignalServiceKit/TSOutgoingMessage.h>
#import <SignalServiceKit/TSThread.h>


NS_ASSUME_NONNULL_BEGIN

//#define SHOW_COLOR_PICKER

const CGFloat kIconViewLength = 24;

@interface RaOWSConversationSettingsViewController () <ContactEditingDelegate,
    ContactsViewHelperDelegate,
#ifdef SHOW_COLOR_PICKER
    ColorPickerDelegate,
#endif
    OWSSheetViewControllerDelegate>

@property (nonatomic) TSThread *thread;
@property (nonatomic) YapDatabaseConnection *uiDatabaseConnection;
@property (nonatomic, readonly) YapDatabaseConnection *editingDatabaseConnection;

@property (nonatomic) NSArray<NSNumber *> *disappearingMessagesDurations;
@property (nonatomic) OWSDisappearingMessagesConfiguration *disappearingMessagesConfiguration;
@property (nullable, nonatomic) MediaGallery *mediaGallery;
@property (nonatomic, readonly) ContactsViewHelper *contactsViewHelper;
@property (nonatomic, readonly) UIImageView *avatarView;
@property (nonatomic, readonly) UILabel *disappearingMessagesDurationLabel;
#ifdef SHOW_COLOR_PICKER
@property (nonatomic) OWSColorPicker *colorPicker;
#endif

@end

#pragma mark -

@implementation RaOWSConversationSettingsViewController

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return self;
    }

    [self commonInit];

    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return self;
    }

    [self commonInit];

    return self;
}

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self) {
        return self;
    }

    [self commonInit];

    return self;
}

- (void)commonInit
{
    _contactsViewHelper = [[ContactsViewHelper alloc] initWithDelegate:self];

    [self observeNotifications];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Dependencies

- (MessageSenderJobQueue *)messageSenderJobQueue
{
    return SSKEnvironment.shared.messageSenderJobQueue;
}

- (TSAccountManager *)tsAccountManager
{
    OWSAssertDebug(SSKEnvironment.shared.tsAccountManager);

    return SSKEnvironment.shared.tsAccountManager;
}

- (OWSContactsManager *)contactsManager
{
    return Environment.shared.contactsManager;
}

- (OWSMessageSender *)messageSender
{
    return SSKEnvironment.shared.messageSender;
}

- (OWSBlockingManager *)blockingManager
{
    return [OWSBlockingManager sharedManager];
}

- (OWSProfileManager *)profileManager
{
    return [OWSProfileManager sharedManager];
}

#pragma mark

- (void)observeNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(identityStateDidChange:)
                                                 name:kNSNotificationName_IdentityStateDidChange
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(otherUsersProfileDidChange:)
                                                 name:kNSNotificationName_OtherUsersProfileDidChange
                                               object:nil];
}

- (YapDatabaseConnection *)editingDatabaseConnection
{
    return [OWSPrimaryStorage sharedManager].dbReadWriteConnection;
}

- (NSString *)threadName
{
    NSString *threadName = self.thread.name;
    if (self.thread.contactIdentifier &&
        [threadName isEqualToString:self.thread.contactIdentifier]) {
        threadName =
            [PhoneNumber bestEffortFormatPartialUserSpecifiedTextToLookLikeAPhoneNumber:self.thread.contactIdentifier];
    } else if (threadName.length == 0 && [self isGroupThread]) {
        threadName = [MessageStrings newGroupDefaultTitle];
    }
    return threadName;
}

- (BOOL)isGroupThread
{
    return [self.thread isKindOfClass:[TSGroupThread class]];
}

- (BOOL)hasSavedGroupIcon
{
    if (![self isGroupThread]) {
        return NO;
    }

    TSGroupThread *groupThread = (TSGroupThread *)self.thread;
    return groupThread.groupModel.groupImage != nil;
}

- (void)configureWithThread:(TSThread *)thread uiDatabaseConnection:(YapDatabaseConnection *)uiDatabaseConnection
{
    OWSAssertDebug(thread);
    self.thread = thread;
    self.uiDatabaseConnection = uiDatabaseConnection;

    if ([self.thread isKindOfClass:[TSContactThread class]]) {
        self.title = NSLocalizedString(
            @"CONVERSATION_SETTINGS_CONTACT_INFO_TITLE", @"Navbar title when viewing settings for a 1-on-1 thread");
    } else {
        self.title = NSLocalizedString(
            @"CONVERSATION_SETTINGS_GROUP_INFO_TITLE", @"Navbar title when viewing settings for a group thread");
    }

    [self updateEditButton];
}

- (void)updateEditButton
{
    OWSAssertDebug(self.thread);

    if ([self.thread isKindOfClass:[TSContactThread class]] && self.contactsManager.supportsContactEditing
        && self.hasExistingContact) {
        self.navigationItem.rightBarButtonItem =
            [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"EDIT_TXT", nil)
                                             style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(didTapEditButton)
                           accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"edit")];
    }
}

- (BOOL)hasExistingContact
{
    OWSAssertDebug([self.thread isKindOfClass:[TSContactThread class]]);
    TSContactThread *contactThread = (TSContactThread *)self.thread;
    NSString *recipientId = contactThread.contactIdentifier;
    return [self.contactsManager hasSignalAccountForRecipientId:recipientId];
}

#pragma mark - ContactEditingDelegate

- (void)didFinishEditingContact
{
    [self updateTableContents];

    OWSLogDebug(@"");
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - CNContactViewControllerDelegate

- (void)contactViewController:(CNContactViewController *)viewController
       didCompleteWithContact:(nullable CNContact *)contact
{
    [self updateTableContents];

    if (contact) {
        // Saving normally returns you to the "Show Contact" view
        // which we're not interested in, so we skip it here. There is
        // an unfortunate blip of the "Show Contact" view on slower devices.
        OWSLogDebug(@"completed editing contact.");
        [self dismissViewControllerAnimated:NO completion:nil];
    } else {
        OWSLogDebug(@"canceled editing contact.");
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - ContactsViewHelperDelegate

- (void)contactsViewHelperDidUpdateContacts
{
    [self updateTableContents];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.estimatedRowHeight = 45;
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    _disappearingMessagesDurationLabel = [UILabel new];
    SET_SUBVIEW_ACCESSIBILITY_IDENTIFIER(self, _disappearingMessagesDurationLabel);

    self.disappearingMessagesDurations = [OWSDisappearingMessagesConfiguration validDurationsSeconds];

    self.disappearingMessagesConfiguration =
        [OWSDisappearingMessagesConfiguration fetchObjectWithUniqueID:self.thread.uniqueId];

    if (!self.disappearingMessagesConfiguration) {
        self.disappearingMessagesConfiguration =
            [[OWSDisappearingMessagesConfiguration alloc] initDefaultWithThreadId:self.thread.uniqueId];
    }

#ifdef SHOW_COLOR_PICKER
    self.colorPicker = [[OWSColorPicker alloc] initWithThread:self.thread];
    self.colorPicker.delegate = self;
#endif

    [self updateTableContents];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.showVerificationOnAppear) {
        self.showVerificationOnAppear = NO;
        if (self.isGroupThread) {
            [self showGroupMembersView];
        } else {
            [self showVerificationView];
        }
    }
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


-(OWSTableSection*)makeConversationPropertiesSection
{
        OWSTableSection *section = [OWSTableSection new];

        //TODO: Lokalisierung
        section.customHeaderView = [self customSectionHeaderWithText:@"UNTERHALTUNGSEINSTELLUNGEN" andInset:16];
        section.customHeaderHeight = [NSNumber numberWithInt:40];

        return section;
    
}

-(OWSTableSection*)makeNotificationPropertiesSection
{
        OWSTableSection *section = [OWSTableSection new];

        //TODO: Lokalisierung
        section.customHeaderView = [self customSectionHeaderWithText:@"ANRUFEINSTELLUNGEN" andInset:16];
        section.customHeaderHeight = [NSNumber numberWithInt:40];

        return section;
    
}

- (void)updateTableContents
{
    OWSTableContents *contents = [OWSTableContents new];
    contents.title = NSLocalizedString(@"CONVERSATION_SETTINGS", @"title for conversation settings screen");

    BOOL isNoteToSelf = self.thread.isNoteToSelf;

    __weak RaOWSConversationSettingsViewController *weakSelf = self;

    // Main section.

    OWSTableSection *mainSection = [OWSTableSection new];

    mainSection.customHeaderView = [self mainSectionHeader];
    mainSection.customHeaderHeight = @(200.f);

    if ([self.thread isKindOfClass:[TSContactThread class]] && self.contactsManager.supportsContactEditing
        && !self.hasExistingContact) {
        [mainSection
            addItem:[OWSTableItem
                        itemWithCustomCellBlock:^{
                            return [weakSelf
                                 disclosureCellWithName:
                                     NSLocalizedString(@"CONVERSATION_SETTINGS_NEW_CONTACT",
                                         @"Label for 'new contact' button in conversation settings view.")
                                               iconName:@"table_ic_new_contact"
                                accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(
                                                            RaOWSConversationSettingsViewController, @"new_contact")];
                        }
                        actionBlock:^{
                            [weakSelf presentContactViewController];
                        }]];
        [mainSection addItem:[OWSTableItem
                                 itemWithCustomCellBlock:^{
                                     return [weakSelf
                                          disclosureCellWithName:
                                              NSLocalizedString(@"CONVERSATION_SETTINGS_ADD_TO_EXISTING_CONTACT",
                                                  @"Label for 'new contact' button in conversation settings view.")
                                                        iconName:@"table_ic_add_to_existing_contact"
                                         accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(
                                                                     RaOWSConversationSettingsViewController,
                                                                     @"add_to_existing_contact")];
                                 }
                                 actionBlock:^{
                                     RaOWSConversationSettingsViewController *strongSelf = weakSelf;
                                     OWSCAssertDebug(strongSelf);
                                     TSContactThread *contactThread = (TSContactThread *)strongSelf.thread;
                                     NSString *recipientId = contactThread.contactIdentifier;
                                     [strongSelf presentAddToContactViewControllerWithRecipientId:recipientId];
                                 }]];
    }


    if (SSKFeatureFlags.conversationSearch) {
        [mainSection addItem:[OWSTableItem
                                 itemWithCustomCellBlock:^{
                                     NSString *title = NSLocalizedString(@"CONVERSATION_SETTINGS_SEARCH",
                                         @"Table cell label in conversation settings which returns the user to the "
                                         @"conversation with 'search mode' activated");
                                     return [weakSelf
                                          disclosureCellWithName:title
                                                        iconName:@"conversation_settings_search"
                                         accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(
                                                                     RaOWSConversationSettingsViewController, @"search")];
                                 }
                                 actionBlock:^{
                                     [weakSelf tappedConversationSearch];
                                 }]];
    }

#ifdef SHOW_COLOR_PICKER
    [mainSection
        addItem:[OWSTableItem
                    itemWithCustomCellBlock:^{
                        RaOWSConversationSettingsViewController *strongSelf = weakSelf;
                        OWSCAssertDebug(strongSelf);

                        ConversationColorName colorName = strongSelf.thread.conversationColorName;
                        UIColor *currentColor =
                            [OWSConversationColor conversationColorOrDefaultForColorName:colorName].themeColor;
                        NSString *title = NSLocalizedString(@"CONVERSATION_SETTINGS_CONVERSATION_COLOR",
                            @"Label for table cell which leads to picking a new conversation color");
                        return [strongSelf
                                       cellWithName:title
                                           iconName:@"ic_color_palette"
                                disclosureIconColor:currentColor
                            accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(
                                                        RaOWSConversationSettingsViewController, @"conversation_color")];
                    }
                    actionBlock:^{
                        [weakSelf showColorPicker];
                    }]];
#endif

    [contents addSection:mainSection];
    
    
    OWSTableSection *companysection = [OWSTableSection new];
    
    [companysection
    addItem:
        [OWSTableItem
            itemWithCustomCellBlock:^{
                UITableViewCell *cell =
                    [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
                [OWSTableItem configureCell:cell];
                RaOWSConversationSettingsViewController *strongSelf = weakSelf;
                OWSCAssertDebug(strongSelf);
                cell.preservesSuperviewLayoutMargins = YES;
                cell.contentView.preservesSuperviewLayoutMargins = YES;
                //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

                UIImageView *iconView = [strongSelf viewForIconWithName:@"message_over_white_24x24"];

                UILabel *rowLabel = [UILabel new];
                rowLabel.text = self.threadName;
                rowLabel.textColor = [Theme primaryColor];
                rowLabel.font = [UIFont ows_dynamicTypeBodyFont];
                rowLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        
                UILabel *rowLabelDetail = [UILabel new];
                rowLabelDetail.text = [PhoneNumber bestEffortFormatPartialUserSpecifiedTextToLookLikeAPhoneNumber:self.thread.contactIdentifier];
                rowLabelDetail.textColor = [Theme primaryColor];
                rowLabelDetail.font = [UIFont ows_dynamicTypeBodyFont];
                rowLabelDetail.lineBreakMode = NSLineBreakByTruncatingTail;

                UIStackView *contentRow =
                    [[UIStackView alloc] initWithArrangedSubviews:@[rowLabel,rowLabelDetail, iconView
                    ]];
                contentRow.spacing = strongSelf.iconSpacing;
                contentRow.alignment = UIStackViewAlignmentCenter;
        
                [cell.contentView addSubview:contentRow];
                [contentRow autoPinEdgesToSuperviewMargins];

                //cell.textLabel.text = self.threadName;
                //cell.detailTextLabel.text = [PhoneNumber bestEffortFormatPartialUserSpecifiedTextToLookLikeAPhoneNumber:self.thread.contactIdentifier];

                cell.accessibilityIdentifier
                    = ACCESSIBILITY_IDENTIFIER_WITH_NAME(RaOWSConversationSettingsViewController, @"mute");

                return cell;
            }
            customRowHeight:UITableViewAutomaticDimension
            actionBlock:^{
                [weakSelf didTapEditButton];
            }]];
    
    
    [contents addSection:companysection];
  
    OWSTableSection *conversationSection =  [self makeConversationPropertiesSection];
    
    [conversationSection
    addItem:
        [OWSTableItem
            itemWithCustomCellBlock:^{
                UITableViewCell *cell =
                    [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
                [OWSTableItem configureCell:cell];
                RaOWSConversationSettingsViewController *strongSelf = weakSelf;
                OWSCAssertDebug(strongSelf);
                cell.preservesSuperviewLayoutMargins = YES;
                cell.contentView.preservesSuperviewLayoutMargins = YES;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

            
                cell.textLabel.text = NSLocalizedString(@"CONVERSATION_SETTINGS_MUTE_LABEL",
                @"label for 'mute thread' cell in conversation settings");

                NSString *muteStatus = NSLocalizedString(@"CONVERSATION_SETTINGS_MUTE_NOT_MUTED",
                    @"Indicates that the current thread is not muted.");
                NSDate *mutedUntilDate = strongSelf.thread.mutedUntilDate;
                NSDate *now = [NSDate date];
                if (mutedUntilDate != nil && [mutedUntilDate timeIntervalSinceDate:now] > 0) {
                    NSCalendar *calendar = [NSCalendar currentCalendar];
                    NSCalendarUnit calendarUnits = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
                    NSDateComponents *muteUntilComponents =
                        [calendar components:calendarUnits fromDate:mutedUntilDate];
                    NSDateComponents *nowComponents = [calendar components:calendarUnits fromDate:now];
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    if (nowComponents.year != muteUntilComponents.year
                        || nowComponents.month != muteUntilComponents.month
                        || nowComponents.day != muteUntilComponents.day) {

                        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
                        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
                    } else {
                        [dateFormatter setDateStyle:NSDateFormatterNoStyle];
                        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
                    }

                    muteStatus = [NSString
                        stringWithFormat:NSLocalizedString(@"CONVERSATION_SETTINGS_MUTED_UNTIL_FORMAT",
                                             @"Indicates that this thread is muted until a given date or time. "
                                             @"Embeds {{The date or time which the thread is muted until}}."),
                        [dateFormatter stringFromDate:mutedUntilDate]];
                }

                cell.detailTextLabel.text = muteStatus;

                cell.accessibilityIdentifier
                    = ACCESSIBILITY_IDENTIFIER_WITH_NAME(RaOWSConversationSettingsViewController, @"mute");

                return cell;
            }
            customRowHeight:UITableViewAutomaticDimension
            actionBlock:^{
                [weakSelf showMuteUnmuteActionSheet];
            }]];
    
    [conversationSection addItem:[OWSTableItem
                        itemWithCustomCellBlock:^{
                            RaOWSConversationSettingsViewController *strongSelf = weakSelf;
                            if (!strongSelf) {
                                return [UITableViewCell new];
                            }

                            //TODO: Lokalisierung
                            
                            UITableViewCell *cell = [strongSelf
                                 disclosureCellWithName:@"Benutzerdefinierte Benachrichtigungen"
                                               accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(
                                                            RaOWSConversationSettingsViewController, @"block")];

                            cell.selectionStyle = UITableViewCellSelectionStyleNone;

                            UISwitch *switchView = [UISwitch new];
                            switchView.on = [strongSelf.blockingManager isThreadBlocked:strongSelf.thread];
                            [switchView addTarget:strongSelf
                                           action:@selector(blockConversationSwitchDidChange:)
                                 forControlEvents:UIControlEventValueChanged];
                            cell.accessoryView = switchView;
                            switchView.accessibilityIdentifier = ACCESSIBILITY_IDENTIFIER_WITH_NAME(
                                RaOWSConversationSettingsViewController, @"block_conversation_switch");

                            return cell;
                        }
                                    actionBlock:nil]];
    
    [contents addSection:conversationSection];
    
    
    if ((!isNoteToSelf) && (!self.isGroupThread)) {
        //OWSTableSection *notificationsSection = [OWSTableSection new];
        // We need a section header to separate the notifications UI from the group settings UI.
        //notificationsSection.headerTitle = NSLocalizedString(
        //    @"SETTINGS_SECTION_NOTIFICATIONS", @"Label for the notifications section of conversation settings view.");

        OWSTableSection *notificationsSection = [self makeNotificationPropertiesSection];
        
  
        RaOWSConversationSettingsViewController *strongSelf = weakSelf;

        OWSSound sound = [OWSSounds notificationSoundForThread:strongSelf.thread];
            
        [notificationsSection addItem:[OWSTableItem disclosureItemWithText:@"Klingelton"
                               
                                                  detailText:[OWSSounds displayNameForSound:sound] accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"notifications")
                                       actionBlock:^{
                                           OWSSoundSettingsViewController *vc = [OWSSoundSettingsViewController new];
                                           vc.thread = weakSelf.thread;
                                           [weakSelf.navigationController pushViewController:vc animated:YES];
                                       }]];
        
        
        
        
        //TODO: Lokalisierung
                  [notificationsSection addItem:[OWSTableItem disclosureItemWithText:@"Vibration"
                  
                                     detailText:[OWSSounds displayNameForSound:sound] accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"notifications")
                          actionBlock:^{
                              [weakSelf showVibration];
                          }]];
        
                           
        /*
        [notificationsSection
            addItem:[OWSTableItem
                        itemWithCustomCellBlock:^{
                            UITableViewCell *cell =
                                [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
                            [OWSTableItem configureCell:cell];
                            RaOWSConversationSettingsViewController *strongSelf = weakSelf;
                            OWSCAssertDebug(strongSelf);
                            cell.preservesSuperviewLayoutMargins = YES;
                            cell.contentView.preservesSuperviewLayoutMargins = YES;
                            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

                            UIImageView *iconView = [strongSelf viewForIconWithName:@"table_ic_notification_sound"];

                            UILabel *rowLabel = [UILabel new];
                            rowLabel.text = NSLocalizedString(@"SETTINGS_ITEM_NOTIFICATION_SOUND",
                                @"Label for settings view that allows user to change the notification sound.");
                            rowLabel.textColor = [Theme primaryColor];
                            rowLabel.font = [UIFont ows_dynamicTypeBodyFont];
                            rowLabel.lineBreakMode = NSLineBreakByTruncatingTail;

                            UIStackView *contentRow =
                                [[UIStackView alloc] initWithArrangedSubviews:@[ iconView, rowLabel ]];
                            contentRow.spacing = strongSelf.iconSpacing;
                            contentRow.alignment = UIStackViewAlignmentCenter;
                            [cell.contentView addSubview:contentRow];
                            [contentRow autoPinEdgesToSuperviewMargins];

                            OWSSound sound = [OWSSounds notificationSoundForThread:strongSelf.thread];
                            cell.detailTextLabel.text = [OWSSounds displayNameForSound:sound];

                            cell.accessibilityIdentifier = ACCESSIBILITY_IDENTIFIER_WITH_NAME(
                                RaOWSConversationSettingsViewController, @"notifications");

                            return cell;
                        }
                        customRowHeight:UITableViewAutomaticDimension
                        actionBlock:^{
                            OWSSoundSettingsViewController *vc = [OWSSoundSettingsViewController new];
                            vc.thread = weakSelf.thread;
                            [weakSelf.navigationController pushViewController:vc animated:YES];
                        }]];
        
        */
        
   


        /*[notificationsSection
            addItem:
                [OWSTableItem
                    itemWithCustomCellBlock:^{
                        UITableViewCell *cell =
                            [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
                        [OWSTableItem configureCell:cell];
                        RaOWSConversationSettingsViewController *strongSelf = weakSelf;
                        OWSCAssertDebug(strongSelf);
                        cell.preservesSuperviewLayoutMargins = YES;
                        cell.contentView.preservesSuperviewLayoutMargins = YES;
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

                        UIImageView *iconView = [strongSelf viewForIconWithName:@"table_ic_mute_thread"];

                        UILabel *rowLabel = [UILabel new];
                        rowLabel.text = NSLocalizedString(@"CONVERSATION_SETTINGS_MUTE_LABEL",
                            @"label for 'mute thread' cell in conversation settings");
                        rowLabel.textColor = [Theme primaryColor];
                        rowLabel.font = [UIFont ows_dynamicTypeBodyFont];
                        rowLabel.lineBreakMode = NSLineBreakByTruncatingTail;

                        NSString *muteStatus = NSLocalizedString(@"CONVERSATION_SETTINGS_MUTE_NOT_MUTED",
                            @"Indicates that the current thread is not muted.");
                        NSDate *mutedUntilDate = strongSelf.thread.mutedUntilDate;
                        NSDate *now = [NSDate date];
                        if (mutedUntilDate != nil && [mutedUntilDate timeIntervalSinceDate:now] > 0) {
                            NSCalendar *calendar = [NSCalendar currentCalendar];
                            NSCalendarUnit calendarUnits = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
                            NSDateComponents *muteUntilComponents =
                                [calendar components:calendarUnits fromDate:mutedUntilDate];
                            NSDateComponents *nowComponents = [calendar components:calendarUnits fromDate:now];
                            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                            if (nowComponents.year != muteUntilComponents.year
                                || nowComponents.month != muteUntilComponents.month
                                || nowComponents.day != muteUntilComponents.day) {

                                [dateFormatter setDateStyle:NSDateFormatterShortStyle];
                                [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
                            } else {
                                [dateFormatter setDateStyle:NSDateFormatterNoStyle];
                                [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
                            }

                            muteStatus = [NSString
                                stringWithFormat:NSLocalizedString(@"CONVERSATION_SETTINGS_MUTED_UNTIL_FORMAT",
                                                     @"Indicates that this thread is muted until a given date or time. "
                                                     @"Embeds {{The date or time which the thread is muted until}}."),
                                [dateFormatter stringFromDate:mutedUntilDate]];
                        }

                        UIStackView *contentRow =
                            [[UIStackView alloc] initWithArrangedSubviews:@[ iconView, rowLabel ]];
                        contentRow.spacing = strongSelf.iconSpacing;
                        contentRow.alignment = UIStackViewAlignmentCenter;
                        [cell.contentView addSubview:contentRow];
                        [contentRow autoPinEdgesToSuperviewMargins];

                        cell.detailTextLabel.text = muteStatus;

                        cell.accessibilityIdentifier
                            = ACCESSIBILITY_IDENTIFIER_WITH_NAME(RaOWSConversationSettingsViewController, @"mute");

                        return cell;
                    }
                    customRowHeight:UITableViewAutomaticDimension
                    actionBlock:^{
                        [weakSelf showMuteUnmuteActionSheet];
                    }]];
         */
        //notificationsSection.footerTitle = NSLocalizedString(
         //   @"MUTE_BEHAVIOR_EXPLANATION", @"An explanation of the consequences of muting a thread.");
        [contents addSection:notificationsSection];
    }
    // Block Conversation section.

    if (!isNoteToSelf) {
        OWSTableSection *section = [OWSTableSection new];
        
        section.customHeaderView  = [self customSectionHeaderWithText:@"DATENSCHUTZ" andInset:16];
        
        section.customHeaderHeight = [NSNumber numberWithInt:50];

        
        /*if (self.thread.isGroupThread) {
            section.footerTitle = NSLocalizedString(
                @"BLOCK_GROUP_BEHAVIOR_EXPLANATION", @"An explanation of the consequences of blocking a group.");
        } else {
            section.footerTitle = NSLocalizedString(
                @"BLOCK_USER_BEHAVIOR_EXPLANATION", @"An explanation of the consequences of blocking another user.");
        }*/
        
        //TODO: Lokalisierung
        [section addItem:[OWSTableItem actionItemWithText:@"Sicherheitsnummer anzeigen" accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"privacy") actionBlock:^{
            [weakSelf showVerificationView];
        }]];

        
        
        [section addItem:[OWSTableItem
                             itemWithCustomCellBlock:^{
                                 RaOWSConversationSettingsViewController *strongSelf = weakSelf;
                                 if (!strongSelf) {
                                     return [UITableViewCell new];
                                 }

                                 NSString *cellTitle;
                                 /*if (strongSelf.thread.isGroupThread) {
                                     cellTitle = NSLocalizedString(@"CONVERSATION_SETTINGS_BLOCK_THIS_GROUP",
                                         @"table cell label in conversation settings");
                                 } else {
                                     cellTitle = NSLocalizedString(@"CONVERSATION_SETTINGS_BLOCK_THIS_USER",
                                         @"table cell label in conversation settings");
                                 }*/
            
                                 //TODO: Lokalisierung
                                 cellTitle = @"Blockieren";
            
                                 UITableViewCell *cell = [strongSelf
                                      disclosureCellWithName:cellTitle
                                                    accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(
                                                                 RaOWSConversationSettingsViewController, @"block")];

                                 cell.selectionStyle = UITableViewCellSelectionStyleNone;

                                 UISwitch *switchView = [UISwitch new];
                                 switchView.on = [strongSelf.blockingManager isThreadBlocked:strongSelf.thread];
                                 [switchView addTarget:strongSelf
                                                action:@selector(blockConversationSwitchDidChange:)
                                      forControlEvents:UIControlEventValueChanged];
                                 cell.accessoryView = switchView;
                                 switchView.accessibilityIdentifier = ACCESSIBILITY_IDENTIFIER_WITH_NAME(
                                     RaOWSConversationSettingsViewController, @"block_conversation_switch");

                                 return cell;
                             }
                                         actionBlock:nil]];
        [contents addSection:section];
    }

    self.contents = contents;
}

- (CGFloat)iconSpacing
{
    return 12.f;
}

- (UITableViewCell *)cellWithName:(NSString *)name
                         iconName:(NSString *)iconName
              disclosureIconColor:(UIColor *)disclosureIconColor
{
    UITableViewCell *cell = [self cellWithName:name iconName:iconName];
    OWSColorPickerAccessoryView *accessoryView =
        [[OWSColorPickerAccessoryView alloc] initWithColor:disclosureIconColor];
    [accessoryView sizeToFit];
    cell.accessoryView = accessoryView;

    return cell;
}

- (UITableViewCell *)cellWithName:(NSString *)name iconName:(NSString *)iconName
{
    OWSAssertDebug(iconName.length > 0);
    UIImageView *iconView = [self viewForIconWithName:iconName];
    return [self cellWithName:name iconView:iconView];
}

- (UITableViewCell *)cellWithName:(NSString *)name iconView:(UIView *)iconView
{
    OWSAssertDebug(name.length > 0);

    UITableViewCell *cell = [OWSTableItem newCell];
    cell.preservesSuperviewLayoutMargins = YES;
    cell.contentView.preservesSuperviewLayoutMargins = YES;

    UILabel *rowLabel = [UILabel new];
    rowLabel.text = name;
    rowLabel.textColor = [Theme primaryColor];
    rowLabel.font = [UIFont ows_dynamicTypeBodyFont];
    rowLabel.lineBreakMode = NSLineBreakByTruncatingTail;

    UIStackView *contentRow = [[UIStackView alloc] initWithArrangedSubviews:@[ iconView, rowLabel ]];
    contentRow.spacing = self.iconSpacing;

    [cell.contentView addSubview:contentRow];
    [contentRow autoPinEdgesToSuperviewMargins];

    return cell;
}

- (UITableViewCell *)cellWithName:(NSString *)name
{
    OWSAssertDebug(name.length > 0);

    UITableViewCell *cell = [OWSTableItem newCell];
    cell.preservesSuperviewLayoutMargins = YES;
    cell.contentView.preservesSuperviewLayoutMargins = YES;

    UILabel *rowLabel = [UILabel new];
    rowLabel.text = name;
    rowLabel.textColor = [Theme primaryColor];
    rowLabel.font = [UIFont ows_regularFontWithSize:15];
    rowLabel.lineBreakMode = NSLineBreakByTruncatingTail;

    [cell.contentView addSubview:rowLabel];
    [rowLabel autoPinEdgesToSuperviewMargins];

    return cell;
}

- (UITableViewCell *)disclosureCellWithName:(NSString *)name
                                   iconName:(NSString *)iconName
                    accessibilityIdentifier:(NSString *)accessibilityIdentifier
{
    UITableViewCell *cell = [self cellWithName:name iconName:iconName];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.accessibilityIdentifier = accessibilityIdentifier;
    return cell;
}

- (UITableViewCell *)disclosureCellWithName:(NSString *)name
                    accessibilityIdentifier:(NSString *)accessibilityIdentifier
{
    UITableViewCell *cell = [self cellWithName:name];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.accessibilityIdentifier = accessibilityIdentifier;
    return cell;
}

- (UITableViewCell *)labelCellWithName:(NSString *)name
                              iconName:(NSString *)iconName
               accessibilityIdentifier:(NSString *)accessibilityIdentifier
{
    UITableViewCell *cell = [self cellWithName:name iconName:iconName];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessibilityIdentifier = accessibilityIdentifier;
    return cell;
}


- (UIView *)mainSectionHeader
{
    UIView *mainSectionHeader = [UIView new];
    UIView *threadInfoView = [UIView containerView];
    [mainSectionHeader addSubview:threadInfoView];
    [threadInfoView autoPinWidthToSuperviewWithMargin:0.f];
    [threadInfoView autoPinHeightToSuperviewWithMargin:0.f];

    UIImage *avatarImage = [OWSAvatarBuilder buildImageForThread:self.thread diameter:1];
    
    OWSAssertDebug(avatarImage);
    
    UIImageView *avatarView = [[UIImageView alloc] initWithImage:avatarImage];
    
    avatarView.layer.masksToBounds = YES;
    avatarView.contentMode = UIViewContentModeScaleAspectFill;
    
    _avatarView = avatarView;
    [threadInfoView addSubview:avatarView];
    [avatarView autoVCenterInSuperview];
    [avatarView autoPinLeadingToSuperviewMargin];
    [avatarView autoPinWidthToSuperviewWithMargin:0.f];
    [avatarView autoPinHeightToSuperviewWithMargin:0.f];

    if (self.isGroupThread && !self.hasSavedGroupIcon) {
        UIImage *cameraImage = [UIImage imageNamed:@"settings-avatar-camera"];
        UIImageView *cameraImageView = [[UIImageView alloc] initWithImage:cameraImage];
        [threadInfoView addSubview:cameraImageView];
        [cameraImageView autoPinTrailingToEdgeOfView:avatarView];
        [cameraImageView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:avatarView];
    }

    UIView *threadNameView = [UIView containerView];
    [threadInfoView addSubview:threadNameView];
    [threadNameView autoVCenterInSuperview];
    [threadNameView autoPinTrailingToSuperviewMargin];
    [threadNameView autoPinLeadingToTrailingEdgeOfView:avatarView offset:16.f];

    UILabel *threadTitleLabel = [UILabel new];
    threadTitleLabel.text = self.threadName;
    threadTitleLabel.textColor = [Theme primaryColor];
    threadTitleLabel.font = [UIFont ows_dynamicTypeTitle2Font];
    threadTitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [threadNameView addSubview:threadTitleLabel];
    [threadTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [threadTitleLabel autoPinWidthToSuperview];

    __block UIView *lastTitleView = threadTitleLabel;

    if (![self isGroupThread]) {
        const CGFloat kSubtitlePointSize = 12.f;
        void (^addSubtitle)(NSAttributedString *) = ^(NSAttributedString *subtitle) {
            UILabel *subtitleLabel = [UILabel new];
            subtitleLabel.textColor = [Theme secondaryColor];
            subtitleLabel.font = [UIFont ows_regularFontWithSize:kSubtitlePointSize];
            subtitleLabel.attributedText = subtitle;
            subtitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
            [threadNameView addSubview:subtitleLabel];
            [subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:lastTitleView];
            [subtitleLabel autoPinLeadingToSuperviewMargin];
            lastTitleView = subtitleLabel;
        };

        NSString *recipientId = self.thread.contactIdentifier;

        BOOL hasName = ![self.thread.name isEqualToString:recipientId];
        if (hasName) {
            NSAttributedString *subtitle = [[NSAttributedString alloc]
                initWithString:[PhoneNumber
                                   bestEffortFormatPartialUserSpecifiedTextToLookLikeAPhoneNumber:recipientId]];
            addSubtitle(subtitle);
        } else {
            NSString *_Nullable profileName = [self.contactsManager formattedProfileNameForRecipientId:recipientId];
            if (profileName) {
                addSubtitle([[NSAttributedString alloc] initWithString:profileName]);
            }
        }

        BOOL isVerified = [[OWSIdentityManager sharedManager] verificationStateForRecipientId:recipientId]
            == OWSVerificationStateVerified;
        if (isVerified) {
            NSMutableAttributedString *subtitle = [NSMutableAttributedString new];
            // "checkmark"
            [subtitle appendAttributedString:[[NSAttributedString alloc]
                                                 initWithString:LocalizationNotNeeded(@"\uf00c ")
                                                     attributes:@{
                                                         NSFontAttributeName :
                                                             [UIFont ows_fontAwesomeFont:kSubtitlePointSize],
                                                     }]];
            [subtitle appendAttributedString:[[NSAttributedString alloc]
                                                 initWithString:NSLocalizedString(@"PRIVACY_IDENTITY_IS_VERIFIED_BADGE",
                                                                    @"Badge indicating that the user is verified.")]];
            addSubtitle(subtitle);
        }
    }

    [lastTitleView autoPinEdgeToSuperviewEdge:ALEdgeBottom];

    [mainSectionHeader
        addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                     action:@selector(conversationNameTouched:)]];
    mainSectionHeader.userInteractionEnabled = YES;

    SET_SUBVIEW_ACCESSIBILITY_IDENTIFIER(self, mainSectionHeader);

    return mainSectionHeader;
}

- (void)conversationNameTouched:(UIGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateRecognized) {
        if (self.isGroupThread) {
            CGPoint location = [sender locationInView:self.avatarView];
            if (CGRectContainsPoint(self.avatarView.bounds, location)) {
                [self showUpdateGroupView:UpdateGroupMode_EditGroupAvatar];
            } else {
                [self showUpdateGroupView:UpdateGroupMode_EditGroupName];
            }
        } else {
            if (self.contactsManager.supportsContactEditing) {
                [self presentContactViewController];
            }
        }
    }
}

- (UIImageView *)viewForIconWithName:(NSString *)iconName
{
    UIImage *icon = [UIImage imageNamed:iconName];

    OWSAssertDebug(icon);
    UIImageView *iconView = [UIImageView new];
    iconView.image = [icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    iconView.tintColor = [Theme sectionHeaderTextColor];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.layer.minificationFilter = kCAFilterTrilinear;
    iconView.layer.magnificationFilter = kCAFilterTrilinear;

    [iconView autoSetDimensionsToSize:CGSizeMake(kIconViewLength, kIconViewLength)];

    return iconView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSIndexPath *_Nullable selectedPath = [self.tableView indexPathForSelectedRow];
    if (selectedPath) {
        // HACK to unselect rows when swiping back
        // http://stackoverflow.com/questions/19379510/uitableviewcell-doesnt-get-deselected-when-swiping-back-quickly
        [self.tableView deselectRowAtIndexPath:selectedPath animated:animated];
    }

    [self updateTableContents];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (self.disappearingMessagesConfiguration.isNewRecord && !self.disappearingMessagesConfiguration.isEnabled) {
        // don't save defaults, else we'll unintentionally save the configuration and notify the contact.
        return;
    }

    if (self.disappearingMessagesConfiguration.dictionaryValueDidChange) {
        [self.editingDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {
            [self.disappearingMessagesConfiguration saveWithTransaction:transaction];
            // MJK TODO - should be safe to remove this senderTimestamp
            OWSDisappearingConfigurationUpdateInfoMessage *infoMessage =
                [[OWSDisappearingConfigurationUpdateInfoMessage alloc]
                         initWithTimestamp:[NSDate ows_millisecondTimeStamp]
                                    thread:self.thread
                             configuration:self.disappearingMessagesConfiguration
                       createdByRemoteName:nil
                    createdInExistingGroup:NO];
            [infoMessage saveWithTransaction:transaction];

            OWSDisappearingMessagesConfigurationMessage *message = [[OWSDisappearingMessagesConfigurationMessage alloc]
                initWithConfiguration:self.disappearingMessagesConfiguration
                               thread:self.thread];

            [self.messageSenderJobQueue addMessage:message transaction:transaction.asAnyWrite];
        }];
    }
}

#pragma mark - Actions

- (void)showShareProfileAlert
{
    [self.profileManager presentAddThreadToProfileWhitelist:self.thread
                                         fromViewController:self
                                                    success:^{
                                                        [self updateTableContents];
                                                    }];
}

-(void)showVibration
{
    NSLog(@"showVibration touched");
}

- (void)showVerificationView
{
    NSString *recipientId = self.thread.contactIdentifier;
    OWSAssertDebug(recipientId.length > 0);

    [FingerprintViewController presentFromViewController:self recipientId:recipientId];
}

- (void)showGroupMembersView
{
    ShowGroupMembersViewController *showGroupMembersViewController = [ShowGroupMembersViewController new];
    [showGroupMembersViewController configWithThread:(TSGroupThread *)self.thread];
    [self.navigationController pushViewController:showGroupMembersViewController animated:YES];
}

- (void)showUpdateGroupView:(UpdateGroupMode)mode
{
    OWSAssertDebug(self.conversationSettingsViewDelegate);

    UpdateGroupViewController *updateGroupViewController = [UpdateGroupViewController new];
    updateGroupViewController.conversationSettingsViewDelegate = self.conversationSettingsViewDelegate;
    updateGroupViewController.thread = (TSGroupThread *)self.thread;
    updateGroupViewController.mode = mode;
    [self.navigationController pushViewController:updateGroupViewController animated:YES];
}

- (void)presentContactViewController
{
    if (!self.contactsManager.supportsContactEditing) {
        OWSFailDebug(@"Contact editing not supported");
        return;
    }
    if (![self.thread isKindOfClass:[TSContactThread class]]) {
        OWSFailDebug(@"unexpected thread: %@", [self.thread class]);
        return;
    }

    TSContactThread *contactThread = (TSContactThread *)self.thread;
    [self.contactsViewHelper presentContactViewControllerForRecipientId:contactThread.contactIdentifier
                                                     fromViewController:self
                                                        editImmediately:YES];
}

- (void)presentAddToContactViewControllerWithRecipientId:(NSString *)recipientId
{
    if (!self.contactsManager.supportsContactEditing) {
        // Should not expose UI that lets the user get here.
        OWSFailDebug(@"Contact editing not supported.");
        return;
    }

    if (!self.contactsManager.isSystemContactsAuthorized) {
        [self.contactsViewHelper presentMissingContactAccessAlertControllerFromViewController:self];
        return;
    }

    OWSAddToContactViewController *viewController = [OWSAddToContactViewController new];
    [viewController configureWithRecipientId:recipientId];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)didTapEditButton
{
    [self presentContactViewController];
}

- (void)didTapLeaveGroup
{
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:NSLocalizedString(@"CONFIRM_LEAVE_GROUP_TITLE", @"Alert title")
                                            message:NSLocalizedString(@"CONFIRM_LEAVE_GROUP_DESCRIPTION", @"Alert body")
                                     preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *leaveAction = [UIAlertAction
                actionWithTitle:NSLocalizedString(@"LEAVE_BUTTON_TITLE", @"Confirmation button within contextual alert")
        accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"leave_group_confirm")
                          style:UIAlertActionStyleDestructive
                        handler:^(UIAlertAction *_Nonnull action) {
                            [self leaveGroup];
                        }];
    [alert addAction:leaveAction];
    [alert addAction:[OWSAlerts cancelAction]];

    [self presentAlert:alert];
}

- (BOOL)hasLeftGroup
{
    if (self.isGroupThread) {
        TSGroupThread *groupThread = (TSGroupThread *)self.thread;
        return !groupThread.isLocalUserInGroup;
    }

    return NO;
}

- (void)leaveGroup
{
    TSGroupThread *gThread = (TSGroupThread *)self.thread;
    TSOutgoingMessage *message =
        [TSOutgoingMessage outgoingMessageInThread:gThread groupMetaMessage:TSGroupMetaMessageQuit expiresInSeconds:0];

    [self.editingDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {
        [self.messageSenderJobQueue addMessage:message transaction:transaction.asAnyWrite];
        [gThread leaveGroupWithTransaction:transaction];
    }];

    [self.navigationController popViewControllerAnimated:YES];
}

- (void)disappearingMessagesSwitchValueDidChange:(UISwitch *)sender
{
    UISwitch *disappearingMessagesSwitch = (UISwitch *)sender;

    [self toggleDisappearingMessages:disappearingMessagesSwitch.isOn];

    [self updateTableContents];
}

- (void)blockConversationSwitchDidChange:(id)sender
{
    if (![sender isKindOfClass:[UISwitch class]]) {
        OWSFailDebug(@"Unexpected sender for block user switch: %@", sender);
    }
    UISwitch *blockConversationSwitch = (UISwitch *)sender;

    BOOL isCurrentlyBlocked = [self.blockingManager isThreadBlocked:self.thread];

    __weak RaOWSConversationSettingsViewController *weakSelf = self;
    if (blockConversationSwitch.isOn) {
        OWSAssertDebug(!isCurrentlyBlocked);
        if (isCurrentlyBlocked) {
            return;
        }
        [BlockListUIUtils showBlockThreadActionSheet:self.thread
                                  fromViewController:self
                                     blockingManager:self.blockingManager
                                     contactsManager:self.contactsManager
                                       messageSender:self.messageSender
                                     completionBlock:^(BOOL isBlocked) {
                                         // Update switch state if user cancels action.
                                         blockConversationSwitch.on = isBlocked;

                                         [weakSelf updateTableContents];
                                     }];

    } else {
        OWSAssertDebug(isCurrentlyBlocked);
        if (!isCurrentlyBlocked) {
            return;
        }
        [BlockListUIUtils showUnblockThreadActionSheet:self.thread
                                    fromViewController:self
                                       blockingManager:self.blockingManager
                                       contactsManager:self.contactsManager
                                       completionBlock:^(BOOL isBlocked) {
                                           // Update switch state if user cancels action.
                                           blockConversationSwitch.on = isBlocked;

                                           [weakSelf updateTableContents];
                                       }];
    }
}

- (void)toggleDisappearingMessages:(BOOL)flag
{
    self.disappearingMessagesConfiguration.enabled = flag;

    [self updateTableContents];
}

- (void)durationSliderDidChange:(UISlider *)slider
{
    // snap the slider to a valid value
    NSUInteger index = (NSUInteger)(slider.value + 0.5);
    [slider setValue:index animated:YES];
    NSNumber *numberOfSeconds = self.disappearingMessagesDurations[index];
    self.disappearingMessagesConfiguration.durationSeconds = [numberOfSeconds unsignedIntValue];

    [self updateDisappearingMessagesDurationLabel];
}

- (void)updateDisappearingMessagesDurationLabel
{
    if (self.disappearingMessagesConfiguration.isEnabled) {
        NSString *keepForFormat = NSLocalizedString(@"KEEP_MESSAGES_DURATION",
            @"Slider label embeds {{TIME_AMOUNT}}, e.g. '2 hours'. See *_TIME_AMOUNT strings for examples.");
        self.disappearingMessagesDurationLabel.text =
            [NSString stringWithFormat:keepForFormat, self.disappearingMessagesConfiguration.durationString];
    } else {
        self.disappearingMessagesDurationLabel.text
            = NSLocalizedString(@"KEEP_MESSAGES_FOREVER", @"Slider label when disappearing messages is off");
    }

    [self.disappearingMessagesDurationLabel setNeedsLayout];
    [self.disappearingMessagesDurationLabel.superview setNeedsLayout];
}

- (void)showMuteUnmuteActionSheet
{
    // The "unmute" action sheet has no title or message; the
    // action label speaks for itself.
    NSString *title = nil;
    NSString *message = nil;
    if (!self.thread.isMuted) {
        title = NSLocalizedString(
            @"CONVERSATION_SETTINGS_MUTE_ACTION_SHEET_TITLE", @"Title of the 'mute this thread' action sheet.");
        message = NSLocalizedString(
            @"MUTE_BEHAVIOR_EXPLANATION", @"An explanation of the consequences of muting a thread.");
    }

    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:title
                                                                         message:message
                                                                  preferredStyle:UIAlertControllerStyleActionSheet];

    __weak RaOWSConversationSettingsViewController *weakSelf = self;
    if (self.thread.isMuted) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"CONVERSATION_SETTINGS_UNMUTE_ACTION",
                                                                   @"Label for button to unmute a thread.")
                                       accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"unmute")
                                                         style:UIAlertActionStyleDestructive
                                                       handler:^(UIAlertAction *_Nonnull ignore) {
                                                           [weakSelf setThreadMutedUntilDate:nil];
                                                       }];
        [actionSheet addAction:action];
    } else {
#ifdef DEBUG
        [actionSheet
            addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"CONVERSATION_SETTINGS_MUTE_ONE_MINUTE_ACTION",
                                                         @"Label for button to mute a thread for a minute.")
                             accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"mute_1_minute")
                                               style:UIAlertActionStyleDestructive
                                             handler:^(UIAlertAction *_Nonnull ignore) {
                                                 NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
                                                 NSCalendar *calendar = [NSCalendar currentCalendar];
                                                 [calendar setTimeZone:timeZone];
                                                 NSDateComponents *dateComponents = [NSDateComponents new];
                                                 [dateComponents setMinute:1];
                                                 NSDate *mutedUntilDate =
                                                     [calendar dateByAddingComponents:dateComponents
                                                                               toDate:[NSDate date]
                                                                              options:0];
                                                 [weakSelf setThreadMutedUntilDate:mutedUntilDate];
                                             }]];
#endif
        [actionSheet
            addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"CONVERSATION_SETTINGS_MUTE_ONE_HOUR_ACTION",
                                                         @"Label for button to mute a thread for a hour.")
                             accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"mute_1_hour")
                                               style:UIAlertActionStyleDestructive
                                             handler:^(UIAlertAction *_Nonnull ignore) {
                                                 NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
                                                 NSCalendar *calendar = [NSCalendar currentCalendar];
                                                 [calendar setTimeZone:timeZone];
                                                 NSDateComponents *dateComponents = [NSDateComponents new];
                                                 [dateComponents setHour:1];
                                                 NSDate *mutedUntilDate =
                                                     [calendar dateByAddingComponents:dateComponents
                                                                               toDate:[NSDate date]
                                                                              options:0];
                                                 [weakSelf setThreadMutedUntilDate:mutedUntilDate];
                                             }]];
        [actionSheet
            addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"CONVERSATION_SETTINGS_MUTE_ONE_DAY_ACTION",
                                                         @"Label for button to mute a thread for a day.")
                             accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"mute_1_day")
                                               style:UIAlertActionStyleDestructive
                                             handler:^(UIAlertAction *_Nonnull ignore) {
                                                 NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
                                                 NSCalendar *calendar = [NSCalendar currentCalendar];
                                                 [calendar setTimeZone:timeZone];
                                                 NSDateComponents *dateComponents = [NSDateComponents new];
                                                 [dateComponents setDay:1];
                                                 NSDate *mutedUntilDate =
                                                     [calendar dateByAddingComponents:dateComponents
                                                                               toDate:[NSDate date]
                                                                              options:0];
                                                 [weakSelf setThreadMutedUntilDate:mutedUntilDate];
                                             }]];
        [actionSheet
            addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"CONVERSATION_SETTINGS_MUTE_ONE_WEEK_ACTION",
                                                         @"Label for button to mute a thread for a week.")
                             accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"mute_1_week")
                                               style:UIAlertActionStyleDestructive
                                             handler:^(UIAlertAction *_Nonnull ignore) {
                                                 NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
                                                 NSCalendar *calendar = [NSCalendar currentCalendar];
                                                 [calendar setTimeZone:timeZone];
                                                 NSDateComponents *dateComponents = [NSDateComponents new];
                                                 [dateComponents setDay:7];
                                                 NSDate *mutedUntilDate =
                                                     [calendar dateByAddingComponents:dateComponents
                                                                               toDate:[NSDate date]
                                                                              options:0];
                                                 [weakSelf setThreadMutedUntilDate:mutedUntilDate];
                                             }]];
        [actionSheet
            addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"CONVERSATION_SETTINGS_MUTE_ONE_YEAR_ACTION",
                                                         @"Label for button to mute a thread for a year.")
                             accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"mute_1_year")
                                               style:UIAlertActionStyleDestructive
                                             handler:^(UIAlertAction *_Nonnull ignore) {
                                                 NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
                                                 NSCalendar *calendar = [NSCalendar currentCalendar];
                                                 [calendar setTimeZone:timeZone];
                                                 NSDateComponents *dateComponents = [NSDateComponents new];
                                                 [dateComponents setYear:1];
                                                 NSDate *mutedUntilDate =
                                                     [calendar dateByAddingComponents:dateComponents
                                                                               toDate:[NSDate date]
                                                                              options:0];
                                                 [weakSelf setThreadMutedUntilDate:mutedUntilDate];
                                             }]];
    }

    [actionSheet addAction:[OWSAlerts cancelAction]];

    [self presentAlert:actionSheet];
}

- (void)setThreadMutedUntilDate:(nullable NSDate *)value
{
    [self.editingDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [self.thread updateWithMutedUntilDate:value transaction:transaction];
    }];
    
    [self updateTableContents];
}

- (void)showMediaGallery
{
    OWSLogDebug(@"");

    MediaGallery *mediaGallery = [[MediaGallery alloc] initWithThread:self.thread
                                                              options:MediaGalleryOptionSliderEnabled];

    self.mediaGallery = mediaGallery;

    OWSAssertDebug([self.navigationController isKindOfClass:[OWSNavigationController class]]);
    [mediaGallery pushTileViewFromNavController:(OWSNavigationController *)self.navigationController];
}

- (void)tappedConversationSearch
{
    [self.conversationSettingsViewDelegate conversationSettingsDidRequestConversationSearch:self];
}

#pragma mark - Notifications

- (void)identityStateDidChange:(NSNotification *)notification
{
    OWSAssertIsOnMainThread();

    [self updateTableContents];
}

- (void)otherUsersProfileDidChange:(NSNotification *)notification
{
    OWSAssertIsOnMainThread();

    NSString *recipientId = notification.userInfo[kNSNotificationKey_ProfileRecipientId];
    OWSAssertDebug(recipientId.length > 0);

    if (recipientId.length > 0 && [self.thread isKindOfClass:[TSContactThread class]] &&
        [self.thread.contactIdentifier isEqualToString:recipientId]) {
        [self updateTableContents];
    }
}

#pragma mark - ColorPickerDelegate

#ifdef SHOW_COLOR_PICKER

- (void)showColorPicker
{
    OWSSheetViewController *sheetViewController = self.colorPicker.sheetViewController;
    sheetViewController.delegate = self;

    [self presentViewController:sheetViewController
                       animated:YES
                     completion:^() {
                         OWSLogInfo(@"presented sheet view");
                     }];
}

- (void)colorPicker:(OWSColorPicker *)colorPicker
    didPickConversationColor:(OWSConversationColor *_Nonnull)conversationColor
{
    OWSLogDebug(@"picked color: %@", conversationColor.name);
    [self.editingDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {
        [self.thread updateConversationColorName:conversationColor.name transaction:transaction];
    }];

    [self.contactsManager.avatarCache removeAllImages];
    [self updateTableContents];
    [self.conversationSettingsViewDelegate conversationColorWasUpdated];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ConversationConfigurationSyncOperation *operation =
            [[ConversationConfigurationSyncOperation alloc] initWithThread:self.thread];
        OWSAssertDebug(operation.isReady);
        [operation start];
    });
}

#endif

#pragma mark - OWSSheetViewController

- (void)sheetViewControllerRequestedDismiss:(OWSSheetViewController *)sheetViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

NS_ASSUME_NONNULL_END
