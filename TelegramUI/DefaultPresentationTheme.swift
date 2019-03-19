import Foundation
import UIKit

private func makeDefaultPresentationTheme(accentColor: UIColor, day: Bool) -> PresentationTheme {
    let destructiveColor: UIColor = UIColor(rgb: 0xff3b30)
    let constructiveColor: UIColor = UIColor(rgb: 0x4cd964)
    let secretColor: UIColor = UIColor(rgb: 0x00B12C)
    
    let rootStatusBar = PresentationThemeRootNavigationStatusBar(
        style: .white
    )
    
    let rootTabBar = PresentationThemeRootTabBar(
        backgroundColor: UIColor(rgb: 0xf7f7f7),
        separatorColor: UIColor(rgb: 0xa3a3a3),
        iconColor: UIColor(rgb: 0xA1A1A1),
        selectedIconColor: accentColor,
        textColor: UIColor(rgb: 0xA1A1A1),
        selectedTextColor: accentColor,
        badgeBackgroundColor: UIColor(rgb: 0xff3b30),
        badgeStrokeColor: UIColor(rgb: 0xff3b30),
        badgeTextColor: .white
    )
    
    let rootNavigationBar = PresentationThemeRootNavigationBar(
        buttonColor: .white,
        disabledButtonColor: UIColor(rgb: 0xd0d0d0),
        primaryTextColor: .white,
        secondaryTextColor: UIColor(argb: 0xb3ffffff),
        controlColor: UIColor(rgb: 0x758B89),
        accentTextColor: .white,
        backgroundColor: UIColor(rgb: 0x37cdcc),
        separatorColor: UIColor(rgb: 0xd8d8d8),
        badgeBackgroundColor: UIColor(rgb: 0xff3b30),
        badgeStrokeColor: UIColor(rgb: 0xff3b30),
        badgeTextColor: .white
    )
    
    let activeNavigationSearchBar = PresentationThemeActiveNavigationSearchBar(
        backgroundColor: .white,
        accentColor: accentColor,
        inputFillColor: UIColor(rgb: 0xe9e9e9),
        inputTextColor: .black,
        inputPlaceholderTextColor: UIColor(rgb: 0x8A9190),
        inputIconColor: UIColor(rgb: 0x8A9190),
        inputClearButtonColor: UIColor(rgb: 0x737A79),
        separatorColor: UIColor(red: 0.6953125, green: 0.6953125, blue: 0.6953125, alpha: 1.0)
    )
    
    let rootController = PresentationThemeRootController(
        statusBar: rootStatusBar,
        tabBar: rootTabBar,
        navigationBar: rootNavigationBar,
        activeNavigationSearchBar: activeNavigationSearchBar
    )
    
    let switchColors = PresentationThemeSwitch(
        frameColor: UIColor(rgb: 0xe0e0e0),
        handleColor: UIColor(rgb: 0xffffff),
        contentColor: UIColor(rgb: 0x42d451)
    )
    
    let list = PresentationThemeList(
        blocksBackgroundColor: UIColor(rgb: 0xE9EFEF),
        plainBackgroundColor: .white,
        itemPrimaryTextColor: .black,
        itemSecondaryTextColor: UIColor(rgb: 0x8A9190),
        itemDisabledTextColor: UIColor(rgb: 0x8A9190),
        itemAccentColor: accentColor,
        secondItemAccentColor: .white,
        itemHighlightedColor: secretColor,
        itemDestructiveColor: destructiveColor,
        itemPlaceholderTextColor: UIColor(rgb: 0xBBC2C2),
        itemBlocksBackgroundColor: .white,
        itemHighlightedBackgroundColor: UIColor(rgb: 0xd9d9d9),
        itemBlocksSeparatorColor: UIColor(rgb: 0xBAC4C4),
        itemPlainSeparatorColor: UIColor(rgb: 0xBAC4C4),
        disclosureArrowColor: UIColor(rgb: 0xB5BBBA),
        sectionHeaderTextColor: UIColor(rgb: 0x646A6A),
        freeTextColor: UIColor(rgb: 0x646A6A),
        freeTextErrorColor: UIColor(rgb: 0xcf3030),
        freeTextSuccessColor: UIColor(rgb: 0x26972c),
        freeMonoIcon: UIColor(rgb: 0x737B7B),
        itemSwitchColors: switchColors,
        itemDisclosureActions: PresentationThemeItemDisclosureActions(
            neutral1: PresentationThemeItemDisclosureAction(fillColor: UIColor(rgb: 0x44CFC3), foregroundColor: .white),
            neutral2: PresentationThemeItemDisclosureAction(fillColor: UIColor(rgb: 0xf09a37), foregroundColor: .white),
            destructive: PresentationThemeItemDisclosureAction(fillColor: UIColor(rgb: 0xff3824), foregroundColor: .white),
            constructive: PresentationThemeItemDisclosureAction(fillColor: constructiveColor, foregroundColor: .white),
            accent: PresentationThemeItemDisclosureAction(fillColor: accentColor, foregroundColor: .white),
            warning: PresentationThemeItemDisclosureAction(fillColor: UIColor(rgb: 0xff9500), foregroundColor: .white)
        ),
        itemCheckColors: PresentationThemeCheck(
            strokeColor: UIColor(rgb: 0xBDC3C3),
            fillColor: accentColor,
            foregroundColor: .white
        ),
        controlSecondaryColor: UIColor(rgb: 0xdedede),
        freeInputField: PresentationInputFieldTheme(
            backgroundColor: UIColor(rgb: 0xCFD6D5),
            placeholderColor: UIColor(rgb: 0x909797),
            primaryColor: .black,
            controlColor: UIColor(rgb: 0x909797)
        ),
        mediaPlaceholderColor: UIColor(rgb: 0xe4e4e4)
    )
    
    let chatList = PresentationThemeChatList(
        backgroundColor: .white,
        itemSeparatorColor: UIColor(rgb: 0xBAC4C4),
        itemBackgroundColor: .white,
        pinnedItemBackgroundColor: UIColor(rgb: 0xf7f7f7),
        itemHighlightedBackgroundColor: UIColor(rgb: 0xd9d9d9),
        titleColor: .black,
        secretTitleColor: secretColor,
        dateTextColor: UIColor(rgb: 0x8A9190),
        authorNameColor: .black,
        messageTextColor: UIColor(rgb: 0x8A9190),
        messageDraftTextColor: UIColor(rgb: 0xdd4b39),
        checkmarkColor: UIColor(rgb: 0x21c004),
        pendingIndicatorColor: UIColor(rgb: 0x8A9190),
        muteIconColor: UIColor(rgb: 0x989E9E),
        unreadBadgeActiveBackgroundColor: accentColor,
        unreadBadgeActiveTextColor: .white,
        unreadBadgeInactiveBackgroundColor: UIColor(rgb: 0xA9B1B0),
        unreadBadgeInactiveTextColor: .white,
        pinnedBadgeColor: UIColor(rgb: 0xA9B1B0),
        pinnedSearchBarColor: UIColor(rgb: 0xe5e5e5),
        regularSearchBarColor: UIColor(rgb: 0xe9e9e9),
        sectionHeaderFillColor: UIColor(rgb: 0xf7f7f7),
        sectionHeaderTextColor: UIColor(rgb: 0x8A9190),
        searchBarKeyboardColor: .light,
        verifiedIconFillColor: accentColor,
        verifiedIconForegroundColor: .white,
        secretIconColor: secretColor
    )
    
    let chatListDay = PresentationThemeChatList(
        backgroundColor: .white,
        itemSeparatorColor: UIColor(rgb: 0xBAC4C4),
        itemBackgroundColor: .white,
        pinnedItemBackgroundColor: UIColor(rgb: 0xf7f7f7),
        itemHighlightedBackgroundColor: UIColor(rgb: 0xd9d9d9),
        titleColor: .black,
        secretTitleColor: secretColor,
        dateTextColor: UIColor(rgb: 0x8A9190),
        authorNameColor: .black,
        messageTextColor: UIColor(rgb: 0x8A9190),
        messageDraftTextColor: UIColor(rgb: 0xdd4b39),
        checkmarkColor: accentColor,
        pendingIndicatorColor: UIColor(rgb: 0x8A9190),
        muteIconColor: UIColor(rgb: 0x989E9E),
        unreadBadgeActiveBackgroundColor: accentColor,
        unreadBadgeActiveTextColor: .white,
        unreadBadgeInactiveBackgroundColor: UIColor(rgb: 0xA9B1B0),
        unreadBadgeInactiveTextColor: .white,
        pinnedBadgeColor: UIColor(rgb: 0x919897),
        pinnedSearchBarColor: UIColor(rgb: 0xe5e5e5),
        regularSearchBarColor: UIColor(rgb: 0xe9e9e9),
        sectionHeaderFillColor: UIColor(rgb: 0xf7f7f7),
        sectionHeaderTextColor: UIColor(rgb: 0x8A9190),
        searchBarKeyboardColor: .light,
        verifiedIconFillColor: accentColor,
        verifiedIconForegroundColor: .white,
        secretIconColor: secretColor
    )
    
    let bubble = PresentationThemeChatBubble(
        incoming: PresentationThemeBubbleColor(withWallpaper: PresentationThemeBubbleColorComponents(fill: UIColor(rgb: 0xffffff), highlightedFill: UIColor(rgb: 0xCFF1EE), stroke: UIColor(rgb: 0x7BC4BE, alpha: 0.5)), withoutWallpaper: PresentationThemeBubbleColorComponents(fill: UIColor(rgb: 0xffffff), highlightedFill: UIColor(rgb: 0xCFF1EE), stroke: UIColor(rgb: 0x7BC4BE, alpha: 0.5))),
        outgoing: PresentationThemeBubbleColor(withWallpaper: PresentationThemeBubbleColorComponents(fill: UIColor(rgb: 0xE1FFC7), highlightedFill: UIColor(rgb: 0xc8ffa6), stroke: UIColor(rgb: 0x7BC4BE, alpha: 0.5)), withoutWallpaper: PresentationThemeBubbleColorComponents(fill: UIColor(rgb: 0xE1FFC7), highlightedFill: UIColor(rgb: 0xc8ffa6), stroke: UIColor(rgb: 0x7BC4BE, alpha: 0.5))),
        freeform: PresentationThemeBubbleColor(withWallpaper: PresentationThemeBubbleColorComponents(fill: UIColor(rgb: 0xffffff), highlightedFill: UIColor(rgb: 0xCFF1EE), stroke: UIColor(rgb: 0x7BC4BE, alpha: 0.5)), withoutWallpaper: PresentationThemeBubbleColorComponents(fill: UIColor(rgb: 0xffffff), highlightedFill: UIColor(rgb: 0xCFF1EE), stroke: UIColor(rgb: 0x7BC4BE, alpha: 0.5))),
        incomingPrimaryTextColor: UIColor(rgb: 0x000000),
        incomingSecondaryTextColor: UIColor(rgb: 0x525252, alpha: 0.6),
        incomingLinkTextColor: UIColor(rgb: 0x008B80),
        incomingLinkHighlightColor: accentColor.withAlphaComponent(0.3),
        outgoingPrimaryTextColor: UIColor(rgb: 0x000000),
        outgoingSecondaryTextColor: UIColor(rgb: 0x008c09, alpha: 0.8),
        outgoingLinkTextColor: UIColor(rgb: 0x008B80),
        outgoingLinkHighlightColor: accentColor.withAlphaComponent(0.3),
        infoPrimaryTextColor: UIColor(rgb: 0x000000),
        infoLinkTextColor: UIColor(rgb: 0x008B80),
        incomingAccentTextColor: UIColor(rgb: 0x00C6B6),
        outgoingAccentTextColor: UIColor(rgb: 0x00a700),
        incomingAccentControlColor: UIColor(rgb: 0x00C6B6),
        outgoingAccentControlColor: UIColor(rgb: 0x3FC33B),
        incomingMediaActiveControlColor: UIColor(rgb: 0x00C6B6),
        outgoingMediaActiveControlColor: UIColor(rgb: 0x3FC33B),
        incomingMediaInactiveControlColor: UIColor(rgb: 0xcacaca),
        outgoingMediaInactiveControlColor: UIColor(rgb: 0x93D987),
        outgoingCheckColor: UIColor(rgb: 0x19C700),
        incomingPendingActivityColor: UIColor(rgb: 0x525252, alpha: 0.6),
        outgoingPendingActivityColor: UIColor(rgb: 0x42b649),
        mediaDateAndStatusFillColor: UIColor(white: 0.0, alpha: 0.5),
        mediaDateAndStatusTextColor: .white,
        incomingFileTitleColor: UIColor(rgb: 0x09CCBC),
        outgoingFileTitleColor: UIColor(rgb: 0x3faa3c),
        incomingFileDescriptionColor: UIColor(rgb: 0x999999),
        outgoingFileDescriptionColor: UIColor(rgb: 0x6fb26a),
        incomingFileDurationColor: UIColor(rgb: 0x525252, alpha: 0.6),
        outgoingFileDurationColor: UIColor(rgb: 0x008c09, alpha: 0.8),
        shareButtonFillColor: UIColor(rgb: 0x68807E, alpha: 0.45),
        shareButtonStrokeColor: .clear,
        shareButtonForegroundColor: .white,
        mediaOverlayControlBackgroundColor: UIColor(white: 0.0, alpha: 0.6),
        mediaOverlayControlForegroundColor: UIColor(white: 1.0, alpha: 1.0),
        actionButtonsIncomingFillColor: UIColor(rgb: 0x4D7774, alpha: 0.35),
        actionButtonsIncomingStrokeColor: .clear,
        actionButtonsIncomingTextColor: .white,
        actionButtonsOutgoingFillColor: UIColor(rgb: 0x4D7774, alpha: 0.35),
        actionButtonsOutgoingStrokeColor: .clear,
        actionButtonsOutgoingTextColor: .white,
        selectionControlBorderColor: UIColor(rgb: 0xBDC3C3),
        selectionControlFillColor: accentColor,
        selectionControlForegroundColor: .white,
        mediaHighlightOverlayColor: UIColor(white: 1.0, alpha: 0.6),
        deliveryFailedFillColor: destructiveColor,
        deliveryFailedForegroundColor: .white,
        incomingMediaPlaceholderColor: UIColor(rgb: 0xE4EDED),
        outgoingMediaPlaceholderColor: UIColor(rgb: 0xd2f2b6)
    )
    
    let bubbleDay = PresentationThemeChatBubble(
        incoming: PresentationThemeBubbleColor(withWallpaper: PresentationThemeBubbleColorComponents(fill: UIColor(rgb: 0xffffff), highlightedFill: UIColor(rgb: 0xDADADE), stroke: UIColor(rgb: 0xffffff)), withoutWallpaper: PresentationThemeBubbleColorComponents(fill: UIColor(rgb: 0xECF1F1), highlightedFill: UIColor(rgb: 0xDADADE), stroke: UIColor(rgb: 0xECF1F1))),
        outgoing: PresentationThemeBubbleColor(withWallpaper: PresentationThemeBubbleColorComponents(fill: accentColor, highlightedFill: accentColor.withMultipliedBrightnessBy(0.7), stroke: accentColor), withoutWallpaper: PresentationThemeBubbleColorComponents(fill: accentColor, highlightedFill: accentColor.withMultipliedBrightnessBy(0.7), stroke: accentColor)),
        freeform: PresentationThemeBubbleColor(withWallpaper: PresentationThemeBubbleColorComponents(fill: UIColor(rgb: 0xE4E7E7), highlightedFill: UIColor(rgb: 0xDADADE), stroke: UIColor(rgb: 0xE4E7E7)), withoutWallpaper: PresentationThemeBubbleColorComponents(fill: UIColor(rgb: 0xE4E7E7), highlightedFill: UIColor(rgb: 0xDADADE), stroke: UIColor(rgb: 0xE4E7E7))),
        incomingPrimaryTextColor: UIColor(rgb: 0x000000),
        incomingSecondaryTextColor: UIColor(rgb: 0x525252, alpha: 0.6),
        incomingLinkTextColor: UIColor(rgb: 0x008B80),
        incomingLinkHighlightColor: accentColor.withAlphaComponent(0.3),
        outgoingPrimaryTextColor: UIColor(rgb: 0xffffff),
        outgoingSecondaryTextColor: UIColor(rgb: 0xffffff, alpha: 0.6),
        outgoingLinkTextColor: UIColor(rgb: 0xffffff),
        outgoingLinkHighlightColor: UIColor(rgb: 0xffffff, alpha: 0.3),
        infoPrimaryTextColor: UIColor(rgb: 0x000000),
        infoLinkTextColor: UIColor(rgb: 0x008B80),
        incomingAccentTextColor: accentColor,
        outgoingAccentTextColor: UIColor(rgb: 0xffffff),
        incomingAccentControlColor: accentColor,
        outgoingAccentControlColor: UIColor(rgb: 0xffffff),
        incomingMediaActiveControlColor: accentColor,
        outgoingMediaActiveControlColor: UIColor(rgb: 0xffffff, alpha: 1.0),
        incomingMediaInactiveControlColor: UIColor(rgb: 0xcacaca),
        outgoingMediaInactiveControlColor: UIColor(rgb: 0xffffff, alpha: 0.6),
        outgoingCheckColor: UIColor(rgb: 0xffffff, alpha: 0.6),
        incomingPendingActivityColor: UIColor(rgb: 0x525252, alpha: 0.6),
        outgoingPendingActivityColor: UIColor(rgb: 0xffffff, alpha: 0.7),
        mediaDateAndStatusFillColor: UIColor(rgb: 0x000000, alpha: 0.5),
        mediaDateAndStatusTextColor: .white,
        incomingFileTitleColor: UIColor(rgb: 0x09CCBC),
        outgoingFileTitleColor: UIColor(rgb: 0xffffff),
        incomingFileDescriptionColor: UIColor(rgb: 0x999999),
        outgoingFileDescriptionColor: UIColor(rgb: 0xffffff, alpha: 0.7),
        incomingFileDurationColor: UIColor(rgb: 0x525252, alpha: 0.6),
        outgoingFileDurationColor: UIColor(rgb: 0xffffff, alpha: 0.7),
        shareButtonFillColor: UIColor(rgb: 0xffffff, alpha: 0.8),
        shareButtonStrokeColor: UIColor(rgb: 0xE4E7E7),
        shareButtonForegroundColor: accentColor,
        mediaOverlayControlBackgroundColor: UIColor(rgb: 0x000000, alpha: 0.6),
        mediaOverlayControlForegroundColor: UIColor(rgb: 0xffffff, alpha: 1.0),
        actionButtonsIncomingFillColor: UIColor(rgb: 0xffffff, alpha: 0.5),
        actionButtonsIncomingStrokeColor: UIColor(rgb: 0x2CDBCC),
        actionButtonsIncomingTextColor: UIColor(rgb: 0x2CDBCC),
        actionButtonsOutgoingFillColor: UIColor(rgb: 0xffffff, alpha: 0.5),
        actionButtonsOutgoingStrokeColor: UIColor(rgb: 0x2CDBCC),
        actionButtonsOutgoingTextColor: UIColor(rgb: 0x2CDBCC),
        selectionControlBorderColor: UIColor(rgb: 0xBDC3C3),
        selectionControlFillColor: accentColor,
        selectionControlForegroundColor: .white,
        mediaHighlightOverlayColor: UIColor(rgb: 0xffffff, alpha: 0.6),
        deliveryFailedFillColor: destructiveColor,
        deliveryFailedForegroundColor: .white,
        incomingMediaPlaceholderColor: UIColor(rgb: 0xffffff).withMultipliedBrightnessBy(0.95),
        outgoingMediaPlaceholderColor: accentColor.withMultipliedBrightnessBy(0.95)
    )
    
    let serviceMessage = PresentationThemeServiceMessage(
        serviceMessageFillColor: UIColor(rgb: 0x68807E, alpha: 0.45),
        serviceMessagePrimaryTextColor: .white,
        serviceMessageLinkHighlightColor: UIColor(rgb: 0x68807E, alpha: 0.25),
        unreadBarFillColor: UIColor(white: 1.0, alpha: 0.9),
        unreadBarStrokeColor: UIColor(white: 0.0, alpha: 0.2),
        unreadBarTextColor: UIColor(rgb: 0x818786),
        dateFillStaticColor: UIColor(rgb: 0x68807E, alpha: 0.45),
        dateFillFloatingColor: UIColor(rgb: 0x899E9C, alpha: 0.5),
        dateTextColor: .white
    )
    
    let serviceMessageDay = PresentationThemeServiceMessage(
        serviceMessageFillColor: UIColor(rgb: 0xffffff, alpha: 0.8),
        serviceMessagePrimaryTextColor: UIColor(rgb: 0x8E9494),
        serviceMessageLinkHighlightColor: UIColor(rgb: 0x68807E, alpha: 0.25),
        unreadBarFillColor: UIColor(rgb: 0xffffff),
        unreadBarStrokeColor: UIColor(rgb: 0xffffff),
        unreadBarTextColor: UIColor(rgb: 0x8E9494),
        dateFillStaticColor: UIColor(rgb: 0xffffff, alpha: 0.8),
        dateFillFloatingColor: UIColor(rgb: 0xffffff, alpha: 0.8),
        dateTextColor: UIColor(rgb: 0x8E9494)
    )
    
    let inputPanelMediaRecordingControl = PresentationThemeChatInputPanelMediaRecordingControl(
        buttonColor: accentColor,
        micLevelColor: accentColor.withAlphaComponent(0.2),
        activeIconColor: .white,
        panelControlFillColor: UIColor(rgb: 0xf7f7f7),
        panelControlStrokeColor: UIColor(rgb: 0xb2b2b2),
        panelControlContentPrimaryColor: UIColor(rgb: 0x889392),
        panelControlContentAccentColor: accentColor
    )
    
    let inputPanel = PresentationThemeChatInputPanel(
        panelBackgroundColor: UIColor(rgb: 0xf7f7f7),
        panelStrokeColor: UIColor(rgb: 0xb2b2b2),
        panelControlAccentColor: accentColor,
        panelIconColor: .white,
        panelControlColor: UIColor(rgb: 0x7B8F8D),
        panelControlDisabledColor: UIColor(rgb: 0x727b87, alpha: 0.5),
        panelControlDestructiveColor: UIColor(rgb: 0xff3b30),
        inputBackgroundColor: UIColor(rgb: 0xffffff),
        inputStrokeColor: UIColor(rgb: 0xD6DDDC),
        inputPlaceholderColor: UIColor(rgb: 0xBCBFBF),
        inputTextColor: .black,
        inputControlColor: UIColor(rgb: 0x94A3A2),
        actionControlFillColor: accentColor,
        actionControlForegroundColor: .white,
        primaryTextColor: .black,
        secondaryTextColor: UIColor(rgb: 0x8A9190),
        mediaRecordingDotColor: UIColor(rgb: 0xed2521),
        keyboardColor: .light,
        mediaRecordingControl: inputPanelMediaRecordingControl
    )
    
    let inputMediaPanel = PresentationThemeInputMediaPanel(
        panelSerapatorColor: UIColor(rgb: 0xACB6B5),
        panelIconColor: UIColor(rgb: 0x7B8F8D),
        panelHighlightedIconBackgroundColor: UIColor(rgb: 0x7B8F8D, alpha: 0.2),
        stickersBackgroundColor: UIColor(rgb: 0xE2EAEA),
        stickersSectionTextColor: UIColor(rgb: 0x8EA1A0),
        stickersSearchBackgroundColor: UIColor(rgb: 0x8D9E9C),
        stickersSearchPlaceholderColor: UIColor(rgb: 0x8A9190),
        stickersSearchPrimaryColor: .black,
        stickersSearchControlColor: UIColor(rgb: 0x8A9190),
        gifsBackgroundColor: .white
    )
    
    let inputButtonPanel = PresentationThemeInputButtonPanel(
        panelSerapatorColor: UIColor(rgb: 0xACB6B5),
        panelBackgroundColor: UIColor(rgb: 0xD6E2E1),
        buttonFillColor: .white,
        buttonStrokeColor: UIColor(rgb: 0xC5CACA),
        buttonHighlightedFillColor: UIColor(rgb: 0xA4BBB9),
        buttonHighlightedStrokeColor: UIColor(rgb: 0xC5CACA),
        buttonTextColor: .black
    )
    
    let historyNavigation = PresentationThemeChatHistoryNavigation(
        fillColor: .white,
        strokeColor: UIColor(rgb: 0x000000, alpha: 0.15),
        foregroundColor: UIColor(rgb: 0x838787),
        badgeBackgroundColor: accentColor,
        badgeStrokeColor: accentColor,
        badgeTextColor: .white
    )
    
    let chat = PresentationThemeChat(
        bubble: bubble,
        serviceMessage: serviceMessage,
        inputPanel: inputPanel,
        inputMediaPanel: inputMediaPanel,
        inputButtonPanel: inputButtonPanel,
        historyNavigation: historyNavigation
    )
    
    let chatDay = PresentationThemeChat(
        bubble: bubbleDay,
        serviceMessage: serviceMessageDay,
        inputPanel: inputPanel,
        inputMediaPanel: inputMediaPanel,
        inputButtonPanel: inputButtonPanel,
        historyNavigation: historyNavigation
    )
    
    let actionSheet = PresentationThemeActionSheet(
        dimColor: UIColor(white: 0.0, alpha: 0.4),
        backgroundType: .light,
        opaqueItemBackgroundColor: .white,
        itemBackgroundColor: UIColor(white: 1.0, alpha: 0.8),
        opaqueItemHighlightedBackgroundColor: UIColor(white: 0.9, alpha: 1.0),
        itemHighlightedBackgroundColor: UIColor(white: 0.9, alpha: 0.7),
        standardActionTextColor: accentColor,
        opaqueItemSeparatorColor: UIColor(white: 0.9, alpha: 1.0),
        destructiveActionTextColor: destructiveColor,
        disabledActionTextColor: UIColor(rgb: 0x4d4d4d),
        primaryTextColor: .black,
        secondaryTextColor: UIColor(rgb: 0x5e5e5e),
        controlAccentColor: accentColor,
        inputBackgroundColor: UIColor(rgb: 0xe9e9e9),
        inputPlaceholderColor: UIColor(rgb: 0x777D7C),
        inputTextColor: .black,
        inputClearButtonColor: UIColor(rgb: 0x737A79),
        checkContentColor: .white
    )
    
    let inAppNotification = PresentationThemeInAppNotification(
        fillColor: .white,
        primaryTextColor: .black,
        expandedNotification: PresentationThemeExpandedNotification(
            backgroundType: .light,
            navigationBar: PresentationThemeExpandedNotificationNavigationBar(
                backgroundColor: .white,
                primaryTextColor: .black,
                controlColor: UIColor(rgb: 0x6B7E7C),
                separatorColor: UIColor(red: 0.6953125, green: 0.6953125, blue: 0.6953125, alpha: 1.0)
            )
        )
    )
    
    return PresentationTheme(
        name: .builtin(day ? .day : .dayClassic),
        overallDarkAppearance: false,
        allowsCustomWallpapers: true,
        rootController: rootController,
        list: list,
        chatList: day ? chatListDay : chatList,
        chat: day ? chatDay : chat,
        actionSheet: actionSheet,
        inAppNotification: inAppNotification
    )
}

public let defaultPresentationTheme = makeDefaultPresentationTheme(accentColor: UIColor(rgb: 0x00C6B6), day: false)

let defaultDayAccentColor: Int32 = 0x00C6B6

func makeDefaultDayPresentationTheme(accentColor: Int32?) -> PresentationTheme {
    let color: UIColor
    if let accentColor = accentColor {
        color = UIColor(rgb: UInt32(bitPattern: accentColor))
    } else {
        color = UIColor(rgb: UInt32(bitPattern: defaultDayAccentColor))
    }
    return makeDefaultPresentationTheme(accentColor: color, day: true)
}
