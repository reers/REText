//
//  TextTruncatingViewController.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/1.
//

import UIKit
import REText

@objc(TextTruncatingViewController)
class TextTruncatingViewController: UITableViewController {
    
    private var attributedTruncationMessages: [NSAttributedString] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ExampleHelper.addDebugOption(to: self)
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.register(TextTruncatingTableViewCell.self, forCellReuseIdentifier: "id")
        
        for i in 0..<100 {
            let truncationMessage = "more\(i)"
            let attributedTruncationMessage = NSAttributedString(
                string: truncationMessage,
                attributes: [
                    .foregroundColor: UIColor(red: 0.0, green: 0.449, blue: 1.0, alpha: 1.0),
                    .textLink: TextLink()
                ]
            )
            attributedTruncationMessages.append(attributedTruncationMessage)
        }
        
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attributedTruncationMessages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "id", for: indexPath) as! TextTruncatingTableViewCell
        cell.reLabel.additionalTruncationAttributedMessage = attributedTruncationMessages[indexPath.row]
        cell.reLabel.preferredMaxLayoutWidth = tableView.frame.width
        cell.reLabel.onLinkInteraction = { [weak self] label, link, attributedText, range, interaction in
            guard let self = self else { return }
            guard let superview = label.superview else { return }
            let labelCenterInTableView = superview.convert(label.center, to: tableView)
            
            if let indexPath = tableView.indexPathForRow(at: labelCenterInTableView) {
                let interactionString = interaction == .tap ? "Tapped" : "Long pressed"
                title = "Cell \(indexPath.row) \(interactionString)"
            }
        }
        return cell
    }
}
