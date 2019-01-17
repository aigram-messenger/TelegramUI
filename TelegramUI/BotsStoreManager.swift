//
//  BotsStoreManager.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 09/01/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation
import StoreKit

public final class BotsStoreManager: NSObject {
    public static let shared: BotsStoreManager = .init()
    
    private override init() {
        super.init()
    }
    
    public func buyBot(_ bot: ChatBot, completion: @escaping (Bool) -> Void) {
        if isBotBought(bot) {
            completion(true)
            return
        }
        DispatchQueue.global().async {
            let copied = ChatBotsManager.shared.copyBot(bot)
            completion(copied)
        }
    }
    
    public func isBotBought(_ bot: ChatBot) -> Bool {
        return bot.isLocal
    }
}

extension BotsStoreManager: SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                break
            case .purchased:
                break
            case .failed:
                break
            case .restored:
                break
            case .deferred:
                break
            }
        }
    }
}
