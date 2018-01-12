import Foundation
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import LegacyComponents

private final class ChannelInfoControllerArguments {
    let account: Account
    let avatarAndNameInfoContext: ItemListAvatarAndNameInfoItemContext
    let tapAvatarAction: () -> Void
    let changeProfilePhoto: () -> Void
    let updateEditingName: (ItemListAvatarAndNameInfoItemName) -> Void
    let updateEditingDescriptionText: (String) -> Void
    let openChannelTypeSetup: () -> Void
    let changeNotificationMuteSettings: () -> Void
    let changeNotificationSoundSettings: () -> Void
    let openSharedMedia: () -> Void
    let openAdmins: () -> Void
    let openMembers: () -> Void
    let openBanned: () -> Void
    let reportChannel: () -> Void
    let leaveChannel: () -> Void
    let deleteChannel: () -> Void
    let displayAddressNameContextMenu: (String) -> Void
    let displayAboutContextMenu: (String) -> Void
    let aboutLinkAction: (TextLinkItemActionType, TextLinkItem) -> Void
    
    init(account: Account, avatarAndNameInfoContext: ItemListAvatarAndNameInfoItemContext, tapAvatarAction: @escaping () -> Void, changeProfilePhoto: @escaping () -> Void, updateEditingName: @escaping (ItemListAvatarAndNameInfoItemName) -> Void, updateEditingDescriptionText: @escaping (String) -> Void, openChannelTypeSetup: @escaping () -> Void, changeNotificationMuteSettings: @escaping () -> Void, changeNotificationSoundSettings: @escaping () -> Void, openSharedMedia: @escaping () -> Void, openAdmins: @escaping () -> Void, openMembers: @escaping () -> Void, openBanned: @escaping () -> Void, reportChannel: @escaping () -> Void, leaveChannel: @escaping () -> Void, deleteChannel: @escaping () -> Void, displayAddressNameContextMenu: @escaping (String) -> Void, displayAboutContextMenu: @escaping (String) -> Void, aboutLinkAction: @escaping (TextLinkItemActionType, TextLinkItem) -> Void) {
        self.account = account
        self.avatarAndNameInfoContext = avatarAndNameInfoContext
        self.tapAvatarAction = tapAvatarAction
        self.changeProfilePhoto = changeProfilePhoto
        self.updateEditingName = updateEditingName
        self.updateEditingDescriptionText = updateEditingDescriptionText
        self.openChannelTypeSetup = openChannelTypeSetup
        self.changeNotificationMuteSettings = changeNotificationMuteSettings
        self.changeNotificationSoundSettings = changeNotificationSoundSettings
        self.openSharedMedia = openSharedMedia
        self.openAdmins = openAdmins
        self.openMembers = openMembers
        self.openBanned = openBanned
        self.reportChannel = reportChannel
        self.leaveChannel = leaveChannel
        self.deleteChannel = deleteChannel
        self.displayAddressNameContextMenu = displayAddressNameContextMenu
        self.displayAboutContextMenu = displayAboutContextMenu
        self.aboutLinkAction = aboutLinkAction
    }
}

private enum ChannelInfoSection: ItemListSectionId {
    case info
    case sharedMediaAndNotifications
    case members
    case reportOrLeave
}

private enum ChannelInfoEntryTag {
    case about
}

private enum ChannelInfoEntry: ItemListNodeEntry {
    case info(PresentationTheme, PresentationStrings, peer: Peer?, cachedData: CachedPeerData?, state: ItemListAvatarAndNameInfoItemState, updatingAvatar: ItemListAvatarAndNameInfoItemUpdatingAvatar?)
    case about(theme: PresentationTheme, text: String, value: String)
    case addressName(theme: PresentationTheme, text: String, value: String)
    case channelPhotoSetup(theme: PresentationTheme, text: String)
    case channelTypeSetup(theme: PresentationTheme, text: String, value: String)
    case channelDescriptionSetup(theme: PresentationTheme, placeholder: String, value: String)
    case admins(theme: PresentationTheme, text: String, value: String)
    case members(theme: PresentationTheme, text: String, value: String)
    case banned(theme: PresentationTheme, text: String, value: String)
    case notifications(theme: PresentationTheme, text: String, value: String)
    case notificationSound(theme: PresentationTheme, text: String, value: String)
    case sharedMedia(theme: PresentationTheme, text: String)
    case report(theme: PresentationTheme, text: String)
    case leave(theme: PresentationTheme, text: String)
    case deleteChannel(theme: PresentationTheme, text: String)
    
