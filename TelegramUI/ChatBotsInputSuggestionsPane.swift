//
//  ChatBotsInputSuggestionsPane.swift
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
import AiGramLib

final class ChatBotsInputSuggestionsPane: ChatMediaInputPane, UIScrollViewDelegate {
    private var responses: [BotResponse]
    private let inputNodeInteraction: ChatBotsInputNodeInteraction
    private let listView: ListView
    
    var theme: PresentationTheme
    
    init(
        bot: ChatBot,
        responses: [BotResponse],
        inputNodeInteraction: ChatBotsInputNodeInteraction,
        theme: PresentationTheme,
        dynamicBounceEnabled: Bool
    ) {
        self.responses = responses
        self.inputNodeInteraction = inputNodeInteraction
        self.theme = theme
        
        self.listView = ListView()
        self.listView.dynamicBounceEnabled = dynamicBounceEnabled
        
        super.init()
        
        self.addSubnode(self.listView)
        
        var index = 0//1
        let insertItems: [ListViewInsertItem] = self.responses.map {
            let itemNode = ChatSuggestionListItem(bot: bot, response: $0, inputNodeInteraction: self.inputNodeInteraction, theme: self.theme)
            let item = ListViewInsertItem(index: index, previousIndex: nil, item: itemNode, directionHint: nil)
            index += 1
            return item
        }
//        let itemNode = ChatBotsAdsListItem(bot: bot, inputNodeInteraction: self.inputNodeInteraction, theme: self.theme)
//        let item = ListViewInsertItem(index: 0, previousIndex: nil, item: itemNode, directionHint: nil)
//        insertItems.insert(item, at: 0)

        self.listView.transaction(deleteIndices: [], insertIndicesAndItems: insertItems, updateIndicesAndItems: [], options: [.Synchronous, .LowLatency], scrollToItem: nil, updateSizeAndInsets: nil, stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
    }
    
    override func updateLayout(size: CGSize, topInset: CGFloat, bottomInset: CGFloat, isExpanded: Bool, transition: ContainedViewLayoutTransition) {
        var size = size
        size.height -= topInset + bottomInset
        
        transition.updateFrame(node: self.listView, frame: CGRect(origin: CGPoint(x: 0, y: topInset), size: size))
        
        let insets = UIEdgeInsetsMake(0, 60, 0, 9)
        let updateSizeAndInsets = ListViewUpdateSizeAndInsets(size: size, insets: insets, duration: 0, curve: .Default(duration: nil))
        self.listView.transaction(deleteIndices: [], insertIndicesAndItems: [], updateIndicesAndItems: [], options: [.Synchronous, .LowLatency], scrollToItem: nil, updateSizeAndInsets: updateSizeAndInsets, stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
    }
}
