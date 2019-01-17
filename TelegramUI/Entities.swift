//
//  Entities.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 17/01/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation
import UIKit

public typealias BotResponse = [String: String]

public enum ChatBotError: Error {
    case modelFileNotExists
}

let TargetBotName: String = "binbank"

public struct ChatBot {
    public var id: Int = 0
    public var title: String = ""
    public var words: [String] = []
    public var responses: [BotResponse] = []
    public var modelURL: URL
    public var icon: UIImage = UIImage()
    public let url: URL
    public var isTarget: Bool {
        return title == TargetBotName
    }
    
    public var isLocal: Bool {
        let fm = FileManager.default
        guard var destinationUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return false }
        destinationUrl.appendPathComponent("chatbots", isDirectory: true)
        destinationUrl.appendPathComponent("\(title).chatbot", isDirectory: true)
        let result = (try? destinationUrl.checkResourceIsReachable()) ?? false
        return result
    }
    
    public init(url: URL) throws {
        self.url = url
        title = url.deletingPathExtension().lastPathComponent
        modelURL = url.appendingPathComponent("\(title)converted_model.tflite")
        if !(try modelURL.checkResourceIsReachable()) {
            throw ChatBotError.modelFileNotExists
        }
        
        if let image = UIImage(in: url, name: "icon", ext: "png") {
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

extension ChatBotResult: Equatable {
    public static func == (lhs: ChatBotResult, rhs: ChatBotResult) -> Bool {
        return lhs.bot == rhs.bot
            && lhs.responses == rhs.responses
    }
}

extension UIImage {
    convenience init?(in folder: URL, name: String, ext: String) {
        var nameWithScale = name
        let name = "\(name).\(ext)"
        let scale = UIScreen.main.scale
        if scale != 1 {
            nameWithScale = "\(nameWithScale)@\(Int(scale))x"
        }
        nameWithScale = "\(nameWithScale).\(ext)"
        var url = folder.appendingPathComponent(nameWithScale)
        if !((try? url.checkResourceIsReachable()) ?? false) {
            url = folder.appendingPathComponent(name)
        }
        if !((try? url.checkResourceIsReachable()) ?? false) {
            return nil
        }
        if let data = try? Data(contentsOf: url) {
            self.init(data: data)
            return
        }
        return nil
    }
}
