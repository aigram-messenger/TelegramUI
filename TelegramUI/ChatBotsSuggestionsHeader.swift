//
//  ChatBotsSuggestionsHeader.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 16/01/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import Display
import AiGramLib

final class ChatSuggestionListItemHeader: ListViewItemHeader {
    let id: ListViewItemHeaderId
    var stickDirection: ListViewItemHeaderStickDirection { return .top }
    let height: CGFloat = 26
    let theme: PresentationTheme
    let bot: AiGramBot
    
    init(bot: AiGramBot, theme: PresentationTheme) {
        self.bot = bot
        self.id = ListViewItemHeaderId(bot.id)
        self.theme = theme
    }
    
    func node() -> ListViewItemHeaderNode {
        return ChatSuggestionListItemHeaderNode(title: self.bot.title, theme: self.theme)
    }
}

private let sectionTitleFont = Font.medium(12.0)

final class ChatSuggestionListItemHeaderNode: ListViewItemHeaderNode {
    let theme: PresentationTheme
    let titleNode: ASTextNode
    
    init(title: String, theme: PresentationTheme) {
        self.theme = theme
        
        self.titleNode = ASTextNode()
        self.titleNode.isLayerBacked = true
        self.titleNode.attributedText = NSAttributedString(string: title.capitalized, font: sectionTitleFont, textColor: theme.chat.inputMediaPanel.stickersSectionTextColor)
        self.titleNode.maximumNumberOfLines = 1
        self.titleNode.truncationMode = .byTruncatingTail
        
        super.init()
        
        self.addSubnode(self.titleNode)
        
        self.backgroundColor = theme.chat.inputMediaPanel.stickersBackgroundColor
    }
    
    override func updateLayout(size: CGSize, leftInset: CGFloat, rightInset: CGFloat) {
        guard size.width > 0, size.height > 0 else { return }
        let titleSize = self.titleNode.measure(CGSize(width: size.width - 24.0, height: CGFloat.greatestFiniteMagnitude))
        self.titleNode.frame = CGRect(origin: CGPoint(x: 12.0, y: 9.0), size: titleSize)
    }
}
