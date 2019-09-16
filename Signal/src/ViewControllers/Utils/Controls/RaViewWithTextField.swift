//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation
import UIKit

class RaViewWithTextField: UIView {
    @IBInspectable var offsetMultiplier: CGFloat = 0.95
    private var keyboardHeight = 0 as CGFloat
    private weak var activeTextField: UIView?
    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(self, selector: #selector(RaViewWithTextField.textDidBeginEditing),
                                               name: UITextField.textDidBeginEditingNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RaViewWithTextField.keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RaViewWithTextField.keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func textDidBeginEditing(_ notification: NSNotification) {
        self.activeTextField = notification.object as? UITextField
        self.activeTextField = (notification.object as? UITextField)?.superview
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let frameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            keyboardHeight = frameValue.cgRectValue.size.height
            if let textField = self.activeTextField {
                let offset = textField.frame.maxY < frame.maxY - keyboardHeight ? 0
                    : textField.frame.maxY - (frame.maxY - keyboardHeight) * offsetMultiplier
                self.setView(offset: offset)
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        self.setView(offset: 0)
    }
    
    func setView(offset: CGFloat) {
        UIView.animate(withDuration: 0.25) {
            self.bounds.origin.y = offset
        }
    }
}
