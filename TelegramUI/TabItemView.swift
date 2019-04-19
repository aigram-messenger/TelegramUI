//
//  TabItemView.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 04/04/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import UIKit

final class TabItemView: UIControl {

    typealias TapActionHandler = (TabItem) -> Void

    private struct Constants {
        static let markSideLength: CGFloat = 6
    }

    // MARK: Views & layers

    private var markLayer: CAShapeLayer?

    private lazy var image: UIImage = item.image.withRenderingMode(.alwaysTemplate)
    private let imageView: UIImageView = with(.init()) {
        $0.contentMode = .center
    }

    let item: TabItem
    var onTapAction: TapActionHandler?

    // MARK: - State

    var isMarked: Bool = false {
        didSet {
            isMarked
                ? addMarkLayer()
                : removeMarkLayer()
        }
    }

    override var isSelected: Bool {
        didSet {
            updateColour()
        }
    }

    var theme: PresentationTheme {
        didSet {
            apply(theme: theme)
        }
    }

    // MARK: - Lifecycles

    init(item: TabItem, theme: PresentationTheme) {
        self.item = item
        self.theme = theme

        super.init(frame: .zero)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Actions

    @objc
    private func tap() {
        onTapAction?(item)
    }

    // MARK: - Update appearance

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        with(imageView) {
            addSubview($0)
            $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            $0.image = image
        }

        apply(theme: theme)

        addTarget(self, action: #selector(tap), for: .touchUpInside)
    }

    private func apply(theme: PresentationTheme) {
        updateColour()
    }

    private func updateColour() {
        let barTheme = theme.rootController.tabBar
        markLayer?.fillColor = barTheme.selectedIconColor.cgColor
        if isSelected {
            imageView.tintColor = barTheme.selectedIconColor
        } else {
            imageView.tintColor = barTheme.iconColor
        }
    }

    // MARK: - Mark layer

    private func addMarkLayer() {
        guard markLayer == nil else { return }
        markLayer = with(CAShapeLayer()) {
            let sideLength = Constants.markSideLength
            let markOffset = sideLength * 2

            let size = CGSize(width: sideLength, height: sideLength)
            let origin = CGPoint(x: bounds.width * 0.5 + markOffset, y: bounds.height * 0.5 - markOffset)
            $0.path = .init(
                roundedRect: .init(origin: .zero, size: size),
                cornerWidth: sideLength * 0.5,
                cornerHeight: sideLength * 0.5,
                transform: nil
            )

            $0.frame = .init(origin: origin, size: size)

            layer.addSublayer($0)
        }
        updateColour()
    }

    private func removeMarkLayer() {
        markLayer?.removeFromSuperlayer()
        markLayer = nil
    }

}

// MARK: - Item images

private extension TabItem {
    var image: UIImage {
        let name: String
        switch self {
            case .general: name = "ChatGroupingTabs/AllChats"
//            case .unread: name = "ChatGroupingTabs/UnreadChats"
            case .peers: name = "ChatGroupingTabs/PersonalChats"
            case .groups: name = "ChatGroupingTabs/GroupChats"
            case .channels: name = "ChatGroupingTabs/Channels"
            case .bots: name = "ChatGroupingTabs/Bots"
            case .folders: name = "ChatGroupingTabs/CustomGrouping"
        }

        return UIImage(bundleImageName: name) ?? UIImage()
    }
}
