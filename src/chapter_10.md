# Chapter 10 - Generic Types, Traits and Lifetimes

Generics are abstract stand-ins for concrete types or other properties.

## Generic Structs

``` rust
struct Point<T> {
    x: T,
    y: T,
}

fn main() {
    let integer = Point { x: 5, y: 10 };
    let float = Point { x: 1.0, y: 4.0 };
}
```

## Enum Structs

``` rust
enum Option<T> {
    Some(T),
    None,
}
```

## Generics in method definitions

``` rust
struct Point<T> {
    x: T,
    y: T,
}

impl<T> Point<T> {
    fn x(&self) -> &T {
        &self.x
    }
}

fn main() {
    let p = Point { x: 5, y: 10 };

    println!("p.x = {}", p.x());
}
```

### Traits: Defining shared behaviour

A trait tells the Rust compiler about functionality a particular type
has and can share with other types.

``` rust
pub struct Tweet {
    pub username: String,
    pub content: String,
    pub reply: bool,
    pub retweet: bool,
}

pub trait Summary {
    fn summarize(&self) -> String;
}

impl Summary for Tweet {
    fn summarize(&self) -> String {
        format!("{}: {}", self.username, self.content)
    }
}
```

## Default implementations

``` rust
pub trait Summary {
    fn summarize(&self) -> String {
        String::from("(Read more...)")
    }
}
```

To use a default implementation:

``` rust
impl Summary for Tweet {}
```

## Traits as Parameters

``` rust
pub fn notify(item: impl Summary) {
    println!("Breaking news! {}", item.summarize());
}
```

## Trait Bound syntax

The `impl Trait` syntax in the above example works for straightforward
cases. It is actually a syntax sugar for a longer form which is called
a trait bound:

``` rust
pub fn notify<T: Summary>(item: T) {
    println!("Breaking news! {}", item.summarize());
}
```

## Specifying Multiple Trait Bounds with the + Syntax

``` rust
pub fn notify(item: impl Summary + Display) {
```

Or in the trait bound syntax form:

``` rust
pub fn notify<T: Summary + Display>(item: T) {
```

## Clearer Trait Bounds with where Clauses

``` rust
fn some_function<T: Display + Clone, U: Clone + Debug>(t: T, u: U) -> i32 {
```

can be written as:

``` rust
fn some_function<T, U>(t: T, u: U) -> i32
    where T: Display + Clone,
          U: Clone + Debug
{
```

## Returning Types that Implement Traits

``` rust
fn returns_summarizable() -> impl Summary {
    Tweet {
        username: String::from("horse_ebooks"),
        content: String::from("of course, as you probably already know, people"),
        reply: false,
        retweet: false,
    }
}
```

### Validating references with Lifetimes

Every reference in Rust has a lifetime, which is the scope for which
that reference is valid.

## The Borrow Checker

The Rust compiler has a borrow checker that compares scopes to
determine whether all borrows are valid.

``` rust
{
    let r;                // ---------+-- 'a
                          //          |
    {                     //          |
        let x = 5;        // -+-- 'b  |
        r = &x;           //  |       |
    }                     // -+       |
                          //          |
    println!("r: {}", r); //          |
}                         // ---------+
```

Here, we’ve annotated the lifetime of r with 'a and the lifetime of x
with 'b. As you can see, the inner 'b block is much smaller than the
outer 'a lifetime block. At compile time, Rust compares the size of
the two lifetimes and sees that r has a lifetime of 'a but that it
refers to memory with a lifetime of 'b. The program is rejected
because 'b is shorter than 'a: the subject of the reference doesn’t
live as long as the reference.

## Generic Lifetimes in Functions

This code will result in compile error:

``` rust
fn longest(x: &str, y: &str) -> &str {
    if x.len() > y.len() {
        x
    } else {
        y
    }
}
```

The error:

``` shellsession
error[E0106]: missing lifetime specifier
 --> src/main.rs:1:33
  |
1 | fn longest(x: &str, y: &str) -> &str {
  |                                 ^ expected lifetime parameter
  |
  = help: this function's return type contains a borrowed value, but the
signature does not say whether it is borrowed from `x` or `y`
```

Rust can't tell whether the reference being returned refers to `x` or
`y`. To fix this error, we need to add generic lifetime parameters.

## Lifetime Annotation Syntax

