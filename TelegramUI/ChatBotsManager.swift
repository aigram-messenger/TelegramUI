//
//  ChatBotsManager.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 25/12/2018.
//  Copyright © 2018 Telegram. All rights reserved.
//

import Foundation
import UIKit

public final class ChatBotsManager {
    static let shared: ChatBotsManager = .init()
    private(set) public var bots: [ChatBot] = []
    private var queue: OperationQueue
    private var lastMessages: [String]?
    
    private init() {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        let fm = FileManager.default
        guard var chatBotsUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        chatBotsUrl.appendPathComponent("chatbots", isDirectory: true)
        if !((try? chatBotsUrl.checkResourceIsReachable()) ?? false) {
            try? fm.createDirectory(at: chatBotsUrl, withIntermediateDirectories: true, attributes: nil)
        }
        
        print("BOTS LOCAL URL \(chatBotsUrl)")
        let urls = (try? fm.contentsOfDirectory(at: chatBotsUrl, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
//        if let tb = self.targetBot { bots = [tb] }
        var id = nextBotId
        for url in urls {
            guard var bot = try? ChatBot(url: url) else { continue }
            bot.id = id
            bots.append(bot)
            id += 1
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
    
    public func botsInStore() -> [ChatBot] {
        var result: [ChatBot] = []
        
        let bundle = Bundle(for: ChatBotsManager.self)
        let urls = bundle.urls(forResourcesWithExtension: "chatbot", subdirectory: "bots") ?? []
        for url in urls {
            guard let bot = try? ChatBot(url: url), !bot.isTarget else { continue }
            result.append(bot)
        }
        
        return result
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
        destinationUrl.appendPathComponent("\(bot.title).chatbot", isDirectory: true)
        if ((try? destinationUrl.checkResourceIsReachable()) ?? false) {
            try? fm.removeItem(at: destinationUrl)
        }
        
        do {
            try fm.copyItem(at: bot.url, to: destinationUrl)
            var newBot = try ChatBot(url: destinationUrl)
            newBot.id = nextBotId
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
        botUrl.appendPathComponent("\(bot.title).chatbot", isDirectory: true)
        try? fm.removeItem(at: botUrl)
    }
}

extension ChatBotsManager {
    private var nextBotId: Int {
        var result = 0
        
        for bot in bots {
            result = max(result, bot.id)
        }
        result += 1
        
        return result
    }
    
    private var targetBot: ChatBot? {
        let bundle = Bundle(for: ChatBotsManager.self)
        guard let url = bundle.url(forResource: TargetBotName, withExtension: "chatbot", subdirectory: "bots") else { return nil }
        var bot = try? ChatBot(url: url)
        bot?.id = 1
        return bot
    }
}
