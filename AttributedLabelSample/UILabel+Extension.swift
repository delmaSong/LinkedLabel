//
//  UILabel+Extension.swift
//  AttributedLabelSample
//
//  Created by Delma Song on 2021/03/07.
//

import UIKit

extension UILabel {
    /// 라벨 내 특정 문자열의 CGRect 반환
    /// - Parameter subText: CGRect값을 알고 싶은 특정 문자열
    func boundingRectForCharacterRange(subText: String) -> CGRect? {
        guard let attributedText = attributedText else { return nil }
        guard let text = self.text else { return nil }

        guard let subRange = text.range(of: subText) else { return nil }
        let range = NSRange(subRange, in: text)

        let layoutManager = NSLayoutManager()
        let textStorage = NSTextStorage(attributedString: attributedText)
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(size: intrinsicContentSize)
        textContainer.lineFragmentPadding = 0.0
        layoutManager.addTextContainer(textContainer)

        var glyphRange = NSRange()
        layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)

        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }

    /// 입력된 포지션에 따라 라벨의 문자열의 인덱스 반환
    /// - Parameter point: 인덱스 값을 알고 싶은 CGPoint
    func textIndex(at point: CGPoint, alignment: NSTextAlignment = .left) -> Int? {
        guard var attributedText = attributedText else { return nil }

        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: self.bounds.size)
        let textStorage = NSTextStorage(attributedString: attributedText)

        if let text = text {
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = alignment
            attributedText = NSAttributedString(string: text, attributes: [.paragraphStyle: paragraph])
        }

        textStorage.addLayoutManager(layoutManager)
        textContainer.lineFragmentPadding = 0.0
        layoutManager.addTextContainer(textContainer)

        let range = layoutManager.glyphRange(for: textContainer)

        var textOffset = CGPoint.zero
        let textBounds = layoutManager.boundingRect(forGlyphRange: range, in: textContainer)
        let paddingWidth = (self.bounds.size.width - textBounds.size.width) / 2
        if paddingWidth > 0 {
            textOffset.x = paddingWidth
        }

        let newPoint = CGPoint(x: point.x - textOffset.x, y: point.y - textOffset.y)

        return layoutManager.glyphIndex(for: newPoint, in: textContainer)
    }
}