* Lifetime annotations don’t change how long any of the references live.
* Lifetime annotations describe the relationships of the lifetimes of
  multiple references to each other without affecting the lifetimes.

Lifetime annotations have a slightly unusual syntax: the names of
lifetime parameters must start with an apostrophe (') and are usually
all lowercase and very short, like generic types. Most people use the
name 'a. We place lifetime parameter annotations after the & of a
reference, using a space to separate the annotation from the
reference’s type.

``` rust
&i32        // a reference
&'a i32     // a reference with an explicit lifetime
&'a mut i32 // a mutable reference with an explicit lifetime
```

## Lifetime Annotations in Function Signatures

As with generic type parameters, we need to declare generic lifetime
parameters inside angle brackets between the function name and the
parameter list.

``` rust
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() {
        x
    } else {
        y
    }
}
```

## Lifetime Annotations in Struct Definitions

So far, we’ve only defined structs to hold owned types. It’s possible
for structs to hold references, but in that case we would need to add
a lifetime annotation on every reference in the struct’s definition.

``` rust
struct ImportantExcerpt<'a> {
    part: &'a str,
}
```

## Lifetime Elision

You’ve learned that every reference has a lifetime and that you need
to specify lifetime parameters for functions or structs that use
references. But there are some code which seem to compile without
lifetime parameters:

``` rust
fn first_word(s: &str) -> &str {
    let bytes = s.as_bytes();

    for (i, &item) in bytes.iter().enumerate() {
        if item == b' ' {
            return &s[0..i];
        }
    }

    &s[..]
}
```

While the above code compiles with the recent version of Rust, it
would have not compiled in older versions of Rust.

After writing a lot of Rust code, the Rust team found that Rust
programmers were entering the same lifetime annotations over and over
in particular situations. These situations were predictable and
followed a few deterministic patterns. The developers programmed these
patterns into the compiler’s code so the borrow checker could infer
the lifetimes in these situations and wouldn’t need explicit
annotations.

The patterns programmed into Rust’s analysis of references are called
the lifetime elision rules.

Lifetimes on function or method parameters are called `input lifetimes`,
and lifetimes on return values are called `output lifetimes`.

The compiler uses three rules to figure out what lifetimes references
have when there aren’t explicit annotations. The first rule applies to
input lifetimes, and the second and third rules apply to output
lifetimes. These rules apply to fn definitions as well as impl
blocks:
* The first rule is that each parameter that is a reference gets its
  own lifetime parameter. In other words, a function with one
  parameter gets one lifetime parameter: `fn foo<'a>(x: &'a i32)`; a
  function with two parameters gets two separate lifetime parameters:
  `fn foo<'a, 'b>(x: &'a i32, y: &'b i32)`; and so on.
* The second rule is if there is exactly one input lifetime parameter,
  that lifetime is assigned to all output lifetime parameters: `fn
  foo<'a>(x: &'a i32) -> &'a i32`.
* The third rule is if there are multiple input lifetime parameters,
  but one of them is `&self` or `&mut self` because this is a method,
  the lifetime of `self` is assigned to all output lifetime
  parameters. This third rule makes methods much nicer to read and
  write because fewer symbols are necessary.

## Lifetime Annotations in Method Definitions

When we implement methods on a struct with lifetimes, we use the same
syntax as that of generic type parameters:

``` rust
impl<'a> ImportantExcerpt<'a> {
    fn level(&self) -> i32 {
        3
    }
}
```

The lifetime parameter declaration after `impl` and its use after the
type name are required, but we’re not required to annotate the
lifetime of the reference to `self` because of the first elision rule.

Example where the third lifetime elision rule applies:

``` rust
impl<'a> ImportantExcerpt<'a> {
    fn announce_and_return_part(&self, announcement: &str) -> &str {
        println!("Attention please: {}", announcement);
        self.part
    }
}
```

There are two input lifetimes, so Rust applies the first lifetime
elision rule and gives both `&self` and announcement their own
lifetimes. Then, because one of the parameters is `&self`, the return
type gets the lifetime of `&self`, and all lifetimes have been
accounted for.

## The Static Lifetime

One special lifetime we need to discuss is `'static`, which means that
this reference can live for the entire duration of the program. All
string literals have the `'static` lifetime, which we can annotate as
follows:

``` rust
let s: &'static str = "I have a static lifetime.";
```

The text of this string is stored directly in the program’s binary,
which is always available. Therefore, the lifetime of all string
literals is `'static.`
