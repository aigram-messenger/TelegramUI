//
//  ChatBotsManager.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 25/12/2018.
//  Copyright © 2018 Telegram. All rights reserved.
//

import Foundation
import UIKit

public enum Result<T> {
    case success(T)
    case fail(Error)
}

public final class ChatBotsManager {
    static let shared: ChatBotsManager = .init()
    private(set) public var bots: [ChatBot] = []
    private(set) public var loadedBotsInStore: [ChatBot] = []
    private var queue: OperationQueue
    private var searchQueue: OperationQueue
    private var lastMessages: [String]?
    private var botEnableStates: [ChatBot.ChatBotId: Bool] = [:]
    private var lastSearchText: String?
    
    private init() {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        searchQueue = OperationQueue()
        searchQueue.maxConcurrentOperationCount = 1
        
        let fm = FileManager.default
        guard var chatBotsUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        chatBotsUrl.appendPathComponent("chatbots", isDirectory: true)
        if !((try? chatBotsUrl.checkResourceIsReachable()) ?? false) {
            try? fm.createDirectory(at: chatBotsUrl, withIntermediateDirectories: true, attributes: nil)
        }
        
        print("BOTS LOCAL URL \(chatBotsUrl)")
        let urls = (try? fm.contentsOfDirectory(at: chatBotsUrl, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
//        if let tb = self.targetBot { bots = [tb] }
        for url in urls {
            guard let bot = try? ChatBot(url: url) else { continue }
            bots.append(bot)
        }
        
//        let temp = bots
//        for bot in temp {
//            deleteBot(bot)
//        }
    }
    
    public func handleMessages(_ messages: [String], completion: @escaping ([ChatBotResult]) -> Void) {
        lastMessages = messages
        queue.addOperation {
            let localQueue = OperationQueue()
            let lock = NSRecursiveLock()
            var results: [ChatBotResult] = []
            
            for bot in self.bots {
                guard self.isBotEnabled(bot) else { continue }
                localQueue.addOperation {
                    let processor = BotProcessor(bot: bot)
                    let result = processor.process(messages: messages)
                    if !result.responses.isEmpty {
                        lock.lock()
                        results.append(result)
                        lock.unlock()
                    }
                }
            }
            
            localQueue.waitUntilAllOperationsAreFinished()
            DispatchQueue.main.async {
                if messages == self.lastMessages {
                    self.lastMessages = nil
                    completion(results)
                }
            }
        }
    }
    
    public func botsInStore(completion: @escaping (Result<[ChatBot]>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            var result: [ChatBot] = []
            
            let bundle = Bundle(for: ChatBotsManager.self)
            let urls = bundle.urls(forResourcesWithExtension: ChatBot.botExtension, subdirectory: "bots") ?? []
            for url in urls {
                guard let bot = try? ChatBot(url: url), !bot.isTarget else { continue }
                result.append(bot)
            }
            result.sort(by: { return $0.index <= $1.index })
            BotsStoreManager.shared.loadProducts(for: result) { [weak self] in
                self?.loadedBotsInStore = result
                completion(.success(result))
            }
        }
    }
    
    public func search(_ text: String, completion: @escaping ([ChatBot]) -> Void) {
        if self.lastSearchText != text {
            self.lastSearchText = nil
            self.searchQueue.cancelAllOperations()
        }
        self.lastSearchText = text
        let block = BlockOperation { [unowned self, text] in
            guard self.lastSearchText == text else { return }
            let result: [ChatBot] = self.bots.filter { $0.isAcceptedWithText(text) }
            DispatchQueue.main.async {
                completion(result)
            }
        }
        self.searchQueue.addOperation(block)
    }
    
    public func copyBot(_ bot: ChatBot) -> Bool {
        let fm = FileManager.default
        guard var destinationUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return false }
        
        destinationUrl.appendPathComponent("chatbots", isDirectory: true)
        if !((try? destinationUrl.checkResourceIsReachable()) ?? false) {
            do {
                try fm.createDirectory(at: destinationUrl, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return false
            }
        }
        destinationUrl.appendPathComponent("\(bot.fileNameComponents.0).\(bot.fileNameComponents.1)", isDirectory: true)
        if ((try? destinationUrl.checkResourceIsReachable()) ?? false) {
            try? fm.removeItem(at: destinationUrl)
        }
        
        do {
            try fm.copyItem(at: bot.url, to: destinationUrl)
            let newBot = try ChatBot(url: destinationUrl)
            bots.append(newBot)
        } catch {
            return false
        }
        
        return true
    }
    
    public func deleteBot(_ bot: ChatBot) {
        let fm = FileManager.default
        guard var botUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        botUrl.appendPathComponent("chatbots", isDirectory: true)
        botUrl.appendPathComponent("\(bot.fileNameComponents.0).\(bot.fileNameComponents.1)", isDirectory: true)
        try? fm.removeItem(at: botUrl)
    }
    
    public func enableBot(_ bot: ChatBot, enabled: Bool) {
        botEnableStates[bot.name] = enabled
    }
    
    public func isBotEnabled(_ bot: ChatBot) -> Bool {
        return botEnableStates[bot.name] ?? true
    }
}

extension ChatBotsManager {
    private var targetBot: ChatBot? {
        //TODO: not implemented
        return nil
    }
}
