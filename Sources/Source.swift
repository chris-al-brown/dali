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
    
    public typealias Index = String.UnicodeScalarIndex

    public typealias Location = Range<Index>

    public typealias Scalar = UnicodeScalar
    
    public init(_ source: String, input file: String) {
        self.buffer = source
        self.file = file
    }

    public subscript(position: Index) -> Scalar {
        return buffer.unicodeScalars[position]
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
        return String(buffer.unicodeScalars[location])
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
        return String(buffer.unicodeScalars[sindex..<eindex]).trimmingCharacters(in:.newlines)
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
        return buffer.unicodeScalars.index(after:i)
    }
    
    public func index(before i: Index) -> Index {
        return buffer.unicodeScalars.index(before:i)
    }
    
    public var input: String {
        return file
    }
    
    public var needsContinuation: Bool {
        var curly = 0
        var round = 0
        var square = 0
        for scalar in self {
            switch scalar {
            case "{":
                curly += 1
            case "}":
                curly -= 1
            case "(":
                round += 1
            case ")":
                round -= 1
            case "[":
                square += 1
            case "]":
                square -= 1
            default:
                break
            }
        }
        return !(curly == 0 && round == 0 && square == 0)
    }
    
    public var startIndex: Index {
        return buffer.unicodeScalars.startIndex
    }
    
    public var endIndex: Index {
        return buffer.unicodeScalars.endIndex
    }
    
    private let buffer: String
    private let file: String
}
