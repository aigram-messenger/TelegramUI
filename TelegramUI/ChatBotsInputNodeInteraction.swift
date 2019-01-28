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

final class ChatBotsInputNodeInteraction {
    let navigateToCollectionId: (ItemCollectionId) -> Void
    let sendMessage: (String) -> Void
    let buyBot: (ChatBot) -> Void
    let enableBot: (ChatBot, Bool) -> Void
    let botDetails: (ChatBot) -> Void
    
    var highlightedItemCollectionId: ItemCollectionId?
    var appearanceTransition: CGFloat = 1.0
    
    init(navigateToCollectionId: @escaping (ItemCollectionId) -> Void, sendMessage: @escaping (String) -> Void, buyBot: @escaping (ChatBot) -> Void,
         enableBot: @escaping (ChatBot, Bool) -> Void, botDetails: @escaping (ChatBot) -> Void) {
        self.navigateToCollectionId = navigateToCollectionId
        self.sendMessage = sendMessage
        self.buyBot = buyBot
        self.enableBot = enableBot
        self.botDetails = botDetails
    }
}
