//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "OWSRequestFactory.h"
#import "OWS2FAManager.h"
#import "OWSDevice.h"
#import "ProfileManagerProtocol.h"
#import "RemoteAttestation.h"
#import "SSKEnvironment.h"
#import "TSAccountManager.h"
#import "TSConstants.h"
#import "TSRequest.h"
#import <AxolotlKit/NSData+keyVersionByte.h>
#import <AxolotlKit/SignedPreKeyRecord.h>
#import <Curve25519Kit/Curve25519.h>
#import <SignalCoreKit/Cryptography.h>
#import <SignalCoreKit/NSData+OWS.h>
#import <SignalMetadataKit/SignalMetadataKit-Swift.h>
#import <SignalServiceKit/SignalServiceKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@implementation OWSRequestFactory

#pragma mark - Dependencies

+ (TSAccountManager *)tsAccountManager
{
    return TSAccountManager.sharedInstance;
}

+ (OWS2FAManager *)ows2FAManager
{
    return OWS2FAManager.sharedManager;
}

+ (id<ProfileManagerProtocol>)profileManager
{
    return SSKEnvironment.shared.profileManager;
}

+ (id<OWSUDManager>)udManager
{
    return SSKEnvironment.shared.udManager;
}

#pragma mark -

+ (TSRequest *)enable2FARequestWithPin:(NSString *)pin
{
    OWSAssertDebug(pin.length > 0);

    return [TSRequest requestWithUrl:[NSURL URLWithString:textSecure2FAAPI]
                              method:@"PUT"
                          parameters:@{
                              @"pin" : pin,
                          }];
}

+ (TSRequest *)disable2FARequest
{
    return [TSRequest requestWithUrl:[NSURL URLWithString:textSecure2FAAPI] method:@"DELETE" parameters:@{}];
}

+ (TSRequest *)enableRegistrationLockV2RequestWithToken:(NSString *)token
{
    OWSAssertDebug(token.length > 0);

    return [TSRequest requestWithUrl:[NSURL URLWithString:textSecureRegistrationLockV2API]
                              method:@"PUT"
                          parameters:@{
                                       @"registrationLock" : token,
                                       }];
}

+ (TSRequest *)disableRegistrationLockV2Request
{
    return [TSRequest requestWithUrl:[NSURL URLWithString:textSecureRegistrationLockV2API] method:@"DELETE" parameters:@{}];
}

+ (TSRequest *)acknowledgeMessageDeliveryRequestWithSource:(NSString *)source timestamp:(UInt64)timestamp
{
    OWSAssertDebug(source.length > 0);
    OWSAssertDebug(timestamp > 0);

    NSString *path = [NSString stringWithFormat:@"v1/messages/%@/%llu", source, timestamp];

    return [TSRequest requestWithUrl:[NSURL URLWithString:path] method:@"DELETE" parameters:@{}];
}

+ (TSRequest *)acknowledgeMessageDeliveryRequestWithServerGuid:(NSString *)serverGuid
{
    OWSAssertDebug(serverGuid.length > 0);

    NSString *path = [NSString stringWithFormat:@"v1/messages/uuid/%@", serverGuid];

    return [TSRequest requestWithUrl:[NSURL URLWithString:path] method:@"DELETE" parameters:@{}];
}

+ (TSRequest *)deleteDeviceRequestWithDevice:(OWSDevice *)device
{
    OWSAssertDebug(device);

    NSString *path = [NSString stringWithFormat:textSecureDevicesAPIFormat, @(device.deviceId)];

    return [TSRequest requestWithUrl:[NSURL URLWithString:path] method:@"DELETE" parameters:@{}];
}

+ (TSRequest *)deviceProvisioningCodeRequest
{
    return [TSRequest requestWithUrl:[NSURL URLWithString:textSecureDeviceProvisioningCodeAPI]
                              method:@"GET"
                          parameters:@{}];
}

