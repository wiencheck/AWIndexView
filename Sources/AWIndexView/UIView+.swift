//
//  File.swift
//  
//
//  Created by Adam Wienconek on 19/01/2021.
//

import UIKit

extension UIView {
    func pinToSuperviewEdges(margin: CGFloat = 0) {
        guard let superview = superview else {
            return
        }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor, constant: margin),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: margin),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -margin),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -margin)
        ])
    }
}
