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
    let listView: ListView
    private var bots: [ChatBot] = []
    private var strings: PresentationStrings
    
    var theme: PresentationTheme
    
    init(inputNodeInteraction: ChatBotsInputNodeInteraction, theme: PresentationTheme, strings: PresentationStrings) {
        self.inputNodeInteraction = inputNodeInteraction
        self.theme = theme
        self.strings = strings
        
        self.listView = ListView()
        
        super.init()
        self.backgroundColor = UIColor(argb: 0xffe7ebef)
        
        self.addSubnode(self.listView)
        self.listView.transaction(deleteIndices: [], insertIndicesAndItems: [], updateIndicesAndItems: [], options: [.Synchronous, .LowLatency], scrollToItem: nil, updateSizeAndInsets: nil, stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
        
        ChatBotsManager.shared.botsInStore { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(bots): self.updateBots(bots)
            case .fail: self.updateBots(self.bots)
            }
        }
    }
    
    override func updateLayout(size: CGSize, topInset: CGFloat, bottomInset: CGFloat, isExpanded: Bool, transition: ContainedViewLayoutTransition) {
        var size = size
        size.height -= topInset + bottomInset
        
        transition.updateFrame(node: self.listView, frame: CGRect(origin: CGPoint(x: 0, y: topInset), size: size))
        
        let updateSizeAndInsets = ListViewUpdateSizeAndInsets(size: size, insets: UIEdgeInsets(), duration: 0, curve: .Spring(duration: 0))
        self.listView.transaction(deleteIndices: [], insertIndicesAndItems: [], updateIndicesAndItems: [], options: [.Synchronous, .LowLatency], scrollToItem: nil, updateSizeAndInsets: updateSizeAndInsets, stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
    }
    
    func reloadData(for bot: ChatBot) {
        self.listView.forEachItemNode { node in
            guard let node = node as? ChatStoreBotItemNode, node.bot == bot else { return }
            node.update(bot: bot, theme: self.theme)
        }
    }
    
    private func updateBots(_ bots: [ChatBot]) {
        self.bots = bots
        
        var index = 1
        var insertItems: [ListViewInsertItem] = bots.map {
            let itemNode = ChatBotsStoreListItem(bot: $0, inputNodeInteraction: self.inputNodeInteraction, theme: self.theme)
            let item = ListViewInsertItem(index: index, previousIndex: nil, item: itemNode, directionHint: nil)
            index += 1
            return item
        }
        let searchPlaceholderNode = ChatBotStoreSearchPlaceholderListItem(theme: self.theme, strings: self.strings) {
            self.inputNodeInteraction.toggleSearch(true)
        }
        let searchPlaceholderItem = ListViewInsertItem(index: 0, previousIndex: nil, item: searchPlaceholderNode, directionHint: nil)
        insertItems.insert(searchPlaceholderItem, at: 0)
        
        let updateSizeAndInsets = ListViewUpdateSizeAndInsets(size: self.bounds.size, insets: UIEdgeInsets(), duration: 0, curve: .Spring(duration: 0))
        self.listView.transaction(deleteIndices: [], insertIndicesAndItems: insertItems, updateIndicesAndItems: [], options: [.Synchronous, .AnimateInsertion], scrollToItem: nil, updateSizeAndInsets: updateSizeAndInsets, stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
    }
}
