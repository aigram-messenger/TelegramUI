//
//  ChatBotsInputNode.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 21/12/2018.
//  Copyright © 2018 Telegram. All rights reserved.
//

import UIKit
import Display
import AsyncDisplayKit
import Postbox
import TelegramCore
import SwiftSignalKit

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

class ChatBotsInputNode: ChatInputNode {
    private let account: Account
    private let peerId: PeerId?
    private let controllerInteraction: ChatControllerInteraction
    
    private var inputNodeInteraction: ChatBotsInputNodeInteraction!
    
    private var panRecognizer: UIPanGestureRecognizer?
    
    private let storePane: ChatBotsInputStorePane
    private let botSuggestionsPane: ChatBotsInputSuggestionsPane
    
    private var theme: PresentationTheme
    private var strings: PresentationStrings
    private let themeAndStringsPromise: Promise<(PresentationTheme, PresentationStrings)>
    
    private let collectionListPanel: ASDisplayNode
    private let collectionListSeparator: ASDisplayNode
    private let collectionListContainer: CollectionListContainerNode
    private let listView: ListView
    private var stickerSearchContainerNode: StickerPaneSearchContainerNode?
    
    init(account: Account, peerId: PeerId?, controllerInteraction: ChatControllerInteraction, theme: PresentationTheme, strings: PresentationStrings) {
        self.account = account
        self.peerId = peerId
        self.controllerInteraction = controllerInteraction
        self.theme = theme
        self.strings = strings
        self.themeAndStringsPromise = Promise((theme, strings))
        
        self.storePane = ChatBotsInputStorePane()
        self.botSuggestionsPane = ChatBotsInputSuggestionsPane()
        
        self.collectionListPanel = ASDisplayNode()
        self.collectionListPanel.clipsToBounds = true
        self.collectionListPanel.backgroundColor =  theme.chat.inputPanel.panelBackgroundColor
        
        self.collectionListSeparator = ASDisplayNode()
        self.collectionListSeparator.isLayerBacked = true
        self.collectionListSeparator.backgroundColor = theme.chat.inputMediaPanel.panelSerapatorColor
        
        self.collectionListContainer = CollectionListContainerNode()
        self.collectionListContainer.clipsToBounds = true
        self.collectionListContainer.backgroundColor = UIColor.yellow
        
        self.listView = ListView()
        self.listView.transform = CATransform3DMakeRotation(-CGFloat(Double.pi / 2.0), 0.0, 0.0, 1.0)
        self.listView.backgroundColor = UIColor.blue
        
        super.init()
        
        self.inputNodeInteraction = ChatBotsInputNodeInteraction(navigateToCollectionId: { [weak self] id in
            self?.navigateToCollection(withId: id)
        })
        
        self.collectionListPanel.addSubnode(self.listView)
        self.collectionListContainer.addSubnode(self.collectionListPanel)
        self.collectionListContainer.addSubnode(self.collectionListSeparator)
        self.addSubnode(self.collectionListContainer)
    }
    
    override func didLoad() {
        super.didLoad()
        
        self.view.disablesInteractiveTransitionGestureRecognizer = true
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.panGestureHandler(_:)))
        self.panRecognizer = panRecognizer
        self.view.addGestureRecognizer(panRecognizer)
    }
    
    override func updateLayout(width: CGFloat, leftInset: CGFloat, rightInset: CGFloat, bottomInset: CGFloat, standardInputHeight: CGFloat, inputHeight: CGFloat, maximumHeight: CGFloat, inputPanelHeight: CGFloat, transition: ContainedViewLayoutTransition, interfaceState: ChatPresentationInterfaceState) -> (CGFloat, CGFloat) {
        
        if self.theme !== interfaceState.theme || self.strings !== interfaceState.strings {
            self.updateThemeAndStrings(theme: interfaceState.theme, strings: interfaceState.strings)
        }
        
        let separatorHeight = UIScreenPixel
        let panelHeight: CGFloat = standardInputHeight
        let collectionListPanelOffset = self.currentCollectionListPanelOffset()
        
        transition.updateFrame(node: self.collectionListContainer, frame: CGRect(origin: CGPoint(x: 0.0, y: 0), size: CGSize(width: width, height: 41.0 + UIScreenPixel)))
        transition.updateFrame(node: self.collectionListPanel, frame: CGRect(origin: CGPoint(x: 0.0, y: collectionListPanelOffset), size: CGSize(width: width, height: 41.0)))
        transition.updateFrame(node: self.collectionListSeparator, frame: CGRect(origin: CGPoint(x: 0.0, y: 41.0 + collectionListPanelOffset), size: CGSize(width: width, height: separatorHeight)))
        
        self.listView.bounds = CGRect(x: 0.0, y: 0.0, width: 41.0, height: width)
        transition.updatePosition(node: self.listView, position: CGPoint(x: width / 2.0, y: (41.0 - collectionListPanelOffset) / 2.0))
        
        return (panelHeight, 0)
    }
}

extension ChatBotsInputNode {
    @objc private func panGestureHandler(_ gesture: UIPanGestureRecognizer) {
        
    }
}

