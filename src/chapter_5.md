# Chapter 5 - Using Structs

To define a struct, we enter the keyword struct and name the entire
struct.

``` rust
struct User {
    username: String,
    email: String,
    sign_in_count: u64,
    active: bool,
}
```

Immutable instance of the Struct:

``` rust
let user1 = User {
    email: String::from("someone@example.com"),
    username: String::from("someusername123"),
    active: true,
    sign_in_count: 1,
};
```

Mutuable instance of the Struct:

``` rust
let mut user1 = User {
    email: String::from("someone@example.com"),
    username: String::from("someusername123"),
    active: true,
    sign_in_count: 1,
};

user1.email = String::from("anotheremail@example.com");
```

## Some syntax sugars

Field init shorthand:

``` rust
fn build_user(email: String, username: String) -> User {
    User {
        email,
        username,
        active: true,
        sign_in_count: 1,
    }
}
```

Stuct update syntax:

``` rust
let user2 = User {
    email: String::from("another@example.com"),
    username: String::from("anotherusername567"),
    ..user1
};
```

## Tuple Structs

You can also define structs that look similar to tuples, called tuple
structs. Tuple structs have the added meaning the struct name provides
but don’t have names associated with their fields; rather, they just
have the types of the fields.

``` rust
struct Color(i32, i32, i32);
struct Point(i32, i32, i32);

let black = Color(0, 0, 0);
let origin = Point(0, 0, 0);
```

## Method Syntax

Methods are different from functions in that they’re defined within
the context of a struct (or an enum or a trait object), and their
first parameter is always self, which represents the instance of the
struct the method is being called on.

Example code:

``` rust
#[derive(Debug)]
struct Rectangle {
    width: u32,
    height: u32,
}

impl Rectangle {
    fn area(&self) -> u32 {
        self.width * self.height
    }
}

fn main() {
    let rect1 = Rectangle { width: 30, height: 50 };

    println!(
        "The area of the rectangle is {} square pixels.",
        rect1.area()
    );
}
```

In the signature for area, we use &self instead of rectangle:
&Rectangle because Rust knows the type of self is Rectangle due to
this method’s being inside the impl Rectangle context. Note that we
still need to use the & before self, just as we did in
&Rectangle. Methods can take ownership of self, borrow self immutably
as we’ve done here, or borrow self mutably, just as they can any other
parameter.

## Associated functions

Another useful feature of impl blocks is that we’re allowed to define
functions within impl blocks that don’t take self as a
parameter. These are called associated functions because they’re
associated with the struct.

Associated functions are often used for constructors that will return
a new instance of the struct:

``` rust
impl Rectangle {
    fn square(size: u32) -> Rectangle {
        Rectangle { width: size, height: size }
    }
}
```

To call this associated function, we use the :: syntax with the struct
name; `let sq = Rectangle::square(3);` is an example.
