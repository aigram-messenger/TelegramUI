//
//  FolderController.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 30/04/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit
import Postbox
import SwiftSignalKit
import Display
import TelegramCore

final class FolderController: TelegramController, KeyShortcutResponder, UIViewControllerPreviewingDelegate {
    private var validLayout: ContainerViewLayout?

    private let account: Account
    private let controlsHistoryPreload: Bool

    public let groupId: PeerGroupId?

    let openMessageFromSearchDisposable: MetaDisposable = MetaDisposable()

    private var chatListDisplayNode: FolderControllerNode {
        return super.displayNode as! FolderControllerNode
    }

    private let chatTitleView: _ChatTitleView

    private var proxyUnavailableTooltipController: TooltipController?
    private var didShowProxyUnavailableTooltipController = false

    private var dismissSearchOnDisappear = false

    private var didSetup3dTouch = false

    private var passcodeLockTooltipDisposable = MetaDisposable()
    private var didShowPasscodeLockTooltipController = false

    private var suggestLocalizationDisposable = MetaDisposable()
    private var didSuggestLocalization = false

    private var updateFolderActionDisposable = MetaDisposable()

    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?

    // MARK: -

    private var chatListModeSwitcher: ((ChatListMode) -> Void)?

    private let folder: Folder

    // MARK: -

    public init(account: Account, groupId: PeerGroupId?, controlsHistoryPreload: Bool, folderId: Folder.Id) {
        self.account = account
        self.controlsHistoryPreload = controlsHistoryPreload
        self.folder = account.postbox.folder(with: folderId)!

        self.groupId = groupId

        self.presentationData = (account.telegramApplicationContext.currentPresentationData.with { $0 })

        self.chatTitleView = _ChatTitleView(account: account, theme: presentationData.theme, strings: presentationData.strings, dateTimeFormat: presentationData.dateTimeFormat)

        super.init(account: account, navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData), mediaAccessoryPanelVisibility: .always, locationBroadcastPanelSource: .summary)

        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBar.style.style

        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
        self.navigationItem.titleView = chatTitleView

        chatTitleView.folder = folder
        chatTitleView.pressed = { [weak self] in
            self?.chatListDisplayNode.isTitlePanelShown.toggle()
            self?.requestLayout(transition: .animated(duration: 0.2, curve: .spring))
        }

        self.scrollToTop = { [weak self] in
            self?.chatListDisplayNode.chatListNode.scrollToPosition(.top)
        }

