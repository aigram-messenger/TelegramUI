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
