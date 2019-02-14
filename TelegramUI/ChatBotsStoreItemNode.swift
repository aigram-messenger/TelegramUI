//
//  ChatBotsStoreItemNode.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 17/01/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import Display
import SwiftSignalKit

private let titleFont = Font.medium(16.0)
private let buttonTitleFont = Font.medium(13.0)
private let smallFont = Font.regular(12.0)

class ChatStoreBotItemNode: ListViewItemNode {
    private(set) var bot: ChatBot
    private var theme: PresentationTheme?
    private let titleNode: ASTextNode
    private let typeNode: ASTextNode
    private let descriptionNode: ASTextNode
    private let previewImageNode: ASImageNode
    
    private let installationActionNode: HighlightableButtonNode
    private let enablingActionNode: HighlightableButtonNode
    
    private var item: ChatBotsStoreListItem?
    
    init(bot: ChatBot) {
        self.bot = bot
        
        self.titleNode = ASTextNode()
        self.titleNode.isLayerBacked = true
        self.titleNode.attributedText = NSAttributedString(string: bot.title.capitalized, font: titleFont, textColor: UIColor.black)
        self.titleNode.maximumNumberOfLines = 1
        self.titleNode.truncationMode = .byTruncatingTail
        
        self.typeNode = ASTextNode()
        self.typeNode.isLayerBacked = true
        self.typeNode.attributedText = NSAttributedString(string: bot.type, font: smallFont, textColor: UIColor(argb: 0xff8a8a8a))
        self.typeNode.maximumNumberOfLines = 1
        self.typeNode.truncationMode = .byTruncatingTail
        
        self.descriptionNode = ASTextNode()
        self.descriptionNode.isLayerBacked = true
        self.descriptionNode.attributedText = NSAttributedString(string: bot.shortDescription, font: smallFont, textColor: UIColor(argb: 0xff8a8a8a))
        self.descriptionNode.maximumNumberOfLines = 2
        self.descriptionNode.truncationMode = .byTruncatingTail
        
        self.installationActionNode = HighlightableButtonNode()
        self.installationActionNode.backgroundColor = UIColor(argb: 0xff50a8eb)
        self.installationActionNode.cornerRadius = 4
        let priceString = BotsStoreManager.shared.botPriceString(bot: bot)
        self.installationActionNode.setAttributedTitle(NSAttributedString(string: priceString, font: buttonTitleFont, textColor: .white), for: .normal)
        
        self.enablingActionNode = HighlightableButtonNode()
        self.enablingActionNode.cornerRadius = 4
        self.enablingActionNode.borderWidth = 1
        let botIsEnabled = ChatBotsManager.shared.isBotEnabled(bot)
        let title = botIsEnabled ? "ОТКЛЮЧИТЬ" : "ВКЛЮЧИТЬ"
        let color = botIsEnabled ? UIColor(argb: 0xff848d99) : UIColor(argb: 0xff50a8eb)
        self.enablingActionNode.borderColor = color.cgColor
        self.enablingActionNode.setAttributedTitle(NSAttributedString(string: title, font: buttonTitleFont, textColor: color), for: .normal)
        
        self.previewImageNode = ASImageNode()
        self.previewImageNode.displaysAsynchronously = false
        self.previewImageNode.displayWithoutProcessing = true
        self.previewImageNode.isLayerBacked = true
        self.previewImageNode.image = bot.preview
        self.previewImageNode.contentMode = .scaleAspectFill
        self.previewImageNode.clipsToBounds = true
        
        super.init(layerBacked: false)
        
        self.addSubnode(self.previewImageNode)
        self.addSubnode(self.titleNode)
        self.addSubnode(self.typeNode)
        self.addSubnode(self.descriptionNode)
        self.addSubnode(self.installationActionNode)
        self.addSubnode(self.enablingActionNode)
        
        self.installationActionNode.addTarget(self, action: #selector(self.buyBotAction), forControlEvents: .touchUpInside)
        self.enablingActionNode.addTarget(self, action: #selector(self.enableBotAction), forControlEvents: .touchUpInside)
    }
    
    func update(bot: ChatBot, theme: PresentationTheme) {
        self.bot = bot
        if theme != self.theme {
            self.theme = theme
        }
        self.titleNode.attributedText = NSAttributedString(string: bot.title.capitalized, font: titleFont, textColor: UIColor.black)
        self.descriptionNode.attributedText = NSAttributedString(string: bot.shortDescription, font: smallFont, textColor: UIColor(argb: 0xff8a8a8a))
        let priceString = BotsStoreManager.shared.botPriceString(bot: bot)
        self.installationActionNode.setAttributedTitle(NSAttributedString(string: priceString, font: buttonTitleFont, textColor: .white), for: .normal)
        self.previewImageNode.image = bot.preview
        
        let botIsEnabled = ChatBotsManager.shared.isBotEnabled(bot)
        let title = botIsEnabled ? "ОТКЛЮЧИТЬ" : "ВКЛЮЧИТЬ"
        let color = botIsEnabled ? UIColor(argb: 0xff848d99) : UIColor(argb: 0xff50a8eb)
        self.enablingActionNode.borderColor = color.cgColor
        self.enablingActionNode.setAttributedTitle(NSAttributedString(string: title, font: buttonTitleFont, textColor: color), for: .normal)
        
        let bought = BotsStoreManager.shared.isBotBought(bot)
        self.installationActionNode.isHidden = bought
        self.enablingActionNode.isHidden = !bought
    }
    
    override func animateAdded(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
    }
    
    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
    }
    
    func asyncLayout() -> (_ item: ChatBotsStoreListItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        return { item, params, neighbors in
            let contentSize = CGSize(width: params.width, height: 96)
            var insets = itemListNeighborsPlainInsets(neighbors)
            insets.bottom = 0
            insets.top = 0
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            
            return (layout, { [weak self] in
                if let strongSelf = self {
                    strongSelf.item = item
                    
                    strongSelf.previewImageNode.frame = CGRect(x: 16, y: 16, width: 72, height: 72)
                    
                    let buttonWidth: CGFloat = 105
                    let titleWidth = max(params.width - (16 + strongSelf.previewImageNode.frame.width + 16 + 16 + buttonWidth + 16), 0)
                    let titleSize = strongSelf.titleNode.measure(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
                    strongSelf.titleNode.frame = CGRect(x: strongSelf.previewImageNode.frame.maxX + 16,
                                                        y: strongSelf.previewImageNode.frame.origin.y - 3,
                                                        width: titleWidth,
                                                        height: titleSize.height)
                    
                    let typeSyze = strongSelf.typeNode.measure(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
                    strongSelf.typeNode.frame = CGRect(x: strongSelf.titleNode.frame.minX,
                                                       y: strongSelf.titleNode.frame.maxY + 1,
                                                       width: titleWidth,
                                                       height: typeSyze.height)
                    let descriptionWidth = max(params.width - (16 + strongSelf.previewImageNode.frame.width + 16 + 16), 0)
                    let descriptionHeight: CGFloat = 31
                    let descriptionSize = strongSelf.descriptionNode.measure(CGSize(width: descriptionWidth, height: descriptionHeight))
                    strongSelf.descriptionNode.frame = CGRect(x: strongSelf.titleNode.frame.minX,
                                                              y: strongSelf.typeNode.frame.maxY + 10,
                                                              width: descriptionWidth,
                                                              height: descriptionSize.height)
                    
                    
                    
                    
                    let bought = BotsStoreManager.shared.isBotBought(item.bot)
                    strongSelf.installationActionNode.isHidden = bought
                    strongSelf.enablingActionNode.isHidden = !bought
                    
                    let actionFrame = CGRect(x: params.width - params.rightInset - 16 - buttonWidth, y: 16, width: buttonWidth, height: 26)
                    strongSelf.installationActionNode.frame = actionFrame
                    strongSelf.enablingActionNode.frame = actionFrame
                }
            })
        }
    }
    
    @objc private func buyBotAction() {
//        self.installationActionNode.isUserInteractionEnabled = false
        self.item?.inputNodeInteraction.buyBot(self.bot)
    }
    
    @objc private func enableBotAction() {
        let botIsEnabled = ChatBotsManager.shared.isBotEnabled(bot)
        self.item?.inputNodeInteraction.enableBot(self.bot, !botIsEnabled)
    }
}
