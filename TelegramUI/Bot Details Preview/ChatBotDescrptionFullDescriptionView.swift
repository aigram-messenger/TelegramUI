//
//  ChatBotDescrptionFullDescriptionView.swift
//  fuckin shit
//
//  Created by Dmitry Shelonin on 24/01/2019.
//  Copyright © 2019 Dmitry Shelonin. All rights reserved.
//

import UIKit
import Display
import AiGramLib

class ChatBotDescrptionFullDescriptionView: UIView {
    private let botDescription: String

    private lazy var label: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = Font.regular(12)
        view.textColor = UIColor(argb: 0xff8a8a8a)
        view.text = botDescription
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        
        return view
    }()
    
    override var frame: CGRect {
        didSet {
            updateFrame()
        }
    }
    
    init(bot: ChatBot) {
        self.botDescription = bot.fullDescription
        super.init(frame: .zero)
        
        self.clipsToBounds = true
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateFrame()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = size
        size.width = max(0, size.width - 16 - 16)
        size = label.sizeThatFits(size)
        size.width += 16 + 16
        return size
    }
    
    private func updateFrame() {
        label.frame = CGRect(x: 16, y: 0, width: bounds.width - 16 - 16, height: bounds.height)
    }
}
