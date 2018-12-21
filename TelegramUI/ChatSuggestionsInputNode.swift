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
import Strutext

struct Bot {
    var title: String
}

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
    
    private let disposable = MetaDisposable()

    private let botsListPanel: ASDisplayNode
    private let topSeparator: ASDisplayNode
    private let nodesContainer: ASDisplayNode
    private let botsListView: ListView
    
    private let separatorNode: ASDisplayNode
    private let scrollNode: ASScrollNode

    private var buttonNodes: [ChatSuggestionsInputButtonNode] = []
    private var messages: [String] = []
    private var bots: [Bot] = []

    private var theme: PresentationTheme?
    
    private let strutext: Strutext = .init()

    init(account: Account, controllerInteraction: ChatControllerInteraction, theme: PresentationTheme) {
        self.account = account
        self.controllerInteraction = controllerInteraction
        self.theme = theme
        
        self.nodesContainer = ASDisplayNode()
        self.nodesContainer.clipsToBounds = true
        self.nodesContainer.backgroundColor = theme.chat.inputPanel.panelBackgroundColor
        
        self.botsListPanel = ASDisplayNode()
        self.botsListPanel.clipsToBounds = true
        self.botsListPanel.backgroundColor = theme.chat.inputPanel.panelBackgroundColor
        
        self.topSeparator = ASDisplayNode()
        self.topSeparator.isLayerBacked = true
        self.topSeparator.backgroundColor = theme.chat.inputMediaPanel.panelSerapatorColor
        
        self.botsListView = ListView()
        self.botsListView.transform = CATransform3DMakeRotation(-CGFloat(Double.pi / 2.0), 0.0, 0.0, 1.0)
        
        
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
        
        self.botsListPanel.addSubnode(self.botsListView)
        self.nodesContainer.addSubnode(self.topSeparator)
        self.nodesContainer.addSubnode(self.botsListPanel)
        self.addSubnode(self.nodesContainer)
        
//        self.disposable.set((transitions
//            |> deliverOnMainQueue).start(next: { [weak self] (view, panelTransition, panelFirstTime, gridTransition, gridFirstTime) in
//                if let strongSelf = self {
//                    strongSelf.currentView = view
//                    strongSelf.enqueuePanelTransition(panelTransition, firstTime: panelFirstTime, thenGridTransition: gridTransition, gridFirstTime: gridFirstTime)
//                    if !strongSelf.initializedArrangement {
//                        strongSelf.initializedArrangement = true
//                        var currentPane = strongSelf.paneArrangement.panes[strongSelf.paneArrangement.currentIndex]
//                        if view.entries.isEmpty {
//                            currentPane = .trending
//                        }
//                        if currentPane != strongSelf.paneArrangement.panes[strongSelf.paneArrangement.currentIndex] {
//                            strongSelf.setCurrentPane(currentPane, transition: .immediate)
//                        }
//                    }
//                }
//            }))
    }
    
    deinit {
        self.disposable.dispose()
    }

    override func didLoad() {
        super.didLoad()
    }

    func set(messages: [String]) {
        self.messages = messages
    }

    func trashedSuggestions() -> [[String]] {
        var result: [[String]] = []
        
        for message in messages {
            let words = message.split(separator: " ")
            let temp = strutext.handle(words.map { String($0) })
//            var lemmas: [String] = []
            for set in temp {
                guard let first = set.first else { continue }
//                lemmas.append(first)
                result.append([first])
            }
//            result.append(lemmas)
        }
        
        
        return result
    }

    override func updateLayout(width: CGFloat, leftInset: CGFloat, rightInset: CGFloat, bottomInset: CGFloat, standardInputHeight: CGFloat, inputHeight: CGFloat, maximumHeight: CGFloat, inputPanelHeight: CGFloat, transition: ContainedViewLayoutTransition, interfaceState: ChatPresentationInterfaceState) -> (CGFloat, CGFloat) {
//        let separatorHeight = UIScreenPixel
//        let panelHeight = standardInputHeight
//        let contentVerticalOffset: CGFloat = 0.0
//        let containerOffset: CGFloat = 0
//
//        transition.updateFrame(node: self.nodesContainer, frame: CGRect(origin: CGPoint(x: 0.0, y: contentVerticalOffset), size: CGSize(width: width, height: max(0.0, 41.0 + UIScreenPixel))))
//        transition.updateFrame(node: self.botsListPanel, frame: CGRect(origin: CGPoint(x: 0.0, y: containerOffset), size: CGSize(width: width, height: 41.0)))
//        transition.updateFrame(node: self.topSeparator, frame: CGRect(origin: CGPoint(x: 0.0, y: 41.0 + containerOffset), size: CGSize(width: width, height: separatorHeight)))
        
        print("\(trashedSuggestions())")
        transition.updateFrame(node: self.topSeparator, frame: CGRect(origin: CGPoint(), size: CGSize(width: width, height: UIScreenPixel)))

        if self.theme !== interfaceState.theme {
            self.theme = interfaceState.theme

//            self.separatorNode.backgroundColor = interfaceState.theme.chat.inputButtonPanel.panelSerapatorColor
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
//        return (standardInputHeight, 0)
    }

    @objc func buttonPressed(_ button: ASButtonNode) {
        guard let button = button as? ChatSuggestionsInputButtonNode, let suggestion = button.suggestion else { return }
        controllerInteraction.sendMessage(suggestion)
    }
}
