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
// Console.swift
// 02/23/2017
// Pretty formatting of expressions and errors
// -----------------------------------------------------------------------------

import Foundation

public struct Console {
    
    /// Checks whether Xcode spawned the process (i.e. ANSI color codes not supported in Xcode console)
    public enum Process: CustomStringConvertible {
        case terminal
        case xcode
        
        public init() {
            let environment = ProcessInfo.processInfo.environment
            let xcode = environment["XPC_SERVICE_NAME"]?.range(of:"Xcode") != nil
            self = xcode ? .xcode : .terminal
        }
        
        public var description: String {
            switch self {
            case .terminal:
                return "iterm"
            case .xcode:
                return "xcode"
            }
        }
    }
    
    public init() {
        self.process = Process()
        self.formatter = Formatter()
    }
    
    public func error(_ message: String, terminator: String = "\n") {
        if process == .terminal {
            print("\u{001B}[0;31m\(message)\u{001B}[0;0m", separator:"", terminator:terminator)
        } else {
            print(message, separator:"", terminator:terminator)
        }
    }
    
    public func error(_ issue: Interpreter.Error, in source: Source) {
        error(format(issue.description, in:source, at:issue.location))
    }

    public func error(_ issue: Parser.Error, in source: Source) {
        error(format(issue.description, in:source, at:issue.location))
    }
    
    public func error(_ issue: Scanner.Error, in source: Source) {
        error(format(issue.description, in:source, at:issue.location))
    }
    
    private func format(_ message: String, in source: Source, at location: Source.Location) -> String {
        let row = source.line(for:location)
        let col = source.columns(for:location)
        var output = ""
        output += "file: \(source.input), line: \(row), "
        output += (col.count == 1) ? "column: \(col.lowerBound)\n" : "columns: \(col.lowerBound)-\(col.upperBound)\n"
        output += source.extractLine(location) + "\n"
        output += String(repeating:" ", count:col.lowerBound - 1) + String(repeating:"^", count:col.count) + "\n"
        output += message
        return output
    }
    
    public func log(_ message: String, terminator: String = "\n") {
        print(message, separator:"", terminator:terminator)
    }
    
    public func log(_ expression: Expression) {
        print(formatter.visit(expression))
    }
    
    public func prompt(isContinuation: Bool = false) {
        if isContinuation {
            print("...", separator:"", terminator:" ")
        } else {
            print(">>>", separator:"", terminator:" ")
        }
    }
    
    private var process: Process
    private var formatter: Formatter
}

