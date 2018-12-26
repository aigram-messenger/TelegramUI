//
//  ChatBotsInputSuggestionsPane.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 21/12/2018.
//  Copyright © 2018 Telegram. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import Display
import Postbox
import TelegramCore
import SwiftSignalKit

final class ChatBotsInputSuggestionsPane: ChatMediaInputPane, UIScrollViewDelegate {
    override init() {
        super.init()
        let colors = [
            UIColor.green,
            UIColor.brown,
            UIColor.magenta,
            UIColor.blue
        ]
        let index = Int(arc4random_uniform(UInt32(colors.count)))
        self.backgroundColor = colors[index]
    }
}