+ (TSRequest *)deviceProvisioningRequestWithMessageBody:(NSData *)messageBody ephemeralDeviceId:(NSString *)deviceId
{
    OWSAssertDebug(messageBody.length > 0);
    OWSAssertDebug(deviceId.length > 0);

    NSString *path = [NSString stringWithFormat:textSecureDeviceProvisioningAPIFormat, deviceId];
    return [TSRequest requestWithUrl:[NSURL URLWithString:path]
                              method:@"PUT"
                          parameters:@{
                              @"body" : [messageBody base64EncodedString],
                          }];
}

+ (TSRequest *)getDevicesRequest
{
    NSString *path = [NSString stringWithFormat:textSecureDevicesAPIFormat, @""];
    return [TSRequest requestWithUrl:[NSURL URLWithString:path] method:@"GET" parameters:@{}];
}

+ (TSRequest *)getMessagesRequest
{
    return [TSRequest requestWithUrl:[NSURL URLWithString:@"v1/messages"] method:@"GET" parameters:@{}];
}

+ (TSRequest *)getProfileRequestWithRecipientId:(NSString *)recipientId
                                    udAccessKey:(nullable SMKUDAccessKey *)udAccessKey
{
    OWSAssertDebug(recipientId.length > 0);

    NSString *path = [NSString stringWithFormat:textSecureProfileAPIFormat, recipientId];
    TSRequest *request = [TSRequest requestWithUrl:[NSURL URLWithString:path] method:@"GET" parameters:@{}];
    if (udAccessKey != nil) {
        [self useUDAuthWithRequest:request accessKey:udAccessKey];
    }
    return request;
}

+ (TSRequest *)turnServerInfoRequest
{
    return [TSRequest requestWithUrl:[NSURL URLWithString:@"v1/accounts/turn"] method:@"GET" parameters:@{}];
}

+ (TSRequest *)allocAttachmentRequest
{
    return [TSRequest requestWithUrl:[NSURL URLWithString:@"v2/attachments/form/upload"] method:@"GET" parameters:@{}];
}

+ (TSRequest *)attachmentRequestWithAttachmentId:(UInt64)attachmentId
{
    OWSAssertDebug(attachmentId > 0);

    NSString *path = [NSString stringWithFormat:@"%@/%llu", textSecureAttachmentsAPI, attachmentId];

    return [TSRequest requestWithUrl:[NSURL URLWithString:path] method:@"GET" parameters:@{}];
}

+ (TSRequest *)availablePreKeysCountRequest
{
    NSString *path = [NSString stringWithFormat:@"%@", textSecureKeysAPI];
    return [TSRequest requestWithUrl:[NSURL URLWithString:path] method:@"GET" parameters:@{}];
}

+ (TSRequest *)contactsIntersectionRequestWithHashesArray:(NSArray<NSString *> *)hashes
{
    OWSAssertDebug(hashes.count > 0);

    NSString *path = [NSString stringWithFormat:@"%@/%@", textSecureDirectoryAPI, @"tokens"];
    return [TSRequest requestWithUrl:[NSURL URLWithString:path]
                              method:@"PUT"
                          parameters:@{
                              @"contacts" : hashes,
                          }];
}

+ (TSRequest *)currentSignedPreKeyRequest
{
    NSString *path = textSecureSignedKeysAPI;
    return [TSRequest requestWithUrl:[NSURL URLWithString:path] method:@"GET" parameters:@{}];
}

+ (TSRequest *)profileAvatarUploadFormRequest
{
    NSString *path = textSecureProfileAvatarFormAPI;
    return [TSRequest requestWithUrl:[NSURL URLWithString:path] method:@"GET" parameters:@{}];
}

