//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import UIKit
import PromiseKit
import Photos

@objc
public class OnboardingPermissionsViewController: OnboardingBaseViewController {

    override public func loadView() {
        super.loadView()

        view.backgroundColor = Theme.backgroundColor
        view.layoutMargins = .zero

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("NAVIGATION_ITEM_SKIP_BUTTON", comment: "A button to skip a view."),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(skipWasPressed))

        //let titleLabel = self.titleLabel(text: NSLocalizedString("ONBOARDING_PERMISSIONS_TITLE", comment: "Title of the 'onboarding permissions' view."))
        let headerView = RaCustomHeaderView()
        
        let titleLabel = UILabel()
        titleLabel.font = UIFont.ows_regularFont(withSize: 17)
        let attribStr = NSMutableAttributedString(string:"OfficeApp benötigt einen Zugriff zu Ihren Kontakten, Kamera und Fotos, um zu kommunizieren, Benachrichtungen zu erhalten und sichere Anrufe zu tätigen.")
        attribStr.addAttribute(.font, value: UIFont.ows_boldFont(withSize: 17), range: NSRange(location: 0, length: 9))
        
        titleLabel.attributedText = attribStr
        titleLabel.numberOfLines = 5
       
        
        titleLabel.accessibilityIdentifier = "onboarding.permissions." + "titleLabel"

        //let explanationLabel = self.explanationLabel(explanationText: NSLocalizedString("ONBOARDING_PERMISSIONS_EXPLANATION",
        //                                                                          comment: "Explanation in the 'onboarding permissions' view."))
        //explanationLabel.accessibilityIdentifier = "onboarding.permissions." + "explanationLabel"

        let giveAccessButton = RaGradientButton()
        giveAccessButton.setTitle("Berechtigungen gewähren", for: .normal)
        giveAccessButton.addTarget(self, action: #selector(giveAccessPressed), for: .touchUpInside)
//        let giveAccessButton = self.button(title: NSLocalizedString("ONBOARDING_PERMISSIONS_ENABLE_PERMISSIONS_BUTTON",
//                                                                    comment: "Label for the 'give access' button in the 'onboarding permissions' view."),
//                                           selector: #selector(giveAccessPressed))
//        giveAccessButton.accessibilityIdentifier = "onboarding.permissions." + "giveAccessButton"
//
//        let notNowButton = self.linkButton(title: NSLocalizedString("ONBOARDING_PERMISSIONS_NOT_NOW_BUTTON",
//                                                                    comment: "Label for the 'not now' button in the 'onboarding permissions' view."),
//                                           selector: #selector(notNowPressed))
//        notNowButton.accessibilityIdentifier = "onboarding.permissions." + "notNowButton"

        let logoView = UIView()
        let logoImageView = UIImageView(image: UIImage(named: "logoSignal"))
        logoView.addSubview(logoImageView)
         view.addSubview(headerView)
        logoImageView.autoSetDimension(.height, toSize: 40)
        logoImageView.autoSetDimension(.width, toSize: 40)
        logoImageView.autoPinEdge(.top, to: .top, of: logoView)
        logoImageView.autoPinEdge(.leading, to: .leading, of: logoView)
       
        
        let stackView = UIStackView(arrangedSubviews: [
            logoView,
            UIView.spacer(withHeight: 10),
            titleLabel,
            UIView.spacer(withHeight: 20),
            /*explanationLabel,*/
            /*UIView.vStretchingSpacer(),*/
            /*notNowButton,*/
            
            giveAccessButton
            ])
        
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalCentering
        stackView.layoutMargins = UIEdgeInsets(top: 32, left: 32, bottom: 32, right: 32)
        stackView.isLayoutMarginsRelativeArrangement = true
        view.addSubview(stackView)
        
        logoView.autoSetDimension(.height, toSize: 40)
       
        stackView.autoPinWidthToSuperview()
        stackView.autoPinEdge(.top, to: .bottom, of: headerView)
        
       stackView.autoSetDimension(.height, toSize: 300)
       // stackView.autoPin(toBottomLayoutGuideOf: self, withInset: 0)
        
        titleLabel.autoSetDimension(.height, toSize: 200)
        giveAccessButton.autoSetDimension(.height, toSize: 40)
        // Header View
       
        
        headerView.autoPinWidth(toWidthOf: self.view)
        //headerView.autoPin(toTopLayoutGuideOf: self, withInset: 0)
        //headerView.topAnchor.constraint(equalTo: self.view.topAnchor)
        headerView.autoPinEdge(.top, to: .top, of: self.view!)
        headerView.autoSetDimension(.height, toSize: 80)
        
       
        
    }

    // MARK: Request Access

    private func requestAccess() {
        Logger.info("")

        requestContactsAccess().then { _ in
            return PushRegistrationManager.shared.registerUserNotificationSettings()
        }.done { [weak self] in
            guard let self = self else {
                return
            }
            self.requestPhotoAndCameraAccess()
            
            }.retainUntilComplete()
    }

    private func requestContactsAccess() -> Promise<Void> {
        Logger.info("")

        let (promise, resolver) = Promise<Void>.pending()
        CNContactStore().requestAccess(for: CNEntityType.contacts) { (granted, error) -> Void in
            if granted {
                Logger.info("Granted.")
            } else {
                Logger.error("Error: \(String(describing: error)).")
            }
            // Always fulfill.
            resolver.fulfill(())
        }
        return promise
    }

     // MARK: - Events

    @objc func skipWasPressed() {
        Logger.info("")

        onboardingController.onboardingPermissionsWasSkipped(viewController: self)
    }

    @objc func giveAccessPressed() {
        Logger.info("")

        requestAccess()
    }

    @objc func notNowPressed() {
        Logger.info("")

        onboardingController.onboardingPermissionsWasSkipped(viewController: self)
    }
    
    @objc func requestPhotoAndCameraAccess() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                //access granted
            } else {
                
            }
            //Photos
            let photos = PHPhotoLibrary.authorizationStatus()
            if photos == .notDetermined {
                PHPhotoLibrary.requestAuthorization({status in
                    if status == .authorized{
                        
                    } else {}
                    DispatchQueue.main.async {
                        self.onboardingController.onboardingPermissionsDidComplete(viewController: self)
                    }
                })
            }
            else {
                DispatchQueue.main.async {
                    self.onboardingController.onboardingPermissionsDidComplete(viewController: self)
                }
            }
        }
    }
}
