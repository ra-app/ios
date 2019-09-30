//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import UIKit
import PromiseKit

private protocol OnboardingCodeViewTextFieldDelegate {
    func textFieldDidDeletePrevious()
}

// MARK: -

// Editing a code should feel seamless, as even though
// the UITextField only lets you edit a single digit at
// a time.  For deletes to work properly, we need to
// detect delete events that would affect the _previous_
// digit.
private class OnboardingCodeViewTextField: UITextField {

    fileprivate var codeDelegate: OnboardingCodeViewTextFieldDelegate?

    override func deleteBackward() {
        var isDeletePrevious = false
        if let selectedTextRange = selectedTextRange {
            let cursorPosition = offset(from: beginningOfDocument, to: selectedTextRange.start)
            if cursorPosition == 0 {
                isDeletePrevious = true
            }
        }

        super.deleteBackward()

        if isDeletePrevious {
            codeDelegate?.textFieldDidDeletePrevious()
        }
    }

}

// MARK: -

protocol OnboardingCodeViewDelegate {
    func codeViewDidChange()
}

// MARK: -

// The OnboardingCodeView is a special "verification code"
// editor that should feel like editing a single piece
// of text (ala UITextField) even though the individual
// digits of the code are visually separated.
//
// We use a separate UILabel for each digit, and move
// around a single UITextfield to let the user edit the
// last/next digit.
private class OnboardingCodeView: UIView {

    var delegate: OnboardingCodeViewDelegate?