        self.scrollToTopWithTabBar = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            if strongSelf.chatListDisplayNode.searchDisplayController != nil {
                strongSelf.deactivateSearch(animated: true)
            } else {
                strongSelf.chatListDisplayNode.chatListNode.scrollToPosition(.top)
            }
        }

        self.presentationDataDisposable = (account.telegramApplicationContext.presentationData
            |> deliverOnMainQueue).start(next: { [weak self] presentationData in
                if let strongSelf = self {
                    let previousTheme = strongSelf.presentationData.theme
                    let previousStrings = strongSelf.presentationData.strings

                    strongSelf.presentationData = presentationData

                    if previousTheme !== presentationData.theme || previousStrings !== presentationData.strings {
                        strongSelf.updateThemeAndStrings()
                    }
                }
            })
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.openMessageFromSearchDisposable.dispose()
        self.passcodeLockTooltipDisposable.dispose()
        self.suggestLocalizationDisposable.dispose()
        self.presentationDataDisposable?.dispose()
    }

    private func updateThemeAndStrings() {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)

        self.chatTitleView.updateThemeAndStrings(theme: presentationData.theme, strings: presentationData.strings)

        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBar.style.style
        self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationData: self.presentationData))

        if self.isNodeLoaded {
            self.chatListDisplayNode.updateThemeAndStrings(theme: self.presentationData.theme, strings: self.presentationData.strings, dateTimeFormat: self.presentationData.dateTimeFormat, nameSortOrder: self.presentationData.nameSortOrder, nameDisplayOrder: self.presentationData.nameDisplayOrder, disableAnimations: self.presentationData.disableAnimations)
        }
    }

    private func hideTitlePanel(animated: Bool = false) {
        chatListDisplayNode.isTitlePanelShown = false
        requestLayout(transition: animated ? .immediate : .animated(duration: 0.2, curve: .spring))
    }

    override public func loadDisplayNode() {
        let interaction = FolderInfoTitlePanelInteration(
            addMember: { [weak self] in
                self?.addPressed()
            }, edit: { [weak self] in
                self?.renamePressed()
                self?.hideTitlePanel(animated: true)
            }, delete: { [weak self] in
                self?.deletePressed()
            }
        )

        self.displayNode = FolderControllerNode(account: self.account, groupId: self.groupId, controlsHistoryPreload: self.controlsHistoryPreload, presentationData: self.presentationData, controller: self,
        setupChatListModeHandler: { [weak self, folder] in
            self?.chatListModeSwitcher = $0
            $0(.filter(type: .folder(folder)))
        }, titlePanelInteraction: interaction)

        self.chatListDisplayNode.navigationBar = self.navigationBar

        self.chatListDisplayNode.requestDeactivateSearch = { [weak self] in
//            self?.deactivateSearch(animated: true)
        }

        self.chatListDisplayNode.chatListNode.activateSearch = { [weak self] in
//            self?.activateSearch()
        }

        self.chatListDisplayNode.chatListNode.presentAlert = { [weak self] text in
            if let strongSelf = self {
                self?.present(standardTextAlertController(theme: AlertControllerTheme(presentationTheme: strongSelf.presentationData.theme), title: nil, text: text, actions: [TextAlertAction(type: .defaultAction, title: strongSelf.presentationData.strings.Common_OK, action: {})]), in: .window(.root))
            }
        }

        self.chatListDisplayNode.chatListNode.deletePeerChat = { [weak self, folder] peerId in
            guard let self = self else { return }

            let actionSheet = ActionSheetController(presentationTheme: self.presentationData.theme)

            actionSheet.setItemGroups([
                ActionSheetItemGroup(items: [
                    ActionSheetButtonItem(title: self.presentationData.strings.Folder_RemovePeer, color: .destructive) { [weak self, weak actionSheet, folder] in
                        actionSheet?.dismissAnimated()
                        self?.account.postbox.remove(peerWithId: peerId, from: folder)

                        if self?.folder.peerIds.isEmpty ?? true {
                            self?.navigationController?.popViewController(animated: true)
                        }
                    }
                ]),
                ActionSheetItemGroup(items: [
                    ActionSheetButtonItem(title: self.presentationData.strings.Common_Cancel, color: .accent) { [weak actionSheet] in
                        actionSheet?.dismissAnimated()
                    }
                ])
            ])

            self.present(actionSheet, in: .window(.root))
        }

        self.chatListDisplayNode.chatListNode.peerSelected = { [weak self] peerId, animated, isAd in
            if let strongSelf = self {
                if let navigationController = strongSelf.navigationController as? NavigationController {
                    if isAd {
                        let _ = (ApplicationSpecificNotice.getProxyAdsAcknowledgment(postbox: strongSelf.account.postbox)
                            |> deliverOnMainQueue).start(next: { value in
                                guard let strongSelf = self else {
                                    return
                                }
                                if !value {
                                    strongSelf.present(standardTextAlertController(theme: AlertControllerTheme(presentationTheme: strongSelf.presentationData.theme), title: nil, text: strongSelf.presentationData.strings.DialogList_AdNoticeAlert, actions: [TextAlertAction(type: .defaultAction, title: strongSelf.presentationData.strings.Common_OK, action: {
                                        if let strongSelf = self {
                                            let _ = ApplicationSpecificNotice.setProxyAdsAcknowledgment(postbox: strongSelf.account.postbox).start()
                                        }
                                    })]), in: .window(.root))
                                }
                            })
                    }

                    navigateToChatController(navigationController: navigationController, account: strongSelf.account, chatLocation: .peer(peerId), keepStack: .always, animated: animated, showsUnreadCountOnBackButton: false, completion: { [weak self] in
                        self?.chatListDisplayNode.chatListNode.clearHighlightAnimated(true)
                    })
                }
            }
        }

        self.chatListDisplayNode.chatListNode.groupSelected = { [weak self] groupId in
            if let strongSelf = self {
                if let navigationController = strongSelf.navigationController as? NavigationController {
                    navigateToChatController(navigationController: navigationController, account: strongSelf.account, chatLocation: .group(groupId))
                    strongSelf.chatListDisplayNode.chatListNode.clearHighlightAnimated(true)
                }
            }
        }

        self.chatListDisplayNode.chatListNode.updatePeerGrouping = { [weak self] peerId, group in
            if let strongSelf = self {
                let _ = updatePeerGroupIdInteractively(postbox: strongSelf.account.postbox, peerId: peerId, groupId: group ? Namespaces.PeerGroup.feed : nil).start()
            }
        }

        self.chatListDisplayNode.requestOpenMessageFromSearch = { [weak self] peer, messageId in
            if let strongSelf = self {
                strongSelf.openMessageFromSearchDisposable.set((storedMessageFromSearchPeer(account: strongSelf.account, peer: peer) |> deliverOnMainQueue).start(completed: { [weak strongSelf] in
                    if let strongSelf = strongSelf {
                        if let navigationController = strongSelf.navigationController as? NavigationController {
                            navigateToChatController(navigationController: navigationController, account: strongSelf.account, chatLocation: .peer(messageId.peerId), messageId: messageId)
                            strongSelf.chatListDisplayNode.chatListNode.clearHighlightAnimated(true)
                        }
                    }
                }))
            }
        }

        self.chatListDisplayNode.requestOpenPeerFromSearch = { [weak self] peer, dismissSearch in
            if let strongSelf = self {
                let storedPeer = strongSelf.account.postbox.transaction { transaction -> Void in
                    if transaction.getPeer(peer.id) == nil {
                        updatePeers(transaction: transaction, peers: [peer], update: { previousPeer, updatedPeer in
                            return updatedPeer
                        })
                    }
                }
                strongSelf.openMessageFromSearchDisposable.set((storedPeer |> deliverOnMainQueue).start(completed: { [weak strongSelf] in
                    if let strongSelf = strongSelf {
                        if dismissSearch {
                            strongSelf.dismissSearchOnDisappear = true
                        }
                        if let navigationController = strongSelf.navigationController as? NavigationController {
                            navigateToChatController(navigationController: navigationController, account: strongSelf.account, chatLocation: .peer(peer.id), purposefulAction: { [weak self] in
                                if let strongSelf = self {
                                    strongSelf.deactivateSearch(animated: false)
                                }
                            })
                            strongSelf.chatListDisplayNode.chatListNode.clearHighlightAnimated(true)
                        }
                    }
                }))
            }
        }

        self.chatListDisplayNode.requestOpenRecentPeerOptions = { [weak self] peer in
            if let strongSelf = self {
                strongSelf.chatListDisplayNode.view.endEditing(true)
                let actionSheet = ActionSheetController(presentationTheme: strongSelf.presentationData.theme)

                actionSheet.setItemGroups([
                    ActionSheetItemGroup(items: [
                        ActionSheetButtonItem(title: strongSelf.presentationData.strings.Common_Delete, color: .destructive, action: { [weak actionSheet] in
                            actionSheet?.dismissAnimated()

                            if let strongSelf = self {
                                let _ = removeRecentPeer(account: strongSelf.account, peerId: peer.id).start()
                                let searchContainer = strongSelf.chatListDisplayNode.searchDisplayController?.contentNode as? ChatListSearchContainerNode
                                searchContainer?.removePeerFromTopPeers(peer.id)
                            }
                        })
                        ]),
                    ActionSheetItemGroup(items: [
                        ActionSheetButtonItem(title: strongSelf.presentationData.strings.Common_Cancel, color: .accent, action: { [weak actionSheet] in
                            actionSheet?.dismissAnimated()
                        })
                        ])
                    ])
                strongSelf.present(actionSheet, in: .window(.root))
            }
        }

        self.chatListDisplayNode.requestAddContact = { [weak self] phoneNumber in
            if let strongSelf = self {
                strongSelf.chatListDisplayNode.view.endEditing(true)
                openAddContact(account: strongSelf.account, phoneNumber: phoneNumber, present: { [weak self] controller, arguments in
                    self?.present(controller, in: .window(.root), with: arguments)
                    }, completed: {
                        self?.deactivateSearch(animated: false)
                })
            }
        }

        self.displayNodeDidLoad()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        #if DEBUG
        DispatchQueue.main.async {
            let count = ChatControllerCount.with({ $0 })
            if count != 0 {
                self.present(standardTextAlertController(theme: AlertControllerTheme(presentationTheme: self.presentationData.theme), title: "", text: "ChatControllerCount \(count)", actions: [TextAlertAction(type: .defaultAction, title: "OK", action: {})]), in: .window(.root))
            }
        }
        #endif

        if !self.didSetup3dTouch {
            self.didSetup3dTouch = true
            if #available(iOSApplicationExtension 9.0, *) {
                self.registerForPreviewingNonNative(with: self, sourceView: self.view, theme: PeekControllerTheme(presentationTheme: self.presentationData.theme))
            }
        }

        if !self.didSuggestLocalization {
            self.didSuggestLocalization = true

            let network = self.account.network
            let signal = self.account.postbox.transaction { transaction -> (String, SuggestedLocalizationEntry?) in
                let languageCode: String
                if let current = transaction.getPreferencesEntry(key: PreferencesKeys.localizationSettings) as? LocalizationSettings {
                    let code = current.primaryComponent.languageCode
                    let rawSuffix = "-raw"
                    if code.hasSuffix(rawSuffix) {
                        languageCode = String(code.dropLast(rawSuffix.count))
                    } else {
                        languageCode = code
                    }
                } else {
                    languageCode = "en"
                }
                var suggestedLocalization: SuggestedLocalizationEntry?
                if let localization = transaction.getPreferencesEntry(key: PreferencesKeys.suggestedLocalization) as? SuggestedLocalizationEntry {
                    suggestedLocalization = localization
                }
                return (languageCode, suggestedLocalization)
                } |> mapToSignal({ value -> Signal<(String, SuggestedLocalizationInfo)?, NoError> in
                    guard let suggestedLocalization = value.1, !suggestedLocalization.isSeen && suggestedLocalization.languageCode != "en" && suggestedLocalization.languageCode != value.0 else {
                        return .single(nil)
                    }
                    return suggestedLocalizationInfo(network: network, languageCode: suggestedLocalization.languageCode, extractKeys: LanguageSuggestionControllerStrings.keys)
                        |> map({ suggestedLocalization -> (String, SuggestedLocalizationInfo)? in
                            return (value.0, suggestedLocalization)
                        })
                })

            self.suggestLocalizationDisposable.set((signal |> deliverOnMainQueue).start(next: { [weak self] suggestedLocalization in
                guard let strongSelf = self, let (currentLanguageCode, suggestedLocalization) = suggestedLocalization else {
                    return
                }
                if let controller = languageSuggestionController(account: strongSelf.account, suggestedLocalization: suggestedLocalization, currentLanguageCode: currentLanguageCode, openSelection: { [weak self] in
                    if let strongSelf = self {
                        let controller = LocalizationListController(account: strongSelf.account)
                        (strongSelf.navigationController as? NavigationController)?.pushViewController(controller)
                    }
                }) {
                    strongSelf.present(controller, in: .window(.root))
                    _ = markSuggestedLocalizationAsSeenInteractively(postbox: strongSelf.account.postbox, languageCode: suggestedLocalization.languageCode).start()
                }
            }))
        }
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if self.dismissSearchOnDisappear {
            self.dismissSearchOnDisappear = false
            self.deactivateSearch(animated: false)
        }

        self.chatListDisplayNode.isTitlePanelShown = false
        self.chatListDisplayNode.chatListNode.clearHighlightAnimated(true)
    }

    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)

        self.validLayout = layout

        self.chatListDisplayNode.containerLayoutUpdated(layout, navigationBarHeight: self.navigationHeight, transition: transition)
    }

    override public func navigationStackConfigurationUpdated(next: [ViewController]) {
        super.navigationStackConfigurationUpdated(next: next)

        let chatLocation = (next.first as? ChatController)?.chatLocation

        self.chatListDisplayNode.chatListNode.updateSelectedChatLocation(chatLocation, progress: 1.0, transition: .immediate)
    }

    @objc func editPressed() {
        let editItem = UIBarButtonItem(title: self.presentationData.strings.Common_Done, style: .done, target: self, action: #selector(self.donePressed))
        if self.groupId == nil {
            self.navigationItem.leftBarButtonItem = editItem
        } else {
            self.navigationItem.rightBarButtonItem = editItem
        }
        self.chatListDisplayNode.chatListNode.updateState { state in
            return state.withUpdatedEditing(true)
        }
    }

    @objc func donePressed() {
        let editItem = UIBarButtonItem(title: self.presentationData.strings.Common_Edit, style: .plain, target: self, action: #selector(self.editPressed))
        if self.groupId == nil {
            self.navigationItem.leftBarButtonItem = editItem
        } else {
            self.navigationItem.rightBarButtonItem = editItem
        }
        self.chatListDisplayNode.chatListNode.updateState { state in
            return state.withUpdatedEditing(false).withUpdatedPeerIdWithRevealedOptions(nil)
        }
    }

    private func addPressed() {
        let controller = ChatListSelectionController(account: account, options: [], filters: [.excludeSelf, .exclude(folder.peerIds.collect())], createsFolder: false)
        updateFolderActionDisposable.set(
            (controller.result |> deliverOnMainQueue)
                .start(next: { [account, folder] selectedPeers in
                    let peerIds = selectedPeers.compactMap { (peerSelection) -> PeerId? in
                        if case let .peer(peerId) = peerSelection {
                            return peerId
                        } else {
                            return nil
                        }
                    }

                    account.postbox.add(peerIds: peerIds, to: folder)

                    controller.navigationController?.popViewController(animated: true)
                })
        )
        (self.navigationController as? NavigationController)?.pushViewController(controller, animated: true)
    }

    private func renamePressed() {
        let alert = _standardTextAlertController(
            theme: .init(presentationTheme: presentationData.theme),
            title: nil,
            text: presentationData.strings.Folder_RenameFolder,
            inputPlaceholder: presentationData.strings.Folder_NewName,
            renameAction: { [weak self] in
                guard let self = self else { return }
                guard !$0.isEmpty else { return self.showEmptyNameError() }

                self.account.postbox.rename(folder: self.folder, to: $0)
                self.chatTitleView.updateStatus()
            },
            keyboardColor: presentationData.theme.chatList.searchBarKeyboardColor,
            placeholderColor: presentationData.theme.chat.inputPanel.inputPlaceholderColor,
            primaryTextColor: presentationData.theme.chat.inputPanel.primaryTextColor
        )

        present(alert, in: .window(.root))
    }

    private func showEmptyNameError() {
        let alert = standardTextAlertController(
            theme: .init(presentationTheme: presentationData.theme),
            title: nil,
            text: presentationData.strings.Folder_EmptyError,
            actions: [
                TextAlertAction.init(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})
            ]
        )

        present(alert, in: .window(.root))
    }

    private func deletePressed() {
        account.postbox.delete(folderWithId: folder.id)
        navigationController?.popViewController(animated: true)
    }

    func activateSearch() {
//        tabBarView.isHidden = true
//        tabBarView.alpha = 0.0

        if self.displayNavigationBar {
            let _ = (self.chatListDisplayNode.chatListNode.ready
                |> take(1)
                |> deliverOnMainQueue).start(completed: { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }
                    if let scrollToTop = strongSelf.scrollToTop {
                        scrollToTop()
                    }
                    strongSelf.chatListDisplayNode.activateSearch()
                    strongSelf.setDisplayNavigationBar(false, transition: .animated(duration: 0.5, curve: .spring))
                })
        }
    }

    func deactivateSearch(animated: Bool) {
//        tabBarView.isHidden = false
//        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions.curveEaseInOut, animations: { [weak self] in
//            self?.tabBarView.alpha = 1.0
//        })

        if !self.displayNavigationBar {
            self.setDisplayNavigationBar(true, transition: animated ? .animated(duration: 0.5, curve: .spring) : .immediate)
            self.chatListDisplayNode.deactivateSearch(animated: animated)
            self.scrollToTop?()
        }
    }

    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if #available(iOSApplicationExtension 9.0, *) {
            if let (controller, rect) = self.previewingController(from: previewingContext.sourceView, for: location) {
                previewingContext.sourceRect = rect
                return controller
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    func previewingController(from sourceView: UIView, for location: CGPoint) -> (UIViewController, CGRect)? {
        guard let layout = self.validLayout, case .compact = layout.metrics.widthClass else {
            return nil
        }

        let boundsSize = self.view.bounds.size
        let contentSize: CGSize
        if let metrics = DeviceMetrics.forScreenSize(layout.size) {
            contentSize = metrics.previewingContentSize(inLandscape: boundsSize.width > boundsSize.height)
        } else {
            contentSize = boundsSize
        }

        if let searchController = self.chatListDisplayNode.searchDisplayController {
            if let (view, action) = searchController.previewViewAndActionAtLocation(location) {
                if let peerId = action as? PeerId, peerId.namespace != Namespaces.Peer.SecretChat {
                    var sourceRect = view.superview!.convert(view.frame, to: sourceView)
                    sourceRect.size.height -= UIScreenPixel

                    let chatController = ChatController(account: self.account, chatLocation: .peer(peerId), mode: .standard(previewing: true))
                    //                    chatController.peekActions = .remove({ [weak self] in
                    //                        if let strongSelf = self {
                    //                            let _ = removeRecentPeer(account: strongSelf.account, peerId: peerId).start()
                    //                            let searchContainer = strongSelf.chatListDisplayNode.searchDisplayController?.contentNode as? ChatListSearchContainerNode
                    //                            searchContainer?.removePeerFromTopPeers(peerId)
                    //                        }
                    //                    })
                    chatController.canReadHistory.set(false)
                    chatController.containerLayoutUpdated(ContainerViewLayout(size: contentSize, metrics: LayoutMetrics(), intrinsicInsets: UIEdgeInsets(), safeInsets: UIEdgeInsets(), statusBarHeight: nil, inputHeight: nil, standardInputHeight: 216.0, inputHeightIsInteractivellyChanging: false), transition: .immediate)
                    return (chatController, sourceRect)
                } else if let messageId = action as? MessageId, messageId.peerId.namespace != Namespaces.Peer.SecretChat {
                    var sourceRect = view.superview!.convert(view.frame, to: sourceView)
                    sourceRect.size.height -= UIScreenPixel

                    let chatController = ChatController(account: self.account, chatLocation: .peer(messageId.peerId), messageId: messageId, mode: .standard(previewing: true))
                    chatController.canReadHistory.set(false)
                    chatController.containerLayoutUpdated(ContainerViewLayout(size: contentSize, metrics: LayoutMetrics(), intrinsicInsets: UIEdgeInsets(), safeInsets: UIEdgeInsets(), statusBarHeight: nil, inputHeight: nil, standardInputHeight: 216.0, inputHeightIsInteractivellyChanging: false), transition: .immediate)
                    return (chatController, sourceRect)
                }
            }
            return nil
        }

        var isEditing = false
        self.chatListDisplayNode.chatListNode.updateState { state in
            isEditing = state.editing
            return state
        }

        if isEditing {
            return nil
        }

        let listLocation = self.view.convert(location, to: self.chatListDisplayNode.chatListNode.view)

        var selectedNode: ChatListItemNode?
        self.chatListDisplayNode.chatListNode.forEachItemNode { itemNode in
            if let itemNode = itemNode as? ChatListItemNode, itemNode.frame.contains(listLocation) {
                selectedNode = itemNode
            }
        }
        if let selectedNode = selectedNode, let item = selectedNode.item {
            var sourceRect = selectedNode.view.superview!.convert(selectedNode.frame, to: sourceView)
            sourceRect.size.height -= UIScreenPixel
            switch item.content {
            case let .peer(_, peer, _, _, _, _, _, _, _):
                if peer.peerId.namespace != Namespaces.Peer.SecretChat && peer.peerId.namespace != FolderPeerIdNamespace {
                    let chatController = ChatController(account: self.account, chatLocation: .peer(peer.peerId), mode: .standard(previewing: true))
                    chatController.canReadHistory.set(false)
                    chatController.containerLayoutUpdated(ContainerViewLayout(size: contentSize, metrics: LayoutMetrics(), intrinsicInsets: UIEdgeInsets(), safeInsets: UIEdgeInsets(), statusBarHeight: nil, inputHeight: nil, standardInputHeight: 216.0, inputHeightIsInteractivellyChanging: false), transition: .immediate)
                    return (chatController, sourceRect)
                } else {
                    return nil
                }
            case let .groupReference(groupId, _, _, _):
                let chatListController = ChatListController(account: self.account, groupId: groupId, controlsHistoryPreload: false)
                chatListController.containerLayoutUpdated(ContainerViewLayout(size: contentSize, metrics: LayoutMetrics(), intrinsicInsets: UIEdgeInsets(), safeInsets: UIEdgeInsets(), statusBarHeight: nil, inputHeight: nil, standardInputHeight: 216.0, inputHeightIsInteractivellyChanging: false), transition: .immediate)
                return (chatListController, sourceRect)
            }
        } else {
            return nil
        }
    }

    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.previewingCommit(viewControllerToCommit)
    }

    func previewingCommit(_ viewControllerToCommit: UIViewController) {
        if let viewControllerToCommit = viewControllerToCommit as? ViewController {
            if let chatController = viewControllerToCommit as? ChatController {
                chatController.canReadHistory.set(true)
                chatController.updatePresentationMode(.standard(previewing: false))
                if let navigationController = self.navigationController as? NavigationController {
                    navigateToChatController(navigationController: navigationController, chatController: chatController, account: self.account, chatLocation: chatController.chatLocation, animated: false)
                    self.chatListDisplayNode.chatListNode.clearHighlightAnimated(true)
                }
            }
        }
    }

    public var keyShortcuts: [KeyShortcut] {
//        let strings = self.presentationData.strings
//
//        let toggleSearch: () -> Void = { [weak self] in
//            if let strongSelf = self {
//                if strongSelf.displayNavigationBar {
//                    strongSelf.activateSearch()
//                } else {
//                    strongSelf.deactivateSearch(animated: true)
//                }
//            }
//        }

        return [
//            KeyShortcut(title: strings.KeyCommand_JumpToPreviousChat, input: UIKeyInputUpArrow, modifiers: [.alternate], action: { [weak self] in
//                if let strongSelf = self {
//                    strongSelf.chatListDisplayNode.chatListNode.selectChat(.previous(unread: false))
//                }
//            }),
//            KeyShortcut(title: strings.KeyCommand_JumpToNextChat, input: UIKeyInputDownArrow, modifiers: [.alternate], action: { [weak self] in
//                if let strongSelf = self {
//                    strongSelf.chatListDisplayNode.chatListNode.selectChat(.next(unread: false))
//                }
//            }),
//            KeyShortcut(title: strings.KeyCommand_JumpToPreviousUnreadChat, input: UIKeyInputUpArrow, modifiers: [.alternate, .shift], action: { [weak self] in
//                if let strongSelf = self {
//                    strongSelf.chatListDisplayNode.chatListNode.selectChat(.previous(unread: true))
//                }
//            }),
//            KeyShortcut(title: strings.KeyCommand_JumpToNextUnreadChat, input: UIKeyInputDownArrow, modifiers: [.alternate, .shift], action: { [weak self] in
//                if let strongSelf = self {
//                    strongSelf.chatListDisplayNode.chatListNode.selectChat(.next(unread: true))
//                }
//            }),
//            KeyShortcut(title: strings.KeyCommand_NewMessage, input: "N", modifiers: [.command], action: { [weak self] in
//                if let strongSelf = self {
//                    strongSelf.composePressed()
//                }
//            }),
//            KeyShortcut(title: strings.KeyCommand_Find, input: "\t", modifiers: [], action: toggleSearch),
//            KeyShortcut(input: UIKeyInputEscape, modifiers: [], action: toggleSearch)
        ]
    }

    private func _standardTextAlertController(
        theme: AlertControllerTheme,
        title: String?,
        text: String,
        inputPlaceholder: String,
        renameAction: @escaping (String) -> Void,
        keyboardColor: PresentationThemeKeyboardColor,
        placeholderColor: UIColor,
        primaryTextColor: UIColor
    ) -> AlertController {
        var dismissImpl: (() -> Void)?
        var renameImpl: (() -> Void)?

        let actions = [
            TextAlertAction.init(type: .defaultAction, title: presentationData.strings.Folder_Confirm, action: {
                renameImpl?()
            }),
            TextAlertAction.init(type: .genericAction, title: presentationData.strings.Common_Cancel, action: { })
        ]

        let contentNode = _TextAlertContentNode(
            theme: theme,
            title: title != nil ? NSAttributedString(string: title!, font: Font.medium(17.0), textColor: theme.primaryColor, paragraphAlignment: .center) : nil,
            text: NSAttributedString(string: text, font: title == nil ? Font.semibold(17.0) : Font.regular(13.0),
                                     textColor: theme.primaryColor, paragraphAlignment: .center),
            inputPlaceholder: inputPlaceholder,
            actions: actions.map { action in
                return TextAlertAction(type: action.type, title: action.title, action: {
                    action.action()
                    dismissImpl?()
                })
            },
            actionLayout: .horizontal,
            keyboardColor: keyboardColor,
            placeholderColor: placeholderColor,
            primaryTextColor: primaryTextColor
        )

        let controller = AlertController(
            theme: theme,
            contentNode: contentNode
        )

        renameImpl = { [weak contentNode] in
            renameAction(contentNode?.name ?? "")
        }

        dismissImpl = { [weak controller] in
            controller?.dismissAnimated()
        }

        return controller
    }
}

