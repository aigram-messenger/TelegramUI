//
//  FolderInfoTitlePanel.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 06/05/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation
import Display
import AsyncDisplayKit
import Postbox
import TelegramCore

private enum ChatInfoTitleButton {
    case addChat
    case edit
    case delete

    func title(_ strings: PresentationStrings) -> String {
        switch self {
            case .addChat: return strings.FolderTitlePanel_AddChat
            case .edit: return strings.FolderTitlePanel_Edit
            case .delete: return strings.FolderTitlePanel_DeleteFolder
        }
    }

    func icon(_ theme: PresentationTheme) -> UIImage? {
        switch self {
            case .addChat: return PresentationResourcesItemList.addPersonIcon(theme)
            case .edit: return PresentationResourcesRootController.navigationComposeIcon(theme)
            case .delete: return deleteIcon(theme)
        }
    }
}

private let folderButtons: [ChatInfoTitleButton] = [.addChat, .edit, .delete]

private let buttonFont = Font.regular(10.0)

struct FolderInfoTitlePanelInteration {
    var addMember: () -> Void
    var edit: () -> Void
    var delete: () -> Void
}

private final class ChatInfoTitlePanelButtonNode: HighlightableButtonNode {
    override init() {
        super.init()

        self.displaysAsynchronously = false
        self.imageNode.displayWithoutProcessing = true
        self.imageNode.displaysAsynchronously = false

        self.titleNode.displaysAsynchronously = false

        self.laysOutHorizontally = false
    }

    func setup(text: String, color: UIColor, icon: UIImage?) {
        self.setTitle(text, with: buttonFont, with: color, for: [])
        self.setImage(icon, for: [])
        if let icon = icon {
            self.contentSpacing = max(0.0, 32.0 - icon.size.height)
        }
    }
}

final class FolderTitlePanelNode: ASDisplayNode {
    var interfaceInteraction: FolderInfoTitlePanelInteration?

    private var theme: PresentationTheme?

    private let separatorNode: ASDisplayNode
    private var buttons: [(ChatInfoTitleButton, ChatInfoTitlePanelButtonNode)] = []

    override init() {
        self.separatorNode = ASDisplayNode()
        self.separatorNode.isLayerBacked = true

        super.init()

        self.addSubnode(self.separatorNode)
    }

    func updateLayout(width: CGFloat, leftInset: CGFloat, rightInset: CGFloat, transition: ContainedViewLayoutTransition, theme: PresentationTheme, strings: PresentationStrings) -> CGFloat {
        let themeUpdated = self.theme !== theme
        self.theme = theme

        let panelHeight: CGFloat = 55.0

        if themeUpdated {
            self.separatorNode.backgroundColor = theme.rootController.navigationBar.separatorColor
            self.backgroundColor = theme.rootController.navigationBar.backgroundColor
        }

        let updatedButtons = folderButtons
        var buttonsUpdated = false
        if self.buttons.count != updatedButtons.count {
            buttonsUpdated = true
        } else {
            for i in 0 ..< updatedButtons.count {
                if self.buttons[i].0 != updatedButtons[i] {
                    buttonsUpdated = true
                    break
                }
            }
        }

        if buttonsUpdated || themeUpdated {
            for (_, buttonNode) in self.buttons {
                buttonNode.removeFromSupernode()
            }
            self.buttons.removeAll()
            for button in updatedButtons {
                let buttonNode = ChatInfoTitlePanelButtonNode()
                buttonNode.laysOutHorizontally = false

                buttonNode.setup(text: button.title(strings), color: theme.rootController.navigationBar.accentTextColor, icon: button.icon(theme))

                buttonNode.addTarget(self, action: #selector(self.buttonPressed(_:)), forControlEvents: [.touchUpInside])
                self.addSubnode(buttonNode)
                self.buttons.append((button, buttonNode))
            }
        }

        if !self.buttons.isEmpty {
            let buttonWidth = floor((width - leftInset - rightInset) / CGFloat(self.buttons.count))
            var nextButtonOrigin: CGFloat = leftInset
            for (_, buttonNode) in self.buttons {
                buttonNode.frame = CGRect(origin: CGPoint(x: nextButtonOrigin, y: 0.0), size: CGSize(width: buttonWidth, height: panelHeight))
                nextButtonOrigin += buttonWidth
            }
        }

        transition.updateFrame(node: self.separatorNode, frame: CGRect(origin: CGPoint(x: 0.0, y: panelHeight - UIScreenPixel), size: CGSize(width: width, height: UIScreenPixel)))

        return panelHeight
    }

    @objc func buttonPressed(_ node: HighlightableButtonNode) {
        for (button, buttonNode) in self.buttons {
            if buttonNode === node {
                switch button {
                    case .addChat:
                        self.interfaceInteraction?.addMember()
                    case .edit:
                        self.interfaceInteraction?.edit()
                    case .delete:
                        self.interfaceInteraction?.delete()
                }
                break
            }
        }
    }
}

func deleteIcon(_ theme: PresentationTheme) -> UIImage? {
    return theme.image(-1, { theme in
        return generateTintedImage(image: UIImage(bundleImageName: "Folder Title Panel/TrashIcon"), color: theme.list.itemAccentColor)
    })
}