    public init() {
        super.init(frame: .zero)

        createSubviews()

        updateViewState()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let digitCount = 6
    private var digitLabels = [UILabel]()
    private var digitStrokes = [UIView]()

    // We use a single text field to edit the "current" digit.
    // The "current" digit is usually the "last"
    fileprivate let textfield = OnboardingCodeViewTextField()
    private var currentDigitIndex = 0
    private var textfieldConstraints = [NSLayoutConstraint]()

    // The current complete text - the "model" for this view.
    private var digitText = ""

    var isComplete: Bool {
        return digitText.count == digitCount
    }
    var verificationCode: String {
        return digitText
    }

    private func createSubviews() {
        textfield.textAlignment = .left
        textfield.delegate = self
        textfield.keyboardType = .numberPad
        textfield.textColor = /*Theme.primaryColor*/ UIColor(hexFromString: "#005AF5")
        textfield.font = UIFont.ows_dynamicTypeLargeTitle1Clamped
        textfield.codeDelegate = self

        var digitViews = [UIView]()
        (0..<digitCount).forEach { (_) in
            let (digitView, digitLabel, digitStroke) = makeCellView(text: "", hasStroke: true)

            digitLabels.append(digitLabel)
            digitStrokes.append(digitStroke)
            digitViews.append(digitView)
        }

        let (hyphenView, _, _) = makeCellView(text: "-", hasStroke: false)

        digitViews.insert(hyphenView, at: 3)

        let stackView = UIStackView(arrangedSubviews: digitViews)
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        addSubview(stackView)
        stackView.autoPinHeightToSuperview()
        stackView.autoHCenterInSuperview()

        self.addSubview(textfield)
    }

    private func makeCellView(text: String, hasStroke: Bool) -> (UIView, UILabel, UIView) {
        let digitView = UIView()

        let digitLabel = UILabel()
        digitLabel.text = text
        digitLabel.font = UIFont.ows_dynamicTypeLargeTitle1Clamped
        digitLabel.textColor = /*Theme.primaryColor*/UIColor(hexFromString: "#005AF5")
        digitLabel.textAlignment = .center
        digitView.addSubview(digitLabel)
        digitLabel.autoCenterInSuperview()

        let strokeColor = (hasStroke ? Theme.primaryColor : UIColor.clear)
        let strokeView = digitView.addBottomStroke(color: strokeColor, strokeWidth: 1)

        let vMargin: CGFloat = 4
        let cellHeight: CGFloat = digitLabel.font.lineHeight + vMargin * 2
        let cellWidth: CGFloat = cellHeight * 2 / 3
        digitView.autoSetDimensions(to: CGSize(width: cellWidth, height: cellHeight))

        return (digitView, digitLabel, strokeView)
    }

    private func digit(at index: Int) -> String {
        guard index < digitText.count else {
            return ""
        }
        return digitText.substring(from: index).substring(to: 1)
    }

    // Ensure that all labels are displaying the correct
    // digit (if any) and that the UITextField has replaced
    // the "current" digit.
    private func updateViewState() {
        currentDigitIndex = min(digitCount - 1,
                                digitText.count)

        (0..<digitCount).forEach { (index) in
            let digitLabel = digitLabels[index]
            digitLabel.text = digit(at: index)
            digitLabel.isHidden = index == currentDigitIndex
        }

        NSLayoutConstraint.deactivate(textfieldConstraints)
        textfieldConstraints.removeAll()

        let digitLabelToReplace = digitLabels[currentDigitIndex]
        textfield.text = digit(at: currentDigitIndex)
        textfieldConstraints.append(textfield.autoAlignAxis(.horizontal, toSameAxisOf: digitLabelToReplace))
        textfieldConstraints.append(textfield.autoAlignAxis(.vertical, toSameAxisOf: digitLabelToReplace))

        // Move cursor to end of text.
        let newPosition = textfield.endOfDocument
        textfield.selectedTextRange = textfield.textRange(from: newPosition, to: newPosition)
    }

    public override func becomeFirstResponder() -> Bool {
        return textfield.becomeFirstResponder()
    }

    func setHasError(_ hasError: Bool) {
        let backgroundColor = (hasError ? UIColor.ows_destructiveRed : /*Theme.primaryColor*/UIColor(red: 106/255.0, green: 208/255.0, blue: 159/255.0, alpha: 1))
        for digitStroke in digitStrokes {
            digitStroke.backgroundColor = backgroundColor
        }
    }

    fileprivate func set(verificationCode: String) {
        digitText = verificationCode

        updateViewState()

        self.delegate?.codeViewDidChange()
    }
}

// MARK: -

extension OnboardingCodeView: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString newString: String) -> Bool {
        var oldText = ""
        if let textFieldText = textField.text {
            oldText = textFieldText
        }
        let left = oldText.substring(to: range.location)
        let right = oldText.substring(from: range.location + range.length)
        let unfiltered = left + newString + right
        let characterSet = CharacterSet(charactersIn: "0123456789")
        let filtered = unfiltered.components(separatedBy: characterSet.inverted).joined()
        let filteredAndTrimmed = filtered.substring(to: 1)
        textField.text = filteredAndTrimmed

        digitText = digitText.substring(to: currentDigitIndex) + filteredAndTrimmed

        updateViewState()

        self.delegate?.codeViewDidChange()

        // Inform our caller that we took care of performing the change.
        
        return false
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.delegate?.codeViewDidChange()

        return false
    }
}

// MARK: -

extension OnboardingCodeView: OnboardingCodeViewTextFieldDelegate {
    public func textFieldDidDeletePrevious() {
        guard digitText.count > 0 else {
            return
        }
        digitText = digitText.substring(to: currentDigitIndex - 1)

        updateViewState()
    }
}

// MARK: -

@objc
public class OnboardingVerificationViewController: OnboardingBaseViewController {

    @IBOutlet var arrDigitLabel:[UILabel]!
    @IBOutlet var labelVerifyMobileNr:UILabel!
    @IBOutlet var headerView:UIView!
    
    private enum CodeState {
        case sent
        case readyForResend
        case resent
    }

    // MARK: -

    private var codeState = CodeState.sent

    private var titleLabel: UILabel!
    private var backLink: UIView?
    private let onboardingCodeView = OnboardingCodeView()
    private var codeStateLink: OWSFlatButton?
    private let errorLabel = UILabel()

