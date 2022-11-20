# Chapter 15 - Smart Pointers

* A pointer is a general concept for a variable that contains an address
in memory. This address refers to, or “points at,” some other data.
* Smart pointers, on the other hand, are data structures that not only
  act like a pointer but also have additional metadata and
  capabilities.
* Some examples of smart pointers:
  - Reference counting smart pointer
  - String (metadata is capactiy and ensure that it is valid UTF-8)
  - Vec<T>

Smart pointers are usually implemented using structs. The
characteristic that distinguishes a smart pointer from an ordinary
struct is that smart pointers implement the `Deref` and `Drop` traits.

## Box<T>

* Boxes allow you to store data on the heap rather than the
  stack. What remains on the stack is the pointer to the heap data.

Usecase of Boxes:
* When you have a type whose size can’t be known at compile time.
* When you have a large amount of data and you want to transfer
  ownership but ensure the data won’t be copied when you do so
* When you want to own a value and you care only that it’s a type that
  implements a particular trait rather than being of a specific type

## Enabling recursive types with Boxes

``` rust
enum List {
    Cons(i32, Box<List>),
    Nil,
}

use crate::List::{Cons, Nil};

fn main() {
    let list = Cons(1,
        Box::new(Cons(2,
            Box::new(Cons(3,
                Box::new(Nil))))));
}
```

## Deref Trait

This program doesn't compile:

``` rust
struct MyBox<T>(T);

impl<T> MyBox<T> {
    fn new(x: T) -> MyBox<T> {
        MyBox(x)
    }
}

fn main() {
    let x = 5;
    let y = MyBox::new(x);

    assert_eq!(5, x);
    assert_eq!(5, *y); // The line which causes compile errors
}
```

This is the change required to make it compile:

``` rust
use std::ops::Deref;

impl<T> Deref for MyBox<T> {
    type Target = T;

    fn deref(&self) -> &T {
        &self.0
    }
}
```

## Implicit Deref Coercions with Functions and Methods

Deref coercion converts a reference to a type that implements `Deref`
into a reference to a type that `Deref` can convert the original type
into.

Deref coercion is a convenience that Rust performs on arguments to
functions and methods.

With deref coercion, a program like this will compile successfully:

``` rust
fn hello(name: &str) {
    println!("Hello, {}!", name);
}

fn main() {
    let m = MyBox::new(String::from("Rust"));
    hello(&m);
}
```

If you didn't have deref coercion, you have to write the above code
like this:

``` rust
fn hello(name: &str) {
    println!("Hello, {}!", name);
}

fn main() {
    let m = MyBox::new(String::from("Rust"));
    hello(&(*m)[..]);
}
```

## Deref Coercion and Mutability

Similar to how you use the `Deref` trait to override the * operator on
immutable references, you can use the `DerefMut` trait to override the *
operator on mutable references.

Rust does deref coercion when it finds types and trait implementations
in three cases:

* From `&T` to `&U` when `T: Deref<Target=U>`
* From `&mut T` to `&mut U` when `T: DerefMut<Target=U>`
* From `&mut T` to `&U` when `T: Deref<Target=U>`

The first two cases are the same except for mutability. In the third
one, Rust will also coerce a mutable reference to an immutable
one. But note that reverse is not possible.

## Drop trait

You can provide an implementation for the `Drop` trait on any type, and
the code you specify can be used to release resources like files or
network connections.

`Box<T>` customizes `Drop` to deallocate the space on the heap that
the box points to.

Example implementation:

``` rust
struct CustomSmartPointer {
    data: String,
}

impl Drop for CustomSmartPointer {
    fn drop(&mut self) {
        println!("Dropping CustomSmartPointer with data `{}`!", self.data);
    }
}

fn main() {
    let c = CustomSmartPointer { data: String::from("my stuff") };
    let d = CustomSmartPointer { data: String::from("other stuff") };
    println!("CustomSmartPointers created.");
}
```

You can also drop a value early by using `std::mem::drop`.

## Rc<T>, the Reference counted Smart Pointer

In the majority of cases, ownership is clear: you know exactly which
variable owns a given value. However, there are cases when a single
value might have multiple owners. To enable multiple ownership, Rust
has a type called `Rc<T>`.

The type `Rc<T>` provides shared ownership of a value of type T,
allocated in the heap. Invoking `clone` on `Rc` produces a new pointer to
the same value in the heap.

`Rc` uses non-atomic reference counting. This means that overhead is
very low, but an `Rc` cannot be sent between threads.

Example code:

``` rust
enum List {
    Cons(i32, Rc<List>),
    Nil,
}

use crate::List::{Cons, Nil};
use std::rc::Rc;

fn main() {
    let a = Rc::new(Cons(5, Rc::new(Cons(10, Rc::new(Nil)))));
    let b = Cons(3, Rc::clone(&a));
    let c = Cons(4, Rc::clone(&a));
}
```

## RefCell<T> and Interior mutability

