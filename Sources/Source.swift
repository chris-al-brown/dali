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
    
    public typealias Index = String.UnicodeScalarIndex
    
    public struct Location {
        
        public init(_ range: Range<Index>) {
            self.range = range
        }
        
        fileprivate let range: Range<Index>
    }

    public typealias Scalar = UnicodeScalar
    
    public init(_ input: Input, _ storage: String) {
        self.input = input
        self.storage = storage
    }

    public subscript(position: Index) -> Scalar {
        return storage.unicodeScalars[position]
    }
    
    public subscript(location: Location) -> String {
        return String(storage.unicodeScalars[location.range])
    }
    
    
    
    
    
    public func format(error description: String, for location: Location) -> String {
        let row = line(for:location)
        let col = columns(for:location)
        var output = ""
        if col.count == 1 {
            output += "file: \(input), line: \(row), column: \(col.lowerBound)" + "\n"
        } else {
            output += "file: \(input), line: \(row), columns: \(col.lowerBound)-\(col.upperBound)" + "\n"
        }
        output += context(for:location) + "\n"
        output += String(repeating:" ", count:col.lowerBound - 1) + String(repeating:"^", count:col.count) + "\n"
        output += description
        return output
    }

    private func context(for location: Location) -> String {
        var sindex = location.range.lowerBound
        while self[sindex] != "\n" && sindex != startIndex {
            sindex = index(before:sindex)
        }
        var eindex = location.range.upperBound
        while self[eindex] != "\n" && eindex != endIndex {
            eindex = index(after:eindex)
        }
        if sindex < eindex && self[sindex] == "\n" {
            sindex = index(after:sindex)
        }
        return String(storage.unicodeScalars[sindex..<eindex])
    }

    private func columns(for location: Location) -> ClosedRange<Int> {
        var currentIndex = location.range.lowerBound
        /// Fixes eol to be at end of a line and not at the beginning of the next
        if self[currentIndex] == "\n" && currentIndex != startIndex {
            currentIndex = index(before:currentIndex)
        }
        while self[currentIndex] != "\n" && currentIndex != startIndex {
            currentIndex = index(before:currentIndex)
        }
        /// Fix for the first line that needs to be shifted by one
        let offset = currentIndex == startIndex ? 1 : 0
        let column = distance(from:currentIndex, to:location.range.lowerBound) + offset
        let length = distance(from:location.range.lowerBound, to:location.range.upperBound)
        return column...(column + length - 1)
    }

    private func line(for location: Location) -> Int {
        var line = 1
        var currentIndex = startIndex
        while currentIndex != location.range.lowerBound && currentIndex != endIndex {
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
}
