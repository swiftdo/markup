//
//  main.swift
//  markup
//
//  Created by laijihua on 2021/4/13.
//

import Foundation

private extension CharacterSet {
    static let delimiters = CharacterSet(charactersIn: "*_~")
    
    static let whitespaceAndPunctuation = CharacterSet.whitespacesAndNewlines
        .union(CharacterSet.punctuationCharacters)
        .union(CharacterSet(charactersIn: "~"))

    func contains(of character: Character) -> Bool {
        let res = self.contains(String(character).unicodeScalars.first!)
        print("\(self)-\(character)-\(res)")
        return res
    }

}

extension Character {
    static let space: Character = " "
}

// tokenization\parsing\rendering

enum MarkupToken: CustomStringConvertible {
    /// 内容
    case text(String)
    /// 左边定界符
    case leftDelimiter(Character)
    /// 右边定界符
    case rightDelimiter(Character)
    
    var description: String {
        switch self {
        case .text(let value):
            return value
        case .leftDelimiter(let value):
            return String(value)
        case .rightDelimiter(let value):
            return String(value)
        }
    }
}

enum MarkupNode {
    case text(String)
    case strong([MarkupNode]) // 粗体
    case emphasis([MarkupNode]) // 斜体
    case delete([MarkupNode]) // 删除
    
    init?(delimiter: Character, children: [MarkupNode]) {
        switch delimiter {
        case "*":
            self = .strong(children)
        case "_":
            self = .emphasis(children)
        case "~":
            self = .delete(children)
        default:
            return nil
        }
    }
}

struct MarkupTokenizer {
    private let input: String
    
    private var currentIndex: String.Index
    
    /// Keeps track of the left delimiters detected
    private var leftDelimiters: [Character] = []
    
    init(string: String) {
        self.input = string
        self.currentIndex = string.startIndex
    }
    
    mutating func nextToken() -> MarkupToken? {
        guard let c = current else {
            return nil
        }
        
        var token: MarkupToken?
        if CharacterSet.delimiters.contains(of: c) {
            token = scan(delimiter: c)
        } else {
            token = scanText()
        }
        
        if token == nil {
            token = .text(String(c))
            advance()
        }
        return token
    }
    
    /// 当前字符
    private var current: Character? {
        guard currentIndex < input.endIndex else {return nil}
        return input[currentIndex]
    }
    
    /// 上一个字符
    private var previous: Character? {
        guard currentIndex > input.startIndex else {return nil}
        let index = input.index(before: currentIndex)
        return input[index]
    }
    
    /// 下一个字符
    private var next: Character? {
        guard currentIndex < input.endIndex else {return nil}
        let index = input.index(after: currentIndex)
        guard index < input.endIndex else {return nil}
        return input[index]
    }
    
    /// 扫描
    private mutating func scan(delimiter: Character) -> MarkupToken? {
        return scanLeft(delimiter: delimiter) ?? scanRight(delimiter: delimiter)
    }
    
    /// 扫描左边
    private mutating func scanLeft(delimiter: Character) -> MarkupToken? {
        let p = previous ?? .space
        
        guard let n = next else {
            return nil
        }
        
        guard CharacterSet.whitespaceAndPunctuation.contains(of: p) &&
                !CharacterSet.whitespacesAndNewlines.contains(of: n) &&
                !leftDelimiters.contains(delimiter) else {
            return nil
        }
        
        leftDelimiters.append(delimiter)
        advance()
        return .leftDelimiter(delimiter)
    }
    
    /// 扫描右边
    private mutating func scanRight(delimiter: Character) -> MarkupToken? {
        guard let p = previous else {return nil}
        let n = next ?? .space
        
        guard !CharacterSet.whitespacesAndNewlines.contains(of: p) && CharacterSet.whitespaceAndPunctuation.contains(of: n) && leftDelimiters.contains(delimiter) else {
            return nil
        }
        
        while !leftDelimiters.isEmpty {
            if leftDelimiters.popLast() == delimiter {
                break
            }
        }
        advance()
        return .rightDelimiter(delimiter)
    }
    
    /// 扫描文本
    private mutating func scanText() -> MarkupToken? {
        let startIndex = currentIndex
        scanUntil { CharacterSet.delimiters.contains(of: $0) }
        
        guard currentIndex > startIndex else {
            return nil
        }
        return .text(String(input[startIndex..<currentIndex]))
    }
    
    /// 扫描直到
    private mutating func scanUntil(_ predicate:(Character) -> Bool) {
        while currentIndex < input.endIndex && !predicate(input[currentIndex]) {
            advance()
        }
    }
    
    /// 移动下标
    private mutating func advance() {
        currentIndex = input.index(after: currentIndex)
    }
}


struct MarkupParser {
    private var tokenizer: MarkupTokenizer
    private var openDelimiters: [Character] = []
    
    
    static func parse(text: String) -> [MarkupNode] {
        var parser = MarkupParser(text: text)
        return parser.parse();
    }
    
    private init(text: String) {
        tokenizer = MarkupTokenizer(string: text)
    }
    
    
    private mutating func parse() -> [MarkupNode] {
        var elements: [MarkupNode] = []
        
        while let token = tokenizer.nextToken() {
            switch token {
            case let .text(text):
                elements.append(.text(text))
            case let .leftDelimiter(delimiter):
                openDelimiters.append(delimiter)
                elements.append(contentsOf: parse())
            case let .rightDelimiter(delimter) where openDelimiters.contains(delimter):
                guard let containerNode = close(delimiter: delimter, elements: elements) else {
                    fatalError("there is no markup node for \(delimter)")
                }
                return [containerNode]
            default:
                elements.append(.text(token.description))
            }
        }
        let textElements: [MarkupNode] = openDelimiters.map {.text(String($0))}
        elements.insert(contentsOf: textElements, at: 0)
        openDelimiters.removeAll()
        return elements
    }
    
    private mutating func close(delimiter: Character, elements: [MarkupNode]) -> MarkupNode? {
        var newElements = elements
        while openDelimiters.count > 0 {
            let openingDelimiter = openDelimiters.popLast()!
            if openingDelimiter == delimiter {
                break
            } else {
                newElements.insert(.text(String(openingDelimiter)), at: 0)
            }
        }
        return MarkupNode(delimiter: delimiter, children: newElements)
    }
}


final class MarkupRenderer {
    
    func render(text: String) -> String {
        let elements = MarkupParser.parse(text: text)
        return elements.map { (node) -> String in
            return render(node: node)
        }.joined()
    }
    
    func render(node: MarkupNode) -> String {
        switch node {
        case .text(let text):
            return text
        case .strong(let children):
            return "<strong>" + children.map { render(node: $0)}.joined() + "</strong>"
        case .emphasis(let children):
            return "<i>" + children.map { render(node: $0)}.joined() + "</i>"
        case .delete(let children):
            return "<del>" + children.map { render(node: $0)}.joined() + "</del>"
            
        }
    }
}

let str = "The *quick*, ~red~ brown fox jumps over a _*lazy dog*_."

print(MarkupRenderer().render(text: str))