+ (TSRequest *)recipientPrekeyRequestWithRecipient:(NSString *)recipientNumber
                                          deviceId:(NSString *)deviceId
                                       udAccessKey:(nullable SMKUDAccessKey *)udAccessKey
{
    OWSAssertDebug(recipientNumber.length > 0);
    OWSAssertDebug(deviceId.length > 0);

    NSString *path = [NSString stringWithFormat:@"%@/%@/%@", textSecureKeysAPI, recipientNumber, deviceId];

    TSRequest *request = [TSRequest requestWithUrl:[NSURL URLWithString:path] method:@"GET" parameters:@{}];
    if (udAccessKey != nil) {
        [self useUDAuthWithRequest:request accessKey:udAccessKey];
    }
    return request;
}

+ (TSRequest *)registerForPushRequestWithPushIdentifier:(NSString *)identifier voipIdentifier:(NSString *)voipId
{
    OWSAssertDebug(identifier.length > 0);
    OWSAssertDebug(voipId.length > 0);

    NSString *path = [NSString stringWithFormat:@"%@/%@", textSecureAccountsAPI, @"apn"];
    OWSAssertDebug(voipId);
    return [TSRequest requestWithUrl:[NSURL URLWithString:path]
                              method:@"PUT"
                          parameters:@{
                              @"apnRegistrationId" : identifier,
                              @"voipRegistrationId" : voipId ?: @"",
                          }];
}

+ (TSRequest *)updateAttributesRequest
{
    NSString *authKey = self.tsAccountManager.storedServerAuthToken;
    OWSAssertDebug(authKey.length > 0);
    NSString *_Nullable pin = [self.ows2FAManager pinCode];

    NSDictionary<NSString *, id> *accountAttributes = [self accountAttributesWithPin:pin authKey:authKey];

    return [TSRequest requestWithUrl:[NSURL URLWithString:textSecureAttributesAPI]
                              method:@"PUT"
                          parameters:accountAttributes];
}

+ (TSRequest *)unregisterAccountRequest
{
    NSString *path = [NSString stringWithFormat:@"%@/%@", textSecureAccountsAPI, @"apn"];
    return [TSRequest requestWithUrl:[NSURL URLWithString:path] method:@"DELETE" parameters:@{}];
}

+ (TSRequest *)requestPreauthChallengeRequestWithRecipientId:(NSString *)recipientId pushToken:(NSString *)pushToken
{
    OWSAssertDebug(recipientId.length > 0);
    OWSAssertDebug(pushToken.length > 0);

    NSString *path = [NSString stringWithFormat:@"v1/accounts/apn/preauth/%@/%@", pushToken, recipientId];
    NSURL *url = [NSURL URLWithString:path];

    return [TSRequest requestWithUrl:url method:@"GET" parameters:@{}];
}

+ (TSRequest *)requestVerificationCodeRequestWithPhoneNumber:(NSString *)phoneNumber
                                            preauthChallenge:(nullable NSString *)preauthChallenge
                                                captchaToken:(nullable NSString *)captchaToken
                                                   transport:(TSVerificationTransport)transport
{
    OWSAssertDebug(phoneNumber.length > 0);

    NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray new];
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"client" value:@"ios"]];

    if (captchaToken.length > 0) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"captcha" value:captchaToken]];
    }

    if (preauthChallenge.length > 0) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"challenge" value:preauthChallenge]];
    }

    NSString *path = [NSString
        stringWithFormat:@"%@/%@/code/%@", textSecureAccountsAPI, [self stringForTransport:transport], phoneNumber];

    NSURLComponents *components = [[NSURLComponents alloc] initWithString:path];
    components.queryItems = queryItems;

    TSRequest *request = [TSRequest requestWithUrl:components.URL method:@"GET" parameters:@{}];
    request.shouldHaveAuthorizationHeaders = NO;

    if (transport == TSVerificationTransportVoice) {
        NSString *_Nullable localizationHeader = [self voiceCodeLocalizationHeader];
        if (localizationHeader.length > 0) {
            [request setValue:localizationHeader forHTTPHeaderField:@"Accept-Language"];
        }
    }

    return request;
}