// MARK: -

private extension FolderController {

    private func updateFilter() {
        
    }

    func setupCallbacks() {
//        self.tabBarView.tapHandler = { [weak self] in
//            let mode: ChatListMode
//            switch $0 {
//            case .general:
//                mode = .standard
//            case .groups:
//                mode = .filter(type: .groups)
//            case .peers:
//                mode = .filter(type: .privateChats)
//            case .channels:
//                mode = .filter(type: .channels)
//            case .bots:
//                mode = .filter(type: .bots)
//            case .folders:
//                mode = .folders
//            }
//
//            self?.chatListMode = mode
//        }
//
//        account.postbox.setUnreadCatigoriesCallback { [weak self] unreadCategories in
//            let markedTabs = unreadCategories.compactMap { (category) -> TabItem? in
//                switch category {
//                case .privateChats:
//                    return .peers
//                case .groups:
//                    return .groups
//                case .channels:
//                    return .channels
//                case .bots:
//                    return .bots
//                case .all:
//                    return .general
//                default:
//                    return nil
//                }
//            }
//
//            DispatchQueue.main.async {
//                self?.tabBarView.setMarks(for: .init(markedTabs))
//            }
//        }
//
//        let tabBarHeight = Constants.tabBarHeight
//        let navbarHeight = Constants.navbarHeight
//
//        chatListDisplayNode.chatListNode.didScroll = { [unowned self] in
//            let statusBarHeight = self.validLayout?.statusBarHeight ?? 0.0
//            let tabBarInset = navbarHeight + statusBarHeight
//            let newOffset = $0 - tabBarHeight
//
//            guard newOffset > 0 else { return }
//
//            let change = newOffset - self.previousContentOffset
//            self.previousContentOffset = newOffset
//
//            if self.currentTabBarViewOffset <= 0 && change < 0 {
//                self.currentTabBarViewOffset = min(0.0, self.currentTabBarViewOffset - change)
//            } else if self.currentTabBarViewOffset > -tabBarHeight && change > 0 {
//                self.currentTabBarViewOffset = max(-tabBarHeight, self.currentTabBarViewOffset - change)
//            }
//
//            self.tabBarViewTopConstraint?.constant = self.currentTabBarViewOffset + tabBarInset
//        }
//
//        chatListDisplayNode.chatListNode.didEndScroll = { [unowned self] in
//            let statusBarHeight = self.validLayout?.statusBarHeight ?? 0.0
//            let tabBarInset = navbarHeight + statusBarHeight
//            guard
//                self.currentTabBarViewOffset != 0.0,
//                self.currentTabBarViewOffset != tabBarHeight,
//                self.tabBarViewTopConstraint?.constant != 0,
//                self.tabBarViewTopConstraint?.constant != tabBarInset
//                else { return }
//
//            if self.previousContentOffset <= tabBarHeight * 2 {
//                self.currentTabBarViewOffset = 0.0
//            } else if self.currentTabBarViewOffset >= -tabBarHeight / 2 {
//                self.currentTabBarViewOffset = 0.0
//            } else {
//                self.currentTabBarViewOffset = -tabBarInset
//            }
//
//            self.tabBarViewTopConstraint?.constant = self.currentTabBarViewOffset + tabBarInset
//            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseIn, animations: {
//                self.view.layoutIfNeeded()
//            })
//        }
    }

