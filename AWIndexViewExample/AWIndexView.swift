//
//  AWIndexView.swift
//  AWIndexViewExample
//
//  Created by Adam Wienconek on 25.02.2019.
//  Copyright © 2019 Adam Wienconek. All rights reserved.
//

import UIKit

protocol AWIndexViewDelegate: class {
    func indexViewChanged(indexPath: IndexPath)
    func numberOfItems(in section: Int) -> Int
    var sectionIndexes: [String] { get }
    var indexViewTheme: AWIndexView.Theme { get }
}

extension AWIndexViewDelegate {
    var indexViewTheme: AWIndexView.Theme {
        return AWIndexView.Theme(backgroundColor: .white, tintColor: UIButton().tintColor, font: UIFont.systemFont(ofSize: 12), borderColor: .gray)
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
    public var edge: Edge = .default
    
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
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        addGestureRecognizer(pan)
        
        guard let delegate = delegate else { return }
        setLabels(with: delegate.sectionIndexes)
        applyTheme(delegate.indexViewTheme, animated: false)
    }
    
    private func setLabels(with indexes: [String]) {
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
    
    /// Inserts new label into stack view.
    public func insert(new index: String) {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = index
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
        
        let pointY = sender.location(in: self).y
        
        // procent we frame, min żeby nie wyszło poza section titles a max żeby większe od 0
        let index = max(min(Int(pointY / frame.height * CGFloat(labels.count)), labels.count - 1), 0)
        // procent we frame * ilość titles - wysokość sekcji poniżej
        let percentInSection = max(pointY / frame.height * CGFloat(labels.count) - CGFloat(index), 0)
        scrollToIndex(index, percentInSection: percentInSection)
    }
    
    private var currentIndexSection = 0
    func scrollToIndex(_ index: Int, percentInSection: CGFloat) {
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
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesBegan(touches, with: event)
//        feedbackGenerator.prepare()
//        isDragging = true
//        if shouldHideWhenNotActive {
//            isVisible = true
//        }
//    }
//
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesEnded(touches, with: event)
//        if shouldHideWhenNotActive {
//            isVisible = false
//        }
//        isDragging = false
//    }
    
    @available(iOS 10.0, *) private func vibrate() {
        let feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator.prepare()
    }

}

extension AWIndexView {
    enum Edge {
        case left
        
        case right
        
        /// Left for RTL languages, right for others
        case `default`
        
        var c: Edge {
            switch UIApplication.shared.userInterfaceLayoutDirection {
            case .leftToRight:
                return .right
            case .rightToLeft:
                return .left
            }
        }
    }
    
    struct Theme {
        let backgroundColor: UIColor
        let tintColor: UIColor
        let font: UIFont
        let borderColor: UIColor
    }
}

extension UIViewController {
    func addIndexView(_ indexView: AWIndexView) {
        view.addSubview(indexView)
    }
}