+ (nullable NSString *)voiceCodeLocalizationHeader
{
    NSLocale *locale = [NSLocale currentLocale];
    NSString *_Nullable languageCode = [locale objectForKey:NSLocaleLanguageCode];
    NSString *_Nullable countryCode = [locale objectForKey:NSLocaleCountryCode];

    if (!languageCode) {
        return nil;
    }

    OWSAssertDebug([languageCode rangeOfString:@"-"].location == NSNotFound);

    if (!countryCode) {
        // In the absence of a country code, just send a language code.
        return languageCode;
    }

    OWSAssertDebug(languageCode.length == 2);
    OWSAssertDebug(countryCode.length == 2);
    return [NSString stringWithFormat:@"%@-%@", languageCode, countryCode];
}

+ (NSString *)stringForTransport:(TSVerificationTransport)transport
{
    switch (transport) {
        case TSVerificationTransportSMS:
            return @"sms";
        case TSVerificationTransportVoice:
            return @"voice";
    }
}

+ (TSRequest *)verifyCodeRequestWithVerificationCode:(NSString *)verificationCode
                                           forNumber:(NSString *)phoneNumber
                                                 pin:(nullable NSString *)pin
                                             authKey:(NSString *)authKey
{
    OWSAssertDebug(verificationCode.length > 0);
    OWSAssertDebug(phoneNumber.length > 0);
    OWSAssertDebug(authKey.length > 0);

    NSString *path = [NSString stringWithFormat:@"%@/code/%@", textSecureAccountsAPI, verificationCode];

    NSMutableDictionary<NSString *, id> *accountAttributes =
        [[self accountAttributesWithPin:pin authKey:authKey] mutableCopy];
    [accountAttributes removeObjectForKey:@"AuthKey"];

    TSRequest *request =
        [TSRequest requestWithUrl:[NSURL URLWithString:path] method:@"PUT" parameters:accountAttributes];
    // The "verify code" request handles auth differently.
    request.authUsername = phoneNumber;
    request.authPassword = authKey;
    return request;
}

+ (NSDictionary<NSString *, id> *)accountAttributesWithPin:(nullable NSString *)pin
                                                   authKey:(NSString *)authKey
{
    OWSAssertDebug(authKey.length > 0);
    uint32_t registrationId = [self.tsAccountManager getOrGenerateRegistrationId];

    BOOL isManualMessageFetchEnabled = self.tsAccountManager.isManualMessageFetchEnabled;

    OWSAES256Key *profileKey = [self.profileManager localProfileKey];
    NSError *error;
    SMKUDAccessKey *_Nullable udAccessKey = [[SMKUDAccessKey alloc] initWithProfileKey:profileKey.keyData error:&error];
    if (error || udAccessKey.keyData.length < 1) {
        // Crash app if UD cannot be enabled.
        OWSFail(@"Could not determine UD access key: %@.", error);
    }
    BOOL allowUnrestrictedUD = [self.udManager shouldAllowUnrestrictedAccessLocal] && udAccessKey != nil;

    // We no longer include the signalingKey.
    NSMutableDictionary *accountAttributes = [@{
        @"AuthKey" : authKey,
        @"voice" : @(YES), // all Signal-iOS clients support voice
        @"video" : @(YES), // all Signal-iOS clients support WebRTC-based voice and video calls.
        @"fetchesMessages" : @(isManualMessageFetchEnabled), // devices that don't support push must tell the server
                                                             // they fetch messages manually
        @"registrationId" : [NSString stringWithFormat:@"%i", registrationId],
        @"unidentifiedAccessKey" : udAccessKey.keyData.base64EncodedString,
        @"unrestrictedUnidentifiedAccess" : @(allowUnrestrictedUD),
    } mutableCopy];

    NSString *_Nullable registrationLockToken = [OWSKeyBackupService deriveRegistrationLockToken];
    if (registrationLockToken.length > 0) {
        accountAttributes[@"registrationLock"] = registrationLockToken;
    } else if (pin.length > 0) {
        accountAttributes[@"pin"] = pin;
    }

    return [accountAttributes copy];
}

