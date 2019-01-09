//
//  ChatBotsManager.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 25/12/2018.
//  Copyright © 2018 Telegram. All rights reserved.
//

import Foundation
import UIKit

public typealias BotResponse = [String: String]

public enum ChatBotError: Error {
    case modelFileNotExists
}

public struct ChatBot {
    public var id: Int = 0
    public var title: String = ""
    public var words: [String] = []
    public var responses: [BotResponse] = []
    public var modelURL: URL
    public var icon: UIImage = UIImage()
    
    public init(url: URL) throws {
        title = url.deletingPathExtension().lastPathComponent
        modelURL = url.appendingPathComponent("\(title)converted_model.tflite")
        if !(try modelURL.checkResourceIsReachable()) {
            throw ChatBotError.modelFileNotExists
        }
        
        if let data = try? Data(contentsOf: url.appendingPathComponent("icon.png")), let image = UIImage(data: data) {
            icon = image
        }
        
        let decoder = JSONDecoder()
        var data = try Data(contentsOf: url.appendingPathComponent("words_\(title).json"))
        words = try decoder.decode(type(of: words), from: data)
        
        data = try Data(contentsOf: url.appendingPathComponent("response_\(title).json"))
        responses = try decoder.decode(type(of: responses), from: data)
    }
}

extension ChatBot: Equatable {
    public static func == (lhs: ChatBot, rhs: ChatBot) -> Bool {
        return lhs.title.lowercased() == rhs.title.lowercased()
    }
}

public struct ChatBotResult {
    public let bot: ChatBot
    public let responses: [BotResponse]
}

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
        
        let urls = (try? fm.contentsOfDirectory(at: chatBotsUrl, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        
        var id = 0
        for url in urls {
            guard var bot = try? ChatBot(url: url) else { continue }
            bot.id = id
            bots.append(bot)
            id += 1
        }
        
        print("\(botsInStore())")
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
            guard let bot = try? ChatBot(url: url) else { continue }
            result.append(bot)
        }
        
        return result
    }
}

extension ChatBotsManager {
    private func words(of message: String) -> [String] {
        let tagger = NSLinguisticTagger(tagSchemes: [.lemma], options: 0)
        tagger.string = message
        let range = NSRange(location: 0, length: message.count)
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]
        var words: [String] = []
        tagger.enumerateTags(in: range, scheme: .lemma, options: options) { (tag, tokenRange, sentenceRange, stop) in
            let word = (message as NSString).substring(with: tokenRange)
            words.append(word.lowercased())
        }
        return words
    }
}
