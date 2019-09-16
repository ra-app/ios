
import UIKit

@IBDesignable @objc final class RaCustomHeaderView: UIView {

    var titleLabel:UILabel
    var subTitleLabel: UILabel
    var stackView:UIStackView
    
    
    override init(frame: CGRect) {
        self.titleLabel = UILabel()
        self.subTitleLabel = UILabel()
        self.stackView = UIStackView()
        
        super.init(frame: frame)
        configureView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.titleLabel = UILabel()
        self.subTitleLabel = UILabel()
        self.stackView = UIStackView()
       
        super.init(coder: aDecoder)
        
        self.configureView()
    }
    
    @IBInspectable public var titelText: String = "" {
        didSet {
            self.titleLabel.text = titelText
             self.configureView()
        }
    }
    
    @IBInspectable public var subTitleText: String = "" {
        didSet {
            self.subTitleLabel.text = subTitleText
             self.configureView()
        }
    }
    
    @IBInspectable public var stackViewLineSpace: Float = 5.0 {
        didSet {
            self.stackView.spacing = CGFloat(stackViewLineSpace)
             self.configureView()
        }
    }
    
    @IBInspectable public var subTitleNumberOfLines: Int = 2 {
        didSet {
            self.subTitleLabel.numberOfLines = subTitleNumberOfLines
            self.configureView()
        }
    }
    
    func configureView() {
        
        self.addSubview(self.stackView)
        self.stackView.distribution = .fill
        self.stackView.spacing = 5.0
        self.stackView.axis = .vertical
        
        self.stackView.addArrangedSubview(self.titleLabel)
        self.stackView.addArrangedSubview(self.subTitleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.font = UIFont(name: "Poppins-Bold", size: 17.0)
        subTitleLabel.font = UIFont(name: "Poppins", size: 14.0)
        titleLabel.textAlignment = .center
        subTitleLabel.textAlignment = .center
        subTitleLabel.numberOfLines = 2
        subTitleLabel.textColor = .white
        titleLabel.textColor = .white
        
        
        self.setGradientForTitleView(gradientLayer: CAGradientLayer())
    
        self.configureConstraints()
    }
    
    func configureConstraints() {
        //self.heightAnchor.constraint(equalToConstant: 152).isActive = true
        
        NSLayoutConstraint.activate(//[borderView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            //borderView.topAnchor.constraint(equalTo: self.topAnchor, constant: 7),
            [ /*stackView.heightAnchor.constraint(equalToConstant: 200),*/
              stackView.widthAnchor.constraint(equalTo:self.widthAnchor)/*,
              stackView.topAnchor.constraint(equalTo: self.topAnchor)*/,
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -15)])
    }
    
    override func prepareForInterfaceBuilder() {
        configureView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setGradientForTitleView(gradientLayer: CAGradientLayer())
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
