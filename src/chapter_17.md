# Chapter 17 - OOP Features of Rust

* Objects contains Data and Behavior

structs and enums have data, and impl blocks provide methods on
structs and enums. Even though structs and enums with methods aren’t
called objects, they provide the same functionality, according to the
Gang of Four’s definition of objects.

* Encapsulation that Hides Implementation Details

We can use the `pub` keyword to decide which modules, types,
functions, and methods in our code should be public, and by default
everything else is private. This provides encapsulation.

* Inheritance as a Type System and as Code Sharing

Rust doesn't have the usual inheritance property found in other OOP
langues which allows an object to inherit parent's object data and
behavior without having to define them again. But it has trait
mechanism and polymorphism to enable code reuse.

## Using Trait Objects That Allow for Values of Different Types

Objective: A library that iterates through a list of items and calls
`draw` method on each of them. Note that the some items may have been
created by the user of the library itself rather than the library.

OOP solution: Have a class named `Component` with a method named
`draw` on it. Other classes will inherit this class and may provide
custom behavior. How will Rust solve this kind of problem ?

A rust solution for the above problem:

```
pub trait Draw {
    fn draw(&self);
}

pub struct Screen {
    pub components: Vec<Box<dyn Draw>>,
}

impl Screen {
    pub fn run(&self) {
        for component in self.components.iter() {
            component.draw();
        }
    }
}
```

The above vector is of type `Box<dyn Draw>`, which is a trait object; it’s a
stand-in for any type inside a Box that implements the `Draw` trait.

You might be wondering why not a solution like this which involves
generic type and trait bounds:

```
pub struct Screen<T: Draw> {
    pub components: Vec<T>,
}

impl<T> Screen<T>
    where T: Draw {
    pub fn run(&self) {
        for component in self.components.iter() {
            component.draw();
        }
    }
}
```

The above style won't work in all scenarios. It will only work for
homogenous collections.

## Object safety is required for Trait Object

A trait is object safe if all the methods defined in the trait have
the following properties:

* The return type isn’t `Self`.
* There are no generic type parameters.

## Implementing an OODP

Desired behavior we want:

``` rust
use blog::Post;

fn main() {
    let mut post = Post::new();

    post.add_text("I ate a salad for lunch today");
    assert_eq!("", post.content());

    post.request_review();
    assert_eq!("", post.content());

    post.approve();
    assert_eq!("I ate a salad for lunch today", post.content());
}
```

The implementation for the above behavior:

``` rust
pub struct Post {
    state: Option<Box<dyn State>>,
    content: String,
}

impl Post {
    pub fn new() -> Post {
        Post {
            state: Some(Box::new(Draft {})),
            content: String::new(),
        }
    }

    pub fn approve(&mut self) {
        if let Some(s) = self.state.take() {
            self.state = Some(s.approve())
        }
    }

   pub fn add_text(&mut self, text: &str) {
        self.content.push_str(text);
    }

    pub fn content(&self) -> &str {
        self.state.as_ref().unwrap().content(&self)
    }

    pub fn request_review(&mut self) {
        if let Some(s) = self.state.take() {
            self.state = Some(s.request_review())
        }
    }


}

trait State {
 fn request_review(self: Box<Self>) -> Box<dyn State>;
 fn approve(self: Box<Self>) -> Box<dyn State>;
 fn content<'a>(&self, post: &'a Post) -> &'a str {
        ""
 }
}

struct Draft {}

impl State for Draft {
    fn request_review(self: Box<Self>) -> Box<dyn State> {
        Box::new(PendingReview {})
    }
    fn approve(self: Box<Self>) -> Box<dyn State> {
        self
    }
}

struct PendingReview {}

impl State for PendingReview {
    fn request_review(self: Box<Self>) -> Box<dyn State> {
        self
    }
    fn approve(self: Box<Self>) -> Box<dyn State> {
        Box::new(Published {})
    }
}

struct Published {}

impl State for Published {
    fn request_review(self: Box<Self>) -> Box<dyn State> {
        self
    }

    fn approve(self: Box<Self>) -> Box<dyn State> {
        self
    }

    fn content<'a>(&self, post: &'a Post) -> &'a str {
        &post.content
    }
}
```
