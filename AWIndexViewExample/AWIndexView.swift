//
//  AWIndexView.swift
//  AWIndexViewExample
//
//  Created by Adam Wienconek on 25.02.2019.
//  Copyright © 2019 Adam Wienconek. All rights reserved.
//

import UIKit

protocol AWIndexViewDelegate: class {
    /// Action performed when user drags in index view and path changes.
    func indexViewChanged(indexPath: IndexPath)
    
    /// Number of items for section.
    func numberOfItems(in section: Int) -> Int
    
    /// Array of section indexes.
    var sectionIndexes: [String] { get }
    
    /// Theme used to customize index view's appearance.
    var indexViewTheme: AWIndexView.Theme { get }
}

extension AWIndexViewDelegate {
    var indexViewTheme: AWIndexView.Theme {
        return AWIndexView.Theme(backgroundColor: .white, tintColor: UIButton().tintColor, borderColor: .lightGray, font: UIFont.systemFont(ofSize: 12, weight: .medium))
    }
}

extension AWIndexViewDelegate where Self: UIViewController {
    func indexViewChanged(indexPath: IndexPath) {
        if let tableView = view.subviews.first(where: { $0 is UITableView }) as? UITableView {
            tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        } else {
            if let collectionView = view.subviews.first(where: { $0 is UICollectionView }) as? UICollectionView {
                collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
            }
        }
    }
}

class AWIndexView: UIView {
    
    public weak var delegate: AWIndexViewDelegate?
    
    private var stackView: UIStackView!
    private var labels: [String: UILabel]!
    public var shouldScrollToFirstItemInSection = false
    
    public var verticalSpacing: CGFloat = 16
    public var interLabelSpacing: CGFloat = 4
    
    /// Value indicating which edge the view will 'stick' to.
    /// Default is left for RTL languages and right for others.
    public var edge: Edge = .default
    
    public var shouldHideWhenNotActive = true {
        didSet {
            alpha = shouldHideWhenNotActive ? 0.02 : 1
        }
    }
    public var isDragging = false
    
    init(delegate: AWIndexViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        configureStackView()
        layer.cornerRadius = 6
        layer.borderWidth = 0.7
        alpha = 0.02
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        addGestureRecognizer(pan)
        
        setup()
    }
    
    private func setLabels(with indexes: [String]) {
        if let labels = labels {
            for pair in labels {
                pair.value.removeFromSuperview()
            }
        }
        labels = [:]
        for index in indexes {
            insert(new: index)
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let superView = superview else { return }
        setConstraints(to: superView)
    }
    
    public func applyTheme(_ theme: Theme, animated: Bool = true) {
        UIView.animate(withDuration: animated ? 0.3 : 0) {
            for pair in self.labels {
                pair.value.textColor = theme.tintColor
                pair.value.font = theme.font
            }
            self.backgroundColor = theme.backgroundColor
            self.layer.borderColor = theme.borderColor.cgColor
        }
    }
    
    private func setConstraints(to superView: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        var constraints = [NSLayoutConstraint]()
        
        if #available(iOS 11.0, *) {
            constraints.append(contentsOf: [
                centerYAnchor.constraint(equalTo: superView.safeAreaLayoutGuide.centerYAnchor),
                topAnchor.constraint(greaterThanOrEqualTo: superView.safeAreaLayoutGuide.topAnchor, constant: verticalSpacing)
                ])
            switch edge {
            case .left:
                constraints.append(leadingAnchor.constraint(equalTo: superView.safeAreaLayoutGuide.leadingAnchor))
            case .right:
                constraints.append(trailingAnchor.constraint(equalTo: superView.safeAreaLayoutGuide.trailingAnchor))
            case .default:
                switch UIApplication.shared.userInterfaceLayoutDirection {
                case .leftToRight:
                    constraints.append(trailingAnchor.constraint(equalTo: superView.safeAreaLayoutGuide.trailingAnchor))
                case .rightToLeft:
                    constraints.append(leadingAnchor.constraint(equalTo: superView.safeAreaLayoutGuide.leadingAnchor))
                }
            }
        } else {
            constraints.append(contentsOf: [
                centerYAnchor.constraint(equalTo: superView.centerYAnchor),
                topAnchor.constraint(greaterThanOrEqualTo: superView.topAnchor, constant: verticalSpacing)
                ])
            switch edge {
            case .left:
                constraints.append(leadingAnchor.constraint(equalTo: superView.leadingAnchor))
            case .right:
                constraints.append(trailingAnchor.constraint(equalTo: superView.trailingAnchor))
            case .default:
                switch UIApplication.shared.userInterfaceLayoutDirection {
                case .leftToRight:
                    constraints.append(trailingAnchor.constraint(equalTo: superView.trailingAnchor))
                case .rightToLeft:
                    constraints.append(leadingAnchor.constraint(equalTo: superView.leadingAnchor))
                }
            }
        }
        NSLayoutConstraint.activate(constraints)
    }
    