    @objc
    public func hideBackLink() {
        backLink?.isHidden = true
    }

    override public func loadView() {
        super.loadView()

        view.backgroundColor = Theme.backgroundColor
        view.layoutMargins = .zero
       
        let headerView = self.getHeaderView()
        self.view.addSubview(headerView)
        
//        let titleLabel = self.titleLabel(text: "")
//        self.titleLabel = titleLabel
//        titleLabel.accessibilityIdentifier = "onboarding.verification." + "titleLabel"
//        titleLabel.setGradientForTitleView(gradientLayer: CAGradientLayer())
        let backLink = self.linkButton(title: /*NSLocalizedString("ONBOARDING_VERIFICATION_BACK_LINK",
                                                                comment: "Label for the link that lets users change their phone number in the onboarding views.")*/ "Mich stattdessen anrufen",
                                       selector: #selector(backLinkTapped))
        self.backLink = backLink
        backLink.accessibilityIdentifier = "onboarding.verification." + "backLink"

        onboardingCodeView.delegate = self

        errorLabel.text = NSLocalizedString("ONBOARDING_VERIFICATION_INVALID_CODE",
                                            comment: "Label indicating that the verification code is incorrect in the 'onboarding verification' view.")
        errorLabel.textColor = .ows_destructiveRed
        errorLabel.font = UIFont.ows_dynamicTypeBodyClamped.ows_mediumWeight()
        errorLabel.textAlignment = .center
        errorLabel.autoSetDimension(.height, toSize: errorLabel.font.lineHeight)
        errorLabel.accessibilityIdentifier = "onboarding.verification." + "errorLabel"

        // Wrap the error label in a row so that we can show/hide it without affecting view layout.
        let errorRow = UIView()
        errorRow.addSubview(errorLabel)
        errorLabel.autoPinEdgesToSuperviewEdges()

        let codeStateLink = self.linkButton(title: "",
                                             selector: #selector(resendCodeLinkTapped))
        self.view.addSubview(codeStateLink)
        codeStateLink.enableMultilineLabel()
        self.codeStateLink = codeStateLink
        codeStateLink.accessibilityIdentifier = "onboarding.verification." + "codeStateLink"

        self.view.addSubview(onboardingCodeView)
        onboardingCodeView.autoPinEdge(.top, to: .bottom, of: headerView, withOffset: 100)
        onboardingCodeView.autoSetDimension(.width, toSize: 240)
        onboardingCodeView.autoSetDimension(.height, toSize: 30)
        onboardingCodeView.autoHCenterInSuperview()
        
        codeStateLink.autoPinEdge(.top, to: .bottom, of: onboardingCodeView, withOffset: 50)
        codeStateLink.autoPinWidthToSuperview()
        codeStateLink.autoSetDimension(.height, toSize: 41)
        codeStateLink.autoHCenterInSuperview()
        
//        let topSpacer = UIView.vStretchingSpacer()
//        let bottomSpacer = UIView.vStretchingSpacer()

//        let stackView = UIStackView(arrangedSubviews: [
//            /*titleLabel,
//            UIView.spacer(withHeight: 12),*/
//            backLink,
//            topSpacer,
//            onboardingCodeView,
//            UIView.spacer(withHeight: 12),
//            errorRow,
//            bottomSpacer,
//            codeStateLink
//            ])
//        stackView.axis = .vertical
//        stackView.alignment = .fill
//        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
//        stackView.isLayoutMarginsRelativeArrangement = true
//        view.addSubview(stackView)
//        stackView.autoPinWidthToSuperview()
//        //stackView.autoPin(toTo)
//        stackView.autoPinEdge(.top, to: .bottom, of: headerView)
//
//        //stackView.autoPinEdge(toSuperviewEdge: .top)
//        //stackView.autoPin(toTopLayoutGuideOf: self, withInset: 0)
//        autoPinView(toBottomOfViewControllerOrKeyboard: stackView, avoidNotch: true)
//
//        // Ensure whitespace is balanced, so inputs are vertically centered.
//        topSpacer.autoMatch(.height, to: .height, of: bottomSpacer)

        startCodeCountdown()

        updateCodeState()

        setHasInvalidCode(false)
    }
    
    func getHeaderView()->UIView {
        let headerView = RaCustomHeaderView()
        self.view.addSubview(headerView)
        // headerView.backgroundColor = .blue
        //headerView.setGradientForTitleView(gradientLayer: CAGradientLayer())
        headerView.autoSetDimension(.height, toSize: 172)
        headerView.autoPinEdge(.top, to: .top, of: self.view)
        //headerView.autoPinTopToSuperviewMargin()
        headerView.autoPinWidthToSuperview()
        
        let gradient = CAGradientLayer()
        
        gradient.frame = headerView.bounds
        gradient.colors = [UIColor.white.cgColor, UIColor.black.cgColor]
        
        headerView.layer.insertSublayer(gradient, at: 0)
        
        self.titleLabel = UILabel()
         headerView.addSubview(self.titleLabel!)
        self.titleLabel.autoPinEdge(.top, to: .top, of: headerView, withOffset: 55)
        self.titleLabel.textAlignment = .center
        self.titleLabel.font = UIFont(name: "Poppins-Bold", size: 17)
        self.titleLabel.textColor = .white
        
        let subTitle1 = UILabel()
        headerView.addSubview(subTitle1)
        subTitle1.autoPinEdge(.top, to: .bottom, of: self.titleLabel, withOffset: 10.0)
        subTitle1.numberOfLines = 2
        subTitle1.font = UIFont(name: "Poppins", size: 14)
        subTitle1.textColor = .white
        subTitle1.text = "Bitte geben Sie den angegebenen\nVerifikationcode ein."         // ToDo Localization
        subTitle1.textAlignment = .center
        subTitle1.autoPinWidthToSuperview()
        
        let subTitle2 = UILabel()
        headerView.addSubview(subTitle2)
        subTitle2.autoPinEdge(.top, to: .bottom, of: subTitle1, withOffset: 10.0)
        subTitle2.font = UIFont(name: "Poppins", size: 14)
        subTitle2.textColor = .white
        
        
        subTitle2.textAlignment = .center
        subTitle2.autoPinWidthToSuperview()
        self.titleLabel.autoPinWidthToSuperview()
        
        let underlineAttribute = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue]
        let underlineAttributedString = NSAttributedString(string: "Falsche Telefonnummer?" , attributes: underlineAttribute)   // ToDo Localization
        subTitle2.attributedText = underlineAttributedString
        subTitle2.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(backLinkTapped))
        subTitle2.addGestureRecognizer(tap)
       
        return headerView
    }

     // MARK: - Code State

    private let countdownDuration: TimeInterval = 5//60
    private var codeCountdownTimer: Timer?
    private var codeCountdownStart: NSDate?

    deinit {
        codeCountdownTimer?.invalidate()
    }

    private func startCodeCountdown() {
        codeCountdownStart = NSDate()
        codeCountdownTimer = Timer.weakScheduledTimer(withTimeInterval: 0.25, target: self, selector: #selector(codeCountdownTimerFired), userInfo: nil, repeats: true)
    }

    @objc
    public func codeCountdownTimerFired() {
        guard let codeCountdownStart = codeCountdownStart else {
            owsFailDebug("Missing codeCountdownStart.")
            return
        }
        guard let codeCountdownTimer = codeCountdownTimer else {
            owsFailDebug("Missing codeCountdownTimer.")
            return
        }

        let countdownInterval = abs(codeCountdownStart.timeIntervalSinceNow)

        guard countdownInterval < countdownDuration else {
            // Countdown complete.
            codeCountdownTimer.invalidate()
            self.codeCountdownTimer = nil

            if codeState != .sent {
                owsFailDebug("Unexpected codeState: \(codeState)")
            }
            codeState = .readyForResend
            updateCodeState()
            return
        }

        // Update the "code state" UI to reflect the countdown.
        updateCodeState()
    }

    private func updateCodeState() {
        AssertIsOnMainThread()

        guard let codeCountdownStart = codeCountdownStart else {
            owsFailDebug("Missing codeCountdownStart.")
            return
        }
        guard let titleLabel = titleLabel else {
            owsFailDebug("Missing titleLabel.")
            return
        }
        guard let codeStateLink = codeStateLink else {
            owsFailDebug("Missing codeStateLink.")
            return
        }

        var e164PhoneNumber = ""
        if let phoneNumber = onboardingController.phoneNumber {
            e164PhoneNumber = phoneNumber.e164
        }
        let formattedPhoneNumber = PhoneNumber.bestEffortLocalizedPhoneNumber(withE164: e164PhoneNumber)

        titleLabel.text = formattedPhoneNumber + " verifizieren"         // ToDo Localization
        // Update titleLabel
//        switch codeState {
//        case .sent, .readyForResend:
//            titleLabel.text = String(format: NSLocalizedString("ONBOARDING_VERIFICATION_TITLE_DEFAULT_FORMAT",
//                                                               comment: "Format for the title of the 'onboarding verification' view. Embeds {{the user's phone number}}."),
//                                     formattedPhoneNumber)
//        case .resent:
//            titleLabel.text = String(format: NSLocalizedString("ONBOARDING_VERIFICATION_TITLE_RESENT_FORMAT",
//                                                               comment: "Format for the title of the 'onboarding verification' view after the verification code has been resent. Embeds {{the user's phone number}}."),
//                                     formattedPhoneNumber)
//        }

        // Update codeStateLink
        switch codeState {
        case .sent:
            let countdownInterval = abs(codeCountdownStart.timeIntervalSinceNow)
            let countdownRemaining = max(0, countdownDuration - countdownInterval)
            let formattedCountdown = OWSFormat.formatDurationSeconds(Int(round(countdownRemaining)))
            //let text = String(format: NSLocalizedString("ONBOARDING_VERIFICATION_CODE_COUNTDOWN_FORMAT",
            //                                            comment: "Format for the label of the 'sent code' label of the 'onboarding verification' view. Embeds {{the time until the code can be resent}}."),
            //                  formattedCountdown)
            let text = String(format:"Mich stattdessen anrufen\n(Verfügbar in %@)", formattedCountdown)             // ToDo Localization
            
            codeStateLink.setTitle(title: text, font: /*.ows_dynamicTypeBodyClamped*/UIFont(name: "Poppins", size: 14)!, titleColor: /*Theme.secondaryColor*/UIColor(hexFromString: "#005AF5"))
        case .readyForResend:
             let text = String(format:"Mich stattdessen anrufen")  // ToDo Localization
            codeStateLink.setTitle(title: text, font: /*.ows_dynamicTypeBodyClamped*/UIFont(name: "Poppins", size: 14)!, titleColor: /*Theme.secondaryColor*/UIColor(hexFromString: "#005AF5"))
//            codeStateLink.setTitle(title: NSLocalizedString("ONBOARDING_VERIFICATION_ORIGINAL_CODE_MISSING_LINK",
//                                                            comment: "Label for link that can be used when the original code did not arrive."),
//                                   font: .ows_dynamicTypeBodyClamped,
//                                   titleColor: .ows_materialBlue)
        case .resent:
            codeStateLink.setTitle(title: NSLocalizedString("ONBOARDING_VERIFICATION_RESENT_CODE_MISSING_LINK",
                                                            comment: "Label for link that can be used when the resent code did not arrive."),
                                   font: .ows_dynamicTypeBodyClamped,
                                   titleColor: .ows_materialBlue)
        }
    }

    // MARK: - View Lifecycle

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        _ = onboardingCodeView.becomeFirstResponder()
    }

