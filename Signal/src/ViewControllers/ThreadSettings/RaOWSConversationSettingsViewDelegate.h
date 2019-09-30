//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class RaOWSConversationSettingsViewController;
@class TSGroupModel;

@protocol RaOWSConversationSettingsViewDelegate <NSObject>

- (void)conversationColorWasUpdated;
- (void)groupWasUpdated:(TSGroupModel *)groupModel;
- (void)conversationSettingsDidRequestConversationSearch:(RaOWSConversationSettingsViewController *)conversationSettingsViewController;

- (void)popAllConversationSettingsViewsWithCompletion:(void (^_Nullable)(void))completionBlock;

@end

NS_ASSUME_NONNULL_END
