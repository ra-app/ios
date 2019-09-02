//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "OWSOutgoingSyncMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface OWSViewOnceMessageReadSyncMessage : OWSOutgoingSyncMessage

@property (nonatomic, readonly) NSString *senderId;
@property (nonatomic, readonly) uint64_t messageIdTimestamp;
@property (nonatomic, readonly) uint64_t readTimestamp;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTimestamp:(uint64_t)timestamp NS_UNAVAILABLE;

- (instancetype)initWithSenderId:(NSString *)senderId
              messageIdTimestamp:(uint64_t)messageIdtimestamp
                   readTimestamp:(uint64_t)readTimestamp NS_DESIGNATED_INITIALIZER;

- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
