//
//  ChatBotDescriptionHeadView.swift
//  fuckin shit
//
//  Created by Dmitry Shelonin on 24/01/2019.
//  Copyright © 2019 Dmitry Shelonin. All rights reserved.
//

import UIKit
import Display

class ChatBotDescriptionHeadView: UIView {
    private var constraintsUpdated: Bool = false
    private let botName: String
    private let botType: String
    private let botImage: UIImage
    private let botTags: [String]
    
    //MARK: -

    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.image = botImage
        view.clipsToBounds = true
        view.contentMode = .scaleToFill
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
        return view
    }()
    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = Font.medium(16)
        view.textColor = UIColor(argb: 0xff000000)
        view.text = botName
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }()
    private lazy var typeLabel: UILabel = {
        let view = UILabel()
        view.font = Font.regular(12)
        view.textColor = UIColor(argb: 0xff8a8a8a)
        view.text = botType
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }()
    private lazy var tagsView: ChatBotDetailsTagsView = {
        let view = ChatBotDetailsTagsView(tags: self.botTags)
        addSubview(view)
        
        return view
    }()
    
    override var frame: CGRect {
        didSet {
            updateFrame()
        }
    }
    
    //MARK: -
    
    init(bot: ChatBot) {
        self.botName = bot.title
        self.botType = bot.type
        self.botImage = bot.preview
        self.botTags = bot.tags.map { $0.capitalized }.sorted(by: { $0 < $1 })
        
        super.init(frame: .zero)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var resultSize = size
        resultSize.height = 8 + 72 + 8
        let width = size.width - 8 - 72 - 16 - 8
        let tagsSize = tagsView.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        let titleSize = titleLabel.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        let typeSize = typeLabel.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        let tempHeight = 8 + titleSize.height + 1 + typeSize.height + 4 + tagsSize.height + 8

        resultSize.height = max(tempHeight, resultSize.height)

        return resultSize
    }

    //MARK: -
    
    private func updateFrame() {
        var rect = CGRect(x: 8, y: 8, width: 72, height: 72)
        imageView.frame = rect

        titleLabel.sizeToFit()
        rect.origin.x = rect.maxX + 16
        rect.size.width = bounds.width - 8 - imageView.frame.maxX - 16
        rect.size.height = titleLabel.frame.height
        titleLabel.frame = rect

        typeLabel.sizeToFit()
        rect.origin.y = rect.maxY + 1
        rect.size.height = typeLabel.frame.height
        typeLabel.frame = rect
        
        let height = bounds.height - 8 - typeLabel.frame.maxY - 4
        let width = bounds.width - 8 - imageView.frame.maxX
        let tagsSize = tagsView.sizeThatFits(CGSize(width: width, height: height))
        rect.size.width = width
        rect.size.height = tagsSize.height
        rect.origin.y = bounds.maxY - 8 - tagsSize.height
        rect.origin.y = max(typeLabel.frame.maxY + 4, rect.origin.y)
        tagsView.frame = rect
    }
}
