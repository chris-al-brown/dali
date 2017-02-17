<center> 
    <h1>dali</h1> 
</center>

<p align="center">
    <img src="https://img.shields.io/badge/platform-osx-lightgrey.svg" alt="Platform">
    <img src="https://img.shields.io/badge/language-swift-orange.svg" alt="Language">
    <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License">
</p>

<p align="center">
    <a href="#requirements">Requirements</a>
    <a href="#installation">Installation</a>
    <a href="#usage">Usage</a>
    <a href="#references">References</a>
    <a href="#language">Language</a>
    <a href="#license">License</a>
</p>

dali is a ...

## Requirements

- Xcode
    - Version: **8.2.1 (8C1002)**
    - Language: **Swift 3.0**
- OS X
    - Latest SDK: **macOS 10.12**
    - Deployment Target: **macOS 10.10**

## Installation

## Usage

## Language

The grammar of the language is given by the following EBNF grammar:

```
 program        → statement* eos
 
 statement      → expression ',' expression
                | expression eol
 
 expression     → binary
                | unary
                | group
                | literal
 
 binary         → expression '[' expression ']'
                | expression '(' keywords? ')'
                | expression (':' | '+' | '-' | '*' | '/' | '=' | '<' | '>' | '&' | '|' ) expression

 keywords       → identifier ':' expression ( ',' identifier ':' expression )*
 
 unary          → ( '!' | '+' | '-' ) expression

 group          → '(' expression ')'
 
 literal        → boolean
                | function
                | list
                | map
                | number
                | string
                | variable
 
 boolean        → 'true' | 'false'
 
 function       → '{' '(' arguments? ')' '|' expression* '}'

 arguments      → identifier ( ',' identifier )*
 
 list           → '[' elements? ']'
 
 elements       → expression ( ',' expression )*
 
 map            → '{' keywords? '}'
 
 number         → digit+ ( '.' digit+ )?
 
 string         → '"' ^( '"' | eol )* '"'

 variable       → identifier | reserved

 identifier     → alpha ( alpha | digit )*

 keyword        → 'pi' | 'e'
 
 alpha          → 'a' ... 'z' | 'A' ... 'Z' | '_'
 
 digit          → '0' ... '9'
 
 eol            → '\n'
 
 eos            → <end of stream>

```

## References

1. [Crafting Interpreters](http://www.craftinginterpreters.com)

2. [LLVM Tutorial](http://llvm.org/docs/tutorial/index.html)

3. [Building a LISP from scratch with Swift](https://www.uraimo.com/2017/02/05/building-a-lisp-from-scratch-with-swift/)

4. [Let’s Build a Compiler](http://blog.analogmachine.org/2011/09/20/lets-build-a-compiler/)

5. [PL/0](https://en.wikipedia.org/wiki/PL/0)

6. [Extended Bachus-Naur form](https://en.wikipedia.org/wiki/Extended_Backus–Naur_form)

7. [ANSI Escape codes](https://en.wikipedia.org/wiki/ANSI_escape_code)

8. [Parsing expressions by precedence climbing](http://eli.thegreenplace.net/2012/08/02/parsing-expressions-by-precedence-climbing)

## License

dali is released under the [MIT License](LICENSE.md).
