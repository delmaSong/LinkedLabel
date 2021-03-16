[블로그 원글 링크](https://delmasong.github.io/blog/LinkedLabel/)

# 다양한 상황에서 UILabel에 링크를 달아보자(without. TTTAttributedLabel)

앱 개발을 하다보면 다양한 환경에서 텍스트와 링크를 연결해줘야하는 상황이 생기게 됩니다. 내용이 정해져있는 문자열이라면 특정 부분만 `UIButton`등으로 구현하는 방법을 사용할 수도 있습니다. 하지만 어떤 내용이 작성될 지 모르는 채팅창 내용에 URL 링크를 활성화시켜야 하는 경우라면 다른 방법이 필요할 것 같습니다.

다양한 상황에서 `UILabel`에 링크를 연결하기 위해, 기존 프로젝트에서 `TTTAttributedLabel`이라는 써드파티 라이브러리를 사용하고 있었습니다. 사실 해당 라이브러리가 텍스트에 링크만 달아주는 역할을 하지는 않습니다. 자동으로 URL, 주소, 전화번호 등의 데이터를 감지할 수도 있고, 한 `UILabel` 안에 다양한 스타일을 적용시킬 수도 있습니다. 

하지만 2016년 이후로는 릴리즈가 없는 등 더 이상의 업데이트가 이루어지지 않고 있고, 전체 프로젝트에서 해당 라이브러리는 상당히 작은 부분에만 쓰이고 있었습니다. 그리고 현재 프로젝트 내에 많은 라이브러리가 사용되고 있는데 버전 업데이트가 이루어지면서 변경사항을 팔로업 하는 것에 리소스가 많이 소요되는 문제가 있었습니다. 그래서 이러한 이유들로 `TTTAttributedLabel` 라이브러리를 걷어내기로 결정했습니다.

해당 라이브러리를 제거하기로 결정한 이상 몇가지 고려 할 사항이 있습니다.

1. 평문과 링크 문자열의 스타일을 다르게 적용이 되어야 함
2. 고정된 안내 문자열처럼 링크 URL이 고정된 경우
3. 채팅 메시지처럼 한 문자열 내에 여러 URL이 달릴 수 있어야 하고 전부 개별적인 링크로 연결되어야 함

1번과 2번이 결합된 경우와 1번과 3번이 결합된 경우를 상정해 어떤식으로 구현할 수 있는지를 알아보겠습니다.



## 고정된 문자열에 고정된 링크 URL + 스타일 적용

우선 문자열을 표현할 `UILabel`을 선언하고 속성들을 지정합니다.

```swift
private var fixedLabel: UILabel = {
  let view = UILabel()
  view.numberOfLines = 0
  view.textAlignment = .center
  view.translatesAutoresizingMaskIntoConstraints = false
  return view
}()
```

하나의 문자열에 여러 스타일을 적용하는 것은 `NSAttributedString`을 이용하면 쉽게 할 수 있습니다.

아래와 같이 google과 github 부분에만 이탤릭폰트, 초록색, 언더라인을 지정해줍니다.

```swift
func configureLabel() {
  let google = "google"
  let github = "github"
  let generalText = String(
    format: "고정된 링크로 이동하는 예제로 \n%@링크와 %@링크로 이동해봅시다",
    google,
    github
  )

  let italicFont = UIFont.italicSystemFont(ofSize: 18)
  let boldFont = UIFont.boldSystemFont(ofSize: 18)

  let green = UIColor.systemGreen
  let darkGray = UIColor.darkGray

  let generalAttributes: [NSAttributedString.Key: Any] = [
    .foregroundColor:darkGray,
    .font: boldFont
  ]
  let linkAttributes: [NSAttributedString.Key: Any] = [
    .underlineStyle: NSUnderlineStyle.single.rawValue,
    .foregroundColor: green,
    .font: italicFont
  ]

  let mutableString = NSMutableAttributedString()
  mutableString.append(
    NSAttributedString(string: generalText,attributes: generalAttributes)
  )
  mutableString.setAttributes(
    linkAttributes,
    range: (generalText as NSString).range(of: google)
  )
  mutableString.setAttributes(
    linkAttributes,
    range: (generalText as NSString).range(of: github)
  )

  fixedLabel.attributedText = mutableString
}
```



그럼 이미지와 같이 스타일이 적용된 `UILabel`을 볼 수 있습니다

<img width="40%" src="https://user-images.githubusercontent.com/40784518/109514679-a50d1a00-7ae9-11eb-8856-ad4c7c8b7812.png"/>

그렇지만 현재는 스타일만 적용된 상태로, 라벨의 google과 github 부분을 눌러도 아무런 일도 일어나지 않습니다.

링크를 적용하는 방법으로 가장 먼저는 `NSAttributedString`의 속성에 `.link` 키를 이용하는 방법입니다. 하지만 그렇게 하게되면 기존에 주었던 `UIColor.systemGreen`색상은 파란 링크 컬러로 덮어씌워지게 됩니다. 명확한 디자인 요구사항이 있는 경우에는 유효한 선택지가 될 수 없겠군요.

그럼 `UILabel`에 `UITapGestrueReconginzer`를 붙여서 눌린 부분이 google인지 github인지 아닌지 알아보는 방법은 어떨까요?



그러기 위해 `UILabel` 확장 함수로 라벨 내 특정 문자열의 `CGRect`를 반환하는 메서드를 구현합니다. 

```swift
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
}
```



아까 생성한 `fixedLabel`에 `isUserInteractionEnabeld`옵션을 켜주고 `UITapGestrueReconginzer`를 추가해줍니다.

```swift
private lazy var fixedLabel: UILabel = {
  let view = UILabel()
  view.numberOfLines = 0
  view.textAlignment = .center
  view.translatesAutoresizingMaskIntoConstraints = false
  view.isUserInteractionEnabled = true

  let recognizer = UITapGestureRecognizer(
    target: self,
    action: #selector(fixedLabelTapped(_:))
  )
  view.addGestureRecognizer(recognizer)
  return view
}()
```



그리고 `fixedLabelTapped(_:)` 메소드도 선언합니다.

```swift
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
```



그럼 아래처럼 정해진 곳으로 잘 이동하는 것을 볼 수 있습니다.

<img width="30%" src="https://user-images.githubusercontent.com/40784518/110243463-cd8b8d00-7f9d-11eb-9c9d-b2fc113c59e0.gif"/>



이처럼 정해진 곳으로만 보내주는 고정된 문자열, URL이라면 이와같은 방법이 해결책이 될 수 있습니다. 하지만 앞서 말한 것처럼 채팅방의 메시지 내의 불특정 URL 주소를 링킹 해줘야 하는 경우라면 어떻게 구현할 수 있을까요?





## 고정되지 않은 문자열에 고정되지 않은 URL + 스타일 적용

먼저는 `UILabel`, `UITextField`, `UIButton`을 이용해 채팅창과 비슷한 UI를 만듭니다.

```swift
    private lazy var dynamicLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.isUserInteractionEnabled = true
        view.textAlignment = .center
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
```

그리고 버튼이 눌렸을 때 텍스트 필드를 비워주고 라벨에 문자열을 채워넣도록 합니다.

```swift
 @objc func sendButtondTapped(_ sender: UIButton) {
        dynamicLabel.text = textField.text
        textField.text = ""
 }
```

<img width="40%" src="https://user-images.githubusercontent.com/40784518/111070276-59f4fd00-8514-11eb-9bd6-1ebd3d82b30b.png"/>

 채팅 메시지처럼 다양한 문자열에 담겨있는 URL에 링크를 달기 위해 `NSAttributedString.Key`의 `.attachment` 키를 사용했습니다.  `.attachment` 키에 URL을 담고, 라벨이 tapped되었을 때 제스쳐가 감지한 `UILabel`의 `CGPoint`에 해당 attribute가 담겨있는지 확인하는 방법으로 구현하고자 했습니다. 그렇게 하면 어떤 문자열이던 URL인 경우라면 해당 URL로 링크를 걸어줄 수 있습니다. 

 개별 문자열 스타일을 적용하기 위해서 `NSAttributedString`을 사용하고 있었기에 금세 추가적인 attribute를 설정할 수 있었습니다. 그리고 `UITapGestureRecognizer`를 이용해서 `UILabel` 중 tapped된 `CGPoint`를 알아내는 것 또한 가능했습니다. 하지만 입력된 포지션에 따라 라벨의 문자열의 인덱스를 반환하는 함수가 필요했습니다. 



여러번의 시행착오 끝에 아래와 같은 함수를 구현했습니다. 

```swift
extension UILabel {
  /// 입력된 포지션에 따라 라벨의 문자열의 인덱스 반환
  /// - Parameter point: 인덱스 값을 알고 싶은 CGPoint
    func textIndex(at point: CGPoint) -> Int? {
        guard let attributedText = attributedText else { return nil }

        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: self.bounds.size)
        let textStorage = NSTextStorage(attributedString: attributedText)

        let paragraph = NSMutableParagraphStyle()
        if let paragraphStyle = textStorage.attribute(
            .paragraphStyle, at: 0, effectiveRange: nil
        ) as? NSParagraphStyle {
            paragraph.setParagraphStyle(paragraphStyle)
        }
        paragraph.alignment = textAlignment
				textStorage.addAttribute(
            .paragraphStyle,
            value: paragraph,
            range: NSRange(location: 0, length: textStorage.length)
        )
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
```



그리고 `UITapGestureRecognizer`를 이용해 터치된 포지션을 확인하기 이전에 `UILabel`에 스타일과 관련한 속성과 입력된 문자열이 `URL`인지 확인해 attatchment에 `URL`을 담아주는 코드를 작성합니다.

```swift
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
```



문자열에 URL이 담겨있는지 여부는 `NSRegularExpression`의 서브클래스인 `NSDataDetector`로 판단합니다. 

`NSTextCheckingResult` 타입인 변수 `m`에 `url`이 담긴 경우 `urlAttributes[.attatchment]`에 `url`을 할당합니다. 그리고 앞서 선언된 `mutableString`에 `attributes`를 지정합니다. 그럼 아래처럼 URL인 부분과 그렇지 않은 부분에 구분되어 스타일이 적용됩니다.

<img width="40%" src="https://user-images.githubusercontent.com/40784518/111071739-eb676d80-851a-11eb-8962-be3207628238.png"/>

하지만 지금은 링크를 눌러도 아무런 변화가 일어나지 않습니다. 이제는 아까 만들어둔 CGPoint를 반환하는 함수를 이용할 때입니다.

```swift
@objc func dynamicLabelTapped(_ sender: UITapGestureRecognizer) {
  let point = sender.location(in: dynamicLabel)

  guard let selectedIndex = dynamicLabel.textIndex(at: point) else { return }

  guard let attr = dynamicLabel.attributedText?.attributes(at: selectedIndex, effectiveRange: nil),
  let url = attr[.attachment] as? URL else { return }
  present(url: url.absoluteString)
}
```



`textIndex(at:)` 메서드를 이용해 `position`을 기반으로 터치된 부분의 라벨의 인덱스를 가져옵니다. 그럼 `dynamicLabel`의 속성들에 `.attachment` 속성이 담겨있고 `URL` 타입인 경우 웹 화면을 띄워주도록 합니다

<img width="30%" src="https://user-images.githubusercontent.com/40784518/111072041-3b92ff80-851c-11eb-9832-cc4727eb7ed7.gif"/>

그럼 위처럼 고정되지 않은 문자열에 스타일 적용 + 링크 띄워주기가 가능해집니다.!



만들면서 이미 있는 바퀴를 재발명할 필요가 있을까? 라는 생각도 잠깐 들었지만 글 서론에 이야기했던 것처럼 관리되지 않는 라이브러리에 의존성도 덜어내고 어떻게 구현할 지 고민하고 공부 할 겸 나름 즐거운 마음으로 했던 작업이었습니다. 



### References

- https://stackoverflow.com/questions/19417776/how-do-i-locate-the-cgrect-for-a-substring-of-text-in-a-uilabel
- 회사 코드 쪼끔
- attatchment에 url 담아보라 조언 주신 분