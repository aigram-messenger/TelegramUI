import Foundation
import Display
import AsyncDisplayKit
import Postbox
import TelegramCore
import SwiftSignalKit

import TelegramUIPrivateModule
import LegacyComponents

final class AuthorizationSequenceSplashController: ViewController {
    private var controllerNode: AuthorizationSequenceSplashControllerNode {
        return self.displayNode as! AuthorizationSequenceSplashControllerNode
    }
    
    private let postbox: Postbox
    private let network: Network
    private let theme: AuthorizationTheme
    
    private let controller: RMIntroViewController
    
    var nextPressed: ((PresentationStrings?) -> Void)?
    
    private let suggestedLocalization = Promise<SuggestedLocalizationInfo?>()
    private let activateLocalizationDisposable = MetaDisposable()
    
    init(postbox: Postbox, network: Network, theme: AuthorizationTheme) {
        self.postbox = postbox
        self.network = network
        self.theme = theme
        
        self.suggestedLocalization.set(.single(nil)
        |> then(currentlySuggestedLocalization(network: network, extractKeys: ["Login.ContinueWithLocalization"])))
        let suggestedLocalization = self.suggestedLocalization
        
        let localizationSignal = SSignal(generator: { subscriber in
            let disposable = suggestedLocalization.get().start(next: { localization in
                guard let localization = localization else {
                    return
                }
                
                var continueWithLanguageString: String = "Continue"
                for entry in localization.extractedEntries {
                    switch entry {
                        case let .string(key, value):
                            if key == "Login.ContinueWithLocalization" {
                                continueWithLanguageString = value
                            }
                        default:
                            break
                    }
                }
                
                if let available = localization.availableLocalizations.first, available.languageCode != "en" {
                    let value = TGSuggestedLocalization(info: TGAvailableLocalization(title: available.title, localizedTitle: available.localizedTitle, code: available.languageCode), continueWithLanguageString: continueWithLanguageString, chooseLanguageString: "Choose Language", chooseLanguageOtherString: "Choose Language", englishLanguageNameString: "English")
                    subscriber?.putNext(value)
                }
            }, completed: {
                subscriber?.putCompletion()
            })
            
            return SBlockDisposable(block: {
                disposable.dispose()
            })
        })
        
        self.controller = RMIntroViewController(backroundColor: theme.backgroundColor, primaryColor: theme.primaryColor, buttonColor: theme.startButtonColor, accentColor: theme.accentColor, regularDotColor: theme.dotColor, highlightedDotColor: theme.primaryColor, suggestedLocalizationSignal: localizationSignal)
        
        super.init(navigationBarPresentationData: nil)
        
        self.supportedOrientations = ViewControllerSupportedOrientations(regularSize: .all, compactSize: .portrait)
        
        self.statusBar.statusBarStyle = theme.statusBarStyle
        
        self.controller.startMessaging = { [weak self] in
            self?.activateLocalization("en")
        }
        self.controller.startMessagingInAlternativeLanguage = { [weak self] code in
            if let code = code {
                self?.activateLocalization(code)
            }
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.activateLocalizationDisposable.dispose()
    }
    
    override public func loadDisplayNode() {
        self.displayNode = AuthorizationSequenceSplashControllerNode(theme: self.theme)
        self.displayNodeDidLoad()
    }
    
    private func addControllerIfNeeded() {
        if !controller.isViewLoaded {
            self.displayNode.view.addSubview(controller.view)
            controller.view.frame = self.displayNode.bounds;
            controller.viewDidAppear(false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.addControllerIfNeeded()
        controller.viewWillAppear(false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        controller.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        controller.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        controller.viewDidDisappear(animated)
    }
    
    override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        self.controllerNode.containerLayoutUpdated(layout, navigationBarHeight: 0.0, transition: transition)
        
        self.addControllerIfNeeded()
        if case .immediate = transition {
            self.controller.view.frame = CGRect(origin: CGPoint(), size: layout.size)
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.controller.view.frame = CGRect(origin: CGPoint(), size: layout.size)
            })
        }
    }
    
    private func activateLocalization(_ code: String) {
        let currentCode = self.postbox.transaction { transaction -> String in
            if let current = transaction.getPreferencesEntry(key: PreferencesKeys.localizationSettings) as? LocalizationSettings {
                return current.primaryComponent.languageCode
            } else {
                return "en"
            }
        }
        let suggestedCode = self.suggestedLocalization.get()
        |> map { localization -> String? in
            return localization?.availableLocalizations.first?.languageCode
        }
        
        let _ = (combineLatest(currentCode, suggestedCode) |> deliverOnMainQueue).start(next: { [weak self] currentCode, suggestedCode in
            guard let strongSelf = self else {
                return
            }
            
            if let suggestedCode = suggestedCode {
                _ = markSuggestedLocalizationAsSeenInteractively(postbox: strongSelf.postbox, languageCode: suggestedCode).start()
            }
            
            if currentCode == code {
                strongSelf.nextPressed?(nil)
                return
            }
            
            strongSelf.controller.isEnabled = false
            let postbox = strongSelf.postbox
            
            strongSelf.activateLocalizationDisposable.set(downloadAndApplyLocalization(postbox: postbox, network: strongSelf.network, languageCode: code).start(completed: {
                let _ = (postbox.transaction { transaction -> PresentationStrings? in
                    let localizationSettings: LocalizationSettings?
                    if let current = transaction.getPreferencesEntry(key: PreferencesKeys.localizationSettings) as? LocalizationSettings {
                        localizationSettings = current
                    } else {
                        localizationSettings = nil
                    }
                    let stringsValue: PresentationStrings
                    if let localizationSettings = localizationSettings {
                        stringsValue = PresentationStrings(primaryComponent: PresentationStringsComponent(languageCode: localizationSettings.primaryComponent.languageCode, localizedName: localizationSettings.primaryComponent.localizedName, pluralizationRulesCode: localizationSettings.primaryComponent.customPluralizationCode, dict: dictFromLocalization(localizationSettings.primaryComponent.localization)), secondaryComponent: localizationSettings.secondaryComponent.flatMap({ PresentationStringsComponent(languageCode: $0.languageCode, localizedName: $0.localizedName, pluralizationRulesCode: $0.customPluralizationCode, dict: dictFromLocalization($0.localization)) }))
                    } else {
                        stringsValue = defaultPresentationStrings
                    }
                    return stringsValue
                }
                |> deliverOnMainQueue).start(next: { strings in
                    self?.controller.isEnabled = true
                    self?.nextPressed?(strings)
                })
            }))
        })
    }
}
