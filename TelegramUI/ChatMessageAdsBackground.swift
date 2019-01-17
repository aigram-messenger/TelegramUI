//
//  ChatMessageAdsBackground.swift
//  TelegramUI
//
//  Created by Dmitry Shelonin on 17/01/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import Display

class ChatMessageAdsBackground: ASImageNode {
    private var currentHighlighted = false
    
    override init() {
        super.init()
        
        self.isLayerBacked = true
        self.displaysAsynchronously = false
        self.displayWithoutProcessing = true
    }
    
    func setType(highlighted: Bool, transition: ContainedViewLayoutTransition) {
        self.currentHighlighted = highlighted
        
        let image: UIImage?
        if highlighted {
            image = messageBubbleImage(incoming: false, fillColor: UIColor(argb: 0xffc2eefd), strokeColor: UIColor(argb: 0xffbacdd5), neighbors: .none)
        } else {
            image = messageBubbleImage(incoming: false, fillColor: UIColor(argb: 0xffc2eefd), strokeColor: UIColor(argb: 0xffbacdd5), neighbors: .none)
        }
        
        if transition.isAnimated {
            let tempLayer = CALayer()
            tempLayer.contents = self.layer.contents
            tempLayer.contentsScale = self.layer.contentsScale
            tempLayer.rasterizationScale = self.layer.rasterizationScale
            tempLayer.contentsGravity = self.layer.contentsGravity
            tempLayer.contentsCenter = self.layer.contentsCenter
            
            tempLayer.frame = self.bounds
            self.layer.addSublayer(tempLayer)
            transition.updateAlpha(layer: tempLayer, alpha: 0.0, completion: { [weak tempLayer] _ in
                tempLayer?.removeFromSuperlayer()
            })
        }
        
        self.image = image
    }
}
