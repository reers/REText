//
//  TextAsyncDisplayViewController.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/1.
//


import UIKit
import REText

@objc(TextAsyncDisplayViewController)
class TextAsyncDisplayViewController: UITableViewController {
    
    private var strings: [NSAttributedString] = []
    private var textRenderers: [TextRenderer] = []
    private var isAsync: Bool = false
    private var toolbar: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        ExampleHelper.addDebugOption(to: self)
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 34
        tableView.register(TextAsyncDisplayTableViewCell.self, forCellReuseIdentifier: "id")
        
        var strings: [NSAttributedString] = []
        var textRenderers: [TextRenderer] = []
        
        for i in 0..<500 {
            let str = "\(i) Async Display Test ✺◟(∗❛ัᴗ❛ั∗)◞✺ ✺◟(∗❛ัᴗ❛ั∗)◞✺ 😀😖😐😣😡🚖🚌🚋🎊💖💗💛💙🏨🏦🏫 Async Display Test ✺◟(∗❛ัᴗ❛ั∗)◞✺ ✺◟(∗❛ัᴗ❛ั∗)◞✺ 😀😖😐😣😡🚖🚌🚋🎊💖💗💛💙🏨🏦🏫 Async Display Test ✺◟(∗❛ัᴗ❛ั∗)◞✺ ✺◟(∗❛ัᴗ❛ั∗)◞✺"
            
            let text = NSMutableAttributedString(
                string: str,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 12),
                    .strokeColor: UIColor.red,
                    .strokeWidth: -3
                ]
            )
            
            strings.append(text)
            
            let attributesBuilder = TextRenderAttributesBuilder()
            attributesBuilder.attributedText = text
            attributesBuilder.lineBreakMode = .byTruncatingTail
            attributesBuilder.maximumNumberOfLines = 3
            attributesBuilder.truncationAttributedText = REText.defaultTruncationAttributedToken
            
            let renderer = TextRenderer(
                renderAttributes: attributesBuilder.build(),
                constrainedSize: CGSize(width: UIScreen.main.bounds.width, height: .greatestFiniteMagnitude)
            )
            textRenderers.append(renderer)
        }
        
        self.strings = strings
        self.textRenderers = textRenderers
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addToolbar()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeToolbar()
    }
    
    private func addToolbar() {
        guard let navigationController = navigationController as? DemoNavigationController,
              let containerView = navigationController.view else { return }
        
        let toolbar = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        containerView.insertSubview(toolbar, belowSubview: navigationController.fpsLabel)
        
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(
                equalTo: containerView.safeAreaLayoutGuide.topAnchor,
                constant: navigationController.navigationBar.frame.height
            ),
            toolbar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        let titleLabel = UILabel()
        titleLabel.text = "UILabel/RELabel(Async): "
        
        let switcher = UISwitch()
        switcher.layer.setValue(0.8, forKeyPath: "transform.scale")
        switcher.isOn = isAsync
        switcher.sizeToFit()
        switcher.addTarget(self, action: #selector(switchAction(_:)), for: .valueChanged)
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, switcher])
        stackView.spacing = 8
        stackView.axis = .horizontal
        
        toolbar.contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 8),
            stackView.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor)
        ])
        
        removeToolbar()
        self.toolbar = toolbar
    }
    
    private func removeToolbar() {
        toolbar?.removeFromSuperview()
    }
    
    @objc private func switchAction(_ switcher: UISwitch) {
        isAsync = switcher.isOn
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return strings.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "id", for: indexPath) as! TextAsyncDisplayTableViewCell
        
        if isAsync {
            cell.setText(textRenderers[indexPath.row], async: isAsync)
        } else {
            cell.setText(strings[indexPath.row], async: isAsync)
        }
        
        return cell
    }
}
