# Design Programming Language

## Notes 

Dali is a nice name. Doesn't seem to be taken other than Salvador Dali.

Devoid of normal control flow
- Iteration (for, while, etc.) is done though infinite sequences
    - 1.0 => ( repeat 1.0 ) => ( 1.0 1.0 1.0 1.0 ... )
    - ( 1.0 2.0 ) => ( repeat ( 1.0 2.0 ) ) => ( 1.0 2.0 1.0 2.0 ... )
    - true => ( repeat true ) => ( true true true true ... )
- Branching (if-elseif-else, switch, etc.) is done though ???

- Reserved variables
    - x => current x value in iteration
    - y => current y value in iteration
    - i => current first index in iteration
    - j => current second index in iteration

## Core Language

- features
	- dynamic typing?
	- automatic memory management
- primitives
	- boolean
	- number
	- string
- operators
	- arithmetic 
		- add +
		- subtract -
		- multiply *
		- divide /
		- negate -
	- comparison 
		- equality
		- lessThan
		- lessThanOfEqual 
		- greaterThan
		- greaterThanOfEqual
	- logical 
		- negation !
		- and
		- or
- variables?
	- define
- control flow?
	- switch
- functions?
	- macro
- closures?
- classes?

## Standard Library

- collection
	- list
	- map 
- color
	- hsva
	- rgba
- constant
	- pi?
	- e?
- function 
	- define
	- draw 
	- print
	- range
- geometry
	- bezier
	- circle
	- ellipse
	- line
	- point
	- polygon
	- rectangle
	- square
- isometry
	- glide-reflect
	- reflect
	- rotate
	- translate (should this generate a sequence of points)
- lattice (bravais)
	- hexagonal
	- oblique 
	- rectangular (centered-rectangular, square)
- noise
	- perlin
	- simplex
- random
	- gaussian 
	- log-normal
	- uniform
- series
	- arithmetic
	- fourier
	- geometric
	- harmonic

