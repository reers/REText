//
//  TextTruncatingTableViewCell.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/1.
//


import UIKit
import REText

class TextTruncatingTableViewCell: UITableViewCell {
    
    private(set) var reLabel: RELabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        let text = "The UIKit framework includes several classes whose purpose is to display text in an app's user interface: UITextView, UITextField, and UILabel, as described in Displaying Text Content in iOS. Text views, created from the UITextView class, are meant to display large amounts of text. Underlying UITextView is a powerful layout engine called Text Kit. If you need to customize the layout process or you need to intervene in that behavior, you can use Text Kit. For smaller amounts of text and special needs requiring custom solutions, you can use alternative, lower-level technologies, as described in Lower Level Text-Handling Technologies."
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        
        let attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .paragraphStyle: paragraphStyle
            ]
        )
        
        reLabel = RELabel()
        reLabel.isUserInteractionEnabled = true
        reLabel.numberOfLines = 5
        reLabel.truncationAttributedToken = REText.defaultTruncationAttributedToken
        reLabel.attributedText = attributedText
        reLabel.translatesAutoresizingMaskIntoConstraints = false
        reLabel.textContainerInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        contentView.addSubview(reLabel)
        
        NSLayoutConstraint.activate([
            reLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            reLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            reLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            reLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}