+ (TSRequest *)submitMessageRequestWithRecipient:(NSString *)recipientId
                                        messages:(NSArray *)messages
                                       timeStamp:(uint64_t)timeStamp
                                     udAccessKey:(nullable SMKUDAccessKey *)udAccessKey
{
    // NOTE: messages may be empty; See comments in OWSDeviceManager.
    OWSAssertDebug(recipientId.length > 0);
    OWSAssertDebug(timeStamp > 0);

    NSString *path = [textSecureMessagesAPI stringByAppendingString:recipientId];
    NSDictionary *parameters = @{
        @"messages" : messages,
        @"timestamp" : @(timeStamp),
    };

    TSRequest *request = [TSRequest requestWithUrl:[NSURL URLWithString:path] method:@"PUT" parameters:parameters];
    if (udAccessKey != nil) {
        [self useUDAuthWithRequest:request accessKey:udAccessKey];
    }
    return request;
}

+ (TSRequest *)registerSignedPrekeyRequestWithSignedPreKeyRecord:(SignedPreKeyRecord *)signedPreKey
{
    OWSAssertDebug(signedPreKey);

    NSString *path = textSecureSignedKeysAPI;
    return [TSRequest requestWithUrl:[NSURL URLWithString:path]
                              method:@"PUT"
                          parameters:[self dictionaryFromSignedPreKey:signedPreKey]];
}

+ (TSRequest *)registerPrekeysRequestWithPrekeyArray:(NSArray *)prekeys
                                         identityKey:(NSData *)identityKeyPublic
                                        signedPreKey:(SignedPreKeyRecord *)signedPreKey
{
    OWSAssertDebug(prekeys.count > 0);
    OWSAssertDebug(identityKeyPublic.length > 0);
    OWSAssertDebug(signedPreKey);

    NSString *path = textSecureKeysAPI;
    NSString *publicIdentityKey = [[identityKeyPublic prependKeyType] base64EncodedStringWithOptions:0];
    NSMutableArray *serializedPrekeyList = [NSMutableArray array];
    for (PreKeyRecord *preKey in prekeys) {
        [serializedPrekeyList addObject:[self dictionaryFromPreKey:preKey]];
    }
    return [TSRequest requestWithUrl:[NSURL URLWithString:path]
                              method:@"PUT"
                          parameters:@{
                              @"preKeys" : serializedPrekeyList,
                              @"signedPreKey" : [self dictionaryFromSignedPreKey:signedPreKey],
                              @"identityKey" : publicIdentityKey
                          }];
}

+ (NSDictionary *)dictionaryFromPreKey:(PreKeyRecord *)preKey
{
    return @{
        @"keyId" : @(preKey.Id),
        @"publicKey" : [[preKey.keyPair.publicKey prependKeyType] base64EncodedStringWithOptions:0],
    };
}

+ (NSDictionary *)dictionaryFromSignedPreKey:(SignedPreKeyRecord *)preKey
{
    return @{
        @"keyId" : @(preKey.Id),
        @"publicKey" : [[preKey.keyPair.publicKey prependKeyType] base64EncodedStringWithOptions:0],
        @"signature" : [preKey.signature base64EncodedStringWithOptions:0]
    };
}

#pragma mark - Remote Attestation

