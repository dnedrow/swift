// RUN: %target-parse-verify-swift

enum Exception : Error { case A }

// Basic syntax ///////////////////////////////////////////////////////////////
func bar() throws -> Int { return 0 }
func foo() -> Int { return 0 }


// Currying ///////////////////////////////////////////////////////////////////
func curry1() {

}

func curry1Throws() throws {

}

func curry2() -> () -> () {
	return curry1
}

func curry2Throws() throws -> () -> () {
	return curry1
}

func curry3() -> () throws -> () {
	return curry1Throws
}

func curry3Throws() throws -> () throws -> () {
	return curry1Throws
}

var a : () -> () -> () = curry2
var b : () throws -> () -> () = curry2Throws
var c : () -> () throws -> () = curry3
var d : () throws -> () throws -> () = curry3Throws

// Partial application ////////////////////////////////////////////////////////

protocol Parallelogram {
  static func partialApply1(_ a: Int) throws
}

func partialApply2<T: Parallelogram>(_ t: T) {
  _ = T.partialApply1
}

// Overload resolution/////////////////////////////////////////////////////////
func barG<T>(_ t : T) throws -> T { return t }
func fooG<T>(_ t : T) -> T { return t }

var bGE: (_ i: Int) -> Int = barG // expected-error{{invalid conversion from throwing function of type '(_) throws -> _' to non-throwing function type '(Int) -> Int'}}
var bg: (_ i: Int) throws -> Int = barG
var fG: (_ i: Int) throws -> Int = fooG

func fred(_ callback: (UInt8) throws -> ()) throws { }

func rachel() -> Int { return 12 }
func donna(_ generator: () throws -> Int) -> Int { return generator() } // expected-error {{call can throw, but it is not marked with 'try' and the error is not handled}}

_ = donna(rachel)

func barT() throws -> Int { return 0 } // expected-note{{}}
func barT() -> Int { return 0 } // expected-error{{invalid redeclaration of 'barT()'}}

func fooT(_ callback: () throws -> Bool) {} //OK
func fooT(_ callback: () -> Bool) {}

// Throwing and non-throwing types are not equivalent.
struct X<T> { }
func specializedOnFuncType1(_ x: X<(String) throws -> Int>) { }
func specializedOnFuncType2(_ x: X<(String) -> Int>) { }
func testSpecializedOnFuncType(_ xThrows: X<(String) throws -> Int>,
                               xNonThrows: X<(String) -> Int>) {
  specializedOnFuncType1(xThrows) // ok
  specializedOnFuncType1(xNonThrows) // expected-error{{cannot convert value of type 'X<(String) -> Int>' to expected argument type 'X<(String) throws -> Int>'}}
  specializedOnFuncType2(xThrows)  // expected-error{{cannot convert value of type 'X<(String) throws -> Int>' to expected argument type 'X<(String) -> Int>'}}
  specializedOnFuncType2(xNonThrows) // ok
}

// Subtyping
func subtypeResult1(_ x: (String) -> ((Int) -> String)) { }
func testSubtypeResult1(_ x1: (String) -> ((Int) throws -> String),
                        x2: (String) -> ((Int) -> String)) {
  subtypeResult1(x1) // expected-error{{cannot convert value of type '(String) -> ((Int) throws -> String)' to expected argument type '(String) -> ((Int) -> String)'}}
  subtypeResult1(x2)
}

func subtypeResult2(_ x: (String) -> ((Int) throws -> String)) { }
func testSubtypeResult2(_ x1: (String) -> ((Int) throws -> String),
                        x2: (String) -> ((Int) -> String)) {
  subtypeResult2(x1)
  subtypeResult2(x2)
}

func subtypeArgument1(_ x: (_ fn: ((String) -> Int)) -> Int) { }
func testSubtypeArgument1(_ x1: (_ fn: ((String) -> Int)) -> Int,
                          x2: (_ fn: ((String) throws -> Int)) -> Int) {
  subtypeArgument1(x1)
  subtypeArgument1(x2)
}

func subtypeArgument2(_ x: (_ fn: ((String) throws -> Int)) -> Int) { }
func testSubtypeArgument2(_ x1: (_ fn: ((String) -> Int)) -> Int,
                          x2: (_ fn: ((String) throws -> Int)) -> Int) {
  subtypeArgument2(x1) // expected-error{{cannot convert value of type '(((String) -> Int)) -> Int' to expected argument type '(((String) throws -> Int)) -> Int'}}
  subtypeArgument2(x2)
}

// Closures
var c1 = {() throws -> Int in 0}
var c2 : () throws -> Int = c1 // ok
var c3 : () -> Int = c1 // expected-error{{invalid conversion from throwing function of type '() throws -> Int' to non-throwing function type '() -> Int'}}
var c4 : () -> Int = {() throws -> Int in 0} // expected-error{{invalid conversion from throwing function of type '() throws -> Int' to non-throwing function type '() -> Int'}}
var c5 : () -> Int = { try c2() } // expected-error{{invalid conversion from throwing function of type '() throws -> Int' to non-throwing function type '() -> Int'}}
var c6 : () throws -> Int = { do { _ = try c2() } ; return 0 }
var c7 : () -> Int = { do { try c2() } ; return 0 } // expected-error{{invalid conversion from throwing function of type '() throws -> _' to non-throwing function type '() -> Int'}}
var c8 : () -> Int = { do { _ = try c2()  } catch _ { var x = 0 } ; return 0 }
var c9 : () -> Int = { do { try c2()  } catch Exception.A { var x = 0 } ; return 0 }// expected-error{{invalid conversion from throwing function of type '() throws -> _' to non-throwing function type '() -> Int'}}
var c10 : () -> Int = { throw Exception.A; return 0 } // expected-error{{invalid conversion from throwing function of type '() throws -> _' to non-throwing function type '() -> Int'}}
var c11 : () -> Int = { try! c2() }
var c12 : () -> Int? = { try? c2() }

// Initializers
struct A {
    init(doomed: ()) throws {}
}

func fi1() throws {
    A(doomed: ()) // expected-error {{call can throw but is not marked with 'try'}} // expected-warning{{unused}}
}

struct B {
 init() throws {}
 init(foo: Int) {}
}

B(foo: 0) // expected-warning{{unused}}
