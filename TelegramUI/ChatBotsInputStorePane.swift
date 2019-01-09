//
//  ChatBotsInputStorePane.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 21/12/2018.
//  Copyright © 2018 Telegram. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import Display
import Postbox
import TelegramCore
import SwiftSignalKit

struct ChatBotsStoreListItem: ListViewItem, ItemListItem {
    var sectionId: ItemListSectionId = 0
    
    let bot: ChatBot
    let inputNodeInteraction: ChatBotsInputNodeInteraction
    let theme: PresentationTheme
    
    var selectable: Bool { return true }
    
    init(bot: ChatBot, inputNodeInteraction: ChatBotsInputNodeInteraction, theme: PresentationTheme) {
        self.bot = bot
        self.inputNodeInteraction = inputNodeInteraction
        self.theme = theme
    }
    
    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, () -> Void)) -> Void) {
        async {
            let node = ChatStoreBotItemNode(bot: self.bot)
            let (layout, apply) = node.asyncLayout()(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
            
            var size = layout.contentSize
            size.height = 10
            node.contentSize = size
            node.insets = layout.insets
            
            Queue.mainQueue().async {
                completion(node, {
                    return (nil, {
                        node.update(bot: self.bot, theme: self.theme, params: params)
                        apply()
                    })
                })
            }
        }
    }
    
    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping () -> Void) -> Void) {
        Queue.mainQueue().async {
            guard let nodeValue = node() as? ChatStoreBotItemNode else {
                assertionFailure()
                return
            }
            
            let makeLayout = nodeValue.asyncLayout()
            
            async {
                let (layout, apply) = makeLayout(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
                Queue.mainQueue().async {
                    completion(layout, {
                        nodeValue.update(bot: self.bot, theme: self.theme, params: params)
                        apply()
                    })
                }
            }
        }
    }
    
    func selected(listView: ListView) {
    }
}

private let titleFont = Font.regular(17.0)
private let titleBoldFont = Font.medium(17.0)
private let titleItalicFont = Font.italic(17.0)
private let titleFixedFont = Font.regular(17.0)

private class ChatStoreBotItemNode: ListViewItemNode {
    private var bot: ChatBot
    private var theme: PresentationTheme?
//    private let textNode: TextNode
    
    private var item: ChatBotsStoreListItem?
    
    init(bot: ChatBot) {
        self.bot = bot
        
//        self.textNode = TextNode()
//        self.textNode.isUserInteractionEnabled = false
//        self.textNode.contentMode = .left
//        self.textNode.contentsScale = UIScreen.main.scale
        
        super.init(layerBacked: false)
        
//        self.backgroundColor = UIColor(argb: arc4random())
        
//        self.addSubnode(self.textNode)
    }
    
    func update(bot: ChatBot, theme: PresentationTheme, params: ListViewItemLayoutParams) {
        self.bot = bot
        if theme != self.theme {
            self.theme = theme
        }
        if BotsStoreManager.shared.isBotBought(bot) {
            self.backgroundColor = UIColor.green
        } else {
            self.backgroundColor = UIColor(argb: arc4random())
        }
    }
    
    override func animateAdded(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
    }
    
    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
    }
    
    func asyncLayout() -> (_ item: ChatBotsStoreListItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
//        let makeTextLayout = TextNode.asyncLayout(self.textNode)
        return { item, params, neighbors in
//            let text = item.response["response"] ?? ""
//            let textColor: UIColor = item.theme.list.itemPrimaryTextColor
//
//            let leftInset = 16.0 + params.leftInset
//
//            let entities = generateTextEntities(text, enabledTypes: [])
//            let string = stringWithAppliedEntities(text, entities: entities, baseColor: textColor, linkColor: item.theme.list.itemAccentColor, baseFont: titleFont, linkFont: titleFont, boldFont: titleBoldFont, italicFont: titleItalicFont, fixedFont: titleFixedFont)
//
//            let (titleLayout, titleApply) = makeTextLayout(TextNodeLayoutArguments(attributedString: string, backgroundColor: nil, maximumNumberOfLines: 0, truncationType: .end, constrainedSize: CGSize(width: params.width - params.leftInset - params.rightInset - 20.0, height: CGFloat.greatestFiniteMagnitude), alignment: .natural, cutout: nil, insets: UIEdgeInsets()))
            
            let contentSize = CGSize(width: params.width, height: 80)
            var insets = itemListNeighborsPlainInsets(neighbors)
            insets.top = 8
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            
            return (layout, { [weak self] in
                if let strongSelf = self {
                    strongSelf.item = item
                    
//                    let _ = titleApply()
                    
//                    strongSelf.textNode.frame = CGRect(origin: CGPoint(x: leftInset, y: 11.0), size: titleLayout.size)
                }
            })
        }
    }
}

final class ChatBotsInputStorePane: ChatMediaInputPane, UIScrollViewDelegate {
    private let inputNodeInteraction: ChatBotsInputNodeInteraction
    private let listView: ListView
    private let bots: [ChatBot] = ChatBotsManager.shared.botsInStore()
    
    var theme: PresentationTheme
    
    init(inputNodeInteraction: ChatBotsInputNodeInteraction, theme: PresentationTheme) {
        self.inputNodeInteraction = inputNodeInteraction
        self.theme = theme
        
        self.listView = ListView()
        
        super.init()
        self.backgroundColor = UIColor.yellow
        
        self.addSubnode(self.listView)
        
        var index = 0
        let insertItems: [ListViewInsertItem] = bots.map {
            let itemNode = ChatBotsStoreListItem(bot: $0, inputNodeInteraction: self.inputNodeInteraction, theme: self.theme)
            let item = ListViewInsertItem(index: index, previousIndex: nil, item: itemNode, directionHint: nil)
            index += 1
            return item
        }
        
        self.listView.transaction(deleteIndices: [], insertIndicesAndItems: insertItems, updateIndicesAndItems: [], options: [.Synchronous, .LowLatency], scrollToItem: nil, updateSizeAndInsets: nil, stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
    }
    
    override func updateLayout(size: CGSize, topInset: CGFloat, bottomInset: CGFloat, isExpanded: Bool, transition: ContainedViewLayoutTransition) {
        var size = size
        size.height -= topInset + bottomInset
        
        transition.updateFrame(node: self.listView, frame: CGRect(origin: CGPoint(x: 0, y: topInset), size: size))
        
        let updateSizeAndInsets = ListViewUpdateSizeAndInsets(size: size, insets: UIEdgeInsets(), duration: 0, curve: .Default(duration: 0))
        self.listView.transaction(deleteIndices: [], insertIndicesAndItems: [], updateIndicesAndItems: [], options: [.Synchronous, .LowLatency], scrollToItem: nil, updateSizeAndInsets: updateSizeAndInsets, stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
    }
}
