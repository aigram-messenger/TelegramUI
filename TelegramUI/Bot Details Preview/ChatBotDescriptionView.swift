//
//  ChatBotDescriptionView.swift
//  fuckin shit
//
//  Created by Dmitry Shelonin on 24/01/2019.
//  Copyright © 2019 Dmitry Shelonin. All rights reserved.
//

import UIKit
import TelegramCore
import AiGramLib

class ChatBotDescriptionView: UIView {
    private lazy var containerView: UIView = {
        let view = UIView(frame: bounds)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self.headerView)
        view.addSubview(self.pointInfoView)
        view.addSubview(self.descriptionView)
        view.addSubview(self.metaInfoView)
        view.addSubview(self.rateView)
        return view
    }()

    private lazy var headerView: ChatBotDescriptionHeadView = {
        let view = ChatBotDescriptionHeadView(bot: self.bot)
        return view
    }()

    private lazy var pointInfoView: ChatBotDescriptionInfoPointView = {
        let details = ChatBotsManager.shared.botDetails(self.bot)
        let model = ChatBotInfoPointModel(numberOfFeedbacks: details.votings, rating: details.rating,
                                          numberOfInstalls: details.installation, numberOfThemes: details.theme,
                                          numberOfSentences: details.phrase)
        let view = ChatBotDescriptionInfoPointView(model: model, strings: self.strings)
        return view
    }()

    private lazy var descriptionView: ChatBotDescrptionFullDescriptionView = {
        let view = ChatBotDescrptionFullDescriptionView(bot: self.bot)
        return view
    }()

    private lazy var metaInfoView: ChatBotDescriptionMetaInfoView = {
        let view = ChatBotDescriptionMetaInfoView(bot: self.bot, strings: strings)
        return view
    }()

    private lazy var rateView: ChatBotDescriptionRateView = {
        let view = ChatBotDescriptionRateView(strings: self.strings) { [weak self] rate in
            guard let self = self else { return }
            ChatBotsManager.shared.rateBot(self.bot, rating: rate, userId: self.account.peerId.id) { [weak self] error in
                self?.rateCompletion?(error)
            }
            ChatBotsManager.shared.isBotRatedBy(self.account.peerId.id, bot: self.bot) { [weak self] result in
                var rating: Int?
                if let result = result {
                    rating = Int(result.rating)
                }
                self?.rateView.updateRateState(userRate: rating, shouldZero: false)
            }
        }
        view.updateRateState(userRate: nil)
        ChatBotsManager.shared.isBotRatedBy(self.account.peerId.id, bot: self.bot) { [weak self] result in
            var rating: Int?
            if let result = result {
                rating = Int(result.rating)
            }
            self?.rateView.updateRateState(userRate: rating, shouldZero: false)
        }

        return view
    }()
    
    private let spacing: CGFloat = 16
    
    //MARK: -
    
    private let bot: ChatBot
    private let account: Account
    private let strings: PresentationStrings
    private var rateCompletion: ((Error?) -> Void)?
    
    override var frame: CGRect {
        didSet {
            self.updateFrame()
        }
    }
    
    //MARK: -
    
    init(account: Account, bot: ChatBot, rateCompletion: ((Error?) -> Void)?) {
        self.bot = bot
        self.account = account
        self.strings = account.telegramApplicationContext.currentPresentationData.with { $0 }.strings
        
        super.init(frame: .zero)
        setup()
        
        self.rateCompletion = { [weak self] error in
            if error == nil, let self = self {
                let details = ChatBotsManager.shared.botDetails(self.bot)
                let model = ChatBotInfoPointModel(numberOfFeedbacks: details.votings, rating: details.rating,
                                                  numberOfInstalls: details.installation, numberOfThemes: details.theme,
                                                  numberOfSentences: details.phrase)
                self.pointInfoView.updateModel(model)
            }
            
            rateCompletion?(error)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    private func setup() {
        self.addSubview(self.containerView)
        
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var height: CGFloat = 0

        let headerSize = headerView.sizeThatFits(size)
        height += headerSize.height
        height += 63
        
        height += spacing
        let fullDescSize = descriptionView.sizeThatFits(size)
        height += fullDescSize.height
        
        height += spacing
        let metaSize = metaInfoView.sizeThatFits(size)
        height += metaSize.height
        height += spacing

        let rateSize = rateView.sizeThatFits(size)
        height += rateSize.height
        
        return CGSize(width: size.width, height: height)
    }
    
    private func updateFrame() {
        self.containerView.frame = bounds

        let headerSize = headerView.sizeThatFits(bounds.size)
        var rect = CGRect(x: 0, y: 0, width: bounds.width, height: headerSize.height)
        self.headerView.frame = rect
        
        rect.origin.y = rect.maxY
        rect.size.height = 63
        self.pointInfoView.frame = rect
        
        let fullDescSize = descriptionView.sizeThatFits(bounds.size)
        rect.origin.y = rect.maxY + spacing
        rect.size.height = fullDescSize.height
        self.descriptionView.frame = rect
        
        let metaSize = metaInfoView.sizeThatFits(bounds.size)
        rect.origin.y = rect.maxY + spacing
        rect.size.height = metaSize.height
        self.metaInfoView.frame = rect

        let rateSize = rateView.sizeThatFits(bounds.size)
        rect.origin.y = rect.maxY + spacing
        rect.size.height = rateSize.height
        self.rateView.frame = rect
    }
}
