import Foundation
import Display

private func generateStatusCheckImage(theme: PresentationTheme, single: Bool) -> UIImage? {
    return generateImage(CGSize(width: single ? 13.0 : 18.0, height: 13.0), rotatedContext: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        context.translateBy(x: 1.0, y: 2.0)
        context.setStrokeColor(theme.chatList.checkmarkColor.cgColor)
        context.setLineWidth(1.32)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        let _ = try? drawSvgPath(context, path: "M0,4.48 L3.59439858,7.93062264 L3.59439858,7.93062264 C3.63384129,7.96848764 3.69651158,7.96720866 3.73437658,7.92776595 C3.7346472,7.92748405 3.73491615,7.92720055 3.73518342,7.92691547 L11.1666667,0 S ")
        
        if !single {
            let _ = try? drawSvgPath(context, path: "M7.33333333,8 L14.8333333,0 S ")
        }
    })
}

private func generateBadgeBackgroundImage(theme: PresentationTheme, active: Bool, icon: UIImage? = nil) -> UIImage? {
    return generateImage(CGSize(width: 20.0, height: 20.0), contextGenerator: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        if active {
            context.setFillColor(theme.chatList.unreadBadgeActiveBackgroundColor.cgColor)
        } else {
            context.setFillColor(theme.chatList.unreadBadgeInactiveBackgroundColor.cgColor)
        }
        context.fillEllipse(in: CGRect(origin: CGPoint(), size: size))
        if let icon = icon, let cgImage = icon.cgImage {
            context.draw(cgImage, in: CGRect(origin: CGPoint(x: floor((size.width - icon.size.width) / 2.0), y: floor((size.height - icon.size.height) / 2.0)), size: icon.size))
        }
    })?.stretchableImage(withLeftCapWidth: 10, topCapHeight: 10)
}

struct PresentationResourcesChatList {
    static func pendingImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatListPending.rawValue, { theme in
            return generateImage(CGSize(width: 12.0, height: 14.0), rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                context.translateBy(x: 0.0, y: 1.0)
                context.setStrokeColor(theme.chatList.pendingIndicatorColor.cgColor)
                let lineWidth: CGFloat = 0.99
                context.setLineWidth(lineWidth)
                context.strokeEllipse(in: CGRect(origin: CGPoint(x: lineWidth / 2.0, y: lineWidth / 2.0), size: CGSize(width: 12.0 - lineWidth, height: 12.0 - lineWidth)))
                context.setLineCap(.round)
                let _ = try? drawSvgPath(context, path: "M6.01830142,3 L6.01830142,6.23251697 L4.5,7.81306587 S ")
            })
        })
    }
    
    static func singleCheckImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatListSingleCheck.rawValue, { theme in
            return generateStatusCheckImage(theme: theme, single: true)
        })
    }
    
    static func doubleCheckImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatListDoubleCheck.rawValue, { theme in
            return generateStatusCheckImage(theme: theme, single: false)
        })
    }
    
    static func lockTopLockedImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatListLockTopLockedImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat List/LockLockedTop"), color: theme.rootController.navigationBar.accentTextColor)
        })
    }
    
    static func lockBottomLockedImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatListLockBottomLockedImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat List/LockLockedBottom"), color: theme.rootController.navigationBar.accentTextColor)
        })
    }
    
    static func lockTopUnlockedImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatListLockTopUnlockedImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat List/LockUnlockedTop"), color: theme.rootController.navigationBar.primaryTextColor)
        })
    }
    
    static func lockBottomUnlockedImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatListLockBottomUnlockedImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat List/LockUnlockedBottom"), color: theme.rootController.navigationBar.primaryTextColor)
        })
    }
    
    static func badgeBackgroundActive(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatListBadgeBackgroundActive.rawValue, { theme in
            return generateBadgeBackgroundImage(theme: theme, active: true)
        })
    }
    
    static func badgeBackgroundInactive(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatListBadgeBackgroundInactive.rawValue, { theme in
            return generateBadgeBackgroundImage(theme: theme, active: false)
        })
    }
    
    static func badgeBackgroundMention(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatListBadgeBackgroundMention.rawValue, { theme in
            return generateBadgeBackgroundImage(theme: theme, active: true, icon: generateTintedImage(image: UIImage(bundleImageName: "Chat List/MentionBadgeIcon"), color: theme.chatList.unreadBadgeActiveTextColor))
        })
    }
    
    static func badgeBackgroundPinned(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatListBadgeBackgroundPinned.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat List/PeerPinnedIcon"), color: theme.chatList.pinnedBadgeColor)
        })
    }
    
    static func mutedIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatListMutedIcon.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat List/PeerMutedIcon"), color: theme.chatList.muteIconColor)
        })
    }
    
    static func verifiedIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatListVerifiedIcon.rawValue, { theme in
            return UIImage(bundleImageName: "Chat List/PeerVerifiedIcon")?.precomposed()
        })
    }
    
    static func secretIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatListSecretIcon.rawValue, { theme in
            return generateImage(CGSize(width: 9.0, height: 12.0), rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                context.setFillColor(theme.chatList.secretIconColor.cgColor)
                context.setStrokeColor(theme.chatList.secretIconColor.cgColor)
                context.setLineWidth(1.32)
                
                let _ = try? drawSvgPath(context, path: "M4.5,0.66 C3.11560623,0.66 1.99333333,1.78227289 1.99333333,3.16666667 L1.99333333,7.8047619 C1.99333333,9.18915568 3.11560623,10.3114286 4.5,10.3114286 C5.88439377,10.3114286 7.00666667,9.18915568 7.00666667,7.8047619 L7.00666667,3.16666667 C7.00666667,1.78227289 5.88439377,0.66 4.5,0.66 S ")
                let _ = try? drawSvgPath(context, path: "M1.32,5.48571429 L7.68,5.48571429 C8.40901587,5.48571429 9,6.07669842 9,6.80571429 L9,10.68 C9,11.4090159 8.40901587,12 7.68,12 L1.32,12 C0.59098413,12 8.92786951e-17,11.4090159 0,10.68 L2.22044605e-16,6.80571429 C1.3276591e-16,6.07669842 0.59098413,5.48571429 1.32,5.48571429 Z ")
            })
        })
    }
}