//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "RaOWSConversationSettingsViewDelegate.h"
#import "OWSTableViewController.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TSThread;
@class YapDatabaseConnection;

@interface RaOWSConversationSettingsViewController : OWSTableViewController

@property (nonatomic, weak) id<RaOWSConversationSettingsViewDelegate> conversationSettingsViewDelegate;

@property (nonatomic) BOOL showVerificationOnAppear;

- (void)configureWithThread:(TSThread *)thread uiDatabaseConnection:(YapDatabaseConnection *)uiDatabaseConnection;

@end

NS_ASSUME_NONNULL_END
