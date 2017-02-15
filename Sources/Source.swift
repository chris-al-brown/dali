// -----------------------------------------------------------------------------
// Copyright (c) 2017, Christopher A. Brown (chris-al-brown)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// dali
// Source.swift
// 02/15/2017
// Represents a source string
// -----------------------------------------------------------------------------

import Foundation

public struct Source: BidirectionalCollection {
    
    /// ANSI colors for pretty printing
    public enum Color: String {
        case black      = "\u{001B}[0;30m"
        case red        = "\u{001B}[0;31m"
        case green      = "\u{001B}[0;32m"
        case yellow     = "\u{001B}[0;33m"
        case blue       = "\u{001B}[0;34m"
        case magenta    = "\u{001B}[0;35m"
        case cyan       = "\u{001B}[0;36m"
        case white      = "\u{001B}[0;37m"
        
        public func apply(_ item: Any) -> String {
            return "\(rawValue)\(item)\u{001B}[0;0m"
        }
    }
    
    public typealias Index = String.UnicodeScalarIndex

    public enum Input: CustomStringConvertible {
        case file(String)
        case stdin
        
        public var description: String {
            switch self {
            case .file(let value):
                return "'\(value)'"
            case .stdin:
                return "<stdin>"
            }
        }
    }
    
    public typealias Location = Range<Index>

    public typealias Scalar = UnicodeScalar
    
    public init(input: Input, source: String, supportsColor: Bool) {
        self.input = input
        self.storage = source
        self.supportsColor = supportsColor
    }

    public subscript(position: Index) -> Scalar {
        return storage.unicodeScalars[position]
    }
    
    public func columns(for location: Location) -> ClosedRange<Int> {
        var currentIndex = location.lowerBound
        /// Fix for eol to be at end of a line
        if self[currentIndex] == "\n" && currentIndex != startIndex {
            currentIndex = index(before:currentIndex)
        }
        while self[currentIndex] != "\n" && currentIndex != startIndex {
            currentIndex = index(before:currentIndex)
        }
        /// Fix for the first line that needs to be shifted by one
        let offset = currentIndex == startIndex ? 1 : 0
        let column = distance(from:currentIndex, to:location.lowerBound) + offset
        let length = distance(from:location.lowerBound, to:location.upperBound)
        return column...(column + length - 1)
    }

    public func extract(_ location: Location) -> String {
        return String(storage.unicodeScalars[location])
    }
    
    public func extractLine(_ location: Location) -> String {
        /// Fix for eol as starting character
        var sindex = location.lowerBound
        if self[sindex] == "\n" && sindex != startIndex {
            sindex = index(before:sindex)
        }
        while self[sindex] != "\n" && sindex != startIndex {
            sindex = index(before:sindex)
        }
        var eindex = location.upperBound
        while self[eindex] != "\n" && eindex != endIndex {
            eindex = index(after:eindex)
        }
        return String(storage.unicodeScalars[sindex..<eindex]).trimmingCharacters(in:.newlines)
    }

    public func format(error message: String, using tokens: [Token], at location: Location) -> String {
        var lineStartIndex = location.lowerBound
        if self[lineStartIndex] == "\n" && lineStartIndex != startIndex {
            lineStartIndex = index(before:lineStartIndex)
        }
        while self[lineStartIndex] != "\n" && lineStartIndex != startIndex {
            lineStartIndex = index(before:lineStartIndex)
        }
        var truncatedSource = extract(startIndex..<lineStartIndex)
        if supportsColor && !truncatedSource.isEmpty {
            let colors: [Token.Category: Color] = [
                .boolean: .yellow,
                .comment: .black,
                .keyword: .cyan,
                .number: .blue,
                .operator: .green,
                .string: .magenta,
                .variable: .cyan
            ]
            for token in tokens.reversed() {
                if token.location.upperBound <= lineStartIndex {
                    let category = token.lexeme.category
                    let substring = truncatedSource.unicodeScalars[token.location]
                    if let color = colors[category] {
                        truncatedSource.unicodeScalars.replaceSubrange(token.location, with:color.apply(substring).unicodeScalars)
                    }
                }
            }
        }
        return (truncatedSource + "\n" + format(error:message, at:location)).trimmingCharacters(in:.newlines)
    }
    
    public func format(error message: String, at location: Location) -> String {
        let row = line(for:location)
        let col = columns(for:location)
        var output = ""
        output += "file: \(input), line: \(row), "
        output += (col.count == 1) ? "column: \(col.lowerBound)\n" : "columns: \(col.lowerBound)-\(col.upperBound)\n"
        output += extractLine(location) + "\n"
        output += String(repeating:" ", count:col.lowerBound - 1) + String(repeating:"^", count:col.count) + "\n"
        output += message
        return supportsColor ? Color.red.apply(output) : output
    }

    public func line(for location: Location) -> Int {
        var line = 1
        var currentIndex = startIndex
        while currentIndex != location.lowerBound && currentIndex != endIndex {
            if self[currentIndex] == "\n" {
                line += 1
            }
            currentIndex = index(after:currentIndex)
        }
        return line
    }
    
    public func index(after i: Index) -> Index {
        return storage.unicodeScalars.index(after:i)
    }
    
    public func index(before i: Index) -> Index {
        return storage.unicodeScalars.index(before:i)
    }

    public var startIndex: Index {
        return storage.unicodeScalars.startIndex
    }
    
    public var endIndex: Index {
        return storage.unicodeScalars.endIndex
    }
    
    private let input: Input
    private let storage: String
    private let supportsColor: Bool
}
