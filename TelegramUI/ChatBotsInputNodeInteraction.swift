//
//  ChatBotsInputNodeInteraction.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 24/12/2018.
//  Copyright © 2018 Telegram. All rights reserved.
//

import Foundation
import Display
import AsyncDisplayKit
import Postbox
import TelegramCore
import SwiftSignalKit
import AiGramLib

final class ChatBotsInputNodeInteraction {
    let navigateToCollectionId: (ItemCollectionId) -> Void
    let sendMessage: (String, AiGramBot.ChatBotId) -> Void
    let buyBot: (AiGramBot) -> Void
    let enableBot: (AiGramBot, Bool) -> Void
    let botDetails: (AiGramBot) -> Void
    let botActions: (AiGramBot) -> Void
    let toggleSearch: (Bool) -> Void
    
    var highlightedItemCollectionId: ItemCollectionId?
    var appearanceTransition: CGFloat = 1.0
    
    init(navigateToCollectionId: @escaping (ItemCollectionId) -> Void, sendMessage: @escaping (String, AiGramBot.ChatBotId) -> Void, buyBot: @escaping (AiGramBot) -> Void,
         enableBot: @escaping (AiGramBot, Bool) -> Void, botDetails: @escaping (AiGramBot) -> Void, toggleSearch: @escaping (Bool) -> Void, botActions: @escaping (AiGramBot) -> Void) {
        self.navigateToCollectionId = navigateToCollectionId
        self.sendMessage = sendMessage
        self.buyBot = buyBot
        self.enableBot = enableBot
        self.botDetails = botDetails
        self.toggleSearch = toggleSearch
        self.botActions = botActions
    }
}
