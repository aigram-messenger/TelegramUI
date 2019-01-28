//
//  ChatBotDetailsItem.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 25/01/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation
import Display
import AsyncDisplayKit
import UIKit

final class ChatBotDetailsItem: ActionSheetItem {
    private let bot: ChatBot
    
    init(bot: ChatBot) {
        self.bot = bot
    }
    
    func node(theme: ActionSheetControllerTheme) -> ActionSheetItemNode {
        return ChatBotDetailsItemNode(bot: self.bot, theme: theme)
    }
    
    func updateNode(_ node: ActionSheetItemNode) {
    }
}

private final class ChatBotDetailsItemNode: ActionSheetItemNode {
    private let theme: ActionSheetControllerTheme
    private let bot: ChatBot
    
    private let descriptionView: ChatBotDescriptionView
    
    init(bot: ChatBot, theme: ActionSheetControllerTheme) {
        self.bot = bot
        self.theme = theme
        
        self.descriptionView = .init(bot: bot)
        
        super.init(theme: theme)
        
        self.view.addSubview(self.descriptionView)
    }
    
    override func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        var size = self.descriptionView.sizeThatFits(constrainedSize)
        
        return size
    }
    
    override func layout() {
        super.layout()
        
        self.descriptionView.frame = self.bounds
    }
}
