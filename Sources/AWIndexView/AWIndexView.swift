//
//  AWIndexView.swift
//  AWIndexViewExample
//
//  Created by Adam Wienconek on 25.02.2019.
//  Copyright © 2019 Adam Wienconek. All rights reserved.
//

import UIKit

public final class AWIndexView: UIView {
    
    // MARK: Public properties
    
    /// Delegate object that responds to events described in `AWIndexViewDelegate`.
    ///
    /// Extend your object to implement the protocol or assign any `UITableView` to this property as it implements necessary methods.
    public weak var delegate: AWIndexViewDelegate?
    
    /// If set to `true` gesture will scroll to first row/item of the section.
    ///
    /// Default value is `false`, which allows for more control over scrolling position.
    public var scrollsToSectionTop = false
    
    public var shouldHideWhenNotActive = true {
        didSet {
            contentView.alpha = shouldHideWhenNotActive ? 0 : 1
        }
    }
    
    /// Value indicating whether index view is currently being dragged.
    public private(set) var isDragging = false
    
    /// Value indicating which edge the view will 'stick' to.
    ///
    /// Default is left for RTL languages and right for others.
    public var edge: Edge = .right {
        didSet {
            guard let superview = superview else {
                return
            }
            setConstraints(superview: superview)
        }
    }
    
    // MARK: Private properties
    private let stackView = UIStackView()
    private var labels = [UILabel]()
    private var sectionIndexes = [String]()
    private var extendedSectionTitles = [String]()
    
    public private(set)lazy var contentView: UIView = {
        let v = UIView()
        v.backgroundColor = .indexBackgroundColor
        v.layer.cornerRadius = 8
        v.layer.borderWidth = 0.3
        v.layer.borderColor = UIColor.gray.cgColor
        v.isUserInteractionEnabled = false
        v.alpha = 0
        return v
    }()
    
    private let verticalSpacing: CGFloat = 2
    private let interLabelSpacing: CGFloat = 4
    
    private lazy var labelView = LabelOverlayView()
    
    // MARK: Initialization
    public init(delegate: AWIndexViewDelegate? = nil) {
        self.delegate = delegate
        super.init(frame: .zero)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        configureStackView()
        backgroundColor = .clear
        
        let press = UILongPressGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        press.minimumPressDuration = 0
        addGestureRecognizer(press)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        addGestureRecognizer(pan)
        
        switch UIApplication.shared.userInterfaceLayoutDirection {
        case .leftToRight:
            edge = .right
        case .rightToLeft:
            edge = .left
        default:
            edge = .right
        }
    }
    