    var section: ItemListSectionId {
        switch self {
            case .info, .about, .addressName, .channelPhotoSetup, .channelTypeSetup, .channelDescriptionSetup:
                return ChannelInfoSection.info.rawValue
            case .admins, .members, .banned:
                return ChannelInfoSection.members.rawValue
            case .sharedMedia, .notifications, .notificationSound:
                return ChannelInfoSection.sharedMediaAndNotifications.rawValue
            case .report, .leave, .deleteChannel:
                return ChannelInfoSection.reportOrLeave.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
            case .info:
                return 0
            case .about:
                return 1
            case .addressName:
                return 2
            case .channelPhotoSetup:
                return 3
            case .channelDescriptionSetup:
                return 4
            case .channelTypeSetup:
                return 5
            case .admins:
                return 6
            case .members:
                return 7
            case .banned:
                return 8
            case .notifications:
                return 9
            case .notificationSound:
                return 10
            case .sharedMedia:
                return 11
            case .report:
                return 12
            case .leave:
                return 13
            case .deleteChannel:
                return 14
        }
    }
    
    static func ==(lhs: ChannelInfoEntry, rhs: ChannelInfoEntry) -> Bool {
        switch lhs {
            case let .info(lhsTheme, lhsStrings, lhsPeer, lhsCachedData, lhsState, lhsUpdatingAvatar):
                if case let .info(rhsTheme, rhsStrings, rhsPeer, rhsCachedData, rhsState, rhsUpdatingAvatar) = rhs {
                    if lhsTheme !== rhsTheme {
                        return false
                    }
                    if lhsStrings !== rhsStrings {
                        return false
                    }
                    if let lhsPeer = lhsPeer, let rhsPeer = rhsPeer {
                        if !lhsPeer.isEqual(rhsPeer) {
                            return false
                        }
                    } else if (lhsPeer == nil) != (rhsPeer != nil) {
                        return false
                    }
                    if let lhsCachedData = lhsCachedData, let rhsCachedData = rhsCachedData {
                        if !lhsCachedData.isEqual(to: rhsCachedData) {
                            return false
                        }
                    } else if (lhsCachedData != nil) != (rhsCachedData != nil) {
                        return false
                    }
                    if lhsState != rhsState {
                        return false
                    }
                    if lhsUpdatingAvatar != rhsUpdatingAvatar {
                        return false
                    }
                    return true
                } else {
                    return false
                }
            case let .about(lhsTheme, lhsText, lhsValue):
                if case let .about(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .addressName(lhsTheme, lhsText, lhsValue):
                if case let .addressName(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .channelPhotoSetup(lhsTheme, lhsText):
                if case let .channelPhotoSetup(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .channelTypeSetup(lhsTheme, lhsText, lhsValue):
                if case let .channelTypeSetup(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .channelDescriptionSetup(lhsTheme, lhsPlaceholder, lhsValue):
                if case let .channelDescriptionSetup(rhsTheme, rhsPlaceholder, rhsValue) = rhs, lhsTheme === rhsTheme, lhsPlaceholder == rhsPlaceholder, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .admins(lhsTheme, lhsText, lhsValue):
                if case let .admins(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .members(lhsTheme, lhsText, lhsValue):
                if case let .members(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .banned(lhsTheme, lhsText, lhsValue):
                if case let .banned(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .sharedMedia(lhsTheme, lhsText):
                if case let .sharedMedia(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .report(lhsTheme, lhsText):
                if case let .report(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .leave(lhsTheme, lhsText):
                if case let .leave(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .deleteChannel(lhsTheme, lhsText):
                if case let .deleteChannel(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .notifications(lhsTheme, lhsText, lhsValue):
                if case let .notifications(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .notificationSound(lhsTheme, lhsText, lhsValue):
                if case let .notificationSound(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
        }
    }
    
    static func <(lhs: ChannelInfoEntry, rhs: ChannelInfoEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(_ arguments: ChannelInfoControllerArguments) -> ListViewItem {
        switch self {
            case let .info(theme, strings, peer, cachedData, state, updatingAvatar):
                return ItemListAvatarAndNameInfoItem(account: arguments.account, theme: theme, strings: strings, mode: .generic, peer: peer, presence: nil, cachedData: cachedData, state: state, sectionId: self.section, style: .plain, editingNameUpdated: { editingName in
                    arguments.updateEditingName(editingName)
                }, avatarTapped: {
                    arguments.tapAvatarAction()
                }, context: arguments.avatarAndNameInfoContext, updatingImage: updatingAvatar)
            case let .about(theme, text, value):
                return ItemListTextWithLabelItem(theme: theme, label: text, text: value, enabledEntitiyTypes: [.url, .mention, .hashtag], multiline: true, sectionId: self.section, action: nil, longTapAction: {
                    arguments.displayAboutContextMenu(value)
                }, linkItemAction: { action, itemLink in
                    arguments.aboutLinkAction(action, itemLink)
                }, tag: ChannelInfoEntryTag.about)
            case let .addressName(theme, text, value):
                return ItemListTextWithLabelItem(theme: theme, label: text, text: "https://t.me/\(value)", enabledEntitiyTypes: [], multiline: false, sectionId: self.section, action: {
                    arguments.displayAddressNameContextMenu("https://t.me/\(value)")
                })
            case let .channelPhotoSetup(theme, text):
                return ItemListActionItem(theme: theme, title: text, kind: .generic, alignment: .natural, sectionId: self.section, style: .plain, action: {
                    arguments.changeProfilePhoto()
                })
            case let .channelTypeSetup(theme, text, value):
                return ItemListDisclosureItem(theme: theme, title: text, label: value, sectionId: self.section, style: .plain, action: {
                    arguments.openChannelTypeSetup()
                })
            case let .channelDescriptionSetup(theme, placeholder, value):
                return ItemListMultilineInputItem(theme: theme, text: value, placeholder: placeholder, maxLength: 1000, sectionId: self.section, style: .plain, textUpdated: { updatedText in
                    arguments.updateEditingDescriptionText(updatedText)
                }, action: {
                    
                })
            case let .admins(theme, text, value):
                return ItemListDisclosureItem(theme: theme, title: text, label: value, sectionId: self.section, style: .plain, action: {
                    arguments.openAdmins()
                })
            case let .members(theme, text, value):
                return ItemListDisclosureItem(theme: theme, title: text, label: value, sectionId: self.section, style: .plain, action: {
                    arguments.openMembers()
                })
            case let .banned(theme, text, value):
                return ItemListDisclosureItem(theme: theme, title: text, label: value, sectionId: self.section, style: .plain, action: {
                    arguments.openBanned()
                })
            case let .sharedMedia(theme, text):
                return ItemListDisclosureItem(theme: theme, title: text, label: "", sectionId: self.section, style: .plain, action: {
                    arguments.openSharedMedia()
                })
            case let .notifications(theme, text, value):
                return ItemListDisclosureItem(theme: theme, title: text, label: value, sectionId: self.section, style: .plain, action: {
                    arguments.changeNotificationMuteSettings()
                })
            case let .notificationSound(theme, text, value):
                return ItemListDisclosureItem(theme: theme, title: text, label: value, sectionId: self.section, style: .plain, action: {
                    arguments.changeNotificationSoundSettings()
                })
            case let .report(theme, text):
                return ItemListActionItem(theme: theme, title: text, kind: .generic, alignment: .natural, sectionId: self.section, style: .plain, action: {
                    arguments.reportChannel()
                })
            case let .leave(theme, text):
                return ItemListActionItem(theme: theme, title: text, kind: .destructive, alignment: .natural, sectionId: self.section, style: .plain, action: {
                    arguments.leaveChannel()
                })
            case let .deleteChannel(theme, text):
                return ItemListActionItem(theme: theme, title: text, kind: .destructive, alignment: .natural, sectionId: self.section, style: .plain, action: {
                    arguments.deleteChannel()
                })
        }
    }
}

private struct ChannelInfoState: Equatable {
    let updatingAvatar: ItemListAvatarAndNameInfoItemUpdatingAvatar?
    let editingState: ChannelInfoEditingState?
    let savingData: Bool
    
    init(updatingAvatar: ItemListAvatarAndNameInfoItemUpdatingAvatar?, editingState: ChannelInfoEditingState?, savingData: Bool) {
        self.updatingAvatar = updatingAvatar
        self.editingState = editingState
        self.savingData = savingData
    }
    
    init() {
        self.updatingAvatar = nil
        self.editingState = nil
        self.savingData = false
    }
    
    static func ==(lhs: ChannelInfoState, rhs: ChannelInfoState) -> Bool {
        if lhs.updatingAvatar != rhs.updatingAvatar {
            return false
        }
        if lhs.editingState != rhs.editingState {
            return false
        }
        if lhs.savingData != rhs.savingData {
            return false
        }
        return true
    }
    
    func withUpdatedUpdatingAvatar(_ updatingAvatar: ItemListAvatarAndNameInfoItemUpdatingAvatar?) -> ChannelInfoState {
        return ChannelInfoState(updatingAvatar: updatingAvatar, editingState: self.editingState, savingData: self.savingData)
    }
    
    func withUpdatedEditingState(_ editingState: ChannelInfoEditingState?) -> ChannelInfoState {
        return ChannelInfoState(updatingAvatar: self.updatingAvatar, editingState: editingState, savingData: self.savingData)
    }
    
    func withUpdatedSavingData(_ savingData: Bool) -> ChannelInfoState {
        return ChannelInfoState(updatingAvatar: self.updatingAvatar, editingState: self.editingState, savingData: savingData)
    }
}

private struct ChannelInfoEditingState: Equatable {
    let editingName: ItemListAvatarAndNameInfoItemName?
    let editingDescriptionText: String
    
    func withUpdatedEditingDescriptionText(_ editingDescriptionText: String) -> ChannelInfoEditingState {
        return ChannelInfoEditingState(editingName: self.editingName, editingDescriptionText: editingDescriptionText)
    }
    
    static func ==(lhs: ChannelInfoEditingState, rhs: ChannelInfoEditingState) -> Bool {
        if lhs.editingName != rhs.editingName {
            return false
        }
        if lhs.editingDescriptionText != rhs.editingDescriptionText {
            return false
        }
        return true
    }
}

private func channelInfoEntries(account: Account, presentationData: PresentationData, view: PeerView, globalNotificationSettings: GlobalNotificationSettings, state: ChannelInfoState) -> [ChannelInfoEntry] {
    var entries: [ChannelInfoEntry] = []
    
    if let peer = view.peers[view.peerId] as? TelegramChannel {
        let canEditChannel = peer.hasAdminRights(.canChangeInfo)
        let canEditMembers = peer.hasAdminRights(.canBanUsers)
        
        let infoState = ItemListAvatarAndNameInfoItemState(editingName: canEditChannel ? state.editingState?.editingName : nil, updatingName: nil)
        entries.append(.info(presentationData.theme, presentationData.strings, peer: peer, cachedData: view.cachedData, state: infoState, updatingAvatar: state.updatingAvatar))
        
        if state.editingState != nil && canEditChannel {
            entries.append(.channelPhotoSetup(theme: presentationData.theme, text: presentationData.strings.Channel_UpdatePhotoItem))
        }
        
        if let cachedChannelData = view.cachedData as? CachedChannelData {
            if let editingState = state.editingState, canEditChannel {
                entries.append(.channelDescriptionSetup(theme: presentationData.theme, placeholder: presentationData.strings.Channel_Edit_AboutItem, value: editingState.editingDescriptionText))
            } else {
                if let about = cachedChannelData.about, !about.isEmpty {
                    entries.append(.about(theme: presentationData.theme, text: presentationData.strings.Channel_AboutItem, value: about))
                }
            }
        }
        
        if state.editingState != nil && peer.flags.contains(.isCreator) {
            let linkText: String
            if let username = peer.username {
                linkText = "@\(username)"
            } else {
                linkText = presentationData.strings.Channel_Setup_TypePrivate
            }
            entries.append(.channelTypeSetup(theme: presentationData.theme, text: presentationData.strings.Channel_Edit_LinkItem, value: linkText))
        } else if let username = peer.username, !username.isEmpty {
            entries.append(.addressName(theme: presentationData.theme, text: presentationData.strings.Channel_LinkItem, value: username))
        }
        
        if let cachedChannelData = view.cachedData as? CachedChannelData {
            if state.editingState != nil && canEditMembers {
                if let kickedCount = cachedChannelData.participantsSummary.kickedCount {
                    entries.append(.banned(theme: presentationData.theme, text: presentationData.strings.Channel_Info_Banned, value: "\(kickedCount)"))
                }
            } else {
                if peer.adminRights != nil || peer.flags.contains(.isCreator) {
                    if let adminCount = cachedChannelData.participantsSummary.adminCount {
                        entries.append(.admins(theme: presentationData.theme, text: presentationData.strings.Channel_Info_Management, value: "\(adminCount)"))
                    }
                    if let memberCount = cachedChannelData.participantsSummary.memberCount {
                        entries.append(.members(theme: presentationData.theme, text: presentationData.strings.Channel_Info_Members, value: "\(memberCount)"))
                    }
                }
            }
        }
        
        if let notificationSettings = view.notificationSettings as? TelegramPeerNotificationSettings {
            let notificationsText: String
            if case .muted = notificationSettings.muteState {
                notificationsText = presentationData.strings.UserInfo_NotificationsDisabled
            } else {
                notificationsText = presentationData.strings.UserInfo_NotificationsEnabled
            }
            entries.append(ChannelInfoEntry.notifications(theme: presentationData.theme, text: presentationData.strings.GroupInfo_Notifications, value: notificationsText))
        }
        if state.editingState != nil {
            var messageSound: PeerMessageSound = .default
            if let settings = view.notificationSettings as? TelegramPeerNotificationSettings {
                messageSound = settings.messageSound
            }
            
            entries.append(ChannelInfoEntry.notificationSound(theme: presentationData.theme, text: presentationData.strings.GroupInfo_Sound, value: localizedPeerNotificationSoundString(strings: presentationData.strings, sound: messageSound, default: globalNotificationSettings.effective.groupChats.sound)))
        } else {
            entries.append(ChannelInfoEntry.sharedMedia(theme: presentationData.theme, text: presentationData.strings.GroupInfo_SharedMedia))
        }
        
        if peer.flags.contains(.isCreator) {
            if state.editingState != nil {
                entries.append(ChannelInfoEntry.deleteChannel(theme: presentationData.theme, text: presentationData.strings.ChannelInfo_DeleteChannel))
            }
        } else {
            entries.append(ChannelInfoEntry.report(theme: presentationData.theme, text: presentationData.strings.ReportPeer_Report))
            if peer.participationStatus == .member {
                entries.append(ChannelInfoEntry.leave(theme: presentationData.theme, text: presentationData.strings.Channel_LeaveChannel))
            }
        }
    }
    
    return entries
}

private func valuesRequiringUpdate(state: ChannelInfoState, view: PeerView) -> (title: String?, description: String?) {
    if let peer = view.peers[view.peerId] as? TelegramChannel {
        var titleValue: String?
        var descriptionValue: String?
        if let editingState = state.editingState {
            if let title = editingState.editingName?.composedTitle, title != peer.title {
                titleValue = title
            }
            if let cachedData = view.cachedData as? CachedChannelData {
                if let about = cachedData.about {
                    if about != editingState.editingDescriptionText {
                        descriptionValue = editingState.editingDescriptionText
                    }
                } else if !editingState.editingDescriptionText.isEmpty {
                    descriptionValue = editingState.editingDescriptionText
                }
            }
        }
        
        return (titleValue, descriptionValue)
    } else {
        return (nil, nil)
    }
}

public func channelInfoController(account: Account, peerId: PeerId) -> ViewController {
    let statePromise = ValuePromise(ChannelInfoState(), ignoreRepeated: true)
    let stateValue = Atomic(value: ChannelInfoState())
    let updateState: ((ChannelInfoState) -> ChannelInfoState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }
    
    var pushControllerImpl: ((ViewController) -> Void)?
    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    var popToRootControllerImpl: (() -> Void)?
    
    let actionsDisposable = DisposableSet()
    
    if peerId.namespace == Namespaces.Peer.CloudChannel {
        actionsDisposable.add(account.viewTracker.updatedCachedChannelParticipants(peerId, forceImmediateUpdate: true).start())
    }
    
    let updatePeerNameDisposable = MetaDisposable()
    actionsDisposable.add(updatePeerNameDisposable)
    
    let updatePeerDescriptionDisposable = MetaDisposable()
    actionsDisposable.add(updatePeerDescriptionDisposable)
    
    let changeMuteSettingsDisposable = MetaDisposable()
    actionsDisposable.add(changeMuteSettingsDisposable)
    
    let hiddenAvatarRepresentationDisposable = MetaDisposable()
    actionsDisposable.add(hiddenAvatarRepresentationDisposable)
    
    let updateAvatarDisposable = MetaDisposable()
    actionsDisposable.add(updateAvatarDisposable)
    let currentAvatarMixin = Atomic<TGMediaAvatarMenuMixin?>(value: nil)
    
    let navigateDisposable = MetaDisposable()
    actionsDisposable.add(navigateDisposable)
    
    var avatarGalleryTransitionArguments: ((AvatarGalleryEntry) -> GalleryTransitionArguments?)?
    let avatarAndNameInfoContext = ItemListAvatarAndNameInfoItemContext()
    var updateHiddenAvatarImpl: (() -> Void)?
    
    var displayAboutContextMenuImpl: ((String) -> Void)?
    var aboutLinkActionImpl: ((TextLinkItemActionType, TextLinkItem) -> Void)?
    
    let arguments = ChannelInfoControllerArguments(account: account, avatarAndNameInfoContext: avatarAndNameInfoContext, tapAvatarAction: {
        let _ = (account.postbox.loadedPeerWithId(peerId) |> take(1) |> deliverOnMainQueue).start(next: { peer in
            if peer.profileImageRepresentations.isEmpty {
                return
            }
            
            let galleryController = AvatarGalleryController(account: account, peer: peer, replaceRootController: { controller, ready in
                
            })
            hiddenAvatarRepresentationDisposable.set((galleryController.hiddenMedia |> deliverOnMainQueue).start(next: { entry in
                avatarAndNameInfoContext.hiddenAvatarRepresentation = entry?.representations.first
                updateHiddenAvatarImpl?()
            }))
            presentControllerImpl?(galleryController, AvatarGalleryControllerPresentationArguments(transitionArguments: { entry in
                return avatarGalleryTransitionArguments?(entry)
            }))
        })
    }, changeProfilePhoto: {
        let _ = (account.postbox.modify { modifier -> Peer? in
            return modifier.getPeer(peerId)
            } |> deliverOnMainQueue).start(next: { peer in
                let presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
                
                let legacyController = LegacyController(presentation: .custom, theme: presentationData.theme)
                legacyController.statusBar.statusBarStyle = .Ignore
                
                let emptyController = LegacyEmptyController(context: legacyController.context)!
                let navigationController = makeLegacyNavigationController(rootController: emptyController)
                navigationController.setNavigationBarHidden(true, animated: false)
                navigationController.navigationBar.transform = CGAffineTransform(translationX: -1000.0, y: 0.0)
                
                legacyController.bind(controller: navigationController)
                
                presentControllerImpl?(legacyController, nil)
                
                var hasPhotos = false
                if let peer = peer, !peer.profileImageRepresentations.isEmpty {
                    hasPhotos = true
                }
                
                let mixin = TGMediaAvatarMenuMixin(context: legacyController.context, parentController: emptyController, hasDeleteButton: hasPhotos, personalPhoto: true, saveEditedPhotos: false, saveCapturedMedia: false)!
                let _ = currentAvatarMixin.swap(mixin)
                mixin.didFinishWithImage = { image in
                    if let image = image {
                        if let data = UIImageJPEGRepresentation(image, 0.6) {
                            let resource = LocalFileMediaResource(fileId: arc4random64())
                            account.postbox.mediaBox.storeResourceData(resource.id, data: data)
                            let representation = TelegramMediaImageRepresentation(dimensions: CGSize(width: 640.0, height: 640.0), resource: resource)
                            updateState {
                                $0.withUpdatedUpdatingAvatar(.image(representation))
                            }
                            updateAvatarDisposable.set((updatePeerPhoto(account: account, peerId: peerId, resource: resource) |> deliverOnMainQueue).start(next: { result in
                                switch result {
                                case .complete:
                                    updateState {
                                        $0.withUpdatedUpdatingAvatar(nil)
                                    }
                                case .progress:
                                    break
                                }
                            }))
                        }
                    }
                }
                mixin.didFinishWithDelete = {
                    let _ = currentAvatarMixin.swap(nil)
                    updateState {
                        if let profileImage = peer?.smallProfileImage {
                            return $0.withUpdatedUpdatingAvatar(.image(profileImage))
                        } else {
                            return $0.withUpdatedUpdatingAvatar(.none)
                        }
                    }
                    updateAvatarDisposable.set((updatePeerPhoto(account: account, peerId: peerId, resource: nil) |> deliverOnMainQueue).start(next: { result in
                        switch result {
                            case .complete:
                                updateState {
                                    $0.withUpdatedUpdatingAvatar(nil)
                                }
                            case .progress:
                                break
                        }
                    }))
                }
                mixin.didDismiss = { [weak legacyController] in
                    let _ = currentAvatarMixin.swap(nil)
                    legacyController?.dismiss()
                }
                let menuController = mixin.present()
                if let menuController = menuController {
                    menuController.customRemoveFromParentViewController = { [weak legacyController] in
                        legacyController?.dismiss()
                    }
                }
            })
    }, updateEditingName: { editingName in
        updateState { state in
            if let editingState = state.editingState {
                return state.withUpdatedEditingState(ChannelInfoEditingState(editingName: editingName, editingDescriptionText: editingState.editingDescriptionText))
            } else {
                return state
            }
        }
    }, updateEditingDescriptionText: { text in
        updateState { state in
            if let editingState = state.editingState {
                return state.withUpdatedEditingState(editingState.withUpdatedEditingDescriptionText(text))
            }
            return state
        }
    }, openChannelTypeSetup: {
        presentControllerImpl?(channelVisibilityController(account: account, peerId: peerId, mode: .generic), ViewControllerPresentationArguments(presentationAnimation: ViewControllerPresentationAnimation.modalSheet))
    }, changeNotificationMuteSettings: {
        let presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
        let controller = ActionSheetController(presentationTheme: presentationData.theme)
        let dismissAction: () -> Void = { [weak controller] in
            controller?.dismissAnimated()
        }
        let notificationAction: (Int32) -> Void = {  muteUntil in
            let muteState: PeerMuteState
            if muteUntil <= 0 {
                muteState = .unmuted
            } else if muteUntil == Int32.max {
                muteState = .muted(until: Int32.max)
            } else {
                muteState = .muted(until: Int32(Date().timeIntervalSince1970) + muteUntil)
            }
            changeMuteSettingsDisposable.set(changePeerNotificationSettings(account: account, peerId: peerId, settings: TelegramPeerNotificationSettings(muteState: muteState, messageSound: PeerMessageSound.bundledModern(id: 0))).start())
        }
        var items: [ActionSheetItem] = []
        items.append(ActionSheetButtonItem(title: presentationData.strings.UserInfo_NotificationsEnable, action: {
            dismissAction()
            notificationAction(0)
        }))
        let intervals: [Int32] = [
            1 * 60 * 60,
            8 * 60 * 60,
            2 * 24 * 60 * 60
        ]
        for value in intervals {
            items.append(ActionSheetButtonItem(title: muteForIntervalString(strings: presentationData.strings, value: value), action: {
                dismissAction()
                notificationAction(value)
            }))
        }
        items.append(ActionSheetButtonItem(title: presentationData.strings.UserInfo_NotificationsDisable, action: {
            dismissAction()
            notificationAction(Int32.max)
        }))
        
        controller.setItemGroups([
            ActionSheetItemGroup(items: items),
            ActionSheetItemGroup(items: [ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, action: { dismissAction() })])
        ])
        presentControllerImpl?(controller, ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
    }, changeNotificationSoundSettings: {
        let _ = (account.postbox.modify { modifier -> (TelegramPeerNotificationSettings, GlobalNotificationSettings) in
            let peerSettings: TelegramPeerNotificationSettings = (modifier.getPeerNotificationSettings(peerId) as? TelegramPeerNotificationSettings) ?? TelegramPeerNotificationSettings.defaultSettings
            let globalSettings: GlobalNotificationSettings = (modifier.getPreferencesEntry(key: PreferencesKeys.globalNotifications) as? GlobalNotificationSettings) ?? GlobalNotificationSettings.defaultSettings
            return (peerSettings, globalSettings)
        } |> deliverOnMainQueue).start(next: { settings in
            let controller = notificationSoundSelectionController(account: account, isModal: true, currentSound: settings.0.messageSound, defaultSound: settings.1.effective.privateChats.sound, completion: { sound in
                let _ = updatePeerNotificationSoundInteractive(account: account, peerId: peerId, sound: sound).start()
            })
            presentControllerImpl?(controller, ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
        })
    }, openSharedMedia: {
        if let controller = peerSharedMediaController(account: account, peerId: peerId) {
            pushControllerImpl?(controller)
        }
    }, openAdmins: {
        pushControllerImpl?(channelAdminsController(account: account, peerId: peerId))
    }, openMembers: {
        pushControllerImpl?(channelMembersController(account: account, peerId: peerId))
    }, openBanned: {
        pushControllerImpl?(channelBlacklistController(account: account, peerId: peerId))
    }, reportChannel: {
        
    }, leaveChannel: {
        let presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
        let controller = ActionSheetController(presentationTheme: presentationData.theme)
        let dismissAction: () -> Void = { [weak controller] in
            controller?.dismissAnimated()
        }
        controller.setItemGroups([
            ActionSheetItemGroup(items: [
                ActionSheetButtonItem(title: presentationData.strings.Channel_LeaveChannel, action: {
                    let _ = removePeerChat(postbox: account.postbox, peerId: peerId, reportChatSpam: false).start()
                    dismissAction()
                    popToRootControllerImpl?()
                }),
            ]),
            ActionSheetItemGroup(items: [ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, action: { dismissAction() })])
        ])
        presentControllerImpl?(controller, ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
    }, deleteChannel: {
        
    }, displayAddressNameContextMenu: { text in
        let shareController = ShareController(account: account, subject: .url(text))
        presentControllerImpl?(shareController, nil)
    }, displayAboutContextMenu: { text in
        displayAboutContextMenuImpl?(text)
    }, aboutLinkAction: { action, itemLink in
        aboutLinkActionImpl?(action, itemLink)
    })
    
    let globalNotificationsKey: PostboxViewKey = .preferences(keys: Set<ValueBoxKey>([PreferencesKeys.globalNotifications]))
    let signal = combineLatest((account.applicationContext as! TelegramApplicationContext).presentationData, statePromise.get(), account.viewTracker.peerView(peerId), account.postbox.combinedView(keys: [globalNotificationsKey]))
        |> map { presentationData, state, view, combinedView -> (ItemListControllerState, (ItemListNodeState<ChannelInfoEntry>, ChannelInfoEntry.ItemGenerationArguments)) in
            let peer = peerViewMainPeer(view)
            
            var globalNotificationSettings: GlobalNotificationSettings = GlobalNotificationSettings.defaultSettings
            if let preferencesView = combinedView.views[globalNotificationsKey] as? PreferencesView {
                if let settings = preferencesView.values[PreferencesKeys.globalNotifications] as? GlobalNotificationSettings {
                    globalNotificationSettings = settings
                }
            }
            
            var canManageChannel = false
            if let peer = peer as? TelegramChannel {
                if peer.flags.contains(.isCreator) {
                    canManageChannel = true
                } else if let adminRights = peer.adminRights, !adminRights.isEmpty {
                    canManageChannel = true
                }
            }
            
            var leftNavigationButton: ItemListNavigationButton?
            var rightNavigationButton: ItemListNavigationButton?
            if let editingState = state.editingState {
                leftNavigationButton = ItemListNavigationButton(title: presentationData.strings.Common_Cancel, style: .regular, enabled: true, action: {
                    updateState {
                        $0.withUpdatedEditingState(nil)
                    }
                })
            
                var doneEnabled = true
                if let editingName = editingState.editingName, editingName.isEmpty {
                    doneEnabled = false
                }
                if peer is TelegramChannel {
                    if (view.cachedData as? CachedChannelData) == nil {
                        doneEnabled = false
                    }
                }
                
                if state.savingData {
                    rightNavigationButton = ItemListNavigationButton(title: "", style: .activity, enabled: doneEnabled, action: {})
                } else {
                    rightNavigationButton = ItemListNavigationButton(title: presentationData.strings.Common_Done, style: .bold, enabled: doneEnabled, action: {
                        var updateValues: (title: String?, description: String?) = (nil, nil)
                        updateState { state in
                            updateValues = valuesRequiringUpdate(state: state, view: view)
                            if updateValues.0 != nil || updateValues.1 != nil {
                                return state.withUpdatedSavingData(true)
                            } else {
                                return state.withUpdatedEditingState(nil)
                            }
                        }
                        
                        let updateTitle: Signal<Void, Void>
                        if let titleValue = updateValues.title {
                            updateTitle = updatePeerTitle(account: account, peerId: peerId, title: titleValue)
                                |> mapError { _ in return Void() }
                        } else {
                            updateTitle = .complete()
                        }
                        
                        let updateDescription: Signal<Void, Void>
                        if let descriptionValue = updateValues.description {
                            updateDescription = updatePeerDescription(account: account, peerId: peerId, description: descriptionValue.isEmpty ? nil : descriptionValue)
                                |> mapError { _ in return Void() }
                        } else {
                            updateDescription = .complete()
                        }
                        
                        let signal = combineLatest(updateTitle, updateDescription)
                        
                        updatePeerNameDisposable.set((signal |> deliverOnMainQueue).start(error: { _ in
                            updateState { state in
                                return state.withUpdatedSavingData(false)
                            }
                        }, completed: {
                            updateState { state in
                                return state.withUpdatedSavingData(false).withUpdatedEditingState(nil)
                            }
                        }))
                    })
                }
            } else {
                rightNavigationButton = ItemListNavigationButton(title: presentationData.strings.Common_Edit, style: .regular, enabled: true, action: {
                    if let channel = peer as? TelegramChannel, case .broadcast = channel.info {
                        var text = ""
                        if let cachedData = view.cachedData as? CachedChannelData, let about = cachedData.about {
                            text = about
                        }
                        updateState { state in
                            return state.withUpdatedEditingState(ChannelInfoEditingState(editingName: ItemListAvatarAndNameInfoItemName(channel), editingDescriptionText: text))
                        }
                    }
                })
            }
            
            let controllerState = ItemListControllerState(theme: presentationData.theme, title: .text(presentationData.strings.UserInfo_Title), leftNavigationButton: leftNavigationButton, rightNavigationButton: rightNavigationButton, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
            let listState = ItemListNodeState(entries: channelInfoEntries(account: account, presentationData: presentationData, view: view, globalNotificationSettings: globalNotificationSettings, state: state), style: .plain)
            
            return (controllerState, (listState, arguments))
        } |> afterDisposed {
            actionsDisposable.dispose()
    }
    
    let controller = ItemListController(account: account, state: signal)
    
    pushControllerImpl = { [weak controller] value in
        (controller?.navigationController as? NavigationController)?.pushViewController(value)
    }
    presentControllerImpl = { [weak controller] value, presentationArguments in
        controller?.present(value, in: .window(.root), with: presentationArguments)
    }
    popToRootControllerImpl = { [weak controller] in
        (controller?.navigationController as? NavigationController)?.popToRoot(animated: true)
    }
    avatarGalleryTransitionArguments = { [weak controller] entry in
        if let controller = controller {
            var result: (ASDisplayNode, CGRect)?
            controller.forEachItemNode { itemNode in
                if let itemNode = itemNode as? ItemListAvatarAndNameInfoItemNode {
                    result = itemNode.avatarTransitionNode()
                }
            }
            if let (node, _) = result {
                return GalleryTransitionArguments(transitionNode: node, addToTransitionSurface: { _ in
                })
            }
        }
        return nil
    }
    updateHiddenAvatarImpl = { [weak controller] in
        if let controller = controller {
            controller.forEachItemNode { itemNode in
                if let itemNode = itemNode as? ItemListAvatarAndNameInfoItemNode {
                    itemNode.updateAvatarHidden()
                }
            }
        }
    }
    displayAboutContextMenuImpl = { [weak controller] text in
        if let strongController = controller {
            let presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
            var resultItemNode: ListViewItemNode?
            let _ = strongController.frameForItemNode({ itemNode in
                if let itemNode = itemNode as? ItemListTextWithLabelItemNode {
                    if let tag = itemNode.tag as? ChannelInfoEntryTag {
                        if tag == .about {
                            resultItemNode = itemNode
                            return true
                        }
                    }
                }
                return false
            })
            if let resultItemNode = resultItemNode {
                let contextMenuController = ContextMenuController(actions: [ContextMenuAction(content: .text(presentationData.strings.Conversation_ContextMenuCopy), action: {
                    UIPasteboard.general.string = text
                })])
                strongController.present(contextMenuController, in: .window(.root), with: ContextMenuControllerPresentationArguments(sourceNodeAndRect: { [weak resultItemNode] in
                    if let resultItemNode = resultItemNode {
                        return (resultItemNode, resultItemNode.contentBounds.insetBy(dx: 0.0, dy: -2.0))
                    } else {
                        return nil
                    }
                }))
                
            }
        }
    }
    aboutLinkActionImpl = { [weak controller] action, itemLink in
        if let controller = controller {
            handlePeerInfoAboutTextAction(account: account, navigateDisposable: navigateDisposable, controller: controller, action: action, itemLink: itemLink)
        }
    }
    return controller
}