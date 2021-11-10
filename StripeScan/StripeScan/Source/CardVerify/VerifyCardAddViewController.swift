import UIKit

/**
 This class is a first cut on providing verification on card add (i.e., Zero Fraud). Currently it includes a manual entry button
 and navigation to the `CardEntryViewController` where the user can complete the information that they add.
 */

@available(iOS 11.2, *)
@objc public protocol VerifyCardAddResult: AnyObject {
    func userDidCancelCardAdd(_ viewController: UIViewController)
    func userDidScanCardAdd(_ viewController: UIViewController, creditCard: CreditCard)
    func userDidPressManualCardAdd(_ viewController: UIViewController)
    @objc optional func fraudModelResultsVerifyCardAdd(viewController: UIViewController, creditCard: CreditCard, extraData: [String: Any])
}

@available(iOS 11.2, *)
@objc open class VerifyCardAddViewController: SimpleScanViewController {

    /// Set this variable to `false` to force the user to scan their card _without_ the option to enter all details manually
    @objc public static var enableManualCardEntry = true
    @objc public var enableManualEntry = enableManualCardEntry
    
    @objc public static var manualCardEntryButton = UIButton(type: .system)
    @objc public static var closeButton: UIButton?
    @objc public static var torchButton: UIButton?
    
    public var debugRetainCompletionLoopImages = false
    
    @objc public static var manualCardEntryText = "Enter card details manually".localize()
    
    @objc public weak var cardAddDelegate: VerifyCardAddResult?
    
    let userId: String?
    
    @objc public init(userId: String) {
        self.userId = userId
        super.init(nibName: nil, bundle: nil)
        if UIDevice.current.userInterfaceIdiom == .pad {
            // For the iPad you can use the full screen style but you have to select "requires full screen" in
            // the Info.plist to lock it in portrait mode. For iPads, we recommend using a formSheet, which
            // handles all orientations correctly.
            modalPresentationStyle = .formSheet
        } else {
            modalPresentationStyle = .fullScreen
        }
    }

    required public init?(coder: NSCoder) { fatalError("not supported") }
    
    override open func viewDidLoad() {
        let fraudData = CardVerifyFraudData()
        
        if debugRetainCompletionLoopImages {
            fraudData.debugRetainImages = true
        }
        
        scanEventsDelegate = fraudData

        super.viewDidLoad()
        setUpUxMainLoop()
    }
    
    func setUpUxMainLoop() {
        var uxAndOcrMainLoop = UxAndOcrMainLoop(stateMachine: CardVerifyStateMachine())
        
        if #available(iOS 13.0, *), scanPerformancePriority == .accurate {
            uxAndOcrMainLoop = UxAndOcrMainLoop(stateMachine: CardVerifyAccurateStateMachine(requiredLastFour: nil, requiredBin: nil, maxNameExpiryDurationSeconds: maxErrorCorrectionDuration))
        }
        
        uxAndOcrMainLoop.mainLoopDelegate = self
        mainLoop = uxAndOcrMainLoop
    }
    // MARK: -Set Up Manual Card Entry Button
    open override func setupUiComponents() {
        if let closeButton = VerifyCardAddViewController.closeButton {
            self.closeButton = closeButton
        }
        
        if let torchButton = VerifyCardAddViewController.torchButton {
            self.torchButton = torchButton
        }
        
        super.setupUiComponents()
        self.view.addSubview(VerifyCardAddViewController.manualCardEntryButton)
        VerifyCardAddViewController.manualCardEntryButton.translatesAutoresizingMaskIntoConstraints = false
        setUpManualCardEntryButtonUI()
    }
    
    open override func setupConstraints() {
        super.setupConstraints()
        setUpManualCardEntryButtonConstraints()
    }
    
    open func setUpManualCardEntryButtonUI() {
        VerifyCardAddViewController.manualCardEntryButton.isHidden = !enableManualEntry
        
        let text = VerifyCardAddViewController.manualCardEntryText
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(NSAttributedString.Key.underlineColor, value: UIColor.white, range: NSRange(location: 0, length: text.count))
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: text.count))
        attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: text.count))
        let font = VerifyCardAddViewController.manualCardEntryButton.titleLabel?.font.withSize(20) ?? UIFont.systemFont(ofSize: 20.0)
        attributedString.addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location: 0, length: text.count))
        
        VerifyCardAddViewController.manualCardEntryButton.setAttributedTitle(attributedString, for: .normal)
        VerifyCardAddViewController.manualCardEntryButton.titleLabel?.textColor = .white
        VerifyCardAddViewController.manualCardEntryButton.addTarget(self, action: #selector(manualCardEntryButtonPress), for: .touchUpInside)
    }
    
    open func setUpManualCardEntryButtonConstraints() {
        VerifyCardAddViewController.manualCardEntryButton.centerXAnchor.constraint(equalTo: enableCameraPermissionsButton.centerXAnchor).isActive = true
        VerifyCardAddViewController.manualCardEntryButton.centerYAnchor.constraint(equalTo: enableCameraPermissionsButton.centerYAnchor).isActive = true
    }
    
    // MARK: -Override some ScanBase functions
    override open func onScannedCard(number: String, expiryYear: String?, expiryMonth: String?, scannedImage: UIImage?) {
        let card = CreditCard(number: number)
        card.expiryYear = expiryYear
        card.expiryMonth = expiryMonth
        card.name = predictedName
        
        cardAddDelegate?.userDidScanCardAdd(self, creditCard: card)
        
        showFullScreenActivityIndicator()
        
        runFraudModels(cardNumber: number, expiryYear: expiryYear,
                       expiryMonth: expiryMonth) { (verificationResult) in
            
            self.cardAddDelegate?.fraudModelResultsVerifyCardAdd?(viewController: self, creditCard: card, extraData: verificationResult.extraData())
        }
    }
    
    override open func onCameraPermissionDenied(showedPrompt: Bool) {
        super.onCameraPermissionDenied(showedPrompt: showedPrompt)
        
        if enableManualEntry {
            enableCameraPermissionsButton.isHidden = true
        }
    }
        
    // MARK: -UI event handlers and other navigation functions
    @objc open override func cancelButtonPress() {
        cardAddDelegate?.userDidCancelCardAdd(self)
    }
    
    @objc open func manualCardEntryButtonPress() {
        cardAddDelegate?.userDidPressManualCardAdd(self)
    }
}