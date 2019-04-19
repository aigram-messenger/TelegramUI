//
//  ChatSelectionControllerNode.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 17/04/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Display
import AsyncDisplayKit
import UIKit
import Postbox
import TelegramCore
import SwiftSignalKit

private struct SearchResultEntry: Identifiable {
    let index: Int
    let peer: Peer

    var stableId: Int64 {
        return self.peer.id.toInt64()
    }

    static func ==(lhs: SearchResultEntry, rhs: SearchResultEntry) -> Bool {
        return lhs.index == rhs.index && lhs.peer.isEqual(rhs.peer)
    }

    static func <(lhs: SearchResultEntry, rhs: SearchResultEntry) -> Bool {
        return lhs.index < rhs.index
    }
}

final class ChatSelectionControllerNode: ASDisplayNode {
    let contactListNode: ChatListSelectionNode
    var searchResultsNode: ContactListNode?

    private let account: Account

    private var containerLayout: (ContainerViewLayout, CGFloat)?

    var requestDeactivateSearch: (() -> Void)?
    var requestOpenPeerFromSearch: ((ChatListSelectionPeerId) -> Void)?
    var openPeer: ((ChatListSelectionPeer) -> Void)?
    var removeSelectedPeer: ((ChatListSelectionPeerId) -> Void)?

    var editableTokens: [EditableTokenListToken] = []

    private let searchResultsReadyDisposable = MetaDisposable()
    var dismiss: (() -> Void)?

    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?

    init(account: Account, options: [ChatListSelectionAdditionalOption], filters: [ChatListSelectionFilter]) {
        self.account = account
        self.presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }

        self.contactListNode = ChatListSelectionNode(account: account, presentation: .natural(displaySearch: false, options: options), filters: filters, selectionState: ChatListSelectionNodeGroupSelectionState())

        super.init()

        self.setViewBlock({
            return UITracingLayerView()
        })

        self.backgroundColor = self.presentationData.theme.chatList.backgroundColor

        self.addSubnode(self.contactListNode)

        self.contactListNode.openPeer = { [weak self] peer in
            self?.openPeer?(peer)
        }

        let searchText = ValuePromise<String>()

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

    deinit {
        self.searchResultsReadyDisposable.dispose()
    }

    private func updateThemeAndStrings() {
        self.backgroundColor = self.presentationData.theme.chatList.backgroundColor
    }

    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        self.containerLayout = (layout, navigationBarHeight)

        var insets = layout.insets(options: [.input])
        insets.top += navigationBarHeight

        self.contactListNode.containerLayoutUpdated(ContainerViewLayout(size: layout.size, metrics: layout.metrics, intrinsicInsets: insets, safeInsets: layout.safeInsets, statusBarHeight: layout.statusBarHeight, inputHeight: layout.inputHeight, standardInputHeight: layout.standardInputHeight, inputHeightIsInteractivellyChanging: layout.inputHeightIsInteractivellyChanging), transition: transition)
        self.contactListNode.frame = CGRect(origin: CGPoint(), size: layout.size)

        if let searchResultsNode = self.searchResultsNode {
            searchResultsNode.containerLayoutUpdated(ContainerViewLayout(size: layout.size, metrics: layout.metrics, intrinsicInsets: insets, safeInsets: layout.safeInsets, statusBarHeight: layout.statusBarHeight, inputHeight: layout.inputHeight, standardInputHeight: layout.standardInputHeight, inputHeightIsInteractivellyChanging: layout.inputHeightIsInteractivellyChanging), transition: transition)
            searchResultsNode.frame = CGRect(origin: CGPoint(), size: layout.size)
        }
    }

    func animateIn() {
        self.layer.animatePosition(from: CGPoint(x: self.layer.position.x, y: self.layer.position.y + self.layer.bounds.size.height), to: self.layer.position, duration: 0.5, timingFunction: kCAMediaTimingFunctionSpring)
    }

    func animateOut(completion: (() -> Void)?) {
        self.layer.animatePosition(from: self.layer.position, to: CGPoint(x: self.layer.position.x, y: self.layer.position.y + self.layer.bounds.size.height), duration: 0.2, timingFunction: kCAMediaTimingFunctionEaseInEaseOut, removeOnCompletion: false, completion: { [weak self] _ in
            if let strongSelf = self {
                strongSelf.dismiss?()
                completion?()
            }
        })
    }
}
