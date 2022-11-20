# Chapter 19: Advanced Features

## Unsafe Superpowers

To switch to unsafe Rust, use the `unsafe` keyword and then start a new
block that holds the unsafe code. You can take four actions in unsafe
Rust, called unsafe superpowers, that you can’t in safe Rust. Those
superpowers include the ability to:

* Dereference a raw pointer
* Call an unsafe function or method
* Access or modify a mutable static variable
* Implement an unsafe trait

### Dereferencing a raw pointer

Raw pointers can be immutable or mutable and are written as:

* Immutable: *const T
* Mutable: *mut T

The asterisk isn’t the dereference operator; it’s part of the type
name.

Different from references and smart pointers, raw pointers:

* Are allowed to ignore the borrowing rules by having both immutable
  and mutable pointers or multiple mutable pointers to the same
  location
* Aren’t guaranteed to point to valid memory
* Are allowed to be null
* Don’t implement any automatic cleanup

Example:

``` rust
let mut num = 5;

let r1 = &num as *const i32;
let r2 = &mut num as *mut i32;

unsafe {
    println!("r1 is: {}", *r1);
    println!("r2 is: {}", *r2);
}
```

Another example which will likely lead to segmentation fault:

``` rust
let address = 0x012345usize;
let r = address as *const i32;
```

### Calling an Unsafe Function or method

Example:

``` rust
unsafe fn dangerous() {}

unsafe {
    dangerous();
}
```

The `unsafe` keyword in this context indicates the function has
requirements we need to uphold when we call this function, because
Rust can’t guarantee we’ve met these requirements. By calling an
`unsafe` function within an unsafe block, we’re saying that we’ve read
this function’s documentation and take responsibility for upholding
the function’s contracts.

### FFI

``` rust
extern "C" {
    fn abs(input: i32) -> i32;
}

fn main() {
    unsafe {
        println!("Absolute value of -3 according to C: {}", abs(-3));
    }
}
```

Within the `extern "C"` block, we list the names and signatures of
external functions from another language we want to call. The `"C"`
part defines which application binary interface (ABI) the external
function uses: the ABI defines how to call the function at the
assembly level. The "C" ABI is the most common and follows the C
programming language’s ABI.

### Accessing or Modifying a Mutable Static Variable

In Rust, global variables are called static variables.

``` rust
static HELLO_WORLD: &str = "Hello, world!";

fn main() {
    println!("name is: {}", HELLO_WORLD);
}
```

In the above example the variable type is `&'static str`. Since,
static variables can only store references with the `'static`
lifetime, you don't need to annotate it explicityly.

``` rust
static mut COUNTER: u32 = 0;

fn add_to_count(inc: u32) {
    unsafe {
        COUNTER += inc;
    }
}

fn main() {
    add_to_count(3);

    unsafe {
        println!("COUNTER: {}", COUNTER);
    }
}
```

### Implementing an Unsafe Trait

 A trait is unsafe when at least one of its methods has some invariant
 that the compiler can’t verify. We can declare that a trait is unsafe
 by adding the unsafe keyword before trait and marking the
 implementation of the trait as unsafe too.

``` rust
unsafe trait Foo {
    // methods go here
}

unsafe impl Foo for i32 {
    // method implementations go here
}
```

## Advanced Traits

### Specifying Placeholder Types in Trait Definitions with Associated Types

Associated types connect a type placeholder with a trait such that the
trait method definitions can use these placeholder types in their
signatures.

``` rust
pub trait Iterator {
    type Item;

    fn next(&mut self) -> Option<Self::Item>;
}
```

And it's implementation:

``` rust
impl Iterator for Counter {
    type Item = u32;

    fn next(&mut self) -> Option<Self::Item> {
        // --snip--
```

### Default Generic Type Parameters and Operator Overloading

When we use generic type parameters, we can specify a default concrete
type for the generic type. . The syntax for specifying a default type
for a generic type is `<PlaceholderType=ConcreteType>` when declaring
the generic type.

``` rust
trait Add<RHS=Self> {
    type Output;

    fn add(self, rhs: RHS) -> Self::Output;
}
```

If we don’t specify a concrete type for `RHS` when we implement the
`Add` trait, the type of `RHS` will default to `Self`, which will be
the type we’re implementing `Add` on.

Operator overloading is customizing the behavior of an operator (such
as +) in particular situations.

Rust doesn’t allow you to create your own operators or overload
arbitrary operators. But you can overload the operations and
corresponding traits listed in `std::ops` by implementing the traits
associated with the operator.

``` rust
use std::ops::Add;

struct Millimeters(u32);
struct Meters(u32);

impl Add<Meters> for Millimeters {
    type Output = Millimeters;

    fn add(self, other: Meters) -> Millimeters {
        Millimeters(self.0 + (other.0 * 1000))
    }
}
```

### Fully Qualified Syntax for Disambiguation: Calling Methods with the Same Name

``` rust
trait Pilot {
    fn fly(&self);
}

trait Wizard {
    fn fly(&self);
}

struct Human;

impl Pilot for Human {
    fn fly(&self) {
        println!("This is your captain speaking.");
    }
}

impl Wizard for Human {
    fn fly(&self) {
        println!("Up!");
    }
}

impl Human {
    fn fly(&self) {
        println!("*waving arms furiously*");
    }
}

fn main() {
    let person = Human;
    Pilot::fly(&person);
    Wizard::fly(&person);
    person.fly();
}
```

Example without the '&self' argument:

