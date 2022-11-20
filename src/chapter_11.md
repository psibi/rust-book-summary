# Chapter 11 - Writing Automated Tests

At its simplest, a test in Rust is a function that’s annotated with
the `test` attribute. Attributes are metadata about pieces of Rust code:

``` rust
#[test]
fn it_works() {
    assert_eq!(2 + 2, 4);
}
```

Various helper macros useful for testing:

* assert!
* assert_eq!
* assert_ne!

You can also add a custom message to be printed with the failure
message as optional arguments to the `assert!`, `assert_eq!`, and
`assert_ne!` macros. Any arguments specified after the one required
argument to `assert!` or the two required arguments to `assert_eq!` and
`assert_ne!` are passed along to the format! macro:

``` rust
#[test]
fn greeting_contains_name() {
    let result = greeting("Carol");
    assert!(
        result.contains("Carol"),
        "Greeting did not contain name, value was `{}`", result
    );
}
```


## Checking for Panics with should_panic

We place the `#[should_panic]` attribute after the `#[test]` attribute and
before the test function it applies to.

``` rust
#[test]
#[should_panic]
fn greater_than_100() {
    panic("hello");
}
```

To make `should_panic` tests more precise, we can add an optional
expected parameter to the `should_panic` attribute. The test harness
will make sure that the failure message contains the provided text.

## Using Result<T, E> in Tests

``` rust
#[test]
fn it_works() -> Result<(), String> {
    if 2 + 2 == 4 {
        Ok(())
    } else {
        Err(String::from("two plus two does not equal four"))
    }
}
```

## Controlling How Tests Are Run

The default behavior of the binary produced by `cargo test` is to run
all the tests in parallel and capture output generated during test
runs, preventing the output from being displayed and making it easier
to read the output related to the test results.

## Various test options

* When you run multiple tests, by default they run in parallel using threads.

``` shellsession
$ cargo test -- --test-threads=1
$ cargo test -- --nocapture
$ cargo test -- --ignored # Runs only the ignored tests
```

## Test Organization

* Unit tests are small and more focused, testing one module in
  isolation at a time, and can test private interfaces.
* Integration tests are entirely external to your library and use your
   code in the same way any other external code would, using only the
   public interface and potentially exercising multiple modules per
  test.

### Unit tests

The convention is to create a module named `tests` in each file to
contain the test functions and to annotate the module with `cfg(test)`.

The `#[cfg(test)]` annotation on the tests module tells Rust to
compile and run the test code only when you run `cargo test`, not when
you run `cargo build`. Note that `cfg` stands for configuration.

### Integration Tests

We create a tests directory at the top level of our project directory,
next to src. Cargo knows to look for integration test files in this
directory.

Note that we can create `tests/common/mod.rs` to put helper
functions. Rust understands this naming convention and treats the
`common` module not as an integration tests file.