    // MARK: - Events

    @objc func backLinkTapped() {
        Logger.info("")

        self.navigationController?.popViewController(animated: true)
    }

    @objc func resendCodeLinkTapped() {
        Logger.info("")

        switch codeState {
        case .sent:
            // Ignore taps until the countdown expires.
            break
        case .readyForResend, .resent:
            /*showResendActionSheet()*/
            self.onboardingController.requestVerification(fromViewController: self, isSMS: false)
        }
    }

    private func showResendActionSheet() {
        Logger.info("")

        let actionSheet = UIAlertController(title: NSLocalizedString("ONBOARDING_VERIFICATION_RESEND_CODE_ALERT_TITLE",
                                                                     comment: "Title for the 'resend code' alert in the 'onboarding verification' view."),
                                            message: NSLocalizedString("ONBOARDING_VERIFICATION_RESEND_CODE_ALERT_MESSAGE",
                                                                       comment: "Message for the 'resend code' alert in the 'onboarding verification' view."),
                                            preferredStyle: .actionSheet)

        if onboardingController.verificationRequestCount > 2 {
            actionSheet.addAction(UIAlertAction(title: NSLocalizedString("ONBOARDING_VERIFICATION_EMAIL_SIGNAL_SUPPORT",
                                                                         comment: "action sheet item shown after a number of failures to receive a verificaiton SMS during registration"),
                                                style: .default) { _ in
                                                    Pastelog.submitEmail(logUrl: nil)
            })
        }

        actionSheet.addAction(UIAlertAction(title: NSLocalizedString("ONBOARDING_VERIFICATION_RESEND_CODE_BY_SMS_BUTTON",
                                                                     comment: "Label for the 'resend code by SMS' button in the 'onboarding verification' view."),
                                            style: .default) { _ in
                                                self.onboardingController.requestVerification(fromViewController: self, isSMS: true)
        })
        actionSheet.addAction(UIAlertAction(title: NSLocalizedString("ONBOARDING_VERIFICATION_RESEND_CODE_BY_VOICE_BUTTON",
                                                                     comment: "Label for the 'resend code by voice' button in the 'onboarding verification' view."),
                                            style: .default) { _ in
                                                self.onboardingController.requestVerification(fromViewController: self, isSMS: false)
        })
        actionSheet.addAction(OWSAlerts.cancelAction)

        self.presentAlert(actionSheet)
    }

