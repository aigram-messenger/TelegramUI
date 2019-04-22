//
//  CreateFolderController.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 17/04/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation
import Display
import SwiftSignalKit
import Postbox
import TelegramCore

import LegacyComponents

private struct CreateFolderArguments {
    let account: Account

    let updateEditingName: (ItemListAvatarAndNameInfoItemName) -> Void
    let done: () -> Void
    let changeProfilePhoto: () -> Void
}

private enum CreateFolderSection: Int32 {
    case info
    case members
}

private enum CreateFolderEntryTag: ItemListItemTag {
    case info

    func isEqual(to other: ItemListItemTag) -> Bool {
        if let other = other as? CreateFolderEntryTag {
            switch self {
            case .info:
                if case .info = other {
                    return true
                } else {
                    return false
                }
            }
        } else {
            return false
        }
    }
}

private enum CreateFolderEntry: ItemListNodeEntry {
    case groupInfo(PresentationTheme, PresentationStrings, PresentationDateTimeFormat, Peer?, ItemListAvatarAndNameInfoItemState, ItemListAvatarAndNameInfoItemUpdatingAvatar?)
//    case setProfilePhoto(PresentationTheme, String)

    case member(Int32, PresentationTheme, PresentationStrings, PresentationDateTimeFormat, Peer, PeerPresence?)

    var section: ItemListSectionId {
        switch self {
        case .groupInfo/*, .setProfilePhoto*/:
            return CreateFolderSection.info.rawValue
        case .member:
            return CreateFolderSection.members.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .groupInfo:
            return 0
//        case .setProfilePhoto:
//            return 1
        case let .member(index, _, _, _, _, _):
            return 1 + index
        }
    }

    static func ==(lhs: CreateFolderEntry, rhs: CreateFolderEntry) -> Bool {
        switch lhs {
        case let .groupInfo(lhsTheme, lhsStrings, lhsDateTimeFormat, lhsPeer, lhsEditingState, lhsAvatar):
            if case let .groupInfo(rhsTheme, rhsStrings, rhsDateTimeFormat, rhsPeer, rhsEditingState, rhsAvatar) = rhs {
                if lhsTheme !== rhsTheme {
                    return false
                }
                if lhsStrings !== rhsStrings {
                    return false
                }
                if lhsDateTimeFormat != rhsDateTimeFormat {
                    return false
                }
                if let lhsPeer = lhsPeer, let rhsPeer = rhsPeer {
                    if !lhsPeer.isEqual(rhsPeer) {
                        return false
                    }
                } else if (lhsPeer != nil) != (rhsPeer != nil) {
                    return false
                }
                if lhsEditingState != rhsEditingState {
                    return false
                }
                if lhsAvatar != rhsAvatar {
                    return false
                }
                return true
            } else {
                return false
            }
//        case let .setProfilePhoto(lhsTheme, lhsText):
//            if case let .setProfilePhoto(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
//                return true
//            } else {
//                return false
//            }
        case let .member(lhsIndex, lhsTheme, lhsStrings, lhsDateTimeFormat, lhsPeer, lhsPresence):
            if case let .member(rhsIndex, rhsTheme, rhsStrings, rhsDateTimeFormat, rhsPeer, rhsPresence) = rhs {
                if lhsIndex != rhsIndex {
                    return false
                }
                if lhsTheme !== rhsTheme {
                    return false
                }
                if lhsStrings !== rhsStrings {
                    return false
                }
                if lhsDateTimeFormat != rhsDateTimeFormat {
                    return false
                }
                if !lhsPeer.isEqual(rhsPeer) {
                    return false
                }
                if let lhsPresence = lhsPresence, let rhsPresence = rhsPresence {
                    if !lhsPresence.isEqual(to: rhsPresence) {
                        return false
                    }
                } else if (lhsPresence != nil) != (rhsPresence != nil) {
                    return false
                }
                return true
            } else {
                return false
            }
        }
    }

