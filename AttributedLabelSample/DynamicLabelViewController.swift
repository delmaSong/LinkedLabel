//
//  DynamicLabelViewController.swift
//  AttributedLabelSample
//
//  Created by Delma Song on 2021/03/14.
//

import UIKit
import SafariServices

class DynamicLabelViewController: UIViewController {

    private lazy var dynamicLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.isUserInteractionEnabled = true
        view.textAlignment = .left
        view.translatesAutoresizingMaskIntoConstraints = false

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(dynamicLabelTapped(_:)))
        view.addGestureRecognizer(recognizer)
        return view
    }()

    private let button: UIButton = {
        let view = UIButton()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBlue
        view.setTitle("전송", for: .normal)
        view.addTarget(self, action: #selector(sendButtondTapped(_:)), for: .touchUpInside)
        return view
    }()

    private lazy var textField: UITextField = {
        let view = UITextField()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.borderStyle = .roundedRect
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
    }

    @objc func dynamicLabelTapped(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: dynamicLabel)

        guard let selectedIndex = dynamicLabel.textIndex(at: point) else { return }

        guard let attr = dynamicLabel.attributedText?.attributes(at: selectedIndex, effectiveRange: nil),
              let url = attr[.attachment] as? URL else { return }
        present(url: url.absoluteString)
    }

    @objc func sendButtondTapped(_ sender: UIButton) {
        dynamicLabel.text = textField.text
        textField.text = ""
        configureLabel()
    }

    private func present(url string: String) {
        if let url = URL(string: string) {
            let viewController = SFSafariViewController(url: url)
            present(viewController, animated: true)
        }
    }

    private func configureLabel() {
        guard let messageText = dynamicLabel.text else { return }
        let mutableString = NSMutableAttributedString()

        let normalAttributes: [NSMutableAttributedString.Key: Any] = [
            .foregroundColor: UIColor.darkGray,
            .font: UIFont.boldSystemFont(ofSize: 18)
        ]
        var urlAttributes: [NSMutableAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemGreen,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .font: UIFont.italicSystemFont(ofSize: 18)
        ]

        let normalText = NSAttributedString(string: messageText, attributes: normalAttributes)
        mutableString.append(normalText)

        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = detector.matches(
                in: messageText,
                options: [],
                range: NSRange(location: 0, length: messageText.count)
            )
            for m in matches {
                if let url = m.url {
                    urlAttributes[.attachment] = url
                    mutableString.setAttributes(urlAttributes, range: m.range)
                }
            }
            dynamicLabel.attributedText = mutableString
        } catch {
            print(error)
        }
    }

    private func configureLayout() {
        view.addSubview(dynamicLabel)
        view.addSubview(button)
        view.addSubview(textField)

        dynamicLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        dynamicLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        dynamicLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12).isActive = true
        dynamicLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12).isActive = true

        textField.topAnchor.constraint(equalTo: dynamicLabel.bottomAnchor, constant: 24).isActive = true
        textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12).isActive = true
        textField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        textField.heightAnchor.constraint(equalToConstant: 30).isActive = true

        button.topAnchor.constraint(equalTo: textField.topAnchor).isActive = true
        button.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 12).isActive = true
        button.heightAnchor.constraint(equalTo: textField.heightAnchor).isActive = true
        button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12).isActive = true
    }
}