    private func configureStackView() {
        stackView = UIStackView()
        addSubview(stackView)
        
        stackView.spacing = interLabelSpacing
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
                stackView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
            ])
    }
    
    /// Loads new section indexes and theme.
    public func setup() {
        guard let delegate = delegate else { return }
        setLabels(with: delegate.sectionIndexes)
        applyTheme(delegate.indexViewTheme, animated: false)
    }
    
    /// Inserts new label into stack view.
    public func insert(new index: String) {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = index
        label.textColor = delegate?.indexViewTheme.tintColor
        label.font = delegate?.indexViewTheme.font
        labels.updateValue(label, forKey: index)
        stackView.addArrangedSubview(label)
    }
    
    public func remove(index: String) -> UILabel? {
        guard let label = labels[index] else {
            print("Label not found")
            return nil
        }
        stackView.removeArrangedSubview(label)
        return labels.removeValue(forKey: index)
    }
    
    @objc private func handleGesture(_ sender: UIGestureRecognizer) {
        switch sender.state {
        case .began:
            show(completion: nil)
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
            hide(completion: nil)
        }
    }
    
    private lazy var feedbackGenerator = UISelectionFeedbackGenerator()
    private var currentIndexSection = 0
    
    private func scrollToIndex(_ index: Int, percentInSection: CGFloat) {
        guard let delegate = delegate else {
            return
        }
        var section = index
        var rows = delegate.numberOfItems(in: section)
        var row = Int(CGFloat(rows) * percentInSection)
        let numberOfSections = labels.count
        
        while (rows == 0 && section < numberOfSections - 1) {
            section += 1
            rows = delegate.numberOfItems(in: section)
            row = 0
        }
        
        if (rows != 0 && row < rows) {
            let indexPath = IndexPath(row: shouldScrollToFirstItemInSection ? 0 : row, section: section)
            if indexPath.section != currentIndexSection {
                currentIndexSection = indexPath.section
                if #available(iOS 10.0, *) {
                    vibrate()
                }
            }
            delegate.indexViewChanged(indexPath: indexPath)
        }
    }
    
    private func vibrate() {
        feedbackGenerator.selectionChanged()
    }
    
    public func show(completion: (() -> Void)?) {
        if isDragging { return }
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 1
        }) { _ in
            completion?()
        }
    }
    
    public func hide(completion: (() -> Void)?) {
        if isDragging { return }
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0.02
        }) { _ in
            completion?()
        }
    }
    
    /// Shows index view to user for given duration and after delay.
    public func flash(delay: TimeInterval = 0, duration: TimeInterval = 2) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.show {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    self.hide(completion: nil)
                }
            }
        }
    }

}

extension AWIndexView {
    enum Edge {
        /// Left edge of the screen.
        case left
        /// Right edge of the screen.
        case right
        /// Left for RTL languages, right for others.
        case `default`
    }
    
    struct Theme {
        let backgroundColor: UIColor
        /// Color used as text color.
        let tintColor: UIColor
        let borderColor: UIColor
        /// Font used by labels.
        let font: UIFont
    }
}
