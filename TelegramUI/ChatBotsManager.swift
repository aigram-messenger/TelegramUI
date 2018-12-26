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

public protocol ChatBotsUpdatingSuggestions {
    func setMessages(_ messages: [String])
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
    public let originalMessages: [String]
    public let responses: [BotResponse]
}

public final class ChatBotsManager {
    static let shared: ChatBotsManager = .init()
    private(set) public var bots: [ChatBot] = []
    
    private init() {
        let bundle = Bundle(for: ChatBotsManager.self)
        var urls = bundle.urls(forResourcesWithExtension: "chatbot", subdirectory: nil) ?? []
        urls.append(contentsOf: urls)
        urls.append(contentsOf: urls)
        var id = 0
        for url in urls {
            guard var bot = try? ChatBot(url: url) else { continue }
            bot.id = id
            bots.append(bot)
            id += 1
        }
    }
    
    public func handleMessages(_ messages: [String], completion: @escaping ([ChatBotResult]) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [unowned self] in
            var tempResults: [Int: (ChatBot, [String], [BotResponse])] = [:]
            for message in messages {
                for bot in self.bots {
                    guard arc4random_uniform(20) % 5 == 0 else { continue }
                    var (chatBot, originalMessages, responses) = tempResults[bot.id] ?? (bot, [], [])
                    originalMessages.append(message)
                    responses.append(contentsOf: bot.responses)
                    tempResults[bot.id] = (chatBot, originalMessages, responses)
                }
            }
            
            let results: [ChatBotResult] = tempResults.map {
                ChatBotResult(bot: $1.0, originalMessages: $1.1, responses: $1.2)
            }
            completion(results)
        }
    }
}
