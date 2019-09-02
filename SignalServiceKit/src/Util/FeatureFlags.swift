//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

/// By centralizing feature flags here and documenting their rollout plan, it's easier to review
/// which feature flags are in play.
@objc(SSKFeatureFlags)
public class FeatureFlags: NSObject {

    @objc
    public static var conversationSearch: Bool {
        return false
    }

    @objc
    public static var useGRDB: Bool {
        return false
    }

    @objc
    public static let shouldPadAllOutgoingAttachments = false

    // Temporary flag helpful for development, where blowing away GRDB and re-running
    // the migration every launch is helpful.
    @objc
    public static let grdbMigratesFreshDBEveryLaunch = true

    @objc
    public static let stickerReceive = true

    // Don't consult this flag directly; instead consult
    // StickerManager.isStickerSendEnabled.  Sticker sending is
    // auto-enabled once the user receives any sticker content.
    @objc
    public static var stickerSend: Bool {
        return OWSIsDebugBuild()
    }

    @objc
    public static let stickerSharing = false

    @objc
    public static let stickerAutoEnable = true

    @objc
    public static let stickerSearch = false

    @objc
    public static let stickerPackOrdering = false

    // Don't enable this flag until the Desktop changes have been in production for a while.
    @objc
    public static let strictSyncTranscriptTimestamps = false

    // This shouldn't be enabled in production until the receive side has been
    // in production for "long enough".
    @objc
    public static let viewOnceSending = false

    // This shouldn't be enabled _in production_ but it should be enabled in beta and developer builds.
    private static let isBetaBuild = false

    // Don't enable this flag in production.
    @objc
    public static let strictYDBExtensions = isBetaBuild

    // Don't enable this flag in production.
    @objc
    public static let onlyModernNotificationClearance = isBetaBuild

    @objc
    public static let registrationLockV2 = false
}
