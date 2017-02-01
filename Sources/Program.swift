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

    /// Parse
    private static func compile(source: String) {
        let scanner = Scanner(source:source)
        switch scanner.scan() {
        case .success(let results):
            print("--------------")
            print("Scanner Tokens")
            print("--------------")
            results.forEach { print("\($1) token: \($0)") }
            let parser = Parser(tokens:results)
            switch parser.parse() {
            case .success(let results):
                print("------------------")
                print("Parser Expressions")
                print("------------------")
                results.forEach { print("\($1) expression: \($0)") }
            case .failure(let errors):
                print("-------------")
                print("Parser Errors")
                print("-------------")
                errors.forEach { print("\($1) Error: \($0)") }
            }
        case .failure(let errors):
            print("--------------")
            print("Scanner Errors")
            print("--------------")
            errors.forEach { print("\($1) Error: \($0)") }
        }
    }

    /// REPL
    public static func repl() {
        print("-------------------------------------")
        print(" dali REPL v0.1.0 (press ^C to exit) ")
        print("-------------------------------------")
        while true {
            print("> ", separator:"", terminator:"")
            guard let input = readLine(strippingNewline:true) else { continue }
            compile(source:input)
        }
    }
    
    /// Script
    public static func script(atPath path: String) throws {
        let contents = try String(contentsOfFile:path, encoding:.utf8)
        compile(source:contents)
    }
}