    func switchToCustomGroups() {
        // TODO: Switch top right icon
    }

}

private final class TextAlertContentActionNode: HighlightableButtonNode {
    private let backgroundNode: ASDisplayNode

    let action: TextAlertAction

    init(theme: AlertControllerTheme, action: TextAlertAction) {
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true
        self.backgroundNode.backgroundColor = theme.highlightedItemColor
        self.backgroundNode.alpha = 0.0

        self.action = action

        super.init()

        self.titleNode.maximumNumberOfLines = 2
        var font = Font.regular(17.0)
        var color = theme.accentColor
        switch action.type {
        case .defaultAction, .genericAction:
            break
        case .destructiveAction:
            color = theme.destructiveColor
        }
        switch action.type {
        case .defaultAction:
            font = Font.semibold(17.0)
        case .destructiveAction, .genericAction:
            break
        }
        self.setAttributedTitle(NSAttributedString(string: action.title, font: font, textColor: color, paragraphAlignment: .center), for: [])

        self.highligthedChanged = { [weak self] value in
            if let strongSelf = self {
                if value {
                    if strongSelf.backgroundNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.backgroundNode, at: 0)
                    }
                    strongSelf.backgroundNode.layer.removeAnimation(forKey: "opacity")
                    strongSelf.backgroundNode.alpha = 1.0
                } else if !strongSelf.backgroundNode.alpha.isZero {
                    strongSelf.backgroundNode.alpha = 0.0
                    strongSelf.backgroundNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.25)
                }
            }
        }
    }

    override func didLoad() {
        super.didLoad()

        self.addTarget(self, action: #selector(self.pressed), forControlEvents: .touchUpInside)
    }

    @objc func pressed() {
        self.action.action()
    }

    override func layout() {
        super.layout()

        self.backgroundNode.frame = self.bounds
    }
}


