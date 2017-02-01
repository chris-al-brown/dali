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
// 02/01/2017
// Source string locations for tokens and errors
// -----------------------------------------------------------------------------

import Foundation

public struct Source {

    public struct Location {
        
        /// Single character
        public init(line: Int, column: Int) {
            self.lines = line..<line+1
            self.columns = (start: column, stop: column+1)
        }
        
        /// Single line string
        public init(line: Int, columns: Range<Int>) {
            self.lines = line..<line+1
            self.columns = (start: columns.lowerBound, stop: columns.upperBound)
        }
        
        /// Multi line string
        public init(lines: Range<Int>, columnStart: Int, columnStop: Int) {
            self.lines = lines
            self.columns = (start: columnStart, stop: columnStop)
        }
        
        /// Get the source string selection
        public func source(from string: String) -> String {
//        let lexeme = String(source.unicodeScalars[start..<current])
            return ""
        }
        
        public let lines: Range<Int>
        public let columns: (start: Int, stop: Int)
    }
}

extension Source.Location: CustomStringConvertible {
    
    public var description: String {
        if lines.count == 1 {
            /// Single line
            if columns.stop - columns.start == 1 {
                /// Single character
                return "[line: \(lines.lowerBound), column: \(columns.start)]"
            } else {
                /// Multiple characters
                return "[line: \(lines.lowerBound), columns: \(columns.start)-\(columns.stop)]"
            }
        } else {
            /// Multiple lines
            return "[lines: \(lines.lowerBound)-\(lines.upperBound), columns: \(columns.start)-\(columns.stop)]"
        }
    }
}
