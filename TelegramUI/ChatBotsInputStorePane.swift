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
    
    var selectable: Bool { return false }
    
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
                        node.update(bot: self.bot, theme: self.theme)
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
                        nodeValue.update(bot: self.bot, theme: self.theme)
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
    private(set) var bot: ChatBot
    private var theme: PresentationTheme?
    private let titleNode: TextNode
    private let separatorNode: ASDisplayNode
    private let backgroundNode: ASDisplayNode
    
    private let installationActionImageNode: ASImageNode
    private let installationActionNode: HighlightableButtonNode
    
    private var item: ChatBotsStoreListItem?
    
    init(bot: ChatBot) {
        self.bot = bot
        
        self.titleNode = TextNode()
        self.titleNode.isUserInteractionEnabled = false
        self.titleNode.contentMode = .left
        self.titleNode.contentsScale = UIScreen.main.scale
        
        self.separatorNode = ASDisplayNode()
        
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true
        self.backgroundNode.backgroundColor = .white
        
        self.installationActionImageNode = ASImageNode()
        self.installationActionImageNode.displaysAsynchronously = false
        self.installationActionImageNode.displayWithoutProcessing = true
        self.installationActionImageNode.isLayerBacked = true
        self.installationActionNode = HighlightableButtonNode()
        
        super.init(layerBacked: false)
        
        self.addSubnode(self.backgroundNode)
        self.addSubnode(self.titleNode)
        self.addSubnode(self.installationActionImageNode)
        self.addSubnode(self.installationActionNode)
        self.addSubnode(self.separatorNode)
        
        self.installationActionNode.addTarget(self, action: #selector(self.buyBotAction), forControlEvents: .touchUpInside)
        self.installationActionNode.highligthedChanged = { [weak self] highlighted in
            if let strongSelf = self {
                if highlighted {
                    strongSelf.installationActionImageNode.layer.removeAnimation(forKey: "opacity")
                    strongSelf.installationActionImageNode.alpha = 0.4
                } else {
                    strongSelf.installationActionImageNode.alpha = 1.0
                    strongSelf.installationActionImageNode.layer.animateAlpha(from: 0.4, to: 1.0, duration: 0.2)
                }
            }
        }
    }
    
    func update(bot: ChatBot, theme: PresentationTheme) {
        self.bot = bot
        if theme != self.theme {
            self.theme = theme
        }
        self.separatorNode.backgroundColor = theme.chatList.itemSeparatorColor
        if BotsStoreManager.shared.isBotBought(bot) {
            self.backgroundNode.backgroundColor = UIColor.green
            self.installationActionNode.isHidden = true
            self.installationActionImageNode.isHidden = true

        } else {
            self.backgroundNode.backgroundColor = UIColor(argb: arc4random())
            self.installationActionImageNode.isHidden = false
            self.installationActionNode.isHidden = false
        }
    }
    
    override func animateAdded(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
    }
    
    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
    }
    
    func asyncLayout() -> (_ item: ChatBotsStoreListItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        let makeTitleLayout = TextNode.asyncLayout(self.titleNode)
        return { item, params, neighbors in
            let title = item.bot.title
            let textColor: UIColor = item.theme.list.itemPrimaryTextColor

            let leftInset = 16.0 + params.leftInset

            let entities = generateTextEntities(title, enabledTypes: [])
            let string = stringWithAppliedEntities(title, entities: entities, baseColor: textColor, linkColor: item.theme.list.itemAccentColor, baseFont: titleFont, linkFont: titleFont, boldFont: titleBoldFont, italicFont: titleItalicFont, fixedFont: titleFixedFont)

            let (titleLayout, titleApply) = makeTitleLayout(TextNodeLayoutArguments(attributedString: string, backgroundColor: nil, maximumNumberOfLines: 0, truncationType: .end, constrainedSize: CGSize(width: params.width - params.leftInset - params.rightInset - 20.0, height: 30), alignment: .natural, cutout: nil, insets: UIEdgeInsets()))
            
            let contentSize = CGSize(width: params.width, height: 80)
            let insets = itemListNeighborsPlainInsets(neighbors)
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            
            return (layout, { [weak self] in
                if let strongSelf = self {
                    strongSelf.item = item
                    
                    let _ = titleApply()
                    
                    strongSelf.titleNode.frame = CGRect(origin: CGPoint(x: leftInset, y: 11.0), size: titleLayout.size)
                    strongSelf.backgroundNode.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: contentSize)
                    strongSelf.separatorNode.frame = CGRect(origin: CGPoint(x: 0, y: contentSize.height - 1), size: CGSize(width: contentSize.width, height: 1))
                    
                    if item.bot.isLocal {
                        strongSelf.installationActionNode.isHidden = true
                        strongSelf.installationActionImageNode.isHidden = true
                    } else {
                        strongSelf.installationActionImageNode.isHidden = false
                        strongSelf.installationActionNode.isHidden = false
                    }
                    
                    let installationActionFrame = CGRect(origin: CGPoint(x: params.width - params.rightInset - 50.0, y: 0.0), size: CGSize(width: 50.0, height: layout.contentSize.height))
                    strongSelf.installationActionNode.frame = installationActionFrame
                    
                    let image = PresentationResourcesItemList.plusIconImage(item.theme) ?? UIImage()
                    let imageSize = image.size
                    strongSelf.installationActionImageNode.image = image
                    strongSelf.installationActionImageNode.frame = CGRect(origin: CGPoint(x: installationActionFrame.minX + floor((installationActionFrame.size.width - imageSize.width) / 2.0), y: installationActionFrame.minY + floor((installationActionFrame.size.height - imageSize.height) / 2.0)), size: imageSize)
                }
            })
        }
    }
    
    @objc private func buyBotAction() {
        self.installationActionNode.isUserInteractionEnabled = false
        self.item?.inputNodeInteraction.buyBot(self.bot)
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
        
        let updateSizeAndInsets = ListViewUpdateSizeAndInsets(size: size, insets: UIEdgeInsets(), duration: 0, curve: .Spring(duration: 0))
        self.listView.transaction(deleteIndices: [], insertIndicesAndItems: [], updateIndicesAndItems: [], options: [.Synchronous, .LowLatency], scrollToItem: nil, updateSizeAndInsets: updateSizeAndInsets, stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
    }
    
    func reloadData(boughtBot bot: ChatBot) {
        self.listView.forEachItemNode { node in
            guard let node = node as? ChatStoreBotItemNode, node.bot.title.lowercased() == bot.title.lowercased() else { return }
            node.update(bot: bot, theme: self.theme)
        }
    }
}
