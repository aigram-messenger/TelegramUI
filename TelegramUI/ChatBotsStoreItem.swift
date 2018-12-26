//
//  ChatBotsStoreItem.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 24/12/2018.
//  Copyright © 2018 Telegram. All rights reserved.
//

import Foundation
import Display
import AsyncDisplayKit
import TelegramCore
import SwiftSignalKit
import Postbox

final class ChatBotsStoreItem: ListViewItem {
    let selectedItem: () -> Void
    let theme: PresentationTheme
    let inputNodeInteraction: ChatBotsInputNodeInteraction
    
    var selectable: Bool {
        return true
    }
    
    init(inputNodeInteraction: ChatBotsInputNodeInteraction, theme: PresentationTheme, selected: @escaping () -> Void) {
        self.inputNodeInteraction = inputNodeInteraction
        self.selectedItem = selected
        self.theme = theme
    }
    
    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, () -> Void)) -> Void) {
        async {
            let node = ChatBotsStoreItemNode()
            node.contentSize = CGSize(width: 41.0, height: 41.0)
            node.insets = ChatSuggestionsInputNode.setupPanelIconInsets(item: self, previousItem: previousItem, nextItem: nextItem)
            node.inputNodeInteraction = self.inputNodeInteraction
            node.updateTheme(theme: self.theme)
            node.updateIsHighlighted()
            node.updateAppearanceTransition(transition: .immediate)
            Queue.mainQueue().async {
                completion(node, {
                    return (nil, {})
                })
            }
        }
    }
    
    public func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping () -> Void) -> Void) {
        Queue.mainQueue().async {
            completion(ListViewItemNodeLayout(contentSize: node().contentSize, insets: ChatSuggestionsInputNode.setupPanelIconInsets(item: self, previousItem: previousItem, nextItem: nextItem)), {
                (node() as? ChatBotsStoreItemNode)?.updateTheme(theme: self.theme)
            })
        }
    }
    
    func selected(listView: ListView) {
        self.selectedItem()
    }
}

private let boundingSize = CGSize(width: 41.0, height: 41.0)
private let boundingImageSize = CGSize(width: 30.0, height: 30.0)
private let highlightSize = CGSize(width: 35.0, height: 35.0)
private let verticalOffset: CGFloat = 3.0 + UIScreenPixel

final class ChatBotsStoreItemNode: ListViewItemNode {
    private let imageNode: ASImageNode
    private let highlightNode: ASImageNode
    
    var currentCollectionId: ItemCollectionId?
    var inputNodeInteraction: ChatBotsInputNodeInteraction?
    
    var theme: PresentationTheme?
    
    init() {
        self.highlightNode = ASImageNode()
        self.highlightNode.isLayerBacked = true
        self.highlightNode.isHidden = true
        
        self.imageNode = ASImageNode()
        self.imageNode.isLayerBacked = true
        self.imageNode.contentMode = .center
        self.imageNode.contentsScale = UIScreenScale
        
        self.highlightNode.frame = CGRect(origin: CGPoint(x: floor((boundingSize.width - highlightSize.width) / 2.0) + verticalOffset, y: floor((boundingSize.height - highlightSize.height) / 2.0)), size: highlightSize)
        
        self.imageNode.transform = CATransform3DMakeRotation(CGFloat.pi / 2.0, 0.0, 0.0, 1.0)
        
        super.init(layerBacked: false, dynamicBounce: false)
        
        self.addSubnode(self.highlightNode)
        self.addSubnode(self.imageNode)
        
        self.currentCollectionId = ItemCollectionId(namespace: ChatBotsInputPanelAuxiliaryNamespace.store.rawValue, id: 0)
        
        let imageSize = CGSize(width: 26.0, height: 26.0)
        self.imageNode.frame = CGRect(origin: CGPoint(x: floor((boundingSize.width - imageSize.width) / 2.0) + verticalOffset, y: floor((boundingSize.height - imageSize.height) / 2.0) + UIScreenPixel), size: imageSize)
    }
    
    deinit {
    }
    
    func updateTheme(theme: PresentationTheme) {
        if self.theme !== theme {
            self.theme = theme
            
            self.highlightNode.image = PresentationResourcesChat.chatMediaInputPanelHighlightedIconImage(theme)
            self.imageNode.image = PresentationResourcesChat.chatInputMediaPanelRecentGifsIconImage(theme)
        }
    }
    
    func updateIsHighlighted() {
        if let currentCollectionId = self.currentCollectionId, let inputNodeInteraction = self.inputNodeInteraction {
            self.highlightNode.isHidden = inputNodeInteraction.highlightedItemCollectionId != currentCollectionId
        }
    }
    
    func updateAppearanceTransition(transition: ContainedViewLayoutTransition) {
        if let inputNodeInteraction = self.inputNodeInteraction {
            transition.updateSublayerTransformScale(node: self, scale: inputNodeInteraction.appearanceTransition)
        }
    }
}
