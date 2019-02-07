//
//  ChatBotsStoreListItem.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 17/01/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import Display
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
            size.height = 96
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
        print("SELECTED")
        self.inputNodeInteraction.botDetails(self.bot)
    }
}
