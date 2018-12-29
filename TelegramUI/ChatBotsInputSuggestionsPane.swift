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
            node.contentSize = CGSize(width: params.width, height: 40)
            Queue.mainQueue().async {
                completion(node, {
                    return (nil, {
                        node.update(response: self.response, theme: self.theme, params: params)
                    })
                })
            }
        }
    }
    
    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping () -> Void) -> Void) {
        Queue.mainQueue().async {
            completion(ListViewItemNodeLayout(contentSize: node().contentSize, insets: ChatSuggestionsInputNode.setupPanelIconInsets(item: self, previousItem: previousItem, nextItem: nextItem)), {
                (node() as? ChatSuggestionItemNode)?.update(response: self.response, theme: self.theme, params: params)
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
    
    func update(response: BotResponse, theme: PresentationTheme, params: ListViewItemLayoutParams) {
        self.response = response
        if theme != self.theme {
            self.theme = theme
        }
        self.contentSize = CGSize(width: params.width, height: 40)
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
        var size = size
        size.height -= topInset + bottomInset
        transition.updateFrame(node: self.listView, frame: CGRect(origin: CGPoint(x: 0, y: topInset), size: size))
        
        let updateSizeAndInsets = ListViewUpdateSizeAndInsets(size: size, insets: UIEdgeInsets(), duration: 0, curve: .Default(duration: 0))
        self.listView.transaction(deleteIndices: [], insertIndicesAndItems: [], updateIndicesAndItems: [], options: [.Synchronous, .LowLatency], scrollToItem: nil, updateSizeAndInsets: updateSizeAndInsets, stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
    }
}
