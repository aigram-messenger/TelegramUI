//
//  ChatBotDetailsTagsView.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 05/02/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit
import Display

class ChatBotDetailsTagsView: UIView {
    private var tags: [String]
    private var spacing: CGSize
    
    private var labels: [UILabel] = []
    
    override var frame: CGRect {
        didSet {
            updateFrames()
        }
    }
    
    init(tags: [String], spacing: CGSize = .init(width: 8, height: 8)) {
        self.tags = tags
        self.spacing = spacing
        
        super.init(frame: .zero)
        
        self.clipsToBounds = true
        self.translatesAutoresizingMaskIntoConstraints = false
        self.initLabels()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var resultingWidth: CGFloat = 0
        var resultingHeight: CGFloat = 0
        var currentWidth: CGFloat = 0
        var numberOfLines: CGFloat = 1
        var currentHorizontalSpacing: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        for label in labels {
            let labelSize = self.sizeOfLabel(label, boundingTo: size)
            let tempWidth = currentWidth + currentHorizontalSpacing + labelSize.width
            maxHeight = max(maxHeight, labelSize.height)
            if tempWidth <= size.width {
                currentWidth = tempWidth
                currentHorizontalSpacing = spacing.width
            } else {
                currentHorizontalSpacing = 0
                currentWidth = labelSize.width
                numberOfLines += 1
                resultingWidth = max(currentWidth, resultingWidth)
            }
        }
        
        resultingHeight = numberOfLines * (spacing.height + maxHeight) - spacing.height
        resultingHeight = min(resultingHeight, size.height)
        return CGSize(width: resultingWidth, height: resultingHeight)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateFrames()
    }
    
    private func initLabels() {
        for tag in tags {
            let view = self.label(with: tag)
            labels.append(view)
        }
    }
    
    private func label(with tag: String) -> UILabel {
        let view = UILabel()
        view.text = tag
        view.backgroundColor = UIColor(argb: 0xfff5f6f7)
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        view.font = Font.regular(12)
        view.textColor = UIColor(argb: 0xff979797)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textAlignment = .center
        view.sizeToFit()
        
        addSubview(view)
        
        return view
    }
    
    private func updateFrames() {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var currentHorizontalSpacing: CGFloat = 0
        var currentVerticalSpacing: CGFloat = 0
        var tempMaxHeight: CGFloat = 0
        
        for label in labels {
            let labelSize = self.sizeOfLabel(label, boundingTo: bounds.size)
            tempMaxHeight = max(tempMaxHeight, labelSize.height)
            
            let temp = x + currentHorizontalSpacing + labelSize.width
            if temp <= bounds.size.width {
                var rect = CGRect(origin: .zero, size: labelSize)
                rect.origin.x = x + currentHorizontalSpacing
                rect.origin.y = y
                label.frame = rect
                
                x = temp
                currentHorizontalSpacing = spacing.width
            } else {
                currentHorizontalSpacing = 0
                currentVerticalSpacing = spacing.height
                x = 0
                y += tempMaxHeight + currentVerticalSpacing
                tempMaxHeight = 0
                
                var rect = CGRect(origin: .zero, size: labelSize)
                rect.origin.x = x + currentHorizontalSpacing
                rect.origin.y = y
                label.frame = rect
                x = labelSize.width
            }
        }
    }
    
    private func sizeOfLabel(_ label: UILabel, boundingTo size: CGSize) -> CGSize {
        var labelSize = label.sizeThatFits(size)
        labelSize.width += 8 + 8
        labelSize.height += 4 + 4
        
        return labelSize
    }
}
