//
//  ViewController.swift
//  AttributedLabelSample
//
//  Created by Delma Song on 2021/03/01.
//

import UIKit
import SafariServices

class ViewController: UIViewController {

    private lazy var fixedLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.isUserInteractionEnabled = true
        view.textAlignment = .center
        view.translatesAutoresizingMaskIntoConstraints = false

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(fixedLabelTapped(_:)))
        view.addGestureRecognizer(recognizer)
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
        configureFixedLabel()
    }

    @objc func fixedLabelTapped(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: fixedLabel)
        if let googleRect = fixedLabel.boundingRectForCharacterRange(subText: "google"),
           googleRect.contains(point) {
            present(url: "https://www.google.com")
        }
        if let githubRect = fixedLabel.boundingRectForCharacterRange(subText: "github"),
           githubRect.contains(point) {
            present(url: "https://www.github.com")
        }
    }

    private func present(url string: String) {
        if let url = URL(string: string) {
            let viewController = SFSafariViewController(url: url)
            present(viewController, animated: true)
        }
    }

    private func configureLayout() {
        view.addSubview(fixedLabel)

        fixedLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        fixedLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }

    func configureFixedLabel() {
        let google = "google"
        let github = "github"
        let generalText = String(format: "고정된 링크로 이동하는 예제로 \n%@링크와 %@링크로 이동해봅시다", google, github)

        let italicFont = UIFont.italicSystemFont(ofSize: 18)
        let boldFont = UIFont.boldSystemFont(ofSize: 18)

        let green = UIColor.systemGreen
        let darkGray = UIColor.darkGray

        let generalAttributes: [NSAttributedString.Key: Any] = [.foregroundColor:darkGray, .font: boldFont]
        let linkAttributes: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .foregroundColor: green,
            .font: italicFont
        ]

        let mutableString = NSMutableAttributedString()
        mutableString.append(NSAttributedString(string: generalText, attributes: generalAttributes))
        mutableString.setAttributes(linkAttributes, range: (generalText as NSString).range(of: google))
        mutableString.setAttributes(linkAttributes, range: (generalText as NSString).range(of: github))

        fixedLabel.attributedText = mutableString
    }
}