``` rust
trait Animal {
    fn baby_name() -> String;
}

struct Dog;

impl Dog {
    fn baby_name() -> String {
        String::from("Spot")
    }
}

impl Animal for Dog {
    fn baby_name() -> String {
        String::from("puppy")
    }
}

fn main() {
    println!("A baby dog is called a {}", Dog::baby_name()); // A baby dog is called a Spot
    println!("A baby dog is called a {}", <Dog as Animal>::baby_name()); // A baby dog is called a puppy
}
```

### Using Supertraits to Require One Trait’s Functionality Within Another Trait

Sometimes, you might need one trait to use another trait’s
functionality. In this case, you need to rely on the dependent trait
also being implemented. The trait you rely on is a supertrait of the
trait you’re implementing.

``` rust
use std::fmt;

trait OutlinePrint: fmt::Display {
    fn outline_print(&self) {
        let output = self.to_string();
        let len = output.len();
        println!("{}", "*".repeat(len + 4));
        println!("*{}*", " ".repeat(len + 2));
        println!("* {} *", output);
        println!("*{}*", " ".repeat(len + 2));
        println!("{}", "*".repeat(len + 4));
    }
}
```

`to_string` is a function implemented for `Display` trait.

### Using the Newtype Pattern to Implement External Traits on External Types

Orphan rule: We’re allowed to implement a trait on a type as long as
either the trait or the type are local to our crate.

You can overcome the above rule using the newtype pattern.

``` rust
use std::fmt;

struct Wrapper(Vec<String>);

impl fmt::Display for Wrapper {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "[{}]", self.0.join(", "))
    }
}

fn main() {
    let w = Wrapper(vec![String::from("hello"), String::from("world")]);
    println!("w = {}", w);
}
```

## Advanced Types

### Using the Newtype Pattern for Type Safety and Abstraction

Example: The `Millimeters` and `Meters` structs wrapped `u32` values
in a newtype.

### Creating Type Synonyms with Type Aliases

Rust provides the ability to declare a type alias to give an existing
type another name. For this we use the `type` keyword.

``` rust
type Kilometers = i32;
```

### The Never Type that Never Returns

Rust has a special type named `!` that’s known in type theory lingo as
the empty type because it has no values. We prefer to call it the
never type because it stands in the place of the return type when a
function will never return.

``` rust
fn bar() -> ! {
    // --snip--
}
```

Functions that return never are called diverging functions.

Example usage:

``` rust
let guess: u32 = match guess.trim().parse() {
    Ok(num) => num,
    Err(_) => continue,
};
```

The `continue` has a `!` value.

### Dynamically Sized Types and the Sized Trait

Dynamically sized types or DSTs or unsized types let us write code
using values whose size we can know only at runtime.

The following code won't compile:

``` rust
let s1: str = "Hello there!";
let s2: str = "How's it going?";
```

Rust needs to know how much memory to allocate for any value of a
particular type, and all values of a type must use the same amount of
memory. If Rust allowed us to write this code, these two str values
would need to take up the same amount of space. But they have
different lengths: s1 needs 12 bytes of storage and s2 needs 15. This
is why it’s not possible to create a variable holding a dynamically
sized type.

We make the types of s1 and s2 a &str rather than a str to make it
work. So although a `&T` is a single value that stores the memory
address of where the `T` is located, a `&str` is two values: the
address of the str and its length. As such, we can know the size of a
`&str` value at compile time: it’s twice the length of a `usize`.

To work with DSTs, Rust has a particular trait called the `Sized` trait
to determine whether or not a type’s size is known at compile time.

That is, a generic function definition like this:

``` rust
fn generic<T>(t: T) {
    // --snip--
}
```

is actually treated as though we had written this:

``` rust
fn generic<T: Sized>(t: T) {
    // --snip--
}
```

By default, generic functions will work only on types that have a
known size at compile time. However, you can use the following special
syntax to relax this restriction:

``` rust
fn generic<T: ?Sized>(t: &T) {
    // --snip--
}
```

A trait bound on `?Sized` is the opposite of a trait bound on `Sized`: we
would read this as “T may or may not be Sized.” This syntax is only
available for Sized, not any other traits.

## Advanced Functions and Closures

### Function Pointers

We can pass regular functions to functions using function
pointers. Functions coerce to the type `fn` (with a lowercase f), not
to be confused with the `Fn` closure trait. The `fn` type is called a
function pointer.

``` rust
fn add_one(x: i32) -> i32 {
    x + 1
}

fn do_twice(f: fn(i32) -> i32, arg: i32) -> i32 {
    f(arg) + f(arg)
}

fn main() {
    let answer = do_twice(add_one, 5);

    println!("The answer is: {}", answer);
}
```

Function pointers implement all three of the closure traits (Fn,
FnMut, and FnOnce), so you can always pass a function pointer as an
argument for a function that expects a closure. It’s best to write
functions using a generic type and one of the closure traits so your
functions can accept either functions or closures.

### Returning Closures

Closures are represented by traits, which means you can’t return
closures directly. A way to make it work:

``` rust
fn returns_closure() -> Box<dyn Fn(i32) -> i32> {
    Box::new(|x| x + 1)
}
```

Another way to make it work (not mentioned in the book):

``` rust
fn returns_closure() -> impl (Fn(i32) -> i32) {
    |x| x + 1
}

fn main() {
    let f = returns_closure();
    let g = f(3);
    println!("hello world");
    println!("hello world, {}", g);
}
```

## Macros

Rust has two kinds of Macros:
* Declarative macros with `macro_rules!`
* Procedural macros

There are three kinds of procedural macros:
* Custom `#[derive]` macros
* Attribute-like macros that define custom attributes usable on any item
* Function-like macros that look like function calls but operate on
  the tokens specified as their argument
