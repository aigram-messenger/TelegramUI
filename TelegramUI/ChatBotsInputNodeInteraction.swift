//
//  ChatBotsInputNodeInteraction.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 24/12/2018.
//  Copyright © 2018 Telegram. All rights reserved.
//

import Foundation
import Display
import AsyncDisplayKit
import Postbox
import TelegramCore
import SwiftSignalKit

final class ChatBotsInputNodeInteraction {
    let navigateToCollectionId: (ItemCollectionId) -> Void
    
    var highlightedItemCollectionId: ItemCollectionId?
    var appearanceTransition: CGFloat = 1.0
    
    init(navigateToCollectionId: @escaping (ItemCollectionId) -> Void) {
        self.navigateToCollectionId = navigateToCollectionId
    }
}