* [Reddit summary on Cell and RefCell](https://www.reddit.com/r/rust/comments/755a5x/i_have_finally_understood_what_cell_and_refcell/)
* RefCell is a mutable memory location with dynamically checked borrow rules.
* Mutating the value inside an immutable value is the interior mutability pattern.

Let's actually check if it has dynamically checked borrow rules. In
Rust, that means a single variable cannot have two owners. Let's check it with `RefCell`:


``` rust
use std::cell::RefCell;

fn main() {
    let c = RefCell::new(5);
    println!("{:?}", c);
    let b = c.into_inner();
    println!("{:?}", b);
}
```


The above program works fine. But you can introduce a compile error like this:

``` rust
use std::cell::RefCell;

fn main() {
    let c = RefCell::new(5);
    println!("{:?}", c);
    let b = c.into_inner();
    println!("{:?}", b);
    println!("{:?}", c); // offending line
}
```

or like this:

``` rust
use std::cell::RefCell;

fn main() {
    let c = RefCell::new(5);
    println!("{:?}", c);
    let b = c.into_inner();
    println!("{:?}", b);
    let b = c.into_inner(); // offending line
}
```

But both the above are compile errors. What does it mean by
dynamically checked ? Let's see an example of mixing mutable and
immutable reference.

``` rust
use std::cell::RefCell;

fn main() {
    let c = RefCell::new(5);
    {
        let mut b = c.borrow_mut();
        *b = 6;
        *b = 7;
    }
    println!("{:?}", c); // prints 7
}
```

The above problem works fine. But let's have two mutable reference at
once:

``` rust
use std::cell::RefCell;

fn main() {
    let c = RefCell::new(5);
    {
        let mut b = c.borrow_mut();
        *b = 6;
        *b = 7;
        let mut d = c.borrow_mut();
        *d = 8;
    }
    println!("{:?}", c);
}
```

``` shellsession
$ ./rust4
thread 'main' panicked at 'already borrowed: BorrowMutError', src/libcore/result.rs:1084:5
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace.
```

Now that causes panic as expected. Another way to cause panic is to
mix mutable and immutable reference. Let's do that:

``` rust
use std::cell::RefCell;

fn main() {
    let c = RefCell::new(5);
    {
        let mut b = c.borrow_mut();
        *b = 6;
        *b = 7;
        let d = c.borrow();
        println!("{:?}", d);
    }
    println!("{:?}", c);
}
```

And bam, even that crashes at runtime.

[Sample usecase of RefCell<T>](https://stackoverflow.com/questions/36413364/as-i-can-make-the-vector-is-mutable-inside-struct)

## Combining Rc<T> and RefCell<T>

A common way to use RefCell<T> is in combination with Rc<T>. Recall
that Rc<T> lets you have multiple owners of some data, but it only
gives immutable access to that data. If you have an Rc<T> that holds a
RefCell<T>, you can get a value that can have multiple owners and that
you can mutate!

``` rust
#[derive(Debug)]
enum List {
    Cons(Rc<RefCell<i32>>, Rc<List>),
    Nil,
}

use crate::List::{Cons, Nil};
use std::rc::Rc;
use std::cell::RefCell;

fn main() {
    let value = Rc::new(RefCell::new(5));

    let a = Rc::new(Cons(Rc::clone(&value), Rc::new(Nil)));

    let b = Cons(Rc::new(RefCell::new(6)), Rc::clone(&a));
    let c = Cons(Rc::new(RefCell::new(10)), Rc::clone(&a));

    *value.borrow_mut() += 10;

    println!("a after = {:?}", a);
    println!("b after = {:?}", b);
    println!("c after = {:?}", c);
}
```

## Reference cycle example

``` rust
use std::rc::Rc;
use std::cell::RefCell;
use crate::List::{Cons, Nil};

#[derive(Debug)]
enum List {
    Cons(i32, RefCell<Rc<List>>),
    Nil,
}

impl List {
    fn tail(&self) -> Option<&RefCell<Rc<List>>> {
        match self {
            Cons(_, item) => Some(item),
            Nil => None,
        }
    }
}

fn main() {
    let a = Rc::new(Cons(5, RefCell::new(Rc::new(Nil))));

    println!("a initial rc count = {}", Rc::strong_count(&a));
    println!("a next item = {:?}", a.tail());

    let b = Rc::new(Cons(10, RefCell::new(Rc::clone(&a))));

    println!("a rc count after b creation = {}", Rc::strong_count(&a));
    println!("b initial rc count = {}", Rc::strong_count(&b));
    println!("b next item = {:?}", b.tail());

    if let Some(link) = a.tail() {
        *link.borrow_mut() = Rc::clone(&b);
    }

    println!("b rc count after changing a = {}", Rc::strong_count(&b));
    println!("a rc count after changing a = {}", Rc::strong_count(&a));

    // Uncomment the next line to see that we have a cycle;
    // it will overflow the stack
    // println!("a next item = {:?}", a.tail());
}
```

The reference cycle happens because of this:

```
a = 5, Nil
b = 10, a
```

Now after the initialization `let Some(link) = a.tail()`, the above
structure changes into this:

```
a = 5, b
b = 10, a
```

## Weak

Weak is a version of `Rc` that holds a non-owning reference to the
managed value. The value is accessed by calling `upgrade` on the `Weak`
pointer, which returns an `Option<Rc<T>>`.

Some experiments:

use std::rc::Rc;

``` rust
fn main() {
    let c = Rc::new(5);
    println!("{}", Rc::strong_count(&c)); // 1
    let f = Rc::clone(&c);
    println!("{}", Rc::strong_count(&c)); // 2
    println!("{}", Rc::weak_count(&c));   // 0
    let weak_f = Rc::downgrade(&c);
    println!("{}", Rc::strong_count(&c)); // 2
    println!("{}", Rc::weak_count(&c));   // 1
}
```

Usecase for Weak:

``` rust
struct Node {
    value: i32,
    parent: RefCell<Weak<Node>>,
    children: RefCell<Vec<Rc<Node>>>,
}
```

A node will be able to refer to its parent node but doesn’t own its parent.
