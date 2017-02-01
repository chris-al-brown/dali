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
// Geometry.swift
// 01/30/2017
// Geometric primitives
// -----------------------------------------------------------------------------

import Foundation

public struct Geometry {}

extension Geometry {
    
    /// Geometric regions
    public enum Region {
        case interior
        case exterior
        case boundary
    }
}

/// Distance metrics
public enum Metric {
    case chebyshev
    case euclidean
    case manhattan
}

public struct Point {
    
    public var x: Double
    public var y: Double
}

public struct Size {
    
    public var width: Double
    public var height: Double
}

public struct Line {
    
    public var from: Point
    public var to: Point
}

public struct Circle {
    
    public var origin: Point
    public var radius: Double
}

public struct Rectangle {
    
    public var origin: Point
    public var size: Size
}
