//
//  ChatSuggestionsInputNode.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 11/12/2018.
//  Copyright © 2018 Telegram. All rights reserved.
//

import Foundation
import Display
import AsyncDisplayKit
import Postbox
import TelegramCore
import SwiftSignalKit

private final class ChatSuggestionsInputButtonNode: ASButtonNode {
    var suggestion: String?

    private var theme: PresentationTheme?

    init(theme: PresentationTheme) {
        super.init()

        self.updateTheme(theme: theme)
    }

    func updateTheme(theme: PresentationTheme) {
        if theme !== self.theme {
            self.theme = theme

            self.setBackgroundImage(PresentationResourcesChat.chatInputButtonPanelButtonImage(theme), for: [])
            self.setBackgroundImage(PresentationResourcesChat.chatInputButtonPanelButtonHighlightedImage(theme), for: [.highlighted])
        }
    }
}

final class ChatSuggestionsInputNode: ChatInputNode {
    private let account: Account
    private let controllerInteraction: ChatControllerInteraction

    private let separatorNode: ASDisplayNode
    private let scrollNode: ASScrollNode

    private var buttonNodes: [ChatSuggestionsInputButtonNode] = []
    private var messages: [String] = []

    private var theme: PresentationTheme?

    init(account: Account, controllerInteraction: ChatControllerInteraction) {
        self.account = account
        self.controllerInteraction = controllerInteraction

        self.scrollNode = ASScrollNode()

        self.separatorNode = ASDisplayNode()
        self.separatorNode.isLayerBacked = true

        super.init()

        self.addSubnode(self.scrollNode)
        self.scrollNode.view.delaysContentTouches = false
        self.scrollNode.view.canCancelContentTouches = true
        self.scrollNode.view.alwaysBounceHorizontal = false
        self.scrollNode.view.alwaysBounceVertical = false

        self.addSubnode(self.separatorNode)

        backgroundColor = UIColor.brown
    }

    override func didLoad() {
        super.didLoad()

        if #available(iOSApplicationExtension 11.0, *) {
            self.scrollNode.view.contentInsetAdjustmentBehavior = .never
        }
    }

    func set(messages: [String]) {
        self.messages = messages
        //TODO: update layout
    }

    func trashedSuggestions() -> [[String]] {
        return messages.map { [$0] }
    }

    override func updateLayout(width: CGFloat, leftInset: CGFloat, rightInset: CGFloat, bottomInset: CGFloat, standardInputHeight: CGFloat, inputHeight: CGFloat, maximumHeight: CGFloat, inputPanelHeight: CGFloat, transition: ContainedViewLayoutTransition, interfaceState: ChatPresentationInterfaceState) -> (CGFloat, CGFloat) {
        transition.updateFrame(node: self.separatorNode, frame: CGRect(origin: CGPoint(), size: CGSize(width: width, height: UIScreenPixel)))

        if self.theme !== interfaceState.theme {
            self.theme = interfaceState.theme

            self.separatorNode.backgroundColor = interfaceState.theme.chat.inputButtonPanel.panelSerapatorColor
            self.backgroundColor = UIColor.brown//interfaceState.theme.chat.inputButtonPanel.panelBackgroundColor
        }

        let suggestions = trashedSuggestions()

        let verticalInset: CGFloat = 10.0
        let sideInset: CGFloat = 6.0 + leftInset
        let buttonHeight: CGFloat = 43.0
        let columnSpacing: CGFloat = 6.0
        let rowSpacing: CGFloat = 5.0

        let panelHeight = standardInputHeight

        let rowsHeight = verticalInset + CGFloat(suggestions.count) * buttonHeight + CGFloat(max(0, suggestions.count - 1)) * rowSpacing + verticalInset

        var verticalOffset = verticalInset
        var buttonIndex = 0
        for suggestionsRow in suggestions {
            let buttonWidth = floor(((width - sideInset - sideInset) + columnSpacing - CGFloat(suggestionsRow.count) * columnSpacing) / CGFloat(suggestionsRow.count))

            var columnIndex = 0
            for suggestion in suggestionsRow {
                let buttonNode: ChatSuggestionsInputButtonNode
                if buttonIndex < self.buttonNodes.count {
                    buttonNode = self.buttonNodes[buttonIndex]
                    buttonNode.updateTheme(theme: interfaceState.theme)
                } else {
                    buttonNode = ChatSuggestionsInputButtonNode(theme: interfaceState.theme)
                    buttonNode.titleNode.maximumNumberOfLines = 2
                    buttonNode.addTarget(self, action: #selector(self.buttonPressed(_:)), forControlEvents: [.touchUpInside])
                    self.scrollNode.addSubnode(buttonNode)
                    self.buttonNodes.append(buttonNode)
                }
                buttonIndex += 1
                if buttonNode.suggestion != suggestion {
                    buttonNode.suggestion = suggestion
                    buttonNode.setAttributedTitle(NSAttributedString(string: suggestion, font: Font.regular(16.0), textColor: interfaceState.theme.chat.inputButtonPanel.buttonTextColor, paragraphAlignment: .center), for: [])
                }
                buttonNode.frame = CGRect(origin: CGPoint(x: sideInset + CGFloat(columnIndex) * (buttonWidth + columnSpacing), y: verticalOffset), size: CGSize(width: buttonWidth, height: buttonHeight))
                columnIndex += 1
            }
            verticalOffset += buttonHeight + rowSpacing
        }

        for i in (buttonIndex ..< self.buttonNodes.count).reversed() {
            self.buttonNodes[i].removeFromSupernode()
            self.buttonNodes.remove(at: i)
        }

        transition.updateFrame(node: self.scrollNode, frame: CGRect(origin: CGPoint(), size: CGSize(width: width, height: panelHeight)))
        self.scrollNode.view.contentSize = CGSize(width: width, height: rowsHeight)
        self.scrollNode.view.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)

        return (panelHeight, 0.0)
    }

    @objc func buttonPressed(_ button: ASButtonNode) {
        guard let button = button as? ChatSuggestionsInputButtonNode, let suggestion = button.suggestion else { return }
        controllerInteraction.sendMessage(suggestion)
    }
}