public final class _TextAlertContentNode: AlertContentNode {
    private let theme: AlertControllerTheme
    private let actionLayout: TextAlertContentActionLayout

    private let titleNode: ASTextNode?
    private let textNode: ImmediateTextNode
    private let inputNode: TextFieldNode

    private let actionNodesSeparator: ASDisplayNode
    private let actionNodes: [TextAlertContentActionNode]
    private let actionVerticalSeparators: [ASDisplayNode]

    var name: String?

    public var textAttributeAction: (NSAttributedStringKey, (Any) -> Void)? {
        didSet {
            if let (attribute, textAttributeAction) = self.textAttributeAction {
                self.textNode.highlightAttributeAction = { attributes in
                    if let _ = attributes[attribute] {
                        return attribute
                    } else {
                        return nil
                    }
                }
                self.textNode.tapAttributeAction = { attributes in
                    if let value = attributes[attribute] {
                        textAttributeAction(value)
                    }
                }
                self.textNode.linkHighlightColor = self.theme.accentColor.withAlphaComponent(0.5)
            } else {
                self.textNode.highlightAttributeAction = nil
                self.textNode.tapAttributeAction = nil
            }
        }
    }

    public init(theme: AlertControllerTheme, title: NSAttributedString?, text: NSAttributedString, inputPlaceholder: String, actions: [TextAlertAction], actionLayout: TextAlertContentActionLayout, keyboardColor: PresentationThemeKeyboardColor, placeholderColor: UIColor, primaryTextColor: UIColor) {
        self.theme = theme
        self.actionLayout = actionLayout
        if let title = title {
            let titleNode = ASTextNode()
            titleNode.attributedText = title
            titleNode.displaysAsynchronously = false
            titleNode.isUserInteractionEnabled = false
            titleNode.maximumNumberOfLines = 1
            titleNode.truncationMode = .byTruncatingTail
            self.titleNode = titleNode
        } else {
            self.titleNode = nil
        }

        self.textNode = ImmediateTextNode()
        self.textNode.maximumNumberOfLines = 0
        self.textNode.attributedText = text
        self.textNode.displaysAsynchronously = false
        self.textNode.isLayerBacked = false
        if text.length != 0 {
            if let paragraphStyle = text.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle {
                self.textNode.textAlignment = paragraphStyle.alignment
            }
        }

        self.inputNode = TextFieldNode()
        self.inputNode.textField.placeholder = inputPlaceholder
        self.inputNode.textField.font = Font.regular(15.0)
        self.inputNode.textField.textColor = primaryTextColor
        self.inputNode.textField.tintColor = theme.accentColor
        self.inputNode.textField.autocorrectionType = .no
        self.inputNode.textField.returnKeyType = .done
        self.inputNode.textField.textAlignment = .natural
//        self.inputNode.textField.contentInsets = .szero
        self.inputNode.textField.attributedPlaceholder = NSAttributedString(string: inputPlaceholder, font: Font.regular(15.0), textColor: placeholderColor)
//        self.inputNode.textField.borderStyle = .roundedRect
        switch keyboardColor {
            case .light:
                self.inputNode.textField.keyboardAppearance = .default
            case .dark:
                self.inputNode.textField.keyboardAppearance = .dark
        }

//        self.firstNameField = TextFieldNode()
//        self.firstNameField.textField.font = Font.regular(20.0)
//        self.firstNameField.textField.textColor = self.theme.primaryColor
//        self.firstNameField.textField.textAlignment = .natural
//        self.firstNameField.textField.returnKeyType = .next
//        self.firstNameField.textField.attributedPlaceholder = NSAttributedString(string: self.strings.UserInfo_FirstNamePlaceholder, font: self.firstNameField.textField.font, textColor: self.theme.textPlaceholderColor)
//        self.firstNameField.textField.autocapitalizationType = .words
//        self.firstNameField.textField.autocorrectionType = .no
//        if #available(iOSApplicationExtension 10.0, *) {
//            self.firstNameField.textField.textContentType = .givenName
//        }
//
//        self.lastNameField = TextFieldNode()
//        self.lastNameField.textField.font = Font.regular(20.0)
//        self.lastNameField.textField.textColor = self.theme.primaryColor
//        self.lastNameField.textField.textAlignment = .natural
//        self.lastNameField.textField.returnKeyType = .done
//        self.lastNameField.textField.attributedPlaceholder = NSAttributedString(string: strings.UserInfo_LastNamePlaceholder, font: self.lastNameField.textField.font, textColor: self.theme.textPlaceholderColor)
//        self.lastNameField.textField.autocapitalizationType = .words
//        self.lastNameField.textField.autocorrectionType = .no
//        if #available(iOSApplicationExtension 10.0, *) {
//            self.lastNameField.textField.textContentType = .familyName
//        }


        self.actionNodesSeparator = ASDisplayNode()
        self.actionNodesSeparator.isLayerBacked = true
        self.actionNodesSeparator.backgroundColor = theme.separatorColor

        self.actionNodes = actions.map { action -> TextAlertContentActionNode in
            return TextAlertContentActionNode(theme: theme, action: action)
        }

        var actionVerticalSeparators: [ASDisplayNode] = []
        if actions.count > 1 {
            for _ in 0 ..< actions.count - 1 {
                let separatorNode = ASDisplayNode()
                separatorNode.isLayerBacked = true
                separatorNode.backgroundColor = theme.separatorColor
                actionVerticalSeparators.append(separatorNode)
            }
        }
        self.actionVerticalSeparators = actionVerticalSeparators

        super.init()

        self.inputNode.textField.delegate = self
        self.inputNode.textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)