    private func tryToVerify() {
        Logger.info("")

        guard onboardingCodeView.isComplete else {
            self.setHasInvalidCode(false)
            return
        }

        setHasInvalidCode(false)

        onboardingController.update(verificationCode: onboardingCodeView.verificationCode)

        // Temporarily hide the "resend link" button during the verification attempt.
        codeStateLink?.layer.opacity = 0.05

        onboardingController.submitVerification(fromViewController: self, completion: { (outcome) in
            self.codeStateLink?.layer.opacity = 1

            if outcome == .invalidVerificationCode {
                self.setHasInvalidCode(true)
            }
        })
    }

    private func setHasInvalidCode(_ value: Bool) {
        onboardingCodeView.setHasError(value)
        errorLabel.isHidden = !value
    }

    @objc
    public func setVerificationCodeAndTryToVerify(_ verificationCode: String) {
        AssertIsOnMainThread()

        let filteredCode = verificationCode.digitsOnly
        guard filteredCode.count > 0 else {
            owsFailDebug("Invalid code: \(verificationCode)")
            return
        }

        onboardingCodeView.set(verificationCode: filteredCode)
    }
}

// MARK: -

extension OnboardingVerificationViewController: OnboardingCodeViewDelegate {
    public func codeViewDidChange() {
        AssertIsOnMainThread()

        setHasInvalidCode(false)

        tryToVerify()
    }
}
