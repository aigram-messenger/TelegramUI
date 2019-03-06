//
//  ChatBotsBotItem.swift
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
import AiGramLib

final class ChatBotsBotItem: ListViewItem {
    let inputNodeInteraction: ChatBotsInputNodeInteraction
    let selectedItem: () -> Void
    let theme: PresentationTheme
    let bot: AiGramBot
    let collectionId: ItemCollectionId

    var selectable: Bool { return true }

    init(inputNodeInteraction: ChatBotsInputNodeInteraction, theme: PresentationTheme, bot: AiGramBot, selected: @escaping () -> Void) {
        self.inputNodeInteraction = inputNodeInteraction
        self.selectedItem = selected
        self.theme = theme
        self.bot = bot
        self.collectionId = ItemCollectionId(namespace: ChatBotsInputPanelAuxiliaryNamespace.bots.rawValue, id: ItemCollectionId.Id(bot.id))
    }

    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, () -> Void)) -> Void) {
        async {
            let node = ChatBotsBotItemNode()
            node.contentSize = boundingSize
            node.insets = ChatSuggestionsInputNode.setupPanelIconInsets(item: self, previousItem: previousItem, nextItem: nextItem)
            node.inputNodeInteraction = self.inputNodeInteraction
            Queue.mainQueue().async {
                completion(node, {
                    return (nil, {
                        node.updateBot(item: self.bot, theme: self.theme, collectionId: self.collectionId)
                        node.updateAppearanceTransition(transition: .immediate)
                    })
                })
            }
        }
    }

    public func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping () -> Void) -> Void) {
        Queue.mainQueue().async {
            completion(ListViewItemNodeLayout(contentSize: node().contentSize, insets: ChatSuggestionsInputNode.setupPanelIconInsets(item: self, previousItem: previousItem, nextItem: nextItem)), {
                (node() as? ChatBotsBotItemNode)?.updateBot(item: self.bot, theme: self.theme, collectionId: self.collectionId)
            })
        }
    }

    func selected(listView: ListView) {
        self.selectedItem()
    }
}

private let boundingSize = CGSize(width: 41.0, height: 41.0)
private let boundingImageSize = CGSize(width: 28.0, height: 28.0)
private let highlightSize = CGSize(width: 34.0, height: 34.0)
private let verticalOffset: CGFloat = 3.0

final class ChatBotsBotItemNode: ListViewItemNode {
    private let imageNode: ASImageNode
    private let highlightNode: ASDisplayNode
    private var gesture: UILongPressGestureRecognizer!

    var inputNodeInteraction: ChatBotsInputNodeInteraction?
    var currentCollectionId: ItemCollectionId?
    
    private var currentItem: AiGramBot?
    private var theme: PresentationTheme?

    init() {
        self.highlightNode = ASDisplayNode()
        self.highlightNode.isLayerBacked = true
        self.highlightNode.clipsToBounds = true
        self.highlightNode.borderColor = UIColor(argb: 0xff4da6ea).cgColor
        self.highlightNode.borderWidth = 2
        self.highlightNode.isHidden = true
        
        self.imageNode = ASImageNode()
        self.imageNode.isLayerBacked = true
        self.imageNode.contentMode = .scaleAspectFit
        self.imageNode.contentsScale = UIScreenScale

        let imageSize = CGSize(width: 26.0, height: 26.0)
        self.highlightNode.frame = CGRect(origin: CGPoint(x: floor((boundingSize.width - highlightSize.width) / 2.0) + verticalOffset, y: floor((boundingSize.height - highlightSize.height) / 2.0) + UIScreenPixel), size: highlightSize)
        self.highlightNode.cornerRadius = 0.5 * min(highlightSize.width, highlightSize.height)

        self.imageNode.transform = CATransform3DMakeRotation(CGFloat.pi / 2.0, 0.0, 0.0, 1.0)

        super.init(layerBacked: false, dynamicBounce: false)
        
        self.gesture = UILongPressGestureRecognizer(target: self, action: #selector(longTapGestureHandler(_:)))
        self.view.addGestureRecognizer(self.gesture)

        self.addSubnode(self.highlightNode)
        self.addSubnode(self.imageNode)
        
        self.imageNode.frame = CGRect(origin: CGPoint(x: floor((boundingSize.width - imageSize.width) / 2.0) + verticalOffset, y: floor((boundingSize.height - imageSize.height) / 2.0) + UIScreenPixel), size: imageSize)
    }

    deinit {
    }

    func updateBot(item: AiGramBot?, theme: PresentationTheme, collectionId: ItemCollectionId) {
        self.currentCollectionId = collectionId
        
        if self.theme !== theme {
            self.theme = theme
        }

        if self.currentItem?.toComparable() != item?.toComparable() {
            self.currentItem = item
            
            if let item = item {
                self.imageNode.image = item.icon
            }

            self.updateIsHighlighted()
        }
    }

    func updateIsHighlighted() {
        assert(Queue.mainQueue().isCurrent())
        if let currentCollectionId = self.currentCollectionId, let inputNodeInteraction = self.inputNodeInteraction {
            self.highlightNode.isHidden = inputNodeInteraction.highlightedItemCollectionId != currentCollectionId
        }
    }

    func updateAppearanceTransition(transition: ContainedViewLayoutTransition) {
        assert(Queue.mainQueue().isCurrent())
        if let inputNodeInteraction = self.inputNodeInteraction {
            transition.updateSublayerTransformScale(node: self, scale: inputNodeInteraction.appearanceTransition)
        }
    }

    override func animateAdded(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
    }

    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
    }
    
    @objc private func longTapGestureHandler(_ gesture: UIGestureRecognizer) {
        guard let bot = self.currentItem else { return }
        switch gesture.state {
        case .began:
            self.inputNodeInteraction?.botActions(bot)
        default:
            break
        }
    }
}

