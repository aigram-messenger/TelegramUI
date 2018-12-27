//
//  BotProcessor.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 27/12/2018.
//  Copyright © 2018 Telegram. All rights reserved.
//

import Foundation

public final class BotProcessor {
    public let bot: ChatBot
    
    public init(bot: ChatBot) {
        self.bot = bot
    }
    
    deinit {
    }
}

extension BotProcessor {
    /// Synchronous call
    public func process(messages: [String]) -> ChatBotResult {
        var operations: [Operation] = []
        let queue = OperationQueue()
        let lock = NSRecursiveLock()
        var responses: [BotResponse] = []
        for message in messages {
//            guard arc4random_uniform(20) % 4 == 0 else { continue }
            let words = self.words(of: message)
            
            let operation = BlockOperation {
                Thread.sleep(forTimeInterval: 0.1)
                
                for word in words {
                    lock.lock()
                    responses.append(["response": word])
                    lock.unlock()
                }
            }
            operations.append(operation)
        }
        queue.addOperations(operations, waitUntilFinished: true)
        let botResult = ChatBotResult(bot: self.bot, responses: responses)
        return botResult
    }
}

extension BotProcessor {
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
