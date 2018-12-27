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
        modelURL = url.appendingPathComponent("model.tflite")
        if !(try modelURL.checkResourceIsReachable()) {
            throw ChatBotError.modelFileNotExists
        }
        
        if let data = try? Data(contentsOf: url.appendingPathComponent("icon.png")), let image = UIImage(data: data) {
            icon = image
        }
        
        let decoder = JSONDecoder()
        var data = try Data(contentsOf: url.appendingPathComponent("words.json"))
        words = try decoder.decode(type(of: words), from: data)
        
        data = try Data(contentsOf: url.appendingPathComponent("responses.json"))
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
//    public let originalMessages: [String]
    public let responses: [BotResponse]
}

public final class ChatBotsManager {
    static let shared: ChatBotsManager = .init()
    private(set) public var bots: [ChatBot] = []
    
    private init() {
        let bundle = Bundle(for: ChatBotsManager.self)
        let urls = bundle.urls(forResourcesWithExtension: "chatbot", subdirectory: nil) ?? []
        var id = 0
        for url in urls {
            guard var bot = try? ChatBot(url: url) else { continue }
            bot.id = id
            bots.append(bot)
            id += 1
        }
    }
    
    public func handleMessages(_ messages: [String], completion: @escaping ([ChatBotResult]) -> Void) {
        DispatchQueue.global().async {
            let queue = OperationQueue()
            let lock = NSRecursiveLock()
            var results: [ChatBotResult] = []
            
            for bot in self.bots {
                queue.addOperation {
                    let processor = BotProcessor(bot: bot)
                    let result = processor.process(messages: messages)
                    if !result.responses.isEmpty {
                        lock.lock()
                        results.append(result)
                        lock.unlock()
                    }
                }
            }
        
            queue.waitUntilAllOperationsAreFinished()
            DispatchQueue.main.async {
                completion(results)
            }
        }
    }
    
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
