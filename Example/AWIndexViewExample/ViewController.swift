//
//  ViewController.swift
//  AWIndexViewExample
//
//  Created by Adam Wienconek on 25.02.2019.
//  Copyright © 2019 Adam Wienconek. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var indexView: AWIndexView!
    
    var names = ["Adam", "Adrian", "Rafał", "Halina", "Burger", "Celina", "Dawid", "Eryk", "Ludwik", "Adam", "Adrian", "Rafał", "Halina", "Burger", "Celina", "Dawid", "Eryk", "Ludwik", "Adam", "Adrian", "Rafał", "Halina", "Burger", "Celina", "Dawid", "Eryk", "Ludwik", "Adam", "Adrian", "Rafał", "Halina", "Burger", "Celina", "Dawid", "Eryk", "Ludwik", "Adam", "Adrian", "Rafał", "Halina", "Burger", "Celina", "Dawid", "Eryk", "Ludwik", "Frank", "Zorro", "Zbigniew", "Garfield"]
    
    private var sections: [String: [String]]!
    private var sectionTitles: [String]!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        sort()
        indexView = AWIndexView(delegate: self)
        //indexView.shouldHideWhenNotActive = false
        view.addSubview(indexView)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.sectionTitles.append("KUPA")
            self.indexView.setup()
            self.indexView.flash(delay: 1)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        indexView.flash(delay: 1)
    }
    
    private func sort() {
        sections = [:]
        for name in names {
            guard let firstCharacter = name.first else { continue }
            let firstLetter = String(firstCharacter)
            if sections[firstLetter] == nil {
                sections.updateValue([name], forKey: firstLetter)
            } else {
                sections[firstLetter]?.append(name)
            }
        }
        sectionTitles = [String](sections.keys).sorted(by: { $0.lowercased() < $1.lowercased() })
    }

}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[sectionTitles[section]]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = sections[sectionTitles[indexPath.section]]?[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
}

extension ViewController: AWIndexViewDelegate {
    var sectionIndexes: [String] {
        return sectionTitles
    }
    
    func indexViewChanged(indexPath: IndexPath) {
        tableView.scrollToRow(at: indexPath, at: .top, animated: false)
    }
    
    func numberOfItems(in section: Int) -> Int {
        return sections[sectionTitles[section]]?.count ?? 0
    }
}
