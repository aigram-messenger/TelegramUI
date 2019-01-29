//
//  ChatSuggestionsInputNode.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 11/12/2018.
//  Copyright © 2018 Telegram. All rights reserved.
//

import Foundation
import Display
import AsyncDisplayKit
import Postbox
import TelegramCore
import SwiftSignalKit

enum ChatBotsInputPanelAuxiliaryNamespace: Int32 {
    case store = 8
    case bots = 9
}

private enum ChatBotsInputPaneType: Equatable, Comparable, Identifiable {
    case store
    case bot(Int)
    
    var stableId: Int {
        switch self {
        case .store: return 1
        case .bot(let id): return 10 + id
        }
    }
    
    static func == (lhs: ChatBotsInputPaneType, rhs: ChatBotsInputPaneType) -> Bool {
        switch (lhs, rhs) {
        case (.store, .store): return true
        case let (.bot(id1), .bot(id2)): return id1 == id2
        default: return false
        }
    }
    
    static func < (lhs: ChatBotsInputPaneType, rhs: ChatBotsInputPaneType) -> Bool {
        switch (lhs, rhs) {
        case let (.bot(id1), .bot(id2)): return id1 < id2
        default: return false
        }
    }
}

private final class CollectionListContainerNode: ASDisplayNode {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for subview in self.view.subviews {
            if let result = subview.hitTest(point.offsetBy(dx: -subview.frame.minX, dy: -subview.frame.minY), with: event) {
                return result
            }
        }
        return nil
    }
}

private struct ChatBotsInputPaneArrangement {
    let panes: [ChatBotsInputPaneType]
    let currentIndex: Int
    let indexTransition: CGFloat
    
    func withIndexTransition(_ indexTransition: CGFloat) -> ChatBotsInputPaneArrangement {
        return ChatBotsInputPaneArrangement(panes: self.panes, currentIndex: currentIndex, indexTransition: indexTransition)
    }
    
    func withCurrentIndex(_ currentIndex: Int) -> ChatBotsInputPaneArrangement {
        return ChatBotsInputPaneArrangement(panes: self.panes, currentIndex: currentIndex, indexTransition: self.indexTransition)
    }
}

final class ChatSuggestionsInputNode: ChatInputNode {
    private let account: Account
    private let controllerInteraction: ChatControllerInteraction
    private var validLayout: (CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, ChatPresentationInterfaceState)?
    
    private var currentView: ItemCollectionsView?

    private let botsListPanel: ASDisplayNode
    private let topSeparator: ASDisplayNode
    private let botsListContainer: ASDisplayNode
    private let botsListView: ListView

    private var bots: [ChatBot] = []

    private var theme: PresentationTheme?
    
    private var inputNodeInteraction: ChatBotsInputNodeInteraction!
    private var paneArrangement: ChatBotsInputPaneArrangement
    
    private var panesAndAnimatingOut: [(ChatMediaInputPane, Bool)]
    private var panRecognizer: UIPanGestureRecognizer?
    private var currentResponses: [ChatBotResult]?

