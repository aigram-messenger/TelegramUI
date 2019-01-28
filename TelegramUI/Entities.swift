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

let TargetBotName: String = "target"

public enum ChatBotType: String, Codable, CustomStringConvertible {
    case bot
    
    public var description: String { return self.rawValue.capitalized }
}

private struct ChatBotInfo: Codable {
    let id: ChatBot.ChatBotId
    let title: String
    let name: String
    let shortDescription: String
    let type: ChatBotType
}

public struct ChatBot {
    public typealias ChatBotId = Int
    static let botExtension: String = "chatbot"
    
    private let info: ChatBotInfo
    
    public let url: URL
    public let fileNameComponents: (String, String)
    
    public var id: ChatBotId { return info.id }
    public var title: String { return info.title }
    public var name: String { return info.name }
    public var shortDescription: String { return info.shortDescription }
    public var type: String { return String(describing: info.type) }
    public var isTarget: Bool { return name == TargetBotName }
    public var fullDescription: String { return shortDescription }
    
    public let words: [String]
    public let responses: [BotResponse]
    
    public let modelURL: URL
    public let icon: UIImage
    public let preview: UIImage
    
    public var isLocal: Bool {
        let fm = FileManager.default
        guard var destinationUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return false }
        destinationUrl.appendPathComponent("chatbots", isDirectory: true)
        destinationUrl.appendPathComponent("\(fileNameComponents.0).\(fileNameComponents.1)", isDirectory: true)
        let result = (try? destinationUrl.checkResourceIsReachable()) ?? false
        return result
    }
    
    public init(url: URL) throws {
        self.url = url
        fileNameComponents = (url.deletingPathExtension().lastPathComponent, url.pathExtension)
        
        let decoder = JSONDecoder()
        var data = try Data(contentsOf: url.appendingPathComponent("info.json"))
        info = try decoder.decode(Swift.type(of: info), from: data)
        
        modelURL = url.appendingPathComponent("\(fileNameComponents.0)converted_model.tflite")
        if !(try modelURL.checkResourceIsReachable()) { throw ChatBotError.modelFileNotExists }
        
        data = try Data(contentsOf: url.appendingPathComponent("words_\(fileNameComponents.0).json"))
        words = try decoder.decode(Swift.type(of: words), from: data)
        
        data = try Data(contentsOf: url.appendingPathComponent("response_\(fileNameComponents.0).json"))
        responses = try decoder.decode(Swift.type(of: responses), from: data)
        
        icon = UIImage(in: url, name: "icon", ext: "png") ?? UIImage()
        preview = UIImage(in: url, name: "preview", ext: "png") ?? UIImage()
    }
}

extension ChatBot: Equatable {
    public static func == (lhs: ChatBot, rhs: ChatBot) -> Bool {
        return lhs.id == rhs.id
    }
}

public struct ChatBotResult {
    public let bot: ChatBot
    public let responses: [BotResponse]
}

extension ChatBotResult: Equatable {
    public static func == (lhs: ChatBotResult, rhs: ChatBotResult) -> Bool {
        return lhs.bot == rhs.bot && lhs.responses == rhs.responses
    }
}