    // MARK: Overrides
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let superview = superview else {
            labelView.removeFromSuperview()
            return
        }
        superview.insertSubview(labelView, belowSubview: self)
        setConstraints(superview: superview)
    }
    
    public override func tintColorDidChange() {
        super.tintColorDidChange()
        labels.forEach { $0.textColor = tintColor }
    }
    
    // MARK: Public methods
    
    /// Loads new section indexes.
    public func setup() {
        if let sv = superview,
            sv.subviews.contains(self),
            !sv.subviews.contains(labelView) {
            sv.insertSubview(labelView, belowSubview: self)
        }
        sectionIndexes = delegate?.indexView(sectionIndexes: self) ?? []
        extendedSectionTitles = delegate?.indexView(extendedSectionTitles: self) ?? []
        
        setLabels()
        if extendedSectionTitles.isEmpty {
            return
        }
        labelView.text = extendedSectionTitles.first
    }
    
    /// Permanently displays the index view.
    ///
    /// You can hide the view again by calling `hide()` method.
    public func show() {
        if isDragging { return }
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveLinear, .allowUserInteraction], animations: {
            self.contentView.alpha = 1
            if self.labelView.text == nil {
                return
            }
            self.labelView.alpha = 1
        }, completion: nil)
    }
    
    /// Hides the index view.
    ///
    /// You can show the view again by calling `show()` method.
    public func hide() {
        if isDragging { return }
        UIView.animate(withDuration: 0.2, animations: {
            self.contentView.alpha = 0
            self.labelView.alpha = 0
        }, completion: nil)
    }
    
    /// Shows index view to user for given duration and after delay.
    public func flash(delay: TimeInterval = 0, duration: TimeInterval = 2) {
        UIView.animate(withDuration: 0.2, delay: delay, options: [.curveLinear, .allowUserInteraction], animations: {
            self.contentView.alpha = 1
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                if self.isDragging {
                    return
                }
                self.hide()
            }
        }
    }
    
    // MARK: Private methods
    private func setLabels() {
        for view in stackView.arrangedSubviews {
            view.removeFromSuperview()
        }
        labels.removeAll()
        
        func insertLabel(withText text: String) {
            let label = prepareNewLabel(text: text)
            labels.append(label)
            stackView.addArrangedSubview(label)
        }
        
        for index in sectionIndexes {
            insertLabel(withText: index)
        }
    }
    
    private func setConstraints(superview: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        var constraints = [
            centerYAnchor.constraint(equalTo: superview.centerYAnchor),
            topAnchor.constraint(greaterThanOrEqualTo: superview.safeAreaLayoutGuide.topAnchor, constant: verticalSpacing),
            heightAnchor.constraint(greaterThanOrEqualTo: superview.safeAreaLayoutGuide.heightAnchor, multiplier: 0.6),
            widthAnchor.constraint(lessThanOrEqualTo: superview.safeAreaLayoutGuide.widthAnchor, multiplier: 0.22)
        ]
        switch edge {
        case .left:
            constraints.append(leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor))
        case .right:
            constraints.append(trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor))
        }
        NSLayoutConstraint.activate(constraints)
    }
    
    private func configureStackView() {
        addSubview(contentView)
        contentView.pinToSuperviewEdges()
        
        stackView.spacing = interLabelSpacing
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.isUserInteractionEnabled = false
        
        contentView.addSubview(stackView)
        stackView.pinToSuperviewEdges(margin: 4)
    }
    
    private func prepareNewLabel(text: String) -> UILabel {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.textColor = tintColor
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        
        return label
    }
    
    @objc private func handleGesture(_ sender: UIGestureRecognizer) {
        if labels.isEmpty {
            return
        }
        
        switch sender.state {
        case .began:
            delegate?.indexView(willBeginDragging: self)
            show()
            isDragging = true
            feedbackGenerator.prepare()
        case .changed:
            let pointY = sender.location(in: self).y
            
            // procent we frame, min żeby nie wyszło poza section titles a max żeby większe od 0
            let index = max(min(Int(pointY / frame.height * CGFloat(labels.count)), labels.count - 1), 0)
            // procent we frame * ilość titles - wysokość sekcji poniżej
            let percentInSection = max(pointY / frame.height * CGFloat(labels.count) - CGFloat(index), 0)
            scrollToIndex(index, percentInSection: percentInSection)
        default:
            isDragging = false
            delegate?.indexView(didEndDragging: self)
            hide()
        }
    }
    
    private lazy var feedbackGenerator = UISelectionFeedbackGenerator()
    private var currentIndexPath = IndexPath(row: 0, section: 0)
    
    private func scrollToIndex(_ index: Int, percentInSection: CGFloat) {
        guard let delegate = delegate else {
            return
        }
        var section = index
        var rows = delegate.indexView(self, numberOfItemsIn: section)
        var row = Int(CGFloat(rows) * percentInSection)
        let numberOfSections = labels.count
        
        while (rows == 0 && section < numberOfSections - 1) {
            section += 1
            rows = delegate.indexView(self, numberOfItemsIn: section)
            row = 0
        }
        
        if (rows != 0 && row < rows) {
            let indexPath = IndexPath(row: scrollsToSectionTop ? 0 : row, section: section)
            if indexPath.section != currentIndexPath.section {
                currentIndexPath = indexPath
                feedbackGenerator.selectionChanged()
            }
            delegate.indexView(self, wasDraggedAt: indexPath)
            if extendedSectionTitles.isEmpty {
                return
            }
            labelView.text = extendedSectionTitles[section]
        }
    }
}

public extension AWIndexView {
    enum Edge {
        /// Left edge of the screen.
        case left
        
        /// Right edge of the screen.
        case right
    }
}

fileprivate class LabelOverlayView: UIView {
    private lazy var label: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.font = UIFont.systemFont(ofSize: 48, weight: .medium)
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.5
        
        return l
    }()
    
    var text: String? {
        get {
            return label.text
        } set {
            label.text = newValue
        }
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        label.textColor = tintColor
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        pinToSuperviewEdges()
    }
    
    init() {
        super.init(frame: .zero)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leftAnchor.constraint(equalTo: leftAnchor, constant: 24),
            label.rightAnchor.constraint(equalTo: rightAnchor, constant: -74)
        ])
        backgroundColor = UIColor.indexBackgroundColor.withAlphaComponent(0.8)
        alpha = 0
    }
}

fileprivate extension UIColor {
    class var indexBackgroundColor: UIColor {
        if #available(iOS 13.0, *) {
            return .secondarySystemGroupedBackground
        } else {
            return .groupTableViewBackground
        }
    }
}
