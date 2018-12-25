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

private final class ChatSuggestionsInputButtonNode: ASButtonNode {
    var suggestion: String?

    private var theme: PresentationTheme?

    init(theme: PresentationTheme) {
        super.init()
        
        self.updateTheme(theme: theme)
    }

    func updateTheme(theme: PresentationTheme) {
        if theme !== self.theme {
            self.theme = theme

            self.setBackgroundImage(PresentationResourcesChat.chatInputButtonPanelButtonImage(theme), for: [])
            self.setBackgroundImage(PresentationResourcesChat.chatInputButtonPanelButtonHighlightedImage(theme), for: [.highlighted])
        }
    }
}

final class ChatSuggestionsInputNode: ChatInputNode {
    private let account: Account
    private let controllerInteraction: ChatControllerInteraction
    
    private var currentView: ItemCollectionsView?

    private let botsListPanel: ASDisplayNode
    private let topSeparator: ASDisplayNode
    private let nodesContainer: ASDisplayNode
    private let botsListView: ListView

    private var buttonNodes: [ChatSuggestionsInputButtonNode] = []
    private var messages: [String] = []
    private var bots: [ChatBot] = []

    private var theme: PresentationTheme?
    
    private var inputNodeInteraction: ChatBotsInputNodeInteraction!

    init(account: Account, controllerInteraction: ChatControllerInteraction, theme: PresentationTheme) {
        self.account = account
        self.controllerInteraction = controllerInteraction
        self.theme = theme
        
        self.nodesContainer = ASDisplayNode()
        self.nodesContainer.clipsToBounds = true
        self.nodesContainer.backgroundColor = theme.chat.inputPanel.panelBackgroundColor
        
        self.botsListPanel = ASDisplayNode()
        self.botsListPanel.clipsToBounds = true
        self.botsListPanel.backgroundColor = theme.chat.inputPanel.panelBackgroundColor
        
        self.topSeparator = ASDisplayNode()
        self.topSeparator.isLayerBacked = true
        self.topSeparator.backgroundColor = theme.chat.inputMediaPanel.panelSerapatorColor
        
        self.botsListView = ListView()
        self.botsListView.transform = CATransform3DMakeRotation(-CGFloat(Double.pi / 2.0), 0.0, 0.0, 1.0)
        self.botsListView.backgroundColor = UIColor.green

        super.init()
        
        self.inputNodeInteraction = ChatBotsInputNodeInteraction(navigateToCollectionId: { [weak self] id in
            self?.navigateToCollection(withId: id)
        })

        backgroundColor = UIColor.brown
        
        self.botsListPanel.addSubnode(self.botsListView)
        self.nodesContainer.addSubnode(self.topSeparator)
        self.nodesContainer.addSubnode(self.botsListPanel)
        self.addSubnode(self.nodesContainer)
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
        let storeItem = ChatBotsStoreItem(inputNodeInteraction: self.inputNodeInteraction, theme: self.theme!) {
            let collectionId = ItemCollectionId(namespace: ChatBotsInputPanelAuxiliaryNamespace.store.rawValue, id: 0)
            self.inputNodeInteraction.navigateToCollectionId(collectionId)
        }
        
        var insertItems: [ListViewInsertItem] = []
        insertItems.append(ListViewInsertItem(index: 0, previousIndex: nil, item: storeItem, directionHint: nil))
        for bot in ChatBotsManager.shared.bots {
            let botCollectionId = ItemCollectionId(namespace: ChatBotsInputPanelAuxiliaryNamespace.bots.rawValue, id: ItemCollectionId.Id(bot.id))
            let botItem = ChatBotsBotItem(inputNodeInteraction: self.inputNodeInteraction, theme: self.theme!, bot: bot, collectionId: botCollectionId) {
                self.inputNodeInteraction.navigateToCollectionId(botCollectionId)
            }
            insertItems.append(ListViewInsertItem(index: insertItems.count, previousIndex: nil, item: botItem, directionHint: nil))
        }
        
        self.botsListView.transaction(deleteIndices: [], insertIndicesAndItems: insertItems, updateIndicesAndItems: [], options: [.Synchronous, .LowLatency], updateOpaqueState: nil)
    }

    func set(messages: [String]) {
        self.messages = messages
    }

    func trashedSuggestions() -> [[String]] {
        var result: [[String]] = []
        
        return result
    }

