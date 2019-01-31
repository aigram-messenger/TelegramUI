//
//  ChatBotsSearchContainerNode.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 30/01/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramCore

final class ChatBotsPaneSearchContainerNode: ASDisplayNode {
    private let theme: PresentationTheme
    private let strings: PresentationStrings
    private let inputNodeInteraction: ChatBotsInputNodeInteraction
    
    private let backgroundNode: ASDisplayNode
    private let searchBar: ChatBotsStoreSearchBar
    private let listView: ListView
    private let notFoundNode: ASImageNode
    private let notFoundLabel: ImmediateTextNode
    
    private var bots: [ChatBot] = []
    
    private var validLayout: CGSize?
    
    init(theme: PresentationTheme, strings: PresentationStrings, inputNodeInteraction: ChatBotsInputNodeInteraction, cancel: @escaping () -> Void) {
        self.theme = theme
        self.strings = strings
        self.inputNodeInteraction = inputNodeInteraction
        
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.backgroundColor = theme.chat.inputMediaPanel.stickersBackgroundColor
        
        self.searchBar = ChatBotsStoreSearchBar(theme: theme, strings: strings)
        
        self.notFoundNode = ASImageNode()
        self.notFoundNode.displayWithoutProcessing = true
        self.notFoundNode.displaysAsynchronously = false
        self.notFoundNode.clipsToBounds = false
        self.notFoundNode.image = generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Media/StickersNotFoundIcon"), color: theme.list.freeMonoIcon)
        
        self.notFoundLabel = ImmediateTextNode()
        self.notFoundLabel.displaysAsynchronously = false
        self.notFoundLabel.isUserInteractionEnabled = false
        self.notFoundLabel.attributedText = NSAttributedString(string: strings.Bots_NoBotsFound, font: Font.medium(14.0), textColor: theme.list.freeTextColor)
        self.notFoundNode.addSubnode(self.notFoundLabel)
        self.notFoundNode.isHidden = true
        
        self.listView = ListView()
        self.listView.backgroundColor = .brown
        
        super.init()
        
        self.addSubnode(self.backgroundNode)
        self.addSubnode(self.notFoundNode)
        self.addSubnode(self.listView)
        self.addSubnode(self.searchBar)
        
        self.listView.transaction(deleteIndices: [], insertIndicesAndItems: [], updateIndicesAndItems: [], options: [.Synchronous, .LowLatency], scrollToItem: nil, updateSizeAndInsets: nil, stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
        
        self.searchBar.placeholderString = NSAttributedString(string: strings.Bots_Search, font: Font.regular(14.0), textColor: theme.chat.inputMediaPanel.stickersSearchPlaceholderColor)
        self.searchBar.cancel = {
            cancel()
        }
        self.searchBar.activate()
        
        ChatBotsManager.shared.search("") { [weak self] bots in
            guard let self = self else { return }
            self.updateBots(bots)
        }
        
        self.searchBar.textUpdated = { [weak self] text in
            print("SEARCH \(text)")
            ChatBotsManager.shared.search(text) { [weak self] bots in
                guard let self = self else { return }
                self.updateBots(bots)
            }
            
//            let signal: Signal<([(String?, FoundStickerItem)], FoundStickerSets, Bool, FoundStickerSets?)?, NoError>
//            if !text.isEmpty {
//                let stickers: Signal<[(String?, FoundStickerItem)], NoError> = Signal { subscriber in
//                    var signals: [Signal<(String?, [FoundStickerItem]), NoError>] = []
//
//                    if text.isSingleEmoji {
//                        signals.append(searchStickers(account: account, query: text.firstEmoji)
//                            |> take(1)
//                            |> map { (nil, $0) })
//                    } else {
//                        for entry in TGEmojiSuggestions.suggestions(forQuery: text.lowercased()) {
//                            if let entry = entry as? TGAlphacodeEntry {
//                                signals.append(searchStickers(account: account, query: entry.emoji)
//                                    |> take(1)
//                                    |> map { (entry.emoji, $0) })
//                            }
//                        }
//                    }
//
//                    return combineLatest(signals).start(next: { results in
//                        var result: [(String?, FoundStickerItem)] = []
//                        for (emoji, stickers) in results {
//                            for sticker in stickers {
//                                result.append((emoji, sticker))
//                            }
//                        }
//                        subscriber.putNext(result)
//                    }, completed: {
//                        subscriber.putCompletion()
//                    })
//                }
//
//                let local = searchStickerSets(postbox: account.postbox, query: text)
//                let remote = searchStickerSetsRemotely(network: account.network, query: text)
//                    |> delay(0.2, queue: Queue.mainQueue())
//                let packs = local
//                    |> mapToSignal { result -> Signal<(FoundStickerSets, Bool, FoundStickerSets?), NoError> in
//                        var localResult = result
//                        if let currentRemote = currentRemotePacks.with ({ $0 }) {
//                            localResult = localResult.merge(with: currentRemote)
//                        }
//                        return .single((localResult, false, nil))
//                            |> then(remote |> map { remote -> (FoundStickerSets, Bool, FoundStickerSets?) in
//                                return (result.merge(with: remote), true, remote)
//                                })
//                }
//                signal = combineLatest(stickers, packs)
//                    |> map { stickers, packs -> ([(String?, FoundStickerItem)], FoundStickerSets, Bool, FoundStickerSets?)? in
//                        return (stickers, packs.0, packs.1, packs.2)
//                }
//                strongSelf.searchBar.activity = true
//            } else {
//                signal = .single(nil)
//                strongSelf.searchBar.activity = false
//            }
//
//            strongSelf.searchDisposable.set((signal
//                |> deliverOn(queue)).start(next: { result in
//                    Queue.mainQueue().async {
//                        guard let strongSelf = self else {
//                            return
//                        }
//
//                        var entries: [StickerSearchEntry] = []
//                        if let (stickers, packs, final, remote) = result {
//                            if let remote = remote {
//                                let _ = currentRemotePacks.swap(remote)
//                            }
//                            strongSelf.gridNode.isHidden = false
//                            strongSelf.trendingPane.isHidden = true
//
//                            if final {
//                                strongSelf.searchBar.activity = false
//                            }
//
//                            var index = 0
//                            for (code, sticker) in stickers {
//                                entries.append(.sticker(index: index, code: code, stickerItem: sticker, theme: theme))
//                                index += 1
//                            }
//                            for (collectionId, info, _, installed) in packs.infos {
//                                if let info = info as? StickerPackCollectionInfo {
//                                    var topItems: [StickerPackItem] = []
//                                    for e in packs.entries {
//                                        if let item = e.item as? StickerPackItem {
//                                            if e.index.collectionId == collectionId {
//                                                topItems.append(item)
//                                            }
//                                        }
//                                    }
//                                    entries.append(.global(index: index, info: info, topItems: topItems, installed: installed))
//                                    index += 1
//                                }
//                            }
//
//                            if final || !entries.isEmpty {
//                                strongSelf.notFoundNode.isHidden = !entries.isEmpty
//                            }
//                        } else {
//                            let _ = currentRemotePacks.swap(nil)
//                            strongSelf.searchBar.activity = false
//                            strongSelf.gridNode.isHidden = true
//                            strongSelf.notFoundNode.isHidden = true
//                            strongSelf.trendingPane.isHidden = false
//                        }
//
//                        let previousEntries = currentEntries.swap(entries)
//                        let transition = preparedChatMediaInputGridEntryTransition(account: account, theme: theme, strings: strings, from: previousEntries ?? [], to: entries, interaction: interaction, inputNodeInteraction: strongSelf.inputNodeInteraction)
//                        strongSelf.enqueueTransition(transition)
//                    }
//                }))
        }
    }
    
    func updateLayout(size: CGSize, leftInset: CGFloat, rightInset: CGFloat, bottomInset: CGFloat, inputHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        let firstLayout = self.validLayout == nil
        self.validLayout = size
        transition.updateFrame(node: self.backgroundNode, frame: CGRect(origin: CGPoint(), size: size))
        
        let searchBarHeight: CGFloat = 48.0
        transition.updateFrame(node: self.searchBar, frame: CGRect(origin: CGPoint(), size: CGSize(width: size.width, height: searchBarHeight)))
        self.searchBar.updateLayout(boundingSize: CGSize(width: size.width, height: searchBarHeight), leftInset: leftInset, rightInset: rightInset, transition: transition)
        
        if let image = self.notFoundNode.image {
            let areaHeight = size.height - searchBarHeight - inputHeight
            
            let labelSize = self.notFoundLabel.updateLayout(CGSize(width: size.width, height: CGFloat.greatestFiniteMagnitude))
            
            transition.updateFrame(node: self.notFoundNode, frame: CGRect(origin: CGPoint(x: floor((size.width - image.size.width) / 2.0), y: searchBarHeight + floor((areaHeight - image.size.height - labelSize.height) / 2.0)), size: image.size))
            transition.updateFrame(node: self.notFoundLabel, frame: CGRect(origin: CGPoint(x: floor((image.size.width - labelSize.width) / 2.0), y: image.size.height + 8.0), size: labelSize))
        }
        
        let contentFrame = CGRect(origin: CGPoint(x: leftInset, y: searchBarHeight), size: CGSize(width: size.width - leftInset - rightInset, height: size.height - searchBarHeight))
        
        let updateSizeAndInsets = ListViewUpdateSizeAndInsets(size: size, insets: UIEdgeInsets(), duration: 0, curve: .Spring(duration: 0))
        self.listView.transaction(deleteIndices: [], insertIndicesAndItems: [], updateIndicesAndItems: [], options: [.Synchronous, .LowLatency], scrollToItem: nil, updateSizeAndInsets: updateSizeAndInsets, stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
        
//        transition.updateFrame(node: self.trendingPane, frame: contentFrame)
//        self.trendingPane.updateLayout(size: contentFrame.size, topInset: 0.0, bottomInset: bottomInset, isExpanded: false, transition: transition)

        transition.updateFrame(node: self.listView, frame: contentFrame)
//        if firstLayout {
//            while !self.enqueuedTransitions.isEmpty {
//                self.dequeueTransition()
//            }
//        }
    }
    
    func deactivate() {
        self.searchBar.deactivate(clear: true)
    }
    
    func animateIn(from placeholder: ChatBotStoreSearchPlaceholderListItemNode, transition: ContainedViewLayoutTransition) {
        self.listView.alpha = 0.0
        transition.updateAlpha(node: self.listView, alpha: 1.0, completion: { _ in
        })
//        self.trendingPane.alpha = 0.0
//        transition.updateAlpha(node: self.trendingPane, alpha: 1.0, completion: { _ in
//        })
        switch transition {
        case let .animated(duration, curve):
            self.backgroundNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: duration / 2.0)
            self.searchBar.animateIn(from: placeholder, duration: duration, timingFunction: curve.timingFunction)
            let placeholderFrame = placeholder.view.convert(placeholder.bounds, to: self.view)
            if let size = self.validLayout {
                let verticalOrigin = placeholderFrame.minY - 4.0
                let initialBackgroundFrame = CGRect(origin: CGPoint(x: 0.0, y: verticalOrigin), size: CGSize(width: size.width, height: max(0.0, size.height - verticalOrigin)))
                self.backgroundNode.layer.animateFrame(from: initialBackgroundFrame, to: self.backgroundNode.frame, duration: duration, timingFunction: curve.timingFunction)
//                self.trendingPane.layer.animatePosition(from: CGPoint(x: 0.0, y: initialBackgroundFrame.minY - self.backgroundNode.frame.minY), to: CGPoint(), duration: duration, timingFunction: curve.timingFunction, additive: true)
            }
        case .immediate:
            break
        }
    }
    
    func animateOut(to placeholder: ChatBotStoreSearchPlaceholderListItemNode, transition: ContainedViewLayoutTransition, completion: @escaping () -> Void) {
        if case let .animated(duration, curve) = transition {
            if let size = self.validLayout {
                let placeholderFrame = placeholder.view.convert(placeholder.bounds, to: self.view)
                let verticalOrigin = placeholderFrame.minY - 4.0
                self.backgroundNode.layer.animateFrame(from: self.backgroundNode.frame, to: CGRect(origin: CGPoint(x: 0.0, y: verticalOrigin), size: CGSize(width: size.width, height: max(0.0, size.height - verticalOrigin))), duration: duration, timingFunction: curve.timingFunction, removeOnCompletion: false)
            }
        }
        self.searchBar.transitionOut(to: placeholder, transition: transition, completion: {
            completion()
        })
        transition.updateAlpha(node: self.searchBar, alpha: 0.0, completion: { _ in
        })
        transition.updateAlpha(node: self.backgroundNode, alpha: 0.0, completion: { _ in
        })
        transition.updateAlpha(node: self.listView, alpha: 0.0, completion: { _ in
        })
//        transition.updateAlpha(node: self.trendingPane, alpha: 0.0, completion: { _ in
//        })
        transition.updateAlpha(node: self.notFoundNode, alpha: 0.0, completion: { _ in
        })
        self.deactivate()
    }
    
    private func updateBots(_ bots: [ChatBot]) {
        let srcBots = self.bots
        self.bots = bots
        let endBots: [ChatBot] = bots
        
        let (deletes, inserts, updates) = mergeListsStableWithUpdates(leftList: srcBots, rightList: endBots)

        let deleteListItems = deletes.map { ListViewDeleteItem(index: $0, directionHint: nil) }
        let insertListItems = self.insertListItems(with: inserts)
        let updateListItems = self.updateListItems(with: updates)

//        for (pane, _) in self.panesAndAnimatingOut {
//            pane.removeFromSupernode()
//        }
//        self.panesAndAnimatingOut = []
//        var resultIndex = 0
//        for paneType in toArrangements {
//            switch paneType {
//            case .store:
//                self.panesAndAnimatingOut.append((ChatBotsInputStorePane(inputNodeInteraction: self.inputNodeInteraction, theme: self.theme!, strings: self.strings), false))
//            case .bot(let botId):
//                let bot = results.first(where: { $0.bot.id == botId })!.bot
//                self.panesAndAnimatingOut.append((ChatBotsInputSuggestionsPane(bot: bot, responses: results[resultIndex].responses, inputNodeInteraction: self.inputNodeInteraction, theme: self.theme!), false))
//                resultIndex += 1
//            }
//        }
        
        
        
        
        
        
        
        
        
//        var index = 0
//        var insertItems: [ListViewInsertItem] = bots.map {
//            let itemNode = ChatBotsStoreListItem(bot: $0, inputNodeInteraction: self.inputNodeInteraction, theme: self.theme)
//            let item = ListViewInsertItem(index: index, previousIndex: nil, item: itemNode, directionHint: nil)
//            index += 1
//            return item
//        }
        
        let updateSizeAndInsets = ListViewUpdateSizeAndInsets(size: self.bounds.size, insets: UIEdgeInsets(), duration: 0, curve: .Spring(duration: 0))
        self.listView.transaction(deleteIndices: deleteListItems, insertIndicesAndItems: insertListItems, updateIndicesAndItems: updateListItems, options: [.Synchronous, .AnimateInsertion], scrollToItem: nil, updateSizeAndInsets: updateSizeAndInsets, stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
    }
    
    private func insertListItems(with inserts: ([(Int, ChatBot, Int?)])) -> [ListViewInsertItem] {
        var result: [ListViewInsertItem] = []
        var index = 0
        for insert in inserts {
            let itemNode = ChatBotsStoreListItem(bot: insert.1, inputNodeInteraction: self.inputNodeInteraction, theme: self.theme)
            result.append(ListViewInsertItem(index: insert.0, previousIndex: insert.2, item: itemNode, directionHint: nil))
        }
        return result
    }
    
    private func updateListItems(with updates: ([(Int, ChatBot, Int)])) -> [ListViewUpdateItem] {
        var result = [ListViewUpdateItem]()
        for update in updates {
            let itemNode = ChatBotsStoreListItem(bot: update.1, inputNodeInteraction: self.inputNodeInteraction, theme: self.theme)
            result.append(ListViewUpdateItem(index: update.0, previousIndex: update.2, item: itemNode, directionHint: nil))
        }
        return result
    }
}