+ (TSRequest *)remoteAttestationRequestForService:(RemoteAttestationService)service
                                      withKeyPair:(ECKeyPair *)keyPair
                                      enclaveName:(NSString *)enclaveName
                                     authUsername:(NSString *)authUsername
                                     authPassword:(NSString *)authPassword
{
    OWSAssertDebug(keyPair);
    OWSAssertDebug(enclaveName.length > 0);
    OWSAssertDebug(authUsername.length > 0);
    OWSAssertDebug(authPassword.length > 0);

    NSString *path = [NSString stringWithFormat:@"v1/attestation/%@", enclaveName];
    TSRequest *request = [TSRequest requestWithUrl:[NSURL URLWithString:path]
                                            method:@"PUT"
                                        parameters:@{
                                            // We DO NOT prepend the "key type" byte.
                                            @"clientPublic" : [keyPair.publicKey base64EncodedStringWithOptions:0],
                                        }];
    request.authUsername = authUsername;
    request.authPassword = authPassword;

    switch (service) {
        case RemoteAttestationServiceContactDiscovery:
            request.customHost = contactDiscoveryURL;
            request.customCensorshipCircumventionPrefix = contactDiscoveryCensorshipPrefix;
            break;
        case RemoteAttestationServiceKeyBackup:
            request.customHost = keyBackupURL;
            request.customCensorshipCircumventionPrefix = keyBackupCensorshipPrefix;
            break;
    }

    // Don't bother with the default cookie store;
    // these cookies are ephemeral.
    //
    // NOTE: TSNetworkManager now separately disables default cookie handling for all requests.
    [request setHTTPShouldHandleCookies:NO];

    return request;
}

+ (TSRequest *)remoteAttestationAuthRequestForService:(RemoteAttestationService)service
{
    NSString *path;
    switch (service) {
        case RemoteAttestationServiceContactDiscovery:
            path = @"v1/directory/auth";
            break;
        case RemoteAttestationServiceKeyBackup:
            path = @"v1/storage/auth";
            break;
    }
    return [TSRequest requestWithUrl:[NSURL URLWithString:path] method:@"GET" parameters:@{}];
}

#pragma mark - CDS

+ (TSRequest *)cdsEnclaveRequestWithRequestId:(NSData *)requestId
                                 addressCount:(NSUInteger)addressCount
                         encryptedAddressData:(NSData *)encryptedAddressData
                                      cryptIv:(NSData *)cryptIv
                                     cryptMac:(NSData *)cryptMac
                                  enclaveName:(NSString *)enclaveName
                                 authUsername:(NSString *)authUsername
                                 authPassword:(NSString *)authPassword
                                      cookies:(NSArray<NSHTTPCookie *> *)cookies
{
    NSString *path = [NSString stringWithFormat:@"v1/discovery/%@", enclaveName];

    TSRequest *request = [TSRequest requestWithUrl:[NSURL URLWithString:path]
                                            method:@"PUT"
                                        parameters:@{
                                            @"requestId" : requestId.base64EncodedString,
                                            @"addressCount" : @(addressCount),
                                            @"data" : encryptedAddressData.base64EncodedString,
                                            @"iv" : cryptIv.base64EncodedString,
                                            @"mac" : cryptMac.base64EncodedString,
                                        }];

    request.authUsername = authUsername;
    request.authPassword = authPassword;
    request.customHost = contactDiscoveryURL;
    request.customCensorshipCircumventionPrefix = contactDiscoveryCensorshipPrefix;

    // Don't bother with the default cookie store;
    // these cookies are ephemeral.
    //
    // NOTE: TSNetworkManager now separately disables default cookie handling for all requests.
    [request setHTTPShouldHandleCookies:NO];
    // Set the cookie header.
    OWSAssertDebug(request.allHTTPHeaderFields.count == 0);
    [request setAllHTTPHeaderFields:[NSHTTPCookie requestHeaderFieldsWithCookies:cookies]];

    return request;
}

+ (TSRequest *)cdsFeedbackRequestWithStatus:(NSString *)status
                                     reason:(nullable NSString *)reason
{

    NSDictionary<NSString *, NSString *> *parameters;
    if (reason == nil) {
        parameters = @{};
    } else {
        const NSUInteger kServerReasonLimit = 1000;
        NSString *limitedReason;
        if (reason.length < kServerReasonLimit) {
            limitedReason = reason;
        } else {
            OWSFailDebug(@"failure: reason should be under 1000");
            limitedReason = [reason substringToIndex:kServerReasonLimit - 1];
        }
        parameters = @{ @"reason": limitedReason };
    }
    NSString *path = [NSString stringWithFormat:@"v1/directory/feedback-v3/%@", status];
    return [TSRequest requestWithUrl:[NSURL URLWithString:path] method:@"PUT" parameters:parameters];
}

