//
//  Extensions.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 20/02/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation
import AiGramLib

extension ChatBot: Identifiable {
    public var stableId: ChatBotId { return self.name }
}
