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

private let titleFont = Font.regular(17.0)
private let titleBoldFont = Font.medium(17.0)
private let titleItalicFont = Font.italic(17.0)
private let titleFixedFont = Font.regular(17.0)

class ChatStoreBotItemNode: ListViewItemNode {
    private(set) var bot: ChatBot
    private var theme: PresentationTheme?
    private let titleNode: TextNode
    private let separatorNode: ASDisplayNode
    private let backgroundNode: ASDisplayNode
    private let previewImageNode: ASImageNode
    
    private let installationActionImageNode: ASImageNode
    private let installationActionNode: HighlightableButtonNode
    
    private var item: ChatBotsStoreListItem?
    
    init(bot: ChatBot) {
        self.bot = bot
        
        self.titleNode = TextNode()
        self.titleNode.isUserInteractionEnabled = false
        self.titleNode.contentMode = .left
        self.titleNode.contentsScale = UIScreen.main.scale
        
        self.separatorNode = ASDisplayNode()
        
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true
        self.backgroundNode.backgroundColor = .white
        
        self.installationActionImageNode = ASImageNode()
        self.installationActionImageNode.displaysAsynchronously = false
        self.installationActionImageNode.displayWithoutProcessing = true
        self.installationActionImageNode.isLayerBacked = true
        self.installationActionNode = HighlightableButtonNode()
        
        self.previewImageNode = ASImageNode()
        self.previewImageNode.displaysAsynchronously = false
        self.previewImageNode.displayWithoutProcessing = true
        self.previewImageNode.isLayerBacked = true
        self.previewImageNode.image = bot.preview
        self.previewImageNode.contentMode = .scaleAspectFill
        self.previewImageNode.clipsToBounds = true
        
        super.init(layerBacked: false)
        
        self.addSubnode(self.backgroundNode)
        self.addSubnode(self.previewImageNode)
        self.addSubnode(self.titleNode)
        self.addSubnode(self.installationActionImageNode)
        self.addSubnode(self.installationActionNode)
        self.addSubnode(self.separatorNode)
        
        self.installationActionNode.addTarget(self, action: #selector(self.buyBotAction), forControlEvents: .touchUpInside)
        self.installationActionNode.highligthedChanged = { [weak self] highlighted in
            if let strongSelf = self {
                if highlighted {
                    strongSelf.installationActionImageNode.layer.removeAnimation(forKey: "opacity")
                    strongSelf.installationActionImageNode.alpha = 0.4
                } else {
                    strongSelf.installationActionImageNode.alpha = 1.0
                    strongSelf.installationActionImageNode.layer.animateAlpha(from: 0.4, to: 1.0, duration: 0.2)
                }
            }
        }
    }
    
    func update(bot: ChatBot, theme: PresentationTheme) {
        self.bot = bot
        if theme != self.theme {
            self.theme = theme
        }
        self.previewImageNode.image = bot.preview
        self.separatorNode.backgroundColor = theme.chatList.itemSeparatorColor
        if BotsStoreManager.shared.isBotBought(bot) {
            self.backgroundNode.backgroundColor = UIColor.green
            self.installationActionNode.isHidden = true
            self.installationActionImageNode.isHidden = true
        } else {
            self.backgroundNode.backgroundColor = UIColor(argb: arc4random())
            self.installationActionImageNode.isHidden = false
            self.installationActionNode.isHidden = false
        }
    }
    
    override func animateAdded(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
    }
    
    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
    }
    
    func asyncLayout() -> (_ item: ChatBotsStoreListItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        let makeTitleLayout = TextNode.asyncLayout(self.titleNode)
        return { item, params, neighbors in
            let title = item.bot.title
            let textColor: UIColor = item.theme.list.itemPrimaryTextColor
            
            let leftInset = 16.0 + params.leftInset
            
            let entities = generateTextEntities(title, enabledTypes: [])
            let string = stringWithAppliedEntities(title, entities: entities, baseColor: textColor, linkColor: item.theme.list.itemAccentColor, baseFont: titleFont, linkFont: titleFont, boldFont: titleBoldFont, italicFont: titleItalicFont, fixedFont: titleFixedFont)
            
            let (titleLayout, titleApply) = makeTitleLayout(TextNodeLayoutArguments(attributedString: string, backgroundColor: nil, maximumNumberOfLines: 0, truncationType: .end, constrainedSize: CGSize(width: params.width - params.leftInset - params.rightInset - 20.0, height: 30), alignment: .natural, cutout: nil, insets: UIEdgeInsets()))
            
            let contentSize = CGSize(width: params.width, height: 96)
            let insets = itemListNeighborsPlainInsets(neighbors)
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            
            return (layout, { [weak self] in
                if let strongSelf = self {
                    strongSelf.item = item
                    
                    let _ = titleApply()
                    
                    strongSelf.previewImageNode.frame = CGRect(x: 16, y: 16, width: 72, height: 72)
                    
                    strongSelf.titleNode.frame = CGRect(origin: CGPoint(x: leftInset, y: 11.0), size: titleLayout.size)
                    strongSelf.backgroundNode.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: contentSize)
                    strongSelf.separatorNode.frame = CGRect(origin: CGPoint(x: 0, y: contentSize.height - 1), size: CGSize(width: contentSize.width, height: 1))
                    
                    if item.bot.isLocal {
                        strongSelf.installationActionNode.isHidden = true
                        strongSelf.installationActionImageNode.isHidden = true
                    } else {
                        strongSelf.installationActionImageNode.isHidden = false
                        strongSelf.installationActionNode.isHidden = false
                    }
                    
                    let installationActionFrame = CGRect(origin: CGPoint(x: params.width - params.rightInset - 50.0, y: 0.0), size: CGSize(width: 50.0, height: layout.contentSize.height))
                    strongSelf.installationActionNode.frame = installationActionFrame
                    
                    let image = PresentationResourcesItemList.plusIconImage(item.theme) ?? UIImage()
                    let imageSize = image.size
                    strongSelf.installationActionImageNode.image = image
                    strongSelf.installationActionImageNode.frame = CGRect(origin: CGPoint(x: installationActionFrame.minX + floor((installationActionFrame.size.width - imageSize.width) / 2.0), y: installationActionFrame.minY + floor((installationActionFrame.size.height - imageSize.height) / 2.0)), size: imageSize)
                }
            })
        }
    }
    
    @objc private func buyBotAction() {
        self.installationActionNode.isUserInteractionEnabled = false
        self.item?.inputNodeInteraction.buyBot(self.bot)
    }
}