    static func <(lhs: CreateFolderEntry, rhs: CreateFolderEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(_ arguments: CreateFolderArguments) -> ListViewItem {
        switch self {
        case let .groupInfo(theme, strings, dateTimeFormat, peer, state, avatar):
            return ItemListAvatarAndNameInfoItem(account: arguments.account, theme: theme, strings: strings, dateTimeFormat: dateTimeFormat, mode: .generic, peer: peer, presence: nil, cachedData: nil, state: state, sectionId: ItemListSectionId(self.section), style: .blocks(withTopInset: false), editingNameUpdated: { editingName in
                arguments.updateEditingName(editingName)
            }, avatarTapped: {
            }, updatingImage: avatar, tag: CreateFolderEntryTag.info)
//        case let .setProfilePhoto(theme, text):
//            return ItemListActionItem(theme: theme, title: text, kind: .generic, alignment: .natural, sectionId: ItemListSectionId(self.section), style: .blocks, action: {
//                arguments.changeProfilePhoto()
//            })
        case let .member(_, theme, strings, dateTimeFormat, peer, _):
            return ItemListPeerItem(theme: theme, strings: strings, dateTimeFormat: dateTimeFormat, account: arguments.account, peer: peer, presence: .none, text: .none, label: .none, editing: ItemListPeerItemEditing(editable: false, editing: false, revealed: false), switchValue: nil, enabled: true, sectionId: self.section, action: nil, setPeerIdWithRevealedOptions: { _, _ in }, removePeer: { _ in })
        }
    }
}

private struct CreateFolderState: Equatable {
    var creating: Bool
    var editingName: ItemListAvatarAndNameInfoItemName
    var avatar: ItemListAvatarAndNameInfoItemUpdatingAvatar?