#pragma mark - KBS

+ (TSRequest *)kbsEnclaveNonceRequestWithEnclaveName:(NSString *)enclaveName
                                        authUsername:(NSString *)authUsername
                                        authPassword:(NSString *)authPassword
                                             cookies:(NSArray<NSHTTPCookie *> *)cookies
{
    NSString *path = [NSString stringWithFormat:@"v1/nonce/%@", enclaveName];

    TSRequest *request = [TSRequest requestWithUrl:[NSURL URLWithString:path] method:@"GET" parameters:@{}];

    request.authUsername = authUsername;
    request.authPassword = authPassword;
    request.customHost = keyBackupURL;
    request.customCensorshipCircumventionPrefix = keyBackupCensorshipPrefix;

    // Don't bother with the default cookie store;
    // these cookies are ephemeral.
    //
    // NOTE: TSNetworkManager now separately disables default cookie handling for all requests.
    [request setHTTPShouldHandleCookies:NO];
    // Set the cookie header.
    OWSAssertDebug(request.allHTTPHeaderFields.count == 0);
    [request setAllHTTPHeaderFields:[NSHTTPCookie requestHeaderFieldsWithCookies:cookies]];

    return request;
}

+ (TSRequest *)kbsEnclaveRequestWithRequestId:(NSData *)requestId
                                         data:(NSData *)data
                                      cryptIv:(NSData *)cryptIv
                                     cryptMac:(NSData *)cryptMac
                                  enclaveName:(NSString *)enclaveName
                                 authUsername:(NSString *)authUsername
                                 authPassword:(NSString *)authPassword
                                      cookies:(NSArray<NSHTTPCookie *> *)cookies
{
    NSString *path = [NSString stringWithFormat:@"v1/backup/%@", enclaveName];

    TSRequest *request = [TSRequest requestWithUrl:[NSURL URLWithString:path]
                                            method:@"PUT"
                                        parameters:@{
                                            @"requestId" : requestId.base64EncodedString,
                                            @"data" : data.base64EncodedString,
                                            @"iv" : cryptIv.base64EncodedString,
                                            @"mac" : cryptMac.base64EncodedString,
                                        }];

    request.authUsername = authUsername;
    request.authPassword = authPassword;
    request.customHost = keyBackupURL;
    request.customCensorshipCircumventionPrefix = keyBackupCensorshipPrefix;

    // Don't bother with the default cookie store;
    // these cookies are ephemeral.
    //
    // NOTE: TSNetworkManager now separately disables default cookie handling for all requests.
    [request setHTTPShouldHandleCookies:NO];
    // Set the cookie header.
    OWSAssertDebug(request.allHTTPHeaderFields.count == 0);
    [request setAllHTTPHeaderFields:[NSHTTPCookie requestHeaderFieldsWithCookies:cookies]];

    return request;
}

#pragma mark - UD

+ (TSRequest *)udSenderCertificateRequest
{
    NSString *path = @"v1/certificate/delivery";
    return [TSRequest requestWithUrl:[NSURL URLWithString:path] method:@"GET" parameters:@{}];
}

+ (void)useUDAuthWithRequest:(TSRequest *)request accessKey:(SMKUDAccessKey *)udAccessKey
{
    OWSAssertDebug(request);
    OWSAssertDebug(udAccessKey);

    // Suppress normal auth headers.
    request.shouldHaveAuthorizationHeaders = NO;

    // Add UD auth header.
    [request setValue:[udAccessKey.keyData base64EncodedString] forHTTPHeaderField:@"Unidentified-Access-Key"];

    request.isUDRequest = YES;
}

@end

NS_ASSUME_NONNULL_END
