//
//  TextAsyncDisplayTableViewCell.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/1.
//

import UIKit
import REText

class TextAsyncDisplayTableViewCell: UITableViewCell {
    
    private var uiLabel: UILabel!
    private var reLabel: RELabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        uiLabel = UILabel()
        uiLabel.font = UIFont.systemFont(ofSize: 8)
        uiLabel.numberOfLines = 3
        uiLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width
        
        reLabel = RELabel()
        reLabel.font = uiLabel.font
        reLabel.numberOfLines = uiLabel.numberOfLines
        reLabel.displaysAsynchronously = true
        reLabel.lineBreakMode = uiLabel.lineBreakMode
        reLabel.preferredMaxLayoutWidth = uiLabel.preferredMaxLayoutWidth
        
        contentView.addSubview(reLabel)
        contentView.addSubview(uiLabel)
        
        let views = [uiLabel, reLabel]
        for view in views {
            guard let view else { continue }
            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                view.topAnchor.constraint(equalTo: contentView.topAnchor),
                view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }
    }
    
    func setText(_ text: Any, async: Bool) {
        reLabel.isHidden = !async
        uiLabel.isHidden = async
        
        if async, let renderer = text as? TextRenderer {
            reLabel.textRenderer = renderer
        } else {
            if let attributedText = text as? NSAttributedString {
                uiLabel.attributedText = attributedText
            } else if let plainText = text as? String {
                uiLabel.text = plainText
            }
        }
    }
}
