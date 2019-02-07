//
//  ChatBotDescriptionRateView.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 05/02/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit
import Display

class ChatBotDescriptionRateView: UIView {
    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.font = Font.medium(14)
        view.textColor = UIColor(argb: 0xff8a8a8a)
        view.text = "Оцените бота"

        addSubview(view)

        return view
    }()

    private lazy var rateView: STRatingControl = {
        let view = STRatingControl()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        view.filledStarImage = UIImage(bundleImageName: "Chat/Input/Media/raitingFilledStar")
        view.emptyStarImage = UIImage(bundleImageName: "Chat/Input/Media/raitingEmptyStar")
        view.spacing = 0

        addSubview(view)

        return view
    }()

    private let rateBlock: (Int) -> Void

    override var frame: CGRect {
        didSet { updateFrame() }
    }

    init(rate: @escaping (Int) -> Void) {
        self.rateBlock = rate

        super.init(frame: .zero)

        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = UIColor(argb: 0xfff5f6f7)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = size
        size.height = 97

        return size
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateFrame()
    }

    private func updateFrame() {
        titleLabel.sizeToFit()
        var rect = CGRect()
        rect.size.width = bounds.width
        rect.size.height = titleLabel.frame.height
        rect.origin.x = 16
        rect.origin.y = 13
        titleLabel.frame = rect

        let freeHeight = bounds.height - titleLabel.frame.maxY
        rect.size.height = 36
        rect.origin.y = titleLabel.frame.maxY + 0.5 * (freeHeight - rect.height)
        rateView.frame = rect
        rect.size.width = CGFloat(rateView.width)
        rect.origin.x = 0.5 * (bounds.width - rect.size.width)
        rateView.frame = rect
        rateView.layoutSubviews()
    }
}

extension ChatBotDescriptionRateView: STRatingControlDelegate {
    func didSelectRating(_ control: STRatingControl, rating: Int) {
        self.rateBlock(rating)
    }
}