extension ChatBotsInputNode {
    private func updateThemeAndStrings(theme: PresentationTheme, strings: PresentationStrings) {
        if self.theme !== theme || self.strings !== strings {
            self.theme = theme
            self.strings = strings
            
//            self.collectionListPanel.backgroundColor = theme.chat.inputPanel.panelBackgroundColor
//            self.collectionListSeparator.backgroundColor = theme.chat.inputMediaPanel.panelSerapatorColor
            self.backgroundColor = theme.chat.inputMediaPanel.gifsBackgroundColor
            
            self.themeAndStringsPromise.set(.single((theme, strings)))
        }
    }
    
    private func currentCollectionListPanelOffset() -> CGFloat {
        return 0
//        let paneOffsets = self.paneArrangement.panes.map { pane -> CGFloat in
//            switch pane {
//            case .stickers:
//                return self.stickerPane.collectionListPanelOffset
//            case .gifs:
//                return self.gifPane.collectionListPanelOffset
//            case .trending:
//                return self.trendingPane.collectionListPanelOffset
//            }
//        }
//
//        let mainOffset = paneOffsets[self.paneArrangement.currentIndex]
//        if self.paneArrangement.indexTransition.isZero {
//            return mainOffset
//        } else {
//            var sideOffset: CGFloat?
//            if self.paneArrangement.indexTransition < 0.0 {
//                if self.paneArrangement.currentIndex != 0 {
//                    sideOffset = paneOffsets[self.paneArrangement.currentIndex - 1]
//                }
//            } else {
//                if self.paneArrangement.currentIndex != paneOffsets.count - 1 {
//                    sideOffset = paneOffsets[self.paneArrangement.currentIndex + 1]
//                }
//            }
//            if let sideOffset = sideOffset {
//                let interpolator = CGFloat.interpolator()
//                let value = interpolator(mainOffset, sideOffset, abs(self.paneArrangement.indexTransition)) as! CGFloat
//                return value
//            } else {
//                return mainOffset
//            }
//        }
    }
    
    private func navigateToCollection(withId collectionId: ItemCollectionId) {
        print("SELECT \(collectionId)")
//        let strongSelf = self
//        if let currentView = strongSelf.currentView, (collectionId != strongSelf.inputNodeInteraction.highlightedItemCollectionId || true) {
//            var index: Int32 = 0
//            if collectionId.namespace == ChatMediaInputPanelAuxiliaryNamespace.recentGifs.rawValue {
//                strongSelf.setCurrentPane(.gifs, transition: .animated(duration: 0.25, curve: .spring))
//            } else if collectionId.namespace == ChatMediaInputPanelAuxiliaryNamespace.trending.rawValue {
//                strongSelf.setCurrentPane(.trending, transition: .animated(duration: 0.25, curve: .spring))
//            } else if collectionId.namespace == ChatMediaInputPanelAuxiliaryNamespace.savedStickers.rawValue {
//                strongSelf.setCurrentPane(.stickers, transition: .animated(duration: 0.25, curve: .spring), collectionIdHint: collectionId.namespace)
//                strongSelf.currentStickerPacksCollectionPosition = .navigate(index: nil, collectionId: collectionId)
//                strongSelf.itemCollectionsViewPosition.set(.single(.navigate(index: nil, collectionId: collectionId)))
//            } else if collectionId.namespace == ChatMediaInputPanelAuxiliaryNamespace.recentStickers.rawValue {
//                strongSelf.setCurrentPane(.stickers, transition: .animated(duration: 0.25, curve: .spring), collectionIdHint: collectionId.namespace)
//                strongSelf.currentStickerPacksCollectionPosition = .navigate(index: nil, collectionId: collectionId)
//                strongSelf.itemCollectionsViewPosition.set(.single(.navigate(index: nil, collectionId: collectionId)))
//            } else if collectionId.namespace == ChatMediaInputPanelAuxiliaryNamespace.peerSpecific.rawValue {
//                strongSelf.setCurrentPane(.stickers, transition: .animated(duration: 0.25, curve: .spring))
//                strongSelf.currentStickerPacksCollectionPosition = .navigate(index: nil, collectionId: collectionId)
//                strongSelf.itemCollectionsViewPosition.set(.single(.navigate(index: nil, collectionId: collectionId)))
//            } else {
//                strongSelf.setCurrentPane(.stickers, transition: .animated(duration: 0.25, curve: .spring))
//                for (id, _, _) in currentView.collectionInfos {
//                    if id.namespace == collectionId.namespace {
//                        if id == collectionId {
//                            let itemIndex = ItemCollectionViewEntryIndex.lowerBound(collectionIndex: index, collectionId: id)
//                            strongSelf.currentStickerPacksCollectionPosition = .navigate(index: itemIndex, collectionId: nil)
//                            strongSelf.itemCollectionsViewPosition.set(.single(.navigate(index: itemIndex, collectionId: nil)))
//                            break
//                        }
//                        index += 1
//                    }
//                }
//            }
//        }
    }
}
