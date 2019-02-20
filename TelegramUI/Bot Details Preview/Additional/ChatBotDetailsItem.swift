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
import TelegramCore
import AiGramLib

final class ChatBotDetailsItem: ActionSheetItem {
    private let bot: ChatBot
    private let account: Account
    private var rateCompletion: ((Error?) -> Void)?
    
    init(account: Account, bot: ChatBot, rateCompletion: ((Error?) -> Void)?) {
        self.account = account
        self.bot = bot
        self.rateCompletion = rateCompletion
    }
    
    func node(theme: ActionSheetControllerTheme) -> ActionSheetItemNode {
        return ChatBotDetailsItemNode(account: self.account, bot: self.bot, theme: theme, rateCompletion: self.rateCompletion)
    }
    
    func updateNode(_ node: ActionSheetItemNode) {
    }
}

private final class ChatBotDetailsItemNode: ActionSheetItemNode {
    private let theme: ActionSheetControllerTheme
    private let bot: ChatBot
    
    private let descriptionView: ChatBotDescriptionView
    
    init(account: Account, bot: ChatBot, theme: ActionSheetControllerTheme, rateCompletion: ((Error?) -> Void)?) {
        self.bot = bot
        self.theme = theme
        
        self.descriptionView = .init(account: account, bot: bot, rateCompletion: rateCompletion)
        
        super.init(theme: theme)
        
        self.view.addSubview(self.descriptionView)
    }
    
    override func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        let size = self.descriptionView.sizeThatFits(constrainedSize)
        
        return size
    }
    
    override func layout() {
        super.layout()
        
        self.descriptionView.frame = self.bounds
    }
}
