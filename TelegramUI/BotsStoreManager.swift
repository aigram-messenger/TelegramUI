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
    
    private let prefix = "com.olcorporation.olai.bot."
    private var productsRequest: SKProductsRequest?
    private(set) public var products: [SKProduct] = []
    private var productsCompletion: (() -> Void)?
    
    private override init() {
        super.init()
    }
    
    public func loadProducts(for bots: [ChatBot], _ completion: @escaping () -> Void) {
        self.productsCompletion = { [weak self] in
            completion()
            self?.productsCompletion = nil
        }
        
        var productIds: [String] = []
        bots.forEach {
            productIds.append(prefix + $0.name)
        }
        let request = SKProductsRequest(productIdentifiers: Set(productIds))
        request.delegate = self
        self.productsRequest = request
        request.start()
    }
    
    public func buyBot(_ bot: ChatBot, completion: @escaping (Bool) -> Void) {
        if isBotBought(bot) {
            completion(true)
            return
        }
        DispatchQueue.global().async {
            let copied = ChatBotsManager.shared.copyBot(bot)
            DispatchQueue.main.async {
                completion(copied)
            }
        }
    }
    
    public func isBotBought(_ bot: ChatBot) -> Bool {
        return bot.isLocal
    }
    
    public func botPriceString(bot: ChatBot) -> String {
        let id = prefix + bot.name
        guard let product = self.products.first(where: { $0.productIdentifier == id }) else { return "ПОЛУЧИТЬ" }
        let formatter = NumberFormatter()
        formatter.formatterBehavior = .default
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        let price = formatter.string(from: product.price) ?? "ПОЛУЧИТЬ"
        return price
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

extension BotsStoreManager: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.products = response.products
        self.productsCompletion?()
    }
}
