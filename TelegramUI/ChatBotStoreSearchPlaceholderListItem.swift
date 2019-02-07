//
//  ChatBotStoreSearchPlaceholderListItem.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 30/01/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import Display
import SwiftSignalKit

class ChatBotStoreSearchPlaceholderListItem: ListViewItem, ItemListItem {
    var sectionId: ItemListSectionId = 1
    
    let theme: PresentationTheme
    let strings: PresentationStrings
    let activate: () -> Void
    
    var selectable: Bool { return false }
    
    init(theme: PresentationTheme, strings: PresentationStrings, activate: @escaping () -> Void) {
        self.theme = theme
        self.strings = strings
        self.activate = activate
    }
    
    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, () -> Void)) -> Void) {
        async {
            let node = ChatBotStoreSearchPlaceholderListItemNode()
            node.activate = self.activate
            node.setup(theme: self.theme, strings: self.strings)
            
            let (layout, apply) = node.asyncLayout()(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
            
            node.contentSize = layout.contentSize
            
            Queue.mainQueue().async {
                completion(node, {
                    return (nil, {
                        node.setup(theme: self.theme, strings: self.strings)
                        apply()
                    })
                })
            }
        }
    }
    
    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping () -> Void) -> Void) {
        Queue.mainQueue().async {
            guard let nodeValue = node() as? ChatBotStoreSearchPlaceholderListItemNode else {
                assertionFailure()
                return
            }
            
            let makeLayout = nodeValue.asyncLayout()
            
            async {
                let (layout, apply) = makeLayout(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
                Queue.mainQueue().async {
                    completion(layout, {
                        nodeValue.setup(theme: self.theme, strings: self.strings)
                        apply()
                    })
                }
            }
        }
    }
}
