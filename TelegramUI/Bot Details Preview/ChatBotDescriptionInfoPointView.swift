//
//  ChatBotDescriptionInfoPointView.swift
//  fuckin shit
//
//  Created by Dmitry Shelonin on 24/01/2019.
//  Copyright © 2019 Dmitry Shelonin. All rights reserved.
//

import UIKit
import Display

struct ChatBotInfoPointModel {
    let numberOfFeedbacks: Int
    let rating: Float
    let numberOfInstalls: Int
    let numberOfThemes: Int
    let numberOfSentences: Int
}

private extension ChatBotDescriptionInfoPointView {
    class PointView: UIView {
        private var caption: String
        private var mark: String
        private var image: UIImage?

        private lazy var imageView: UIImageView = {
            let view = UIImageView(image: image)
            view.sizeToFit()
            var rect = view.frame
            rect.size.width = min(rect.size.width, 14)
            rect.size.height = min(rect.size.height, 14)
            addSubview(view)
            return view
        }()
        private lazy var markLabel: UILabel = {
            let view = UILabel()
            view.font = Font.medium(14)
            view.textColor = UIColor(argb: 0xff000000)
            view.text = mark
            view.textAlignment = (image ?? .init()).size.width == 0 ? .center : .left
            view.sizeToFit()
            addSubview(view)
            return view
        }()
        private lazy var captionLabel: UILabel = {
            let view = UILabel()
            view.font = Font.regular(12)
            view.textColor = UIColor(argb: 0xff8a8a8a)
            view.text = caption
            view.textAlignment = .center
            view.sizeToFit()
            addSubview(view)
            return view
        }()
        
        override var frame: CGRect {
            didSet {
                updateFrame()
            }
        }

        init(caption: String, mark: String, image: UIImage?) {
            self.caption = caption
            self.mark = mark
            self.image = image

            super.init(frame: .zero)
            translatesAutoresizingMaskIntoConstraints = false
            clipsToBounds = true
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            
            updateFrame()
        }
        
        private func updateFrame() {
            captionLabel.frame = CGRect(x: 4, y: bounds.midY + 2, width: bounds.width - 4 - 4, height: captionLabel.frame.height)
            var markX = bounds.midX
            var markWidth = 0.5 * bounds.width - 4
            
            if imageView.frame.width == 0 {
                markX = 4
                markWidth = bounds.width - 4 - 4
            }
            markLabel.frame = CGRect(x: markX + 2, y: bounds.midY - 2 - markLabel.frame.height, width: markWidth, height: markLabel.frame.height)
            var rect = imageView.frame
            rect.origin.x = markX - rect.width - 2
            rect.origin.y = markLabel.frame.midY - 0.5 * rect.height
            imageView.frame = rect
        }
    }
}

class ChatBotDescriptionInfoPointView: UIView {
    private var constraintsUpdated: Bool = false
    private let model: ChatBotInfoPointModel
    
    //MARK: -

    private lazy var ratingView: PointView = {
        var n = "\(model.numberOfFeedbacks)"
        if model.numberOfFeedbacks >= 1000 {
            n = "\(model.numberOfFeedbacks / 1000)к"
        } else if model.numberOfFeedbacks == 0 {
            n = "Нет"
        }
        var caption = "\(n) оценок"
        let view = PointView(caption: caption, mark: String(format: "%0.1f", model.rating), image: UIImage(bundleImageName: "Chat/Input/Media/raitingFilledStar"))
        addSubview(view)
        return view
    }()

    private lazy var installsView: PointView = {
        var mark = "\(model.numberOfInstalls)"
        if model.numberOfInstalls >= 1000 {
            mark = "\(model.numberOfInstalls / 1000)к"
        }
        let view = PointView(caption: "Установок", mark:mark, image: nil)
        addSubview(view)
        return view
    }()

    private lazy var themesView: PointView = {
        var mark = "\(model.numberOfThemes)"
        if model.numberOfThemes >= 1000 {
            mark = "\(model.numberOfThemes / 1000)к"
        }
        let view = PointView(caption: "Тем", mark:mark, image: nil)
        addSubview(view)
        return view
    }()

    private lazy var sentencesView: PointView = {
        var mark = "\(model.numberOfSentences)"
        if model.numberOfSentences >= 1000 {
            mark = "\(model.numberOfSentences / 1000)к"
        }
        let view = PointView(caption: "Фраз", mark:mark, image: nil)
        addSubview(view)
        return view
    }()
    
    //MARK: -

    init(model: ChatBotInfoPointModel) {
        self.model = model
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = UIColor(argb: 0xfff5f6f7)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var frame: CGRect {
        didSet {
            updateFrame()
        }
    }
    
    //MARK: -

    override func layoutSubviews() {
        super.layoutSubviews()

        updateFrame()
    }
    
    private func updateFrame() {
        var x: CGFloat = 8
        let width = bounds.width - 16
        let views = [
            self.ratingView,
            self.installsView,
            self.themesView,
            self.sentencesView
        ]
        let viewWidth = width / CGFloat(views.count)
        for view in views {
            let rect = CGRect(x: x, y: 0, width: viewWidth, height: bounds.height)
            view.frame = rect
            x += viewWidth
        }
    }
}
