# Chapter 2 - Programming a Guessing game

``` rust
let mut guess = String::new();
```

let statement is used to create a variable.

``` rust
let foo = 5; // immutable
let mut bar = 5; // mutable
```

The `::` syntax in the `::new` line indicates that new is an
associated function of the `String` type. An associated function is
implemented on a type, in this case `String`, rather than on a
particular instance of a `String`. Some languages call this a static
method.

This `new` function creates a new, empty string. You’ll find a new
function on many types, because it’s a common name for a function that
makes a new value of some kind.

Crate link: https://doc.rust-lang.org/stable/std/string/struct.String.html#method.new

``` rust
use std::io;
use std::cmp::Ordering;
use rand::Rng;

fn main() {
    println!("Guess the number!");

    let secret_number = rand::thread_rng().gen_range(1, 101);

    loop {
        println!("Please input your guess.");

        let mut guess = String::new();

        io::stdin().read_line(&mut guess)
            .expect("Failed to read line");

        let guess: u32 = match guess.trim().parse() {
            Ok(num) => num,
            Err(_) => continue,
        };

        println!("You guessed: {}", guess);

        match guess.cmp(&secret_number) {
            Ordering::Less => println!("Too small!"),
            Ordering::Greater => println!("Too big!"),
            Ordering::Equal => {
                println!("You win!");
                break;
            }
        }
    }
}
```
