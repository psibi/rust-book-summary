# Chapter 7 - Managing Growing Projects with Packages, Crates, and Modules

A package can contain multiple binary crates and optionally one
library crate. For very large projects of a set of interrelated
packages that evolve together, Cargo provides workspaces.

Rust has a number of features that allow you to manage your code’s
organization, including which details are exposed and which details
are private, and what names are in each scope in your programs. These
features are sometimes collectively referred to as the module system
and include:

* Packages: A Cargo feature that lets you build, test, and share crates
* Crates: A tree of modules that produces a library or executable
* Modules and use: Let you control the organization, scope, and privacy of paths
* Paths: A way of naming an item, such as a struct, function, or module

## Packages and Crates

A crate is a binary or library.

A package is one or more crates that provide a set of functionality. A
package contains a Cargo.toml file that describes how to build those
crates.

Cargo follows a convention that `src/main.rs` is the crate root of a
binary crate with the same name as the package. Similarly,
`src/lib.rs` is the crate root of a library.

A package can have multiple binary crates by placing files in the
`src/bin` directory: each file will be a separate binary crate.

## Defining Modules to Control Scope and Privacy

Modules let us organize code within a crate into groups for
readability and easy reuse. Modules also control the privacy of items,
which is whether an item can be used by outside code (public) or
whether it’s an internal implementation detail and not available for
outside use (private).

``` rust
$ cargo new --lib restaurant
$ cat src/lib.rs
mod front_of_house {
    mod hosting {
        fn add_to_waitlist() {}

        fn seat_at_table() {}
    }

    mod serving {
        fn take_order() {}

        fn serve_order() {}

        fn take_payment() {}
    }
}
```

The keyworld `mod` is used to create modules.

## Paths for Referring to an Item in the Module Tree

To show Rust where to find an item in a module tree, we use a path in
the same way we use a path when navigating a filesystem. If we want to
call a function, we need to know its path.

A path can take two forms:

* An absolute path starts from a crate root by using a crate name or a
literal crate.
* A relative path starts from the current module and uses self, super,
or an identifier in the current module.

Both absolute and relative paths are followed by one or more
identifiers separated by double colons (::).

``` rust
mod front_of_house {
    pub mod hosting {
        pub fn add_to_waitlist() {}
    }
}

pub fn eat_at_restaurant() {
    // Absolute path
    crate::front_of_house::hosting::add_to_waitlist();

    // Relative path
    front_of_house::hosting::add_to_waitlist();
}
```

Note that `crate` is a keyword.

## super keyword

We can also construct relative paths that begin in the parent module
by using super at the start of the path. Example:

``` rust
fn serve_order() {}

mod back_of_house {
    fn fix_incorrect_order() {
        cook_order();
        super::serve_order();
    }

    fn cook_order() {}
}
```


## Making Structs and Enums Public

If we use pub before a struct definition, we make the struct public,
but the struct’s fields will still be private. We can make each field
public or not on a case-by-case basis.

In contrast, if we make an enum public, all of its variants are then
public.

## Bringing Paths into Scope with the use keyword

We can bring a path into a scope once and then call the items in that
path as if they’re local items with the use keyword.

``` rust
mod front_of_house {
    pub mod hosting {
        pub fn add_to_waitlist() {}
    }
}

use crate::front_of_house::hosting;

pub fn eat_at_restaurant() {
    hosting::add_to_waitlist();
    hosting::add_to_waitlist();
    hosting::add_to_waitlist();
}
```

Specifying a relative path with use is slightly different. Instead of
starting from a name in the current scope, we must start the path
given to use with the keyword `self`:

``` rust
mod front_of_house {
    pub mod hosting {
        pub fn add_to_waitlist() {}
    }
}

use self::front_of_house::hosting;

pub fn eat_at_restaurant() {
    hosting::add_to_waitlist();
    hosting::add_to_waitlist();
    hosting::add_to_waitlist();
}
```

You can also do this:

```
use self::front_of_house::hosting::add_to_waitlist;
```

and don't need to qualify. But that isn't considered good practice for
functions (For structs and enum it is fine).

## Providing New Names with the as Keyword

``` rust
use std::fmt::Result;
use std::io::Result as IoResult;

fn function1() -> Result {
}

fn function2() -> IoResult<()> {
}
```

## Re-exporting Names with pub use

When we bring a name into scope with the use keyword, the name
available in the new scope is private. To enable the code that calls
our code to refer to that name as if it had been defined in that
code’s scope, we can combine pub and use. This technique is called
re-exporting because we’re bringing an item into scope but also making
that item available for others to bring into their scope.

``` rust
mod front_of_house {
    pub mod hosting {
        pub fn add_to_waitlist() {}
    }
}

pub use crate::front_of_house::hosting;

pub fn eat_at_restaurant() {
    hosting::add_to_waitlist();
    hosting::add_to_waitlist();
    hosting::add_to_waitlist();
}
```

## Using External packages

``` rust
use rand::Rng;
fn main() {
    let secret_number = rand::thread_rng().gen_range(1, 101);
}
```

Also make sure to add the dependency to the `cargo.toml` file:

``` toml
[dependencies]
rand = "0.5.5"
```

## Using Nested Paths to Clean Up Large use Lists

This code:

``` rust
use std::cmp::Ordering;
use std::io;
```

is same as:

``` rust
use std::{cmp::Ordering, io};
```

Similarly, this code:

``` rust
use std::io;
use std::io::Write;
```

is same as:

``` rust
use std::io::{self, Write};
```


## The Glob Operator

``` rust
use std::collections::*;
```

this brings all public items defined in a path into scope.

## Separating modules into Different files

In `src/lib.rs`:

``` rust
mod front_of_house;

pub use crate::front_of_house::hosting;

pub fn eat_at_restaurant() {
    hosting::add_to_waitlist();
    hosting::add_to_waitlist();
    hosting::add_to_waitlist();
}
```

In `src/front_of_house.rs`:

``` rust
pub mod hosting {
    pub fn add_to_waitlist() {}
}
```

Using a semicolon after mod front_of_house rather than using a block
tells Rust to load the contents of the module from another file with
the same name as the module.