    override func updateLayout(width: CGFloat, leftInset: CGFloat, rightInset: CGFloat, bottomInset: CGFloat, standardInputHeight: CGFloat, inputHeight: CGFloat, maximumHeight: CGFloat, inputPanelHeight: CGFloat, transition: ContainedViewLayoutTransition, interfaceState: ChatPresentationInterfaceState) -> (CGFloat, CGFloat) {
        let separatorHeight = UIScreenPixel
        let panelHeight = standardInputHeight
        let contentVerticalOffset: CGFloat = 0.0
        let containerOffset: CGFloat = 0

        transition.updateFrame(node: self.nodesContainer, frame: CGRect(origin: CGPoint(x: 0.0, y: contentVerticalOffset), size: CGSize(width: width, height: max(0.0, 41.0 + UIScreenPixel))))
        transition.updateFrame(node: self.botsListPanel, frame: CGRect(origin: CGPoint(x: 0.0, y: containerOffset), size: CGSize(width: width, height: 41.0)))
        transition.updateFrame(node: self.topSeparator, frame: CGRect(origin: CGPoint(x: 0.0, y: 41.0 + containerOffset), size: CGSize(width: width, height: separatorHeight)))
        
        let collectionListPanelOffset = CGFloat(0)
        self.botsListView.bounds = CGRect(x: 0.0, y: 0.0, width: 41.0, height: width)
        transition.updatePosition(node: self.botsListView, position: CGPoint(x: width / 2.0, y: (41.0 - collectionListPanelOffset) / 2.0))
        
        let updateSizeAndInsets = ListViewUpdateSizeAndInsets(size: CGSize(width: 41.0, height: width), insets: UIEdgeInsets(top: 4.0 + leftInset, left: 0.0, bottom: 4.0 + rightInset, right: 0.0), duration: 0, curve: .Default(duration: 0))
        
        self.botsListView.transaction(deleteIndices: [], insertIndicesAndItems: [], updateIndicesAndItems: [], options: [.Synchronous, .LowLatency], scrollToItem: nil, updateSizeAndInsets: updateSizeAndInsets, stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
        
//        print("\(trashedSuggestions())")
//        transition.updateFrame(node: self.topSeparator, frame: CGRect(origin: CGPoint(), size: CGSize(width: width, height: UIScreenPixel)))
//
//        if self.theme !== interfaceState.theme {
//            self.theme = interfaceState.theme
//
//            self.separatorNode.backgroundColor = interfaceState.theme.chat.inputButtonPanel.panelSerapatorColor
//            self.backgroundColor = UIColor.brown//interfaceState.theme.chat.inputButtonPanel.panelBackgroundColor
//        }
//
//        let suggestions = trashedSuggestions()
//
//        let verticalInset: CGFloat = 10.0
//        let sideInset: CGFloat = 6.0 + leftInset
//        let buttonHeight: CGFloat = 43.0
//        let columnSpacing: CGFloat = 6.0
//        let rowSpacing: CGFloat = 5.0
//
//        let panelHeight = standardInputHeight
//
//        let rowsHeight = verticalInset + CGFloat(suggestions.count) * buttonHeight + CGFloat(max(0, suggestions.count - 1)) * rowSpacing + verticalInset
//
//        var verticalOffset = verticalInset
//        var buttonIndex = 0
//        for suggestionsRow in suggestions {
//            let buttonWidth = floor(((width - sideInset - sideInset) + columnSpacing - CGFloat(suggestionsRow.count) * columnSpacing) / CGFloat(suggestionsRow.count))
//
//            var columnIndex = 0
//            for suggestion in suggestionsRow {
//                let buttonNode: ChatSuggestionsInputButtonNode
//                if buttonIndex < self.buttonNodes.count {
//                    buttonNode = self.buttonNodes[buttonIndex]
//                    buttonNode.updateTheme(theme: interfaceState.theme)
//                } else {
//                    buttonNode = ChatSuggestionsInputButtonNode(theme: interfaceState.theme)
//                    buttonNode.titleNode.maximumNumberOfLines = 2
//                    buttonNode.addTarget(self, action: #selector(self.buttonPressed(_:)), forControlEvents: [.touchUpInside])
//                    self.scrollNode.addSubnode(buttonNode)
//                    self.buttonNodes.append(buttonNode)
//                }
//                buttonIndex += 1
//                if buttonNode.suggestion != suggestion {
//                    buttonNode.suggestion = suggestion
//                    buttonNode.setAttributedTitle(NSAttributedString(string: suggestion, font: Font.regular(16.0), textColor: interfaceState.theme.chat.inputButtonPanel.buttonTextColor, paragraphAlignment: .center), for: [])
//                }
//                buttonNode.frame = CGRect(origin: CGPoint(x: sideInset + CGFloat(columnIndex) * (buttonWidth + columnSpacing), y: verticalOffset), size: CGSize(width: buttonWidth, height: buttonHeight))
//                columnIndex += 1
//            }
//            verticalOffset += buttonHeight + rowSpacing
//        }
//
//        for i in (buttonIndex ..< self.buttonNodes.count).reversed() {
//            self.buttonNodes[i].removeFromSupernode()
//            self.buttonNodes.remove(at: i)
//        }
//
//        transition.updateFrame(node: self.scrollNode, frame: CGRect(origin: CGPoint(), size: CGSize(width: width, height: panelHeight)))
//        self.scrollNode.view.contentSize = CGSize(width: width, height: rowsHeight)
//        self.scrollNode.view.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
//
        return (panelHeight, 0.0)
    }

    @objc func buttonPressed(_ button: ASButtonNode) {
        guard let button = button as? ChatSuggestionsInputButtonNode, let suggestion = button.suggestion else { return }
        controllerInteraction.sendMessage(suggestion)
    }
    
    private func navigateToCollection(withId collectionId: ItemCollectionId) {
        print("\(collectionId.namespace) \(collectionId.id)")
//        if let currentView = self.currentView, (collectionId != self.inputNodeInteraction.highlightedItemCollectionId || true) {
//            var index: Int32 = 0
//            if collectionId.namespace == ChatMediaInputPanelAuxiliaryNamespace.recentGifs.rawValue {
//                self.setCurrentPane(.gifs, transition: .animated(duration: 0.25, curve: .spring))
//            } else if collectionId.namespace == ChatMediaInputPanelAuxiliaryNamespace.trending.rawValue {
//                self.setCurrentPane(.trending, transition: .animated(duration: 0.25, curve: .spring))
//            } else if collectionId.namespace == ChatMediaInputPanelAuxiliaryNamespace.savedStickers.rawValue {
//                self.setCurrentPane(.stickers, transition: .animated(duration: 0.25, curve: .spring), collectionIdHint: collectionId.namespace)
//                self.currentStickerPacksCollectionPosition = .navigate(index: nil, collectionId: collectionId)
//                self.itemCollectionsViewPosition.set(.single(.navigate(index: nil, collectionId: collectionId)))
//            } else if collectionId.namespace == ChatMediaInputPanelAuxiliaryNamespace.recentStickers.rawValue {
//                self.setCurrentPane(.stickers, transition: .animated(duration: 0.25, curve: .spring), collectionIdHint: collectionId.namespace)
//                self.currentStickerPacksCollectionPosition = .navigate(index: nil, collectionId: collectionId)
//                self.itemCollectionsViewPosition.set(.single(.navigate(index: nil, collectionId: collectionId)))
//            } else if collectionId.namespace == ChatMediaInputPanelAuxiliaryNamespace.peerSpecific.rawValue {
//                self.setCurrentPane(.stickers, transition: .animated(duration: 0.25, curve: .spring))
//                self.currentStickerPacksCollectionPosition = .navigate(index: nil, collectionId: collectionId)
//                self.itemCollectionsViewPosition.set(.single(.navigate(index: nil, collectionId: collectionId)))
//            } else {
//                self.setCurrentPane(.stickers, transition: .animated(duration: 0.25, curve: .spring))
//                for (id, _, _) in currentView.collectionInfos {
//                    if id.namespace == collectionId.namespace {
//                        if id == collectionId {
//                            let itemIndex = ItemCollectionViewEntryIndex.lowerBound(collectionIndex: index, collectionId: id)
//                            self.currentStickerPacksCollectionPosition = .navigate(index: itemIndex, collectionId: nil)
//                            self.itemCollectionsViewPosition.set(.single(.navigate(index: itemIndex, collectionId: nil)))
//                            break
//                        }
//                        index += 1
//                    }
//                }
//            }
//        }
    }
}
