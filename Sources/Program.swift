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
// Program.swift
// 01/20/2017
// Represents an instance of a program
// -----------------------------------------------------------------------------

import Foundation

public struct Program {

    /// Log
    private static func log(message: String, separator: String = " ", terminator: String = "\n") {
        print(message, separator:separator, terminator:terminator)
    }
    
    /// Log
    private static func log(token: Token) {
        print(token)
    }
    
    /// Log
    private static func log(error: ScannerError) {
        print(error)
    }

    /// Parse
    private static func parse(source: String, tokenHandler: (Token) -> Void, errorHandler: (ScannerError) -> Void) {
        let scanner = Scanner(source:source)
        let (tokens, errors) = scanner.scan()
        if errors.isEmpty {
            tokens.forEach(tokenHandler)
        } else {
            errors.forEach(errorHandler)
        }
    }

    /// REPL
    public static func repl() {
        log(message:"-------------------------------------")
        log(message:" dali REPL v0.1.0 (press ^C to exit) ")
        log(message:"-------------------------------------")
        while true {
            log(message:"> ", separator:"", terminator:"")
            guard let input = readLine(strippingNewline:true) else { continue }
            parse(source:input, tokenHandler:log, errorHandler:log)
        }
    }
    
    /// Script
    public static func script(atPath path: String) throws {
        let contents = try String(contentsOfFile:path, encoding:.utf8)
        parse(source:contents, tokenHandler:log, errorHandler:log)
    }
}
