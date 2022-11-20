# Chapter 14 - More about Cargo and Crates.io

## Customizing Builds with Release Profiles

* In Rust, release profiles are predefined and customizable profiles
with different configurations that allow a programmer to have more
control over various options for compiling code. Each profile is
configured independently of the others.
* Cargo has two main profiles:
  - `dev` profile: Used when you run `cargo build`
  - `release` profile: Used when you run `cargo build --release`

You can also override the optimization level via `cargo.toml` file:

``` toml
[profile.dev]
opt-level = 0

[profile.release]
opt-level = 3
```

## Documentation comment

Documentation comments use three slashes, `///`, instead of two and
support Markdown notation for formatting the text. Place documentation
comments just before the item they’re documenting.

We can generate documentation through `cargo doc` which uses `rustdoc`
to genrate HTML documentation.

Documentation comments have an additional bonus that they will be run
by `cargo test`.

Another style of doc comment, `//!`, adds documentation to the item that
contains the comments rather than adding documentation to the items
following the comments.

``` rust
//! # My Crate
//!
//! `my_crate` is a collection of utilities to make performing certain
//! calculations more convenient.

/// Adds one to the number given.
///
/// # Examples
///
/// ```
/// let arg = 5;
/// let answer = my_crate::add_one(arg);
///
/// assert_eq!(6, answer);
/// ```
pub fn add_one(x: i32) -> i32 {
    x + 1
}
```

## Publishing package

* Create a account in [crates.io](https://crates.io/)
* cargo publish

## Yank

Yanking a version prevents new projects from starting to depend on
that version while allowing all existing projects that depend on it to
continue to download and depend on that version. Essentially, a yank
means that all projects with a Cargo.lock will not break, and any
future Cargo.lock files generated will not use the yanked version.

``` shellsession
$ cargo yank --vers 1.0.1
```

## Cargo Workspaces

Cargo offers a feature called workspaces that can help manage multiple
related packages that are developed in tandem.

Example workspace project we will be creating: Two libraries and one
binary. Code structure:

``` shellsession
├── Cargo.lock
├── Cargo.toml
├── add-one
│   ├── Cargo.toml
│   └── src
│       └── lib.rs
├── adder
│   ├── Cargo.toml
│   └── src
│       └── main.rs
└── target
```

The root level `cargo.toml` will have this:

``` toml
[workspace]

members = [
    "adder",
    "add-one",
]
```

The `adder/cargo.toml` will contain this:

``` toml
[dependencies]

add-one = { path = "../add-one" }
```

## cargo install

The `cargo install` command allows you to install and use binary
crates locally.

## Custom cargo commands

If a binary in your `$PATH` is named `cargo-something`, you can run it as
if it was a Cargo subcommand by running `cargo something`.

You can also use `cargo --list` to find out all the sub commands
(including custom ones).
