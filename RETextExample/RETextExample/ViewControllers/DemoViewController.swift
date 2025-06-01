//
//  DemoViewController.swift
//  RETextExample
//
//  Created by phoenix on 2025/4/4.
//

import UIKit
import REText

class DemoViewController: UITableViewController {
    
    private var titles: [String] = []
    private var classNames: [String] = []
    private var storyboardIDs: [String: String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "REText Demo"
        view.backgroundColor = .white
        
        setupData()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "id")
        tableView.reloadData()
    }
    
    private func setupData() {
        addCell("Text Attributes", className: "TextAttributesViewController")
        addCell("Text Attachment", className: "TextAttachmentViewController")
        addCell("Text Truncating", className: "TextTruncatingViewController")
        addCell("Async Display", className: "TextAsyncDisplayViewController")
        addCell("Exclusion Path", className: "TextExclusionPathsViewController")
        addCell("Custom Attribute", className: "TextCustomAttributeViewController")
//        addCell("Swift Example", className: String(describing: MPITextSwfitExampleViewController.self))
        addCell("Text Selection", className: "TextSelectionViewController")
        addCell("Size Calculation", className: "TextSizeCalculationViewController")
        addCell("Attributes Separation", className: "TextAttributesSeparationViewController")
        addCell("Features Comparison", className: "FeaturesComparisonViewController", storyboardID: "FeaturesComparison")
    }
    
    private func addCell(_ title: String, className: String) {
        addCell(title, className: className, storyboardID: nil)
    }
    
    private func addCell(_ title: String, className: String, storyboardID: String?) {
        titles.append(title)
        classNames.append(className)
        if let storyboardID = storyboardID {
            storyboardIDs[className] = storyboardID
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "id", for: indexPath)
        cell.textLabel?.text = titles[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let className = classNames[indexPath.row]
        let storyboardID = storyboardIDs[className]
        
        let viewController: UIViewController
        
        if let storyboardID = storyboardID, !storyboardID.isEmpty {
            viewController = storyboard!.instantiateViewController(withIdentifier: storyboardID)
        } else {
            guard let aClass = NSClassFromString(className) as? UIViewController.Type else {
                print("Failed to create class from string: \(className)")
                return
            }
            viewController = aClass.init()
        }
        
        viewController.title = titles[indexPath.row]
        navigationController?.pushViewController(viewController, animated: true)
    }
}
