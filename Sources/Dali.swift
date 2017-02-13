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
// Dali.swift
// 02/10/2017
// Represents an instance of a running program or script
// -----------------------------------------------------------------------------

import Foundation

public struct Dali {
    
    /// Available exit statues
    public enum Status {
        case success
        case failure(String)
    }

    /// Compile a program from a source string
    public static func compile(source: String) {
        let scanner = Scanner(source:source)
        switch scanner.scan() {
        case .success(let tokens):
            tokens.forEach { token in print(token) }
            let parser = Parser(tokens:tokens)
            switch parser.parse() {
            case .success(let expressions):
                expressions.forEach { expression in print(expression) }
            case .failure(let errors):
                errors.forEach { error in print(error) }
            }
        case .failure(let errors):
            errors.forEach { error in print(error) }
        }
        print()
    }
    
    /// Exit a running program
    public static func exit(with status: Status) -> Never {
        switch status {
        case .success:
            Darwin.exit(EXIT_SUCCESS)
        case .failure(let reason):
            print(reason)
            Darwin.exit(EXIT_FAILURE)
        }
    }
    
    /// Read-Eval-Print Loop
    public static func REPL() -> Never {
        print("-------------------------------------")
        print(" dali REPL v0.1.0 (press ^C to exit) ")
        print("-------------------------------------")
        while true {
            print(">", terminator:" ")
            guard let input = readLine(strippingNewline:false) else { continue }
            compile(source:input)
        }
    }
}


/// REPL old stuff

//    public func run() -> Never {
//        print("-------------------------------------")
//        print(" dali REPL v0.1.0 (press ^C to exit) ")
//        print("-------------------------------------")
//        while true {
//            print("1  ", terminator:"\r")
//            fflush(stdout)
//            sleep(1)
//            print("2  ", terminator:"\r")
//            fflush(stdout)
//            sleep(1)
//            print("3  ", terminator:"\r")
//            fflush(stdout)
//            sleep(1)
//            print(">", terminator:"  ")
//
//            guard let input = readLine(strippingNewline:true) else { continue }
//            compile(source:input)
//        }
//    }

//    /// Read single input characters
//    /// http://stackoverflow.com/questions/25551321/xcode-swift-command-line-tool-reads-1-char-from-keyboard-without-echo-or-need-to
//    private static func read() -> Int? {
//        var key: Int = 0
//        let c: cc_t = 0
//        let cct = (c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c) // Set of 20 Special Characters
//        var oldt: termios = termios(c_iflag: 0, c_oflag: 0, c_cflag: 0, c_lflag: 0, c_cc: cct, c_ispeed: 0, c_ospeed: 0)
//        tcgetattr(STDIN_FILENO, &oldt) // 1473
//        var newt = oldt
//        newt.c_lflag = 1217  // Reset ICANON and Echo off
//        tcsetattr(STDIN_FILENO, TCSANOW, &newt)
//        key = Int(getchar())  // works like "getch()"
//        tcsetattr(STDIN_FILENO, TCSANOW, &oldt)
//        return key
//    }

//    /// REPL
//    public static func repl() {
//        print("-------------------------------------")
//        print(" dali REPL v0.1.0 (press ^C to exit) ")
//        print("-------------------------------------")
//
//        var buffer: [CChar] = []
//        while let key = read() {
//            if key == Int(EOF) {
//                print("EOF")
//            } else {
//                print("now!")
//                buffer.append(CChar(key))
//                print(String(cString:&buffer))
//                buffer.removeAll(keepingCapacity:true)
//            }
//        }
//    }