    static func ==(lhs: CreateFolderState, rhs: CreateFolderState) -> Bool {
        if lhs.creating != rhs.creating {
            return false
        }
        if lhs.editingName != rhs.editingName {
            return false
        }
        if lhs.avatar != rhs.avatar {
            return false
        }

        return true
    }
}

private func createFolderEntries(presentationData: PresentationData, state: CreateFolderState, peerIds: [PeerId], view: MultiplePeersView) -> [CreateFolderEntry] {
    var entries: [CreateFolderEntry] = []

    let groupInfoState = ItemListAvatarAndNameInfoItemState(editingName: state.editingName, updatingName: nil)

    let peer = TelegramGroup(id: PeerId(namespace: -1, id: 0), title: state.editingName.composedTitle, photo: [], participantCount: 0, role: .creator, membership: .Member, flags: [], migrationReference: nil, creationDate: 0, version: 0)

    entries.append(.groupInfo(presentationData.theme, presentationData.strings, presentationData.dateTimeFormat, peer, groupInfoState, state.avatar))

    var peers: [Peer] = []
    for peerId in peerIds {
        if let peer = view.peers[peerId] {
            peers.append(peer)
        }
    }

    peers.sort(by: { lhs, rhs in
        let lhsPresence = view.presences[lhs.id] as? TelegramUserPresence
        let rhsPresence = view.presences[rhs.id] as? TelegramUserPresence
        if let lhsPresence = lhsPresence, let rhsPresence = rhsPresence {
            if lhsPresence.status < rhsPresence.status {
                return false
            } else if lhsPresence.status > rhsPresence.status {
                return true
            } else {
                return lhs.id < rhs.id
            }
        } else if let _ = lhsPresence {
            return true
        } else if let _ = rhsPresence {
            return false
        } else {
            return lhs.id < rhs.id
        }
    })

    for i in 0 ..< peers.count {
        entries.append(.member(Int32(i), presentationData.theme, presentationData.strings, presentationData.dateTimeFormat, peers[i], view.presences[peers[i].id]))
    }

    return entries
}

public func createFolderController(account: Account, peerIds: [PeerId] = []) -> ViewController {
    let initialState = CreateFolderState(creating: false, editingName: .title(title: "", type: .folder), avatar: nil)
    let statePromise = ValuePromise(initialState, ignoreRepeated: true)
    let stateValue = Atomic(value: initialState)
    let updateState: ((CreateFolderState) -> CreateFolderState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }

    var replaceControllerImpl: ((ViewController) -> Void)?
    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    var dismissControllerImpl: (() -> Void)?
    var endEditingImpl: (() -> Void)?

    let actionsDisposable = DisposableSet()

//    let currentAvatarMixin = Atomic<TGMediaAvatarMenuMixin?>(value: nil)
//
//    let uploadedAvatar = Promise<UploadedPeerPhotoData>()

    let arguments = CreateFolderArguments(account: account, updateEditingName: { editingName in
        updateState { current in
            var current = current
            current.editingName = editingName
            return current
        }
    }, done: {
        let (creating, title) = stateValue.with { state -> (Bool, String) in
            return (state.creating, state.editingName.composedTitle)
        }

        if !creating && !title.isEmpty {
            updateState { current in
                var current = current
                current.creating = true
                return current
            }
            endEditingImpl?()
            dismissControllerImpl?()
//            actionsDisposable.add((createFolder(account: account, title: title, peerIds: peerIds) |> deliverOnMainQueue |> afterDisposed {
//                Queue.mainQueue().async {
//                    updateState { current in
//                        var current = current
//                        current.creating = false
//                        return current
//                    }
//                }
//                }).start(next: { peerId in
//                    if let peerId = peerId {
//                        let updatingAvatar = stateValue.with {
//                            return $0.avatar
//                        }
//                        if let _ = updatingAvatar {
//                            let _ = updatePeerPhoto(postbox: account.postbox, network: account.network, stateManager: account.stateManager, accountPeerId: account.peerId, peerId: peerId, photo: uploadedAvatar.get()).start()
//                        }
//                        let controller = ChatController(account: account, chatLocation: .peer(peerId))
//                        replaceControllerImpl?(controller)
//                    }
//                }))
        }
    }, changeProfilePhoto: {
//        let presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
//
//        let legacyController = LegacyController(presentation: .custom, theme: presentationData.theme)
//        legacyController.statusBar.statusBarStyle = .Ignore
//
//        let emptyController = LegacyEmptyController(context: legacyController.context)!
//        let navigationController = makeLegacyNavigationController(rootController: emptyController)
//        navigationController.setNavigationBarHidden(true, animated: false)
//        navigationController.navigationBar.transform = CGAffineTransform(translationX: -1000.0, y: 0.0)
//
//        legacyController.bind(controller: navigationController)
//
//        endEditingImpl?()
//        presentControllerImpl?(legacyController, nil)
//
//        let mixin = TGMediaAvatarMenuMixin(context: legacyController.context, parentController: emptyController, hasDeleteButton: stateValue.with({ $0.avatar }) != nil, personalPhoto: false, saveEditedPhotos: false, saveCapturedMedia: false)!
//        let _ = currentAvatarMixin.swap(mixin)
//        mixin.didFinishWithImage = { image in
//            if let image = image, let data = UIImageJPEGRepresentation(image, 0.6) {
//                let resource = LocalFileMediaResource(fileId: arc4random64())
//                account.postbox.mediaBox.storeResourceData(resource.id, data: data)
//                let representation = TelegramMediaImageRepresentation(dimensions: CGSize(width: 640.0, height: 640.0), resource: resource)
//                uploadedAvatar.set(uploadedPeerPhoto(postbox: account.postbox, network: account.network, resource: resource))
//                updateState { current in
//                    var current = current
//                    current.avatar = .image(representation)
//                    return current
//                }
//            }
//        }
//        if stateValue.with({ $0.avatar }) != nil {
//            mixin.didFinishWithDelete = {
//                updateState { current in
//                    var current = current
//                    current.avatar = nil
//                    return current
//                }
//                uploadedAvatar.set(.never())
//            }
//        }
//        mixin.didDismiss = { [weak legacyController] in
//            let _ = currentAvatarMixin.swap(nil)
//            legacyController?.dismiss()
//        }
//        let menuController = mixin.present()
//        if let menuController = menuController {
//            menuController.customRemoveFromParentViewController = { [weak legacyController] in
//                legacyController?.dismiss()
//            }
//        }
    })

    let signal = combineLatest((account.applicationContext as! TelegramApplicationContext).presentationData, statePromise.get(), account.postbox.multiplePeersView(peerIds))
        |> map { presentationData, state, view -> (ItemListControllerState, (ItemListNodeState<CreateFolderEntry>, CreateFolderEntry.ItemGenerationArguments)) in

            let rightNavigationButton: ItemListNavigationButton
            if state.creating {
                rightNavigationButton = ItemListNavigationButton(content: .none, style: .activity, enabled: true, action: {})
            } else {
                rightNavigationButton = ItemListNavigationButton(content: .text(presentationData.strings.Compose_Create), style: .bold, enabled: !state.editingName.composedTitle.isEmpty, action: {
                    arguments.done()
                })
            }

            let controllerState = ItemListControllerState(theme: presentationData.theme, title: .text(presentationData.strings.ComposeFolder_NewFolder), leftNavigationButton: nil, rightNavigationButton: rightNavigationButton, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
            let listState = ItemListNodeState(entries: createFolderEntries(presentationData: presentationData, state: state, peerIds: peerIds, view: view), style: .blocks, focusItemTag: CreateFolderEntryTag.info)

            return (controllerState, (listState, arguments))
        } |> afterDisposed {

            actionsDisposable.dispose()
    }

    let controller = ItemListController(account: account, state: signal)
    replaceControllerImpl = { [weak controller] value in
        (controller?.navigationController as? NavigationController)?.replaceAllButRootController(value, animated: true)
    }
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    dismissControllerImpl = { [weak controller] in
        (controller?.navigationController as? NavigationController)?.popToRoot(animated: true)
    }
    controller.willDisappear = { _ in
        endEditingImpl?()
    }
    endEditingImpl = {
        [weak controller] in
        controller?.view.endEditing(true)
    }
    return controller
}

