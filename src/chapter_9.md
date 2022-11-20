# Chapter 9 - Error Handling

* Rust groups errors into two major categories: recoverable and
unrecoverable errors.
* Rust doesn’t have exceptions. Instead, it has the type Result<T, E>
  for recoverable errors and the panic! macro that stops execution
  when the program encounters an unrecoverable error.

## panic! macro

When the `panic!` macro executes, your program will print a failure
message, unwind and clean up the stack, and then quit.

 But this walking back and cleanup is a lot of work. The alternative
 is to immediately abort, which ends the program without cleaning
 up. For example, if you want to abort on panic in release mode, add
 this to `cargol.toml`:

``` toml
[profile.release]
panic = 'abort'
```

## Recoverable errors with Result

``` rust
enum Result<T, E> {
    Ok(T),
    Err(E),
}
```

## Shortcuts for Panic on Error: unwrap and expect

If the Result value is the Ok variant, unwrap will return the value
inside the Ok. If the Result is the Err variant, unwrap will call the
panic! macro for us:

``` rust
use std::fs::File;

fn main() {
    let f = File::open("hello.txt").unwrap();
}
```

Another method, expect, which is similar to unwrap, lets us also
choose the panic! error message. Using expect instead of unwrap and
providing good error messages can convey your intent and make tracking
down the source of a panic easier. The syntax of expect looks like
this:

``` rust
use std::fs::File;

fn main() {
    let f = File::open("hello.txt").expect("Failed to open hello.txt");
}
```

## Propagating errors

``` rust
use std::io;
use std::io::Read;
use std::fs::File;

fn read_username_from_file() -> Result<String, io::Error> {
    let f = File::open("hello.txt");

    let mut f = match f {
        Ok(file) => file,
        Err(e) => return Err(e),
    };

    let mut s = String::new();

    match f.read_to_string(&mut s) {
        Ok(_) => Ok(s),
        Err(e) => Err(e),
    }
}
```

The above code can be written as:

``` rust
use std::io;
use std::io::Read;
use std::fs::File;

fn read_username_from_file() -> Result<String, io::Error> {
    let mut f = File::open("hello.txt")?;
    let mut s = String::new();
    f.read_to_string(&mut s)?;
    Ok(s)
}
```

There is a difference between what the match expression and what `?`
operator do: error values that have the ? operator called on them go
through the `from` function, defined in the `From` trait in the
standard library, which is used to convert errors from one type into
another.

Note that the `?` operator can only be used in functions that have a
return type of Result.