        if let titleNode = self.titleNode {
            self.addSubnode(titleNode)
        }
        self.addSubnode(self.textNode)
        self.addSubnode(self.inputNode)

        self.addSubnode(self.actionNodesSeparator)

        for actionNode in self.actionNodes {
            self.addSubnode(actionNode)
        }

        for separatorNode in self.actionVerticalSeparators {
            self.addSubnode(separatorNode)
        }
    }

    override public func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition) -> CGSize {
        let insets = UIEdgeInsets(top: 18.0, left: 18.0, bottom: 18.0, right: 18.0)

        var titleSize: CGSize?
        if let titleNode = self.titleNode {
            titleSize = titleNode.measure(CGSize(width: size.width - insets.left - insets.right, height: CGFloat.greatestFiniteMagnitude))
        }
        let textSize = self.textNode.updateLayout(CGSize(width: size.width - insets.left - insets.right, height: CGFloat.greatestFiniteMagnitude))
        let inputSize = CGSize(width: textSize.width, height: 44.0)

        let actionButtonHeight: CGFloat = 44.0

        var minActionsWidth: CGFloat = 0.0
        let maxActionWidth: CGFloat = floor(size.width / CGFloat(self.actionNodes.count))
        let actionTitleInsets: CGFloat = 8.0

        var effectiveActionLayout = self.actionLayout
        for actionNode in self.actionNodes {
            let actionTitleSize = actionNode.titleNode.measure(CGSize(width: maxActionWidth, height: actionButtonHeight))
            if case .horizontal = effectiveActionLayout, actionTitleSize.height > actionButtonHeight * 0.6667 {
                effectiveActionLayout = .vertical
            }
            switch effectiveActionLayout {
            case .horizontal:
                minActionsWidth += actionTitleSize.width + actionTitleInsets
            case .vertical:
                minActionsWidth = max(minActionsWidth, actionTitleSize.width + actionTitleInsets)
            }
        }

        let resultSize: CGSize

        var actionsHeight: CGFloat = 0.0
        switch effectiveActionLayout {
        case .horizontal:
            actionsHeight = actionButtonHeight
        case .vertical:
            actionsHeight = actionButtonHeight * CGFloat(self.actionNodes.count)
        }

        if let titleNode = titleNode, let titleSize = titleSize {
            var contentWidth = max(max(titleSize.width, textSize.width), minActionsWidth)
            contentWidth = max(contentWidth, 150.0)

            let spacing: CGFloat = 6.0
            let titleFrame = CGRect(origin: CGPoint(x: insets.left + floor((contentWidth - titleSize.width) / 2.0), y: insets.top), size: titleSize)
            transition.updateFrame(node: titleNode, frame: titleFrame)

            let textFrame = CGRect(origin: CGPoint(x: insets.left + floor((contentWidth - textSize.width) / 2.0), y: titleFrame.maxY + spacing), size: textSize)
            transition.updateFrame(node: self.textNode, frame: textFrame)

            let inputFrame = CGRect(origin: CGPoint(x: textFrame.origin.x, y: textFrame.maxY + spacing), size: inputSize)
            transition.updateFrame(node: self.inputNode, frame: inputFrame)

            resultSize = CGSize(width: contentWidth + insets.left + insets.right, height: titleSize.height + spacing + textSize.height + spacing + inputSize.height + actionsHeight + insets.top + insets.bottom)
        } else {
            var contentWidth = max(textSize.width, minActionsWidth)
            contentWidth = max(contentWidth, 150.0)

            let spacing: CGFloat = 6.0
            let textFrame = CGRect(origin: CGPoint(x: insets.left + floor((contentWidth - textSize.width) / 2.0), y: insets.top), size: textSize)
            transition.updateFrame(node: self.textNode, frame: textFrame)

            let inputFrame = CGRect(origin: CGPoint(x: textFrame.origin.x, y: textFrame.maxY + spacing), size: inputSize)
            transition.updateFrame(node: self.inputNode, frame: inputFrame)

            resultSize = CGSize(width: contentWidth + insets.left + insets.right, height: textSize.height + inputSize.height + actionsHeight + insets.top + insets.bottom)
        }

        self.actionNodesSeparator.frame = CGRect(origin: CGPoint(x: 0.0, y: resultSize.height - actionsHeight - UIScreenPixel), size: CGSize(width: resultSize.width, height: UIScreenPixel))

        var actionOffset: CGFloat = 0.0
        let actionWidth: CGFloat = floor(resultSize.width / CGFloat(self.actionNodes.count))
        var separatorIndex = -1
        var nodeIndex = 0
        for actionNode in self.actionNodes {
            if separatorIndex >= 0 {
                let separatorNode = self.actionVerticalSeparators[separatorIndex]
                switch effectiveActionLayout {
                case .horizontal:
                    transition.updateFrame(node: separatorNode, frame: CGRect(origin: CGPoint(x: actionOffset - UIScreenPixel, y: resultSize.height - actionsHeight), size: CGSize(width: UIScreenPixel, height: actionsHeight - UIScreenPixel)))
                case .vertical:
                    transition.updateFrame(node: separatorNode, frame: CGRect(origin: CGPoint(x: 0.0, y: resultSize.height - actionsHeight + actionOffset - UIScreenPixel), size: CGSize(width: resultSize.width, height: UIScreenPixel)))
                }
            }
            separatorIndex += 1

            let currentActionWidth: CGFloat
            switch effectiveActionLayout {
            case .horizontal:
                if nodeIndex == self.actionNodes.count - 1 {
                    currentActionWidth = resultSize.width - actionOffset
                } else {
                    currentActionWidth = actionWidth
                }
            case .vertical:
                currentActionWidth = resultSize.width
            }

            let actionNodeFrame: CGRect
            switch effectiveActionLayout {
            case .horizontal:
                actionNodeFrame = CGRect(origin: CGPoint(x: actionOffset, y: resultSize.height - actionsHeight), size: CGSize(width: currentActionWidth, height: actionButtonHeight))
                actionOffset += currentActionWidth
            case .vertical:
                actionNodeFrame = CGRect(origin: CGPoint(x: 0.0, y: resultSize.height - actionsHeight + actionOffset), size: CGSize(width: currentActionWidth, height: actionButtonHeight))
                actionOffset += actionButtonHeight
            }

            transition.updateFrame(node: actionNode, frame: actionNodeFrame)

            nodeIndex += 1
        }

        return resultSize
    }

    @objc
    private func textDidChange() {
        name = inputNode.textField.text
    }

}

extension _TextAlertContentNode: UITextFieldDelegate {

    public func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        return range.location + range.length <= 24
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.actionNodes.first?.action.action()
        return true
    }

}
