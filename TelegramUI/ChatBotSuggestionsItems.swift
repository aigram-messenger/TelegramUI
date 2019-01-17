//
//  ChatBotSuggestionsItems.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 16/01/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import Display
import SwiftSignalKit

struct ChatSuggestionListItem: ListViewItem, ItemListItem {
    var sectionId: ItemListSectionId = 0
    
    let response: BotResponse
    let inputNodeInteraction: ChatBotsInputNodeInteraction
    let theme: PresentationTheme
    
    var selectable: Bool { return true }
    var header: ListViewItemHeader
    
    init(bot: ChatBot, response: BotResponse, inputNodeInteraction: ChatBotsInputNodeInteraction, theme: PresentationTheme) {
        self.response = response
        self.inputNodeInteraction = inputNodeInteraction
        self.theme = theme
        self.header = ChatSuggestionListItemHeader(bot: bot, theme: self.theme)
    }
    
    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, () -> Void)) -> Void) {
        async {
            let node = ChatSuggestionItemNode()
            let (layout, apply) = node.asyncLayout()(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
            
            var size = layout.contentSize
            size.height = 10
            node.contentSize = size
            node.insets = layout.insets
            
            Queue.mainQueue().async {
                completion(node, {
                    return (nil, {
                        node.update(response: self.response, theme: self.theme, params: params)
                        apply()
                    })
                })
            }
        }
    }
    
    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping () -> Void) -> Void) {
        Queue.mainQueue().async {
            guard let nodeValue = node() as? ChatSuggestionItemNode else {
                assertionFailure()
                return
            }
            
            let makeLayout = nodeValue.asyncLayout()
            
            async {
                let (layout, apply) = makeLayout(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
                Queue.mainQueue().async {
                    completion(layout, {
                        nodeValue.update(response: self.response, theme: self.theme, params: params)
                        apply()
                    })
                }
            }
        }
    }
    
    func selected(listView: ListView) {
        guard let message = self.response["response"] else { return }
        self.inputNodeInteraction.sendMessage(message)
    }
}

private let titleFont = Font.regular(17.0)
private let titleBoldFont = Font.medium(17.0)
private let titleItalicFont = Font.italic(17.0)
private let titleFixedFont = Font.regular(17.0)

private class ChatSuggestionItemNode: ListViewItemNode {
    private var response: BotResponse
    private var theme: PresentationTheme?
    private let textNode: TextNode
    private let backgroundNode: ChatMessageBackground
    
    private var item: ChatSuggestionListItem?
    
    init() {
        self.response = BotResponse()
        
        self.textNode = TextNode()
        self.textNode.isUserInteractionEnabled = false
        self.textNode.contentMode = .left
        self.textNode.contentsScale = UIScreen.main.scale
        
        self.backgroundNode = ChatMessageBackground()
        
        super.init(layerBacked: false)
        
        self.addSubnode(self.backgroundNode)
        self.addSubnode(self.textNode)
    }
    
    override func header() -> ListViewItemHeader? {
        return item?.header
    }
    
    func update(response: BotResponse, theme: PresentationTheme, params: ListViewItemLayoutParams) {
        self.response = response
        if theme != self.theme {
            self.theme = theme
            let graphics = PresentationResourcesChat.principalGraphics(theme, wallpaper: false)
            
            self.backgroundNode.setType(type: .outgoing(.None), highlighted: false, graphics: graphics, transition: .immediate)
        }
    }
    
    override func animateAdded(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
    }
    
    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
    }
    
    func asyncLayout() -> (_ item: ChatSuggestionListItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        let makeTextLayout = TextNode.asyncLayout(self.textNode)
        return { item, params, neighbors in
            let text = item.response["response"] ?? ""
            let textColor: UIColor = item.theme.list.itemPrimaryTextColor
            
            let textInsets = UIEdgeInsetsMake(5, 8, 5, 14)
            
            let entities = generateTextEntities(text, enabledTypes: [])
            let string = stringWithAppliedEntities(text, entities: entities, baseColor: textColor, linkColor: item.theme.list.itemAccentColor, baseFont: titleFont, linkFont: titleFont, boldFont: titleBoldFont, italicFont: titleItalicFont, fixedFont: titleFixedFont)
            
            let textConstrainedSize = CGSize(width: params.width - params.leftInset - params.rightInset, height: CGFloat.greatestFiniteMagnitude)
            let (titleLayout, titleApply) = makeTextLayout(TextNodeLayoutArguments(attributedString: string, backgroundColor: nil, maximumNumberOfLines: 0, truncationType: .end, constrainedSize: textConstrainedSize, alignment: .right, cutout: nil, insets: .init()))
            
            let contentSize = CGSize(width: params.width, height: titleLayout.size.height + textInsets.top + textInsets.bottom)
            var insets = itemListNeighborsPlainInsets(neighbors)
            insets.top = 3
            if case ItemListNeighbor.none = neighbors.top {
                insets.top += 26
            }
            insets.bottom = 3
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            
            return (layout, { [weak self] in
                if let strongSelf = self {
                    strongSelf.item = item
                    
                    let _ = titleApply()
                    
                    let bubbleWidth = titleLayout.size.width + textInsets.left + textInsets.right
                    let x = strongSelf.bounds.maxX - params.rightInset - bubbleWidth
                    let bubbleFrame = CGRect(origin: CGPoint(x: x, y: 0), size: CGSize(width: bubbleWidth, height: contentSize.height))
                    strongSelf.backgroundNode.frame = bubbleFrame
                    var textNodeFrame = bubbleFrame
                    textNodeFrame.origin.x += textInsets.left
                    textNodeFrame.origin.y += textInsets.top
                    textNodeFrame.size.width -= textInsets.left + textInsets.right
                    textNodeFrame.size.height -= textInsets.top + textInsets.bottom
                    strongSelf.textNode.frame = textNodeFrame
                }
            })
        }
    }
}
