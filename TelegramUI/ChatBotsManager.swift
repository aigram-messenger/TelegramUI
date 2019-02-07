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
    private var loadedBotsFlag: Bool = false
    private(set) public var loadedBotsInStore: [ChatBot] = []
    private var queue: OperationQueue
    private var searchQueue: OperationQueue
    private var lastMessages: [String]?
    private var lastSearchText: String?
    private var storeBotsLoadingStarted: Bool = false
    private var storeBotsLoadingCompletions: [(Result<[ChatBot]>) -> Void] = []
    
    public var autoOpenBots: Bool {
        get { return UserDefaults.standard.bool(forKey: "autoOpenBots") ?? true }
        set {
            UserDefaults.standard.set(newValue, forKey: "autoOpenBots")
            UserDefaults.standard.synchronize()
        }
    }
    public var inviteUrl: String {
        return "https://aigram.app"
    }
    public var shareText: String {
        return """
            Привет, я общаюсь здесь с тобой используя нейроботов – помощников для переписок. Скачай AiGram – мессенджер с Искусственным интеллектом и продолжай общаться с пользователями Telegram в новом формате!
            https://aigram.app
            """
    }
    
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
        if loadedBotsFlag {
            completion(.success(self.loadedBotsInStore))
            return
        }
        storeBotsLoadingCompletions.append(completion)
        guard !storeBotsLoadingStarted else { return }
        DispatchQueue.global().asyncAfter(deadline: .now()) {
            self.storeBotsLoadingStarted = true
            var result: [ChatBot] = []
            
            let bundle = Bundle(for: ChatBotsManager.self)
            let urls = bundle.urls(forResourcesWithExtension: ChatBot.botExtension, subdirectory: "bots") ?? []
            for url in urls {
                guard let bot = try? ChatBot(url: url), !bot.isTarget else { continue }
                if bot.tags.contains(String(describing: ChatBotTag.free)), !bot.isLocal {
                    _ = self.copyBot(bot)
                }
                result.append(bot)
            }
            result.sort(by: { return $0.index <= $1.index })
            BotsStoreManager.shared.loadProducts(for: result) { [weak self] in
                self?.loadedBotsInStore = result
                self?.loadedBotsFlag = true
                DispatchQueue.main.async {
                    self?.storeBotsLoadingCompletions.forEach({ (block) in
                        block(.success(result))
                    })
                    self?.storeBotsLoadingCompletions.removeAll()
                }
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
        var botEnableStates: [ChatBot.ChatBotId: Bool] = (UserDefaults.standard.value(forKey: "EnabledBots") as? [ChatBot.ChatBotId: Bool]) ?? [:]
        botEnableStates[bot.name] = enabled
        UserDefaults.standard.setValue(botEnableStates, forKey: "EnabledBots")
        UserDefaults.standard.synchronize()
    }
    
    public func isBotEnabled(_ bot: ChatBot) -> Bool {
        let botEnableStates: [ChatBot.ChatBotId: Bool] = (UserDefaults.standard.value(forKey: "EnabledBots") as? [ChatBot.ChatBotId: Bool]) ?? [:]
        return botEnableStates[bot.name] ?? true
    }
}

extension ChatBotsManager {
    private var targetBot: ChatBot? {
        //TODO: not implemented
        return nil
    }
}
