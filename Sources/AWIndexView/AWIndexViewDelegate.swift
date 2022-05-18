//
//  File.swift
//  
//
//  Created by Adam Wienconek on 19/01/2021.
//

import UIKit

public protocol AWIndexViewDelegate: AnyObject {
    /// Action performed when user drags in index view and path changes.
    func indexView(_ indexView: AWIndexView, wasDraggedAt indexPath: IndexPath)
    
    /// Method called just before index view starts reporting movement.
    func indexView(willBeginDragging indexView: AWIndexView)
    
    /// Method called when index view stops registering movement.
    func indexView(didEndDragging indexView: AWIndexView)
    
    /// Number of items for section.
    func indexView(_ indexView: AWIndexView, numberOfItemsIn section: Int) -> Int
    
    /// Titles for index view, preferably acronyms or single characters.
    func indexView(sectionIndexes indexView: AWIndexView) -> [String]
    
    /// Titles for overlay label view, if empty no overlay will be displayed.
    func indexView(extendedSectionTitles indexView: AWIndexView) -> [String]
}

public extension AWIndexViewDelegate {
    func indexView(willBeginDragging indexView: AWIndexView) {}
    
    func indexView(didEndDragging indexView: AWIndexView) {}
    
    func indexView(extendedSectionTitles indexView: AWIndexView) -> [String] {
        return []
    }
}

extension UITableView: AWIndexViewDelegate {
    public func indexView(_ indexView: AWIndexView, numberOfItemsIn section: Int) -> Int {
        return numberOfRows(inSection: section)
    }
    
    public func indexView(_ indexView: AWIndexView, wasDraggedAt indexPath: IndexPath) {
        scrollToRow(at: indexPath, at: .top, animated: false)
    }
    
    public func indexView(sectionIndexes indexView: AWIndexView) -> [String] {
        return dataSource?.sectionIndexTitles?(for: self) ?? []
    }
    
    public func indexView(extendedSectionTitles indexView: AWIndexView) -> [String] {
        return [0 ..< numberOfSections].indices.compactMap { section in
            return dataSource?.tableView?(self, titleForHeaderInSection: section)
        }
    }
}
