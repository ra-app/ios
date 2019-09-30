import UIKit

@objc class RaAlwaysPresentAsPopover : NSObject, UIPopoverPresentationControllerDelegate {
    typealias SelectionHandler = (Int) -> Void
    
    // `sharedInstance` because the delegate property is weak - the delegate instance needs to be retained.
    private static let sharedInstance = RaAlwaysPresentAsPopover()
    private let onSelect : SelectionHandler?
    
    private override init() {
        onSelect = nil
        super.init()
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    static func configurePresentation(forController controller : UIViewController) -> UIPopoverPresentationController {
        controller.modalPresentationStyle = .popover
        let presentationController = controller.presentationController as! UIPopoverPresentationController        
        presentationController.delegate = RaAlwaysPresentAsPopover.sharedInstance
        return presentationController
    }
    
    @objc static func showPopUpInViewController(viewCtrl:UIViewController, sourceView:UIView, valueArray:Array<String>, onSelect : SelectionHandler? = nil) {
        let controller = RaArrayChoiceTableViewController(valueArray) { (result) in
            //self.model.direction = direction
            onSelect!(0)
        }
        controller.preferredContentSize = CGSize(width: 300, height: 250)
        
        let presentationController = RaAlwaysPresentAsPopover.configurePresentation(forController: controller)
        presentationController.sourceView = sourceView
        presentationController.sourceRect = sourceView.bounds
        presentationController.permittedArrowDirections = [.down, .up]
        viewCtrl.present(controller, animated: true)
    }
}
