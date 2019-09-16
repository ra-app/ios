//
//  RaTextField.swift
//  Testing
//
//  Created by Lars Thode on 08.08.19.
//  Copyright © 2019 Jurasoft. All rights reserved.
//

import UIKit

@IBDesignable @objc final class RaTextField: UIView {
        @objc let titleLabel: UILabel
        @objc let textField: UITextField
        @objc let borderView: UIView
        
        
        init(title: String) {
            
            titleLabel = UILabel()
            textField = UITextField()
            borderView = UIView()
            self.titleLabel.text = " " + title + " "
            
            super.init(frame: .zero)
            
            configureView()
        }
        
        override init(frame: CGRect) {
            titleLabel = UILabel()
            textField = UITextField()
            borderView = UIView()
            
            super.init(frame: frame)
            configureView()
        }
    
    required init?(coder aDecoder: NSCoder) {
        titleLabel = UILabel()
        textField = UITextField()
        borderView = UIView()
        
      
        //self.titleLabel.text = " " + title + " "
        
        super.init(coder: aDecoder)
        configureView()
    }
  
    @IBInspectable public var title: String = "Title" {
        didSet {
            self.titleLabel.text = title
        }
    }
        
        func configureView() {
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            textField.translatesAutoresizingMaskIntoConstraints = false
            borderView.translatesAutoresizingMaskIntoConstraints = false
            
            addSubview(borderView)
            addSubview(textField)
            addSubview(titleLabel)
            self.backgroundColor = .clear
            
            titleLabel.font = UIFont.boldSystemFont(ofSize: 12)
            titleLabel.textColor = UIColor.gray
            titleLabel.backgroundColor = .clear
            
            //borderView.layer.cornerRadius = 5
            //borderView.layer.borderWidth = 0.5
            //borderView.layer.borderColor = UIColor.darkGray.cgColor
            borderView.layer.shadowOpacity = 0.0;
            borderView.backgroundColor = .darkGray
            
            configureConstraints()
    }
    
    func configureConstraints() {
        self.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        NSLayoutConstraint.activate(//[borderView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                                     //borderView.topAnchor.constraint(equalTo: self.topAnchor, constant: 7),
                                    [ borderView.heightAnchor.constraint(equalToConstant: 1),
                                     borderView.widthAnchor.constraint(equalTo:self.widthAnchor),
                                     borderView.bottomAnchor.constraint(equalTo: self.bottomAnchor)])
        
        NSLayoutConstraint.activate([textField.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
                                     textField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
                                     textField.widthAnchor.constraint(equalTo:self.widthAnchor, constant: -6),
                                     textField.bottomAnchor.constraint(equalTo: self.bottomAnchor)])
        
        NSLayoutConstraint.activate([titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
                                     titleLabel.topAnchor.constraint(equalTo: self.topAnchor),
                                     titleLabel.heightAnchor.constraint(equalToConstant: 15),
                                     /*titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor)*/])
        
    }
    
    override func prepareForInterfaceBuilder() {
        configureView()
    }
}


