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

private final class ChatSuggestionsInputButtonNode: ASButtonNode {
    var suggestion: String = ""
    
    private var theme: PresentationTheme?
    
    override init() {
        super.init()
        backgroundColor = UIColor.darkGray
    }
    
//    init(theme: PresentationTheme) {
//        super.init()
//
//        self.updateTheme(theme: theme)
//    }
//
//    func updateTheme(theme: PresentationTheme) {
//        if theme !== self.theme {
//            self.theme = theme
//            self.setBackgroundImage(PresentationResourcesChat.chatInputButtonPanelButtonImage(theme), for: [])
//            self.setBackgroundImage(PresentationResourcesChat.chatInputButtonPanelButtonHighlightedImage(theme), for: [.highlighted])
//        }
//    }
}

final class ChatBotsInputSuggestionsPane: ChatMediaInputPane, UIScrollViewDelegate {
    private var responses: [BotResponse]
    private let controllerInteraction: ChatControllerInteraction
    private let scrollNode: ASScrollNode
    
    var theme: PresentationTheme?
    
    private var buttonNodes: [ChatSuggestionsInputButtonNode] = []
    
    init(responses: [BotResponse], controllerInteraction: ChatControllerInteraction) {
        self.responses = responses
        self.controllerInteraction = controllerInteraction
        
        self.scrollNode = ASScrollNode()
        
        super.init()
        let colors = [
            UIColor.green,
            UIColor.brown,
            UIColor.magenta,
            UIColor.blue
        ]
        let index = Int(arc4random_uniform(UInt32(colors.count)))
        self.backgroundColor = colors[index]
        
        self.addSubnode(self.scrollNode)
        self.scrollNode.view.delaysContentTouches = false
        self.scrollNode.view.canCancelContentTouches = true
        self.scrollNode.view.alwaysBounceHorizontal = false
        self.scrollNode.view.alwaysBounceVertical = false
    }
    
    override func didLoad() {
        super.didLoad()
        
        if #available(iOSApplicationExtension 11.0, *) {
            self.scrollNode.view.contentInsetAdjustmentBehavior = .never
        }
    }
    
    override func updateLayout(size: CGSize, topInset: CGFloat, bottomInset: CGFloat, isExpanded: Bool, transition: ContainedViewLayoutTransition) {
        let suggestions = self.responses.map { $0["response"] ?? "" }

        let verticalInset: CGFloat = 10.0
        let sideInset: CGFloat = 6.0
        let buttonHeight: CGFloat = 43.0
        let rowSpacing: CGFloat = 5.0

        let rowsHeight = verticalInset + CGFloat(suggestions.count) * buttonHeight + CGFloat(max(0, suggestions.count - 1)) * rowSpacing + verticalInset

        var verticalOffset = verticalInset
        var buttonIndex = 0
        for suggestion in suggestions {
            let buttonWidth = floor(size.width - sideInset - sideInset)

            let buttonNode: ChatSuggestionsInputButtonNode
            if buttonIndex < self.buttonNodes.count {
                buttonNode = self.buttonNodes[buttonIndex]
            } else {
                buttonNode = ChatSuggestionsInputButtonNode()
                buttonNode.titleNode.maximumNumberOfLines = 2
                buttonNode.addTarget(self, action: #selector(self.buttonPressed(_:)), forControlEvents: [.touchUpInside])
                self.scrollNode.addSubnode(buttonNode)
                self.buttonNodes.append(buttonNode)
            }
            buttonIndex += 1
            buttonNode.frame = CGRect(origin: CGPoint(x: sideInset, y: verticalOffset), size: CGSize(width: buttonWidth, height: buttonHeight))
            if buttonNode.suggestion != suggestion {
                buttonNode.suggestion = suggestion
                buttonNode.setAttributedTitle(NSAttributedString(string: suggestion, font: Font.regular(16.0), textColor: UIColor.white, paragraphAlignment: .right), for: [])
            }
            verticalOffset += buttonHeight + rowSpacing
        }

        for i in (buttonIndex ..< self.buttonNodes.count).reversed() {
            self.buttonNodes[i].removeFromSupernode()
            self.buttonNodes.remove(at: i)
        }

        transition.updateFrame(node: self.scrollNode, frame: CGRect(origin: CGPoint(), size: size))
        self.scrollNode.view.contentSize = CGSize(width: size.width, height: rowsHeight)
        self.scrollNode.view.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
    }
    
    @objc func buttonPressed(_ button: ASButtonNode) {
        guard let button = button as? ChatSuggestionsInputButtonNode else { return }
        self.controllerInteraction.sendMessage(button.suggestion)
    }
}
