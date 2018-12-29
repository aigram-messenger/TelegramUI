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

struct ChatSuggestionListItem: ListViewItem {
    private let response: BotResponse
    let inputNodeInteraction: ChatBotsInputNodeInteraction
    let theme: PresentationTheme
    
    var selectable: Bool { return true }
    
    init(response: BotResponse, inputNodeInteraction: ChatBotsInputNodeInteraction, theme: PresentationTheme) {
        self.response = response
        self.inputNodeInteraction = inputNodeInteraction
        self.theme = theme
    }
    
    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, () -> Void)) -> Void) {
        async {
            let node = ChatSuggestionItemNode()
            node.contentSize = CGSize(width: 100, height: 40)
            Queue.mainQueue().async {
                completion(node, {
                    return (nil, {
                        node.update(response: self.response, theme: self.theme)
                    })
                })
            }
        }
    }
    
    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping () -> Void) -> Void) {
        Queue.mainQueue().async {
            completion(ListViewItemNodeLayout(contentSize: node().contentSize, insets: ChatSuggestionsInputNode.setupPanelIconInsets(item: self, previousItem: previousItem, nextItem: nextItem)), {
                (node() as? ChatSuggestionItemNode)?.update(response: self.response, theme: self.theme)
            })
        }
    }
    
    func selected(listView: ListView) {
        guard let message = self.response["response"] else { return }
        self.inputNodeInteraction.sendMessage(message)
    }
}

private class ChatSuggestionItemNode: ListViewItemNode {
    private var response: BotResponse
    private var theme: PresentationTheme?
    
    init() {
        self.response = BotResponse()
        super.init(layerBacked: true)
        self.backgroundColor = UIColor(argb: arc4random())
    }
    
    func update(response: BotResponse, theme: PresentationTheme) {
        self.response = response
        if theme != self.theme {
            self.theme = theme
        }
        print("\(self.response)")
        self.contentSize = CGSize(width: 100, height: 40)
    }
    
    override func animateAdded(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
    }
    
    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
    }
}

final class ChatBotsInputSuggestionsPane: ChatMediaInputPane, UIScrollViewDelegate {
    private var responses: [BotResponse]
    private let inputNodeInteraction: ChatBotsInputNodeInteraction
    private let listView: ListView
    
    var theme: PresentationTheme
    
    init(responses: [BotResponse], inputNodeInteraction: ChatBotsInputNodeInteraction, theme: PresentationTheme) {
        self.responses = responses
        self.inputNodeInteraction = inputNodeInteraction
        self.theme = theme
        
        self.listView = ListView()
        
        super.init()
        let colors = [
            UIColor.green,
            UIColor.brown,
            UIColor.magenta,
            UIColor.blue
        ]
        var index = Int(arc4random_uniform(UInt32(colors.count)))
//        self.backgroundColor = colors[index]
        
        self.listView.backgroundColor = colors[index]
        
        self.addSubnode(self.listView)
        
        index = 0
        let insertItems: [ListViewInsertItem] = self.responses.map {
            let itemNode = ChatSuggestionListItem(response: $0, inputNodeInteraction: self.inputNodeInteraction, theme: self.theme)
            let item = ListViewInsertItem(index: index, previousIndex: nil, item: itemNode, directionHint: nil)
            index += 1
            return item
        }
        self.listView.transaction(deleteIndices: [], insertIndicesAndItems: insertItems, updateIndicesAndItems: [], options: [.Synchronous, .LowLatency], updateOpaqueState: nil)
    }
    
    override func updateLayout(size: CGSize, topInset: CGFloat, bottomInset: CGFloat, isExpanded: Bool, transition: ContainedViewLayoutTransition) {
//        let suggestions = self.responses.map { $0["response"] ?? "" }

//        let verticalInset: CGFloat = 10.0
//        let sideInset: CGFloat = 6.0
//        let buttonHeight: CGFloat = 43.0
//        let rowSpacing: CGFloat = 5.0
//
//        let rowsHeight = verticalInset + CGFloat(suggestions.count) * buttonHeight + CGFloat(max(0, suggestions.count - 1)) * rowSpacing + verticalInset
//
//        var verticalOffset = verticalInset
//        var buttonIndex = 0
//        for suggestion in suggestions {
//            let buttonWidth = floor(size.width - sideInset - sideInset)
//
//            let buttonNode: ChatSuggestionsInputButtonNode
//            if buttonIndex < self.buttonNodes.count {
//                buttonNode = self.buttonNodes[buttonIndex]
//            } else {
//                buttonNode = ChatSuggestionsInputButtonNode()
//                buttonNode.titleNode.maximumNumberOfLines = 2
//                buttonNode.addTarget(self, action: #selector(self.buttonPressed(_:)), forControlEvents: [.touchUpInside])
//                self.scrollNode.addSubnode(buttonNode)
//                self.buttonNodes.append(buttonNode)
//            }
//            buttonIndex += 1
//            buttonNode.frame = CGRect(origin: CGPoint(x: sideInset, y: verticalOffset), size: CGSize(width: buttonWidth, height: buttonHeight))
//            if buttonNode.suggestion != suggestion {
//                buttonNode.suggestion = suggestion
//                buttonNode.setAttributedTitle(NSAttributedString(string: suggestion, font: Font.regular(16.0), textColor: UIColor.white, paragraphAlignment: .right), for: [])
//            }
//            verticalOffset += buttonHeight + rowSpacing
//        }
//
//        for i in (buttonIndex ..< self.buttonNodes.count).reversed() {
//            self.buttonNodes[i].removeFromSupernode()
//            self.buttonNodes.remove(at: i)
//        }

        var size = size
        size.height -= topInset + bottomInset
        transition.updateFrame(node: self.listView, frame: CGRect(origin: CGPoint(x: 0, y: topInset), size: size))
        
        let updateSizeAndInsets = ListViewUpdateSizeAndInsets(size: size, insets: UIEdgeInsets(), duration: 0, curve: .Default(duration: 0))
        self.listView.transaction(deleteIndices: [], insertIndicesAndItems: [], updateIndicesAndItems: [], options: [.Synchronous, .LowLatency], scrollToItem: nil, updateSizeAndInsets: updateSizeAndInsets, stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
//        self.listView.contentSize = CGSize(width: size.width, height: rowsHeight)
//        self.listView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
    }
    
    @objc func buttonPressed(_ button: ASButtonNode) {
//        guard let button = button as? ChatSuggestionsInputButtonNode else { return }
//        self.controllerInteraction.sendMessage(button.suggestion)
    }
}