    init(account: Account, controllerInteraction: ChatControllerInteraction, theme: PresentationTheme) {
        self.account = account
        self.controllerInteraction = controllerInteraction
        self.theme = theme
        
        self.botsListContainer = ASDisplayNode()
        self.botsListContainer.clipsToBounds = true
        self.botsListContainer.backgroundColor = theme.chat.inputPanel.panelBackgroundColor
        
        self.botsListPanel = ASDisplayNode()
        self.botsListPanel.clipsToBounds = true
        self.botsListPanel.backgroundColor = theme.chat.inputPanel.panelBackgroundColor
        
        self.topSeparator = ASDisplayNode()
        self.topSeparator.isLayerBacked = true
        self.topSeparator.backgroundColor = theme.chat.inputMediaPanel.panelSerapatorColor
        
        self.botsListView = ListView()
        self.botsListView.transform = CATransform3DMakeRotation(-CGFloat(Double.pi / 2.0), 0.0, 0.0, 1.0)
        
        self.paneArrangement = ChatBotsInputPaneArrangement(panes: [], currentIndex: -1, indexTransition: 0.0)
        
        self.panesAndAnimatingOut = []
        
        super.init()
        
        self.inputNodeInteraction = ChatBotsInputNodeInteraction(navigateToCollectionId: { [weak self] id in
            self?.navigateToCollection(withId: id)
        }, sendMessage: { [weak self] in
            self?.controllerInteraction.sendMessage($0)
        }, buyBot: { [weak self] bot in
            self?.controllerInteraction.buyBot(bot) { (bought) in
                self?.updateStorePane(for: bot)
            }
        }, enableBot: { [weak self] bot, enabled in
            ChatBotsManager.shared.enableBot(bot, enabled: enabled)
            self?.updateStorePane(for: bot)
            self?.controllerInteraction.handleMessagesWithBots(nil)
        }, botDetails: { [weak self] bot in
            self?.controllerInteraction.showBotDetails(bot)
        })

        self.backgroundColor = theme.chat.inputMediaPanel.stickersBackgroundColor
        
        self.botsListPanel.addSubnode(self.botsListView)
        self.botsListContainer.addSubnode(self.topSeparator)
        self.botsListContainer.addSubnode(self.botsListPanel)
        self.addSubnode(self.botsListContainer)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.panGesture(_:)))
        self.panRecognizer = panRecognizer
        self.view.addGestureRecognizer(panRecognizer)
    }
    
    deinit {}

    static func setupPanelIconInsets(item: ListViewItem, previousItem: ListViewItem?, nextItem: ListViewItem?) -> UIEdgeInsets {
        var insets = UIEdgeInsets()
        if previousItem != nil {
            insets.top += 3.0
        }
        if nextItem != nil {
            insets.bottom += 3.0
        }
        return insets
    }

    override func didLoad() {
        super.didLoad()
        self.view.disablesInteractiveTransitionGestureRecognizer = true
    }
    
    func set(botResponses: [ChatBotResult]) {
        guard self.currentResponses != botResponses else { return }
        self.currentResponses = botResponses
        self.updateBotsResults(botResponses)
    }
    
    func updateStorePane(for bot: ChatBot) {
        guard let pane = self.panesAndAnimatingOut.first?.0 as? ChatBotsInputStorePane else { return }
        pane.reloadData(for: bot)
    }
    
    private func insertListItems(with inserts: ([(Int, ChatBotsInputPaneType, Int?)]), botsResults: [ChatBotResult]) -> [ListViewInsertItem] {
        var result: [ListViewInsertItem] = []
        for insert in inserts {
            var item: ListViewItem
            switch insert.1 {
            case .store:
                item = ChatBotsStoreItem(inputNodeInteraction: self.inputNodeInteraction, theme: self.theme!) {
                    let collectionId = ItemCollectionId(namespace: ChatBotsInputPanelAuxiliaryNamespace.store.rawValue, id: 0)
                    self.inputNodeInteraction.navigateToCollectionId(collectionId)
                }
            case let .bot(id):
                let collectionId = ItemCollectionId(namespace: ChatBotsInputPanelAuxiliaryNamespace.bots.rawValue, id: ItemCollectionId.Id(id))
                guard let bot = botsResults.first(where: { $0.bot.id == id })?.bot else { continue }
                item = ChatBotsBotItem(inputNodeInteraction: self.inputNodeInteraction, theme: self.theme!, bot: bot) {
                    self.inputNodeInteraction.navigateToCollectionId(collectionId)
                }
            }
            result.append(ListViewInsertItem(index: insert.0, previousIndex: insert.2, item: item, directionHint: nil))
        }
        return result
    }
    
    private func updateListItems(with updates: ([(Int, ChatBotsInputPaneType, Int)]), botsResults: [ChatBotResult]) -> [ListViewUpdateItem] {
        var result = [ListViewUpdateItem]()
        for update in updates {
            var item: ListViewItem
            switch update.1 {
            case .store:
                item = ChatBotsStoreItem(inputNodeInteraction: self.inputNodeInteraction, theme: self.theme!) {
                    let collectionId = ItemCollectionId(namespace: ChatBotsInputPanelAuxiliaryNamespace.store.rawValue, id: 0)
                    self.inputNodeInteraction.navigateToCollectionId(collectionId)
                }
            case let .bot(id):
                let collectionId = ItemCollectionId(namespace: ChatBotsInputPanelAuxiliaryNamespace.bots.rawValue, id: ItemCollectionId.Id(id))
                guard let bot = botsResults.first(where: { $0.bot.id == id })?.bot else { continue }
                item = ChatBotsBotItem(inputNodeInteraction: self.inputNodeInteraction, theme: self.theme!, bot: bot) {
                    self.inputNodeInteraction.navigateToCollectionId(collectionId)
                }
            }
            result.append(ListViewUpdateItem(index: update.0, previousIndex: update.2, item: item, directionHint: nil))
        }
        return result
    }
    
    func updateBotsResults(_ results: [ChatBotResult]) {
        var toArrangements: [ChatBotsInputPaneType] = [.store]
        toArrangements.append(contentsOf: results.map { .bot($0.bot.id) })
        let (deletes, inserts, updates) = mergeListsStableWithUpdates(leftList: self.paneArrangement.panes, rightList: toArrangements)
        self.paneArrangement = ChatBotsInputPaneArrangement(panes: toArrangements, currentIndex: results.isEmpty ? 0 : 1, indexTransition: 0)
        
        let deleteListItems = deletes.map { ListViewDeleteItem(index: $0, directionHint: nil) }
        let insertListItems = self.insertListItems(with: inserts, botsResults: results)
        let updateListItems = self.updateListItems(with: updates, botsResults: results)
        
        for (pane, _) in self.panesAndAnimatingOut {
            pane.removeFromSupernode()
        }
        self.panesAndAnimatingOut = []
        var resultIndex = 0
        for paneType in toArrangements {
            switch paneType {
            case .store:
                self.panesAndAnimatingOut.append((ChatBotsInputStorePane(inputNodeInteraction: self.inputNodeInteraction, theme: self.theme!), false))
            case .bot(let botId):
                let bot = results.first(where: { $0.bot.id == botId })!.bot
                self.panesAndAnimatingOut.append((ChatBotsInputSuggestionsPane(bot: bot, responses: results[resultIndex].responses, inputNodeInteraction: self.inputNodeInteraction, theme: self.theme!), false))
                resultIndex += 1
            }
        }

        self.botsListView.transaction(deleteIndices: deleteListItems,
                                      insertIndicesAndItems: insertListItems,
                                      updateIndicesAndItems: updateListItems,
                                      options: [.Synchronous, .LowLatency],
                                      updateOpaqueState: nil)
        self.setCurrentPane(self.paneArrangement.panes[self.paneArrangement.currentIndex], transition: .animated(duration: 0.25, curve: .spring))
    }

    override func updateLayout(width: CGFloat, leftInset: CGFloat, rightInset: CGFloat, bottomInset: CGFloat, standardInputHeight: CGFloat, inputHeight: CGFloat, maximumHeight: CGFloat, inputPanelHeight: CGFloat, transition: ContainedViewLayoutTransition, interfaceState: ChatPresentationInterfaceState) -> (CGFloat, CGFloat) {
        self.validLayout = (width, leftInset, rightInset, bottomInset, standardInputHeight, inputHeight, maximumHeight, inputPanelHeight, interfaceState)
        
        let separatorHeight = UIScreenPixel
        let panelHeight = standardInputHeight
        let contentVerticalOffset: CGFloat = 0.0
        let containerOffset: CGFloat = 0

        transition.updateFrame(node: self.botsListContainer, frame: CGRect(origin: CGPoint(x: 0.0, y: contentVerticalOffset), size: CGSize(width: width, height: max(0.0, 41.0 + UIScreenPixel))))
        transition.updateFrame(node: self.botsListPanel, frame: CGRect(origin: CGPoint(x: 0.0, y: containerOffset), size: CGSize(width: width, height: 41.0)))
        transition.updateFrame(node: self.topSeparator, frame: CGRect(origin: CGPoint(x: 0.0, y: 41.0 + containerOffset), size: CGSize(width: width, height: separatorHeight)))
        
        let collectionListPanelOffset = CGFloat(0)
        self.botsListView.bounds = CGRect(x: 0.0, y: 0.0, width: 41.0, height: width)
        transition.updatePosition(node: self.botsListView, position: CGPoint(x: width / 2.0, y: (41.0 - collectionListPanelOffset) / 2.0))
        
        let updateSizeAndInsets = ListViewUpdateSizeAndInsets(size: CGSize(width: 41.0, height: width), insets: UIEdgeInsets(top: 4.0 + leftInset, left: 0.0, bottom: 4.0 + rightInset, right: 0.0), duration: 0, curve: .Default(duration: 0))
        
        self.botsListView.transaction(deleteIndices: [], insertIndicesAndItems: [], updateIndicesAndItems: [], options: [.Synchronous, .LowLatency], scrollToItem: nil, updateSizeAndInsets: updateSizeAndInsets, stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
        
        var visiblePanes: [(ChatBotsInputPaneType, CGFloat)] = []
        var paneIndex = 0
        for pane in self.paneArrangement.panes {
            let paneOrigin = CGFloat(paneIndex - self.paneArrangement.currentIndex) * width - self.paneArrangement.indexTransition * width
            if paneOrigin.isLess(than: width) && CGFloat(0.0).isLess(than: (paneOrigin + width)) {
                visiblePanes.append((pane, paneOrigin))
            }
            paneIndex += 1
        }
        
        for (pane, paneOrigin) in visiblePanes {
            guard let index = self.paneArrangement.panes.firstIndex(where: { $0 == pane }) else { continue }
            
            let paneFrame = CGRect(origin: CGPoint(x: paneOrigin + leftInset, y: 0.0), size: CGSize(width: width - leftInset - rightInset, height: panelHeight))
            let (panelNode, _) = self.panesAndAnimatingOut[index]
            
            if panelNode.supernode == nil {
                let x = index == 0 ? -width : width
                self.insertSubnode(panelNode, belowSubnode: self.botsListContainer)
                panelNode.frame = CGRect(origin: CGPoint(x: x, y: 0.0), size: CGSize(width: width, height: panelHeight))
            }
            if panelNode.frame != paneFrame {
                panelNode.layer.removeAnimation(forKey: "position")
                transition.updateFrame(node: panelNode, frame: paneFrame)
            }
        }
        
        for i in 0..<self.panesAndAnimatingOut.count {
            self.panesAndAnimatingOut[i].0.updateLayout(size: CGSize(width: width - leftInset - rightInset, height: panelHeight), topInset: 41.0, bottomInset: bottomInset, isExpanded: false, transition: transition)
            
            let paneType = self.paneArrangement.panes[i]
            let contains = visiblePanes.contains(where: { $0.0 == paneType })
            guard self.panesAndAnimatingOut[i].0.supernode != nil, !contains else {
                self.panesAndAnimatingOut[i].1 = false
                continue
            }

            if case .animated = transition {
                if !self.panesAndAnimatingOut[i].1 {
                    self.panesAndAnimatingOut[i].1 = true
                    var toLeft = false
                    if i <= self.paneArrangement.currentIndex {
                        toLeft = true
                    }
                    transition.animatePosition(node: self.panesAndAnimatingOut[i].0, to: CGPoint(x: (toLeft ? -width : width) + width / 2.0, y: self.panesAndAnimatingOut[i].0.layer.position.y), removeOnCompletion: false, completion: { [weak self] value in
                        if let strongSelf = self, value {
                            strongSelf.panesAndAnimatingOut[i].1 = false
                            strongSelf.panesAndAnimatingOut[i].0.removeFromSupernode()
                        }
                    })
                }
            } else {
                self.panesAndAnimatingOut[i].1 = false
                self.panesAndAnimatingOut[i].0.removeFromSupernode()
            }
        }
        
        return (standardInputHeight, max(0.0, panelHeight - standardInputHeight))
    }
    
    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            for i in 0..<self.panesAndAnimatingOut.count {
                if self.panesAndAnimatingOut[i].1 {
                    self.panesAndAnimatingOut[i].1 = false
                    self.panesAndAnimatingOut[i].0.removeFromSupernode()
                }
                self.panesAndAnimatingOut[i].0.layer.removeAllAnimations()
            }
        case .changed:
            guard let (width, leftInset, rightInset, bottomInset, standardInputHeight, inputHeight, maximumHeight, inputPanelHeight, interfaceState) = self.validLayout else { break }
            
            let translationX = -recognizer.translation(in: self.view).x
            var indexTransition = translationX / width
            if self.paneArrangement.currentIndex == 0 {
                indexTransition = max(0.0, indexTransition)
            } else if self.paneArrangement.currentIndex == self.paneArrangement.panes.count - 1 {
                indexTransition = min(0.0, indexTransition)
            }
            self.paneArrangement = self.paneArrangement.withIndexTransition(indexTransition)
            let _ = self.updateLayout(width: width, leftInset: leftInset, rightInset: rightInset, bottomInset: bottomInset, standardInputHeight: standardInputHeight, inputHeight: inputHeight, maximumHeight: maximumHeight, inputPanelHeight: inputPanelHeight, transition: .immediate, interfaceState: interfaceState)
        case .ended:
            guard let (width, _, _, _, _, _, _, _, _) = self.validLayout else { break }
            
            var updatedIndex = self.paneArrangement.currentIndex
            if abs(self.paneArrangement.indexTransition * width) > 30.0 {
                if self.paneArrangement.indexTransition < 0.0 {
                    updatedIndex = max(0, self.paneArrangement.currentIndex - 1)
                } else {
                    updatedIndex = min(self.paneArrangement.panes.count - 1, self.paneArrangement.currentIndex + 1)
                }
            }
            self.paneArrangement = self.paneArrangement.withIndexTransition(0.0)
            self.setCurrentPane(self.paneArrangement.panes[updatedIndex], transition: .animated(duration: 0.25, curve: .spring))
        case .cancelled:
            guard let (width, leftInset, rightInset, bottomInset, standardInputHeight, inputHeight, maximumHeight, inputPanelHeight, interfaceState) = self.validLayout else { break }
            
            self.paneArrangement = self.paneArrangement.withIndexTransition(0.0)
            let _ = self.updateLayout(width: width, leftInset: leftInset, rightInset: rightInset, bottomInset: bottomInset, standardInputHeight: standardInputHeight, inputHeight: inputHeight, maximumHeight: maximumHeight, inputPanelHeight: inputPanelHeight, transition: .animated(duration: 0.25, curve: .spring), interfaceState: interfaceState)
        default:
            break
        }
    }
    
    private func navigateToCollection(withId collectionId: ItemCollectionId) {
        guard (collectionId != self.inputNodeInteraction.highlightedItemCollectionId || true) else { return }

        if collectionId.namespace == ChatBotsInputPanelAuxiliaryNamespace.store.rawValue {
            self.setCurrentPane(.store, transition: .animated(duration: 0.25, curve: .spring))
        } else {
            self.setCurrentPane(.bot(Int(collectionId.id)), transition: .animated(duration: 0.25, curve: .spring))
        }
    }
    
    private func setCurrentPane(_ pane: ChatBotsInputPaneType, transition: ContainedViewLayoutTransition, collectionIdHint: Int32? = nil) {
        print("\(pane)")
        if let index = self.paneArrangement.panes.index(of: pane), index != self.paneArrangement.currentIndex {
            let previousStorePanelWasActive = self.paneArrangement.panes[self.paneArrangement.currentIndex] == .store
            self.paneArrangement = self.paneArrangement.withIndexTransition(0.0).withCurrentIndex(index)
            if let (width, leftInset, rightInset, bottomInset, standardInputHeight, inputHeight, maximumHeight, inputPanelHeight, interfaceState) = self.validLayout {
                let _ = self.updateLayout(width: width, leftInset: leftInset, rightInset: rightInset, bottomInset: bottomInset, standardInputHeight: standardInputHeight, inputHeight: inputHeight, maximumHeight: maximumHeight, inputPanelHeight: inputPanelHeight,  transition: .animated(duration: 0.25, curve: .spring), interfaceState: interfaceState)
                self.updateAppearanceTransition(transition: transition)
            }
            let updatedStorePanelWasActive = self.paneArrangement.panes[self.paneArrangement.currentIndex] == .store
            if updatedStorePanelWasActive != previousStorePanelWasActive {
                print("=>> UPDATE STORE PANE")
    //            self.gifPaneIsActiveUpdated(updatedGifPanelWasActive)
            }
            switch pane {
            case .store:
                self.setHighlightedItemCollectionId(ItemCollectionId(namespace: ChatBotsInputPanelAuxiliaryNamespace.store.rawValue, id: 0))
            case .bot(let id):
                self.setHighlightedItemCollectionId(ItemCollectionId(namespace: ChatBotsInputPanelAuxiliaryNamespace.bots.rawValue, id: ItemCollectionId.Id(id)))
            }
        } else {
            if let (width, leftInset, rightInset, bottomInset, standardInputHeight, inputHeight, maximumHeight, inputPanelHeight, interfaceState) = self.validLayout {
                let _ = self.updateLayout(width: width, leftInset: leftInset, rightInset: rightInset, bottomInset: bottomInset, standardInputHeight: standardInputHeight, inputHeight: inputHeight, maximumHeight: maximumHeight, inputPanelHeight: inputPanelHeight, transition: .animated(duration: 0.25, curve: .spring), interfaceState: interfaceState)
            }
            switch pane {
            case .store:
                self.setHighlightedItemCollectionId(ItemCollectionId(namespace: ChatBotsInputPanelAuxiliaryNamespace.store.rawValue, id: 0))
            case .bot(let id):
                self.setHighlightedItemCollectionId(ItemCollectionId(namespace: ChatBotsInputPanelAuxiliaryNamespace.bots.rawValue, id: ItemCollectionId.Id(id)))
            }
        }
    }
    
    private func updateAppearanceTransition(transition: ContainedViewLayoutTransition) {
//        var value: CGFloat = 1.0 - abs(self.currentCollectionListPanelOffset() / 41.0)
//        value = min(1.0, max(0.0, value))
//        self.inputNodeInteraction.appearanceTransition = max(0.1, value)
//        transition.updateAlpha(node: self.listView, alpha: value)
//        self.listView.forEachItemNode { itemNode in
//            if let itemNode = itemNode as? ChatMediaInputStickerPackItemNode {
//                itemNode.updateAppearanceTransition(transition: transition)
//            } else if let itemNode = itemNode as? ChatMediaInputMetaSectionItemNode {
//                itemNode.updateAppearanceTransition(transition: transition)
//            } else if let itemNode = itemNode as? ChatMediaInputRecentGifsItemNode {
//                itemNode.updateAppearanceTransition(transition: transition)
//            } else if let itemNode = itemNode as? ChatMediaInputTrendingItemNode {
//                itemNode.updateAppearanceTransition(transition: transition)
//            } else if let itemNode = itemNode as? ChatMediaInputPeerSpecificItemNode {
//                itemNode.updateAppearanceTransition(transition: transition)
//            }
//        }
    }
    
    private func setHighlightedItemCollectionId(_ collectionId: ItemCollectionId) {
        self.inputNodeInteraction.highlightedItemCollectionId = collectionId
        
        var ensuredNodeVisible = false
        var firstVisibleCollectionId: ItemCollectionId?
        self.botsListView.forEachItemNode { itemNode in
            if let itemNode = itemNode as? ChatBotsStoreItemNode {
                if firstVisibleCollectionId == nil {
                    firstVisibleCollectionId = itemNode.currentCollectionId
                }
                itemNode.updateIsHighlighted()
                if itemNode.currentCollectionId == collectionId {
                    self.botsListView.ensureItemNodeVisible(itemNode)
                    ensuredNodeVisible = true
                }
            } else if let itemNode = itemNode as? ChatBotsBotItemNode {
                if firstVisibleCollectionId == nil {
                    firstVisibleCollectionId = itemNode.currentCollectionId
                }
                itemNode.updateIsHighlighted()
                if itemNode.currentCollectionId == collectionId {
                    self.botsListView.ensureItemNodeVisible(itemNode)
                    ensuredNodeVisible = true
                }
            }
        }

        if let firstVisibleCollectionId = firstVisibleCollectionId, !ensuredNodeVisible {
            var collectionIdType: ChatBotsInputPaneType = .store
            switch collectionId.namespace {
            case ChatBotsInputPanelAuxiliaryNamespace.store.rawValue: collectionIdType = .store
            case ChatBotsInputPanelAuxiliaryNamespace.bots.rawValue: collectionIdType = .bot(Int(collectionId.id))
            default: break
            }
            var firstVisibleCollectionIdType: ChatBotsInputPaneType = .store
            switch firstVisibleCollectionId.namespace {
            case ChatBotsInputPanelAuxiliaryNamespace.store.rawValue: firstVisibleCollectionIdType = .store
            case ChatBotsInputPanelAuxiliaryNamespace.bots.rawValue: firstVisibleCollectionIdType = .bot(Int(firstVisibleCollectionId.id))
            default: break
            }
            
            let targetIndex = self.paneArrangement.panes.firstIndex(where: { $0 == collectionIdType })
            let firstVisibleIndex = self.paneArrangement.panes.firstIndex(where: { $0 == firstVisibleCollectionIdType })
            if let targetIndex = targetIndex, let firstVisibleIndex = firstVisibleIndex {
                let toRight = targetIndex > firstVisibleIndex
                self.botsListView.transaction(deleteIndices: [], insertIndicesAndItems: [], updateIndicesAndItems: [], options: [], scrollToItem: ListViewScrollToItem(index: targetIndex, position: toRight ? .bottom(0.0) : .top(0.0), animated: true, curve: .Default(duration: nil), directionHint: toRight ? .Down : .Up), updateSizeAndInsets: nil, stationaryItemRange: nil, updateOpaqueState: nil)
            }
        }
    }
}
