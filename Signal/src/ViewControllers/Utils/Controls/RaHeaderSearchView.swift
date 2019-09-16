
import UIKit

class RaHeaderSearchView: UIView {

    @IBOutlet var view:UIView!
    @IBOutlet var btnExit: UIButton!
    //@IBOutlet var tfSearch: UITextField!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = UIScreen.main.bounds
        Bundle.main.loadNibNamed("HeaderSearchView", owner: self, options: nil)
        self.view.frame = UIScreen.main.bounds
        self.addSubview(self.view)
        self.view.layer.borderWidth = 0.5
        self.view.layer.cornerRadius = 15
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
