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
// main.swift
// 01/20/2017
// Main program entry point for the command line tool
// -----------------------------------------------------------------------------

import Foundation

public typealias Source = String

public typealias SourceIndex = Source.UnicodeScalarIndex

public typealias SourceLocation = Range<SourceIndex>

public typealias SourceScalar = UnicodeScalar

public final class Dali {
    
    private enum Mode {
        case file(String)
        case help
        case repl
    }
    
    public enum Status {
        case success
        case failure
    }
    
    public init(_ args: [String]) {
        self.runtime = Runtime()
        let environment = ProcessInfo.processInfo.environment
        self.iterm = environment["XPC_SERVICE_NAME"]?.range(of:"Xcode") == nil
        switch args.count {
        case 1:
            self.mode = .repl
        case 2:
            switch args[1] {
            case "-h", "--help":
                self.mode = .help
            default:
                self.mode = .file(args[1])
            }
        default:
            self.mode = .help
        }
    }
    
    public func columns(in source: Source, for location: SourceLocation) -> ClosedRange<Int> {
        var currentIndex = location.lowerBound
        /// Fix for eol to be at end of a line
        if source.unicodeScalars[currentIndex] == "\n" && currentIndex != source.unicodeScalars.startIndex {
            currentIndex = source.unicodeScalars.index(before:currentIndex)
        }
        while source.unicodeScalars[currentIndex] != "\n" && currentIndex != source.unicodeScalars.startIndex {
            currentIndex = source.unicodeScalars.index(before:currentIndex)
        }
        /// Fix for the first line that needs to be shifted by one
        let offset = currentIndex == source.unicodeScalars.startIndex ? 1 : 0
        let column = source.unicodeScalars.distance(from:currentIndex, to:location.lowerBound) + offset
        let length = source.unicodeScalars.distance(from:location.lowerBound, to:location.upperBound)
        return column...(column + length - 1)
    }
    
    public func compile(_ source: Source) -> Status {
        do {
            let scanner = Scanner(source)
            let parser = Parser(try scanner.scan())
            try runtime.evaluate(try parser.parse())
            return .success
        } catch let issue as RuntimeError {
            error(issue, in:source)
        } catch let issue as ScannerError {
            error(issue, in:source)
        } catch let issue as ParserError {
            error(issue, in:source)
        } catch {
            fatalError("Unexpected error: \(error)")
        }
        return .failure
    }
    
    public func error(_ message: String, separator: String = "", terminator: String = "\n") {
        if iterm {
            print("\u{001B}[0;31m\(message)\u{001B}[0;0m", separator:separator, terminator:terminator)
        } else {
            print(message, separator:separator, terminator:terminator)
        }
    }
    
    private func error(_ message: String, in source: Source, at location: SourceLocation) {
        let row = line(in:source, for:location)
        let col = columns(in:source, for:location)
        let cols = (col.count == 1) ? "column: \(col.lowerBound)" : "columns: \(col.lowerBound)-\(col.upperBound)"
        switch mode {
        case .file(let filename):
            error("file: '\(filename)', line: \(row.number), \(cols)")
        default:
            error("file: <stdin>, line: \(row.number), \(cols)")
        }
        error(row.source)
        error(String(repeating:" ", count:col.lowerBound - 1) + String(repeating:"^", count:col.count))
        error(message)
    }
    
    public func error(_ issue: RuntimeError, in source: Source) {
        error("RuntimeError: \(issue.description)", in:source, at:issue.location)
    }
    
    public func error(_ issue: ParserError, in source: Source) {
        error("SyntaxError: \(issue.description)", in:source, at:issue.location)
    }
    
    public func error(_ issue: ScannerError, in source: Source) {
        error("SyntaxError: \(issue.description)", in:source, at:issue.location)
    }
    
    public func exit(with status: Status) -> Never {
        switch status {
        case .success:
            Darwin.exit(EXIT_SUCCESS)
        case .failure:
            Darwin.exit(EXIT_FAILURE)
        }
    }
    
    public func line(in source: Source, for location: SourceLocation) -> (source: Source, number: Int) {
        var line = 1
        var currentIndex = source.unicodeScalars.startIndex
        while currentIndex != location.lowerBound && currentIndex != source.unicodeScalars.endIndex {
            if source.unicodeScalars[currentIndex] == "\n" {
                line += 1
            }
            currentIndex = source.unicodeScalars.index(after:currentIndex)
        }
        var sindex = location.lowerBound
        if source.unicodeScalars[sindex] == "\n" && sindex != source.unicodeScalars.startIndex {
            sindex = source.unicodeScalars.index(before:sindex)
        }
        while source.unicodeScalars[sindex] != "\n" && sindex != source.unicodeScalars.startIndex {
            sindex = source.unicodeScalars.index(before:sindex)
        }
        var eindex = location.upperBound
        while source.unicodeScalars[eindex] != "\n" && eindex != source.unicodeScalars.endIndex {
            eindex = source.unicodeScalars.index(after:eindex)
        }
        return (source: String(source.unicodeScalars[sindex..<eindex]).trimmingCharacters(in:.newlines), number: line)
    }
    
    public func log(_ message: String, terminator: String = "\n") {
        print(message, separator:"", terminator:terminator)
    }
    
    public func log(_ expression: ASTExpression) {
        print(expression.description)
    }
    
    public func log(_ object: RuntimeObject) {
        print(object.description)
    }
    
    public func log(_ statement: ASTStatement) {
        print(statement.description)
    }
    
    public func premature(_ source: Source) -> Bool {
        var curly = 0
        var round = 0
        var square = 0
        for scalar in source.unicodeScalars {
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
    
    public func prompt(premature: Bool = false) {
        if premature {
            print("...", separator:"", terminator:" ")
        } else {
            print(">>>", separator:"", terminator:" ")
        }
    }

    public func run() -> Never {
        switch mode {
        case .file(let name):
            do {
                let source = try String(contentsOfFile:name, encoding:.utf8)
                let result = compile(source)
                exit(with:result)
            } catch let issue {
                error("ScriptError: \(issue.localizedDescription)")
                exit(with:.failure)
            }
        case .repl:
            log("-------------------------------------")
            log(" dali REPL v1.0.0 (press ^C to exit) ")
            log("-------------------------------------")
            var source = ""
            while true {
                prompt()
                while true {
                    guard let line = readLine(strippingNewline:false) else { break }
                    source += line
                    if premature(source) {
                        prompt(premature:true)
                    } else {
                        let _ = compile(source)
                        source.removeAll(keepingCapacity:true)
                        break
                    }
                }
            }
        case .help:
            log("Usage:")
            log("    dali")
            log("    dali <script>")
            log("    dali (-h | --help)")
            exit(with:.success)
        }
    }
    
    private let runtime: Runtime
    private let iterm: Bool
    private let mode: Mode
}

/// Start the program
let dali = Dali(CommandLine.arguments)
dali.run()


