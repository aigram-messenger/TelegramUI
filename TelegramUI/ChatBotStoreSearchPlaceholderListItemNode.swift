//
//  ChatBotStoreSearchPlaceholderListItemNode.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 30/01/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import UIKit
import Display

private let templateLoupeIcon = UIImage(bundleImageName: "Components/Search Bar/Loupe")

private func generateLoupeIcon(color: UIColor) -> UIImage? {
    return generateTintedImage(image: templateLoupeIcon, color: color)
}

class ChatBotStoreSearchPlaceholderListItemNode: ListViewItemNode {
    private var currentState: (PresentationTheme, PresentationStrings)?
    var activate: (() -> Void)?
    
    let backgroundNode: ASImageNode
    let labelNode: ImmediateTextNode
    let iconNode: ASImageNode
    
    init() {
        self.backgroundNode = ASImageNode()
        self.backgroundNode.displaysAsynchronously = false
        self.backgroundNode.displayWithoutProcessing = true
        self.backgroundNode.isUserInteractionEnabled = false
        
        self.labelNode = ImmediateTextNode()
        self.labelNode.displaysAsynchronously = false
        self.labelNode.isUserInteractionEnabled = false
        
        self.iconNode = ASImageNode()
        self.iconNode.displaysAsynchronously = false
        self.iconNode.displayWithoutProcessing = true
        self.iconNode.isUserInteractionEnabled = false
        
        super.init(layerBacked: false)
        
        self.addSubnode(self.backgroundNode)
        self.addSubnode(self.labelNode)
        self.addSubnode(self.iconNode)
    }
    
    override func didLoad() {
        super.didLoad()
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(_:))))
    }
    
    func setup(theme: PresentationTheme, strings: PresentationStrings) {
        if self.currentState?.0 !== theme || self.currentState?.1 !== strings {
            self.backgroundNode.image = generateStretchableFilledCircleImage(diameter: 33.0, color: theme.chat.inputMediaPanel.stickersSearchBackgroundColor)
            self.iconNode.image = generateLoupeIcon(color: theme.chat.inputMediaPanel.stickersSearchControlColor)
            self.labelNode.attributedText = NSAttributedString(string: "Поиск по магазину", font: Font.regular(14.0), textColor: theme.chat.inputMediaPanel.stickersSearchPlaceholderColor)
        }
    }
    
    func asyncLayout() -> (_ item: ChatBotStoreSearchPlaceholderListItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        return { item, params, neighbors in
            let contentSize = CGSize(width: params.width, height: 56)
            var insets = itemListNeighborsPlainInsets(neighbors)
            insets.bottom = 0
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            
            return (layout, { [weak self] in
                if let strongSelf = self {
                    let bounds = strongSelf.bounds
                    guard !bounds.isEmpty else { return }
                    
                    let backgroundFrame = CGRect(origin: CGPoint(x: 8.0, y: 12.0), size: CGSize(width: bounds.width - 8.0 * 2.0, height: 33.0))
                    strongSelf.backgroundNode.frame = backgroundFrame
                    
                    let textSize = strongSelf.labelNode.updateLayout(bounds.size)
                    let textFrame = CGRect(origin: CGPoint(x: backgroundFrame.minX + floor((backgroundFrame.width - textSize.width) / 2.0), y: backgroundFrame.minY + floor((backgroundFrame.height - textSize.height) / 2.0)), size: textSize)
                    strongSelf.labelNode.frame = textFrame
                    
                    if let iconImage = strongSelf.iconNode.image {
                        strongSelf.iconNode.frame = CGRect(origin: CGPoint(x: textFrame.minX - iconImage.size.width - 5.0, y: floorToScreenPixels(textFrame.midY - iconImage.size.height / 2.0)), size: iconImage.size)
                    }
                }
            })
        }
    }
    
    @objc private func tapGesture(_ recognizer: UITapGestureRecognizer) {
        if case .ended = recognizer.state {
            self.activate?()
        }
    }
}
