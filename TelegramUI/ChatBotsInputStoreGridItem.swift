//
//  ChatBotsInputStorePane.swift
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

final class ChatBotsInputStorePane: ChatMediaInputPane, UIScrollViewDelegate {
    override init() {
        super.init()
        self.backgroundColor = UIColor.yellow
    }
}
