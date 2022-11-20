# Chapter 3 - Common Programming Concepts

## Constants

* Constants are values that are bound to a name and not allowed to
  change.
* You declare constants using the `const` keyword instead of the `let`
  keyword, and the type of the value must be annotated.
* In Rust, constants can be set only to a constant expression, not the
  result of a function call or any other value that could only be
  computed at runtime.

Example:

``` rust
const MAX_POINTS: u32 = 100_000;
```

## Shadowing

``` rust
fn main() {
    let x = 5;

    let x = x + 1; // shadow the first x

    let x = x * 2; // shadow the second x

    println!("The value of x is: {}", x);
}
```

Difference between `mut` and shadowing is that because we’re
effectively creating a new variable when we use the let keyword again,
we can change the type of the value but reuse the same name.

## Data types

Rust has two kinds of data types:

### Scalar types

A scalar type represents a single value. Rust has four primary scalar
types: integers, floating-point numbers, Booleans, and characters.

* Signed integer: i8, i16, i32, i64, i128, isize
* Unsigned integer: u8, u16, u32, u64, u128, usize
* Floating point: f32, f64
* Boolean: bool
* Character: char

Rust’s char type is four bytes in size and represents a Unicode Scalar
Value.

### Compound types

Compound types can group multiple values into one type. Rust has two
primitive compound types: tuples and arrays.

```
let tuple: (i32, f64, u8) = (500, 6.4, 1);
```

Unlike a tuple, every element of an array must have the same
type. Arrays in Rust are different from arrays in some other languages
because arrays in Rust have a fixed length, like tuples.

```
let a: [i32; 5] = [1, 2, 3, 4, 5];
```

Another way of writing arrays:

``` rust
let a = [3; 5];
let b = [3, 3, 3, 3, 3]; // equivalent as a array
let first = a[0]; // Access element
```

Note that all the types discussed above are stored in stack.

## Functions

Some examples:

``` rust
fn main() {
    another_function(5, 6);
}

fn another_function(x: i32, y: i32) {
    println!("The value of x is: {}", x);
    println!("The value of y is: {}", y);
}

fn plus_one(x: i32) -> i32 {
    x + 1
}
```

## Control Flow

### If Expressions

``` rust
fn main() {
    let number = 3;

    if number < 5 {
        println!("condition was true");
    } else {
        println!("condition was false");
    }
}
```

### loop construct

``` rust
loop {
  println!("again!");
}
 ```

### while loop

``` rust
while number != 0 {
     println!("{}!", number);

     number = number - 1;
 }
```

### for loop

``` rust
fn main() {
    let a = [10, 20, 30, 40, 50];

    for element in a.iter() {
        println!("the value is: {}", element);
    }
}
```
