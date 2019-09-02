//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "OWSRecipientIdentity.h"
#import <AxolotlKit/IdentityKeyStore.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const OWSPrimaryStorageIdentityKeyStoreCollection;

extern NSString *const OWSPrimaryStorageTrustedKeysCollection;

// This notification will be fired whenever identities are created
// or their verification state changes.
extern NSString *const kNSNotificationName_IdentityStateDidChange;

// number of bytes in a signal identity key, excluding the key-type byte.
extern const NSUInteger kIdentityKeyLength;

#ifdef DEBUG
extern const NSUInteger kStoredIdentityKeyLength;
#endif

@class OWSRecipientIdentity;
@class SDSAnyReadTransaction;
@class SDSAnyWriteTransaction;
@class SDSDatabaseStorage;
@class SSKProtoVerified;

// This class can be safely accessed and used from any thread.
@interface OWSIdentityManager : NSObject <IdentityKeyStore>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDatabaseStorage:(SDSDatabaseStorage *)databaseStorage;

+ (instancetype)sharedManager;

- (void)generateNewIdentityKey;

- (nullable ECKeyPair *)identityKeyPairWithTransaction:(SDSAnyReadTransaction *)transaction;

- (void)setVerificationState:(OWSVerificationState)verificationState
                 identityKey:(NSData *)identityKey
                 recipientId:(NSString *)recipientId
       isUserInitiatedChange:(BOOL)isUserInitiatedChange
                 transaction:(SDSAnyWriteTransaction *)transaction;

- (OWSVerificationState)verificationStateForRecipientId:(NSString *)recipientId;
- (OWSVerificationState)verificationStateForRecipientId:(NSString *)recipientId
                                            transaction:(SDSAnyReadTransaction *)transaction;

- (void)setVerificationState:(OWSVerificationState)verificationState
                 identityKey:(NSData *)identityKey
                 recipientId:(NSString *)recipientId
       isUserInitiatedChange:(BOOL)isUserInitiatedChange;

- (nullable OWSRecipientIdentity *)recipientIdentityForRecipientId:(NSString *)recipientId;

/**
 * @param   recipientId unique stable identifier for the recipient, e.g. e164 phone number
 * @returns nil if the recipient does not exist, or is trusted for sending
 *          else returns the untrusted recipient.
 */
- (nullable OWSRecipientIdentity *)untrustedIdentityForSendingToRecipientId:(NSString *)recipientId;

// This method can be called from any thread.
- (void)throws_processIncomingSyncMessage:(SSKProtoVerified *)verified
                              transaction:(SDSAnyWriteTransaction *)transaction;

- (BOOL)saveRemoteIdentity:(NSData *)identityKey recipientId:(NSString *)recipientId;

- (BOOL)saveRemoteIdentity:(NSData *)identityKey
               recipientId:(NSString *)recipientId
               transaction:(SDSAnyWriteTransaction *)transaction;

- (BOOL)isTrustedIdentityKey:(NSData *)identityKey
                 recipientId:(NSString *)recipientId
                   direction:(TSMessageDirection)direction
                 transaction:(SDSAnyReadTransaction *)transaction;

- (nullable NSData *)identityKeyForRecipientId:(NSString *)recipientId transaction:(SDSAnyReadTransaction *)transaction;

#pragma mark - Debug

- (nullable ECKeyPair *)identityKeyPair;

#if DEBUG
// Clears everything except the local identity key.
- (void)clearIdentityState:(SDSAnyWriteTransaction *)transaction;
#endif

#pragma mark - Deprecated IdentityStore methods

- (nullable ECKeyPair *)identityKeyPair:(nullable id<SPKProtocolWriteContext>)protocolContext
    DEPRECATED_MSG_ATTRIBUTE("use the strongly typed `transaction:` flavor instead");

- (int)localRegistrationId:(nullable id<SPKProtocolWriteContext>)protocolContext
    DEPRECATED_MSG_ATTRIBUTE("use the strongly typed `transaction:` flavor instead");

- (BOOL)saveRemoteIdentity:(NSData *)identityKey
               recipientId:(NSString *)recipientId
           protocolContext:(nullable id<SPKProtocolWriteContext>)protocolContext
    DEPRECATED_MSG_ATTRIBUTE("use the strongly typed `transaction:` flavor instead");

- (BOOL)isTrustedIdentityKey:(NSData *)identityKey
                 recipientId:(NSString *)recipientId
                   direction:(TSMessageDirection)direction
             protocolContext:(nullable id<SPKProtocolWriteContext>)protocolContext
    DEPRECATED_MSG_ATTRIBUTE("use the strongly typed `transaction:` flavor instead");

- (nullable NSData *)identityKeyForRecipientId:(NSString *)recipientId
    DEPRECATED_MSG_ATTRIBUTE("use the strongly typed `transaction:` flavor instead");

- (nullable NSData *)identityKeyForRecipientId:(NSString *)recipientId
                               protocolContext:(nullable id<SPKProtocolReadContext>)protocolContext
    DEPRECATED_MSG_ATTRIBUTE("use the strongly typed `transaction:` flavor instead");

@end

NS_ASSUME_NONNULL_END
