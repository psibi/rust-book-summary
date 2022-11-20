# Chapter 13 - Functional Language Features: Iterators and Closures

## Motivation for Closure

``` rust
fn generate_workout(intensity: u32, random_number: u32) {
    if intensity < 25 {
        println!(
            "Today, do {} pushups!",
            simulated_expensive_calculation(intensity)
        );
        println!(
            "Next, do {} situps!",
            simulated_expensive_calculation(intensity)
        );
    } else {
        if random_number == 3 {
            println!("Take a break today! Remember to stay hydrated!");
        } else {
            println!(
                "Today, run for {} minutes!",
                simulated_expensive_calculation(intensity)
            );
        }
    }
}
```

Cons: In the above function, you call `simulated_expensive_calculation`
twice in the first if block. Let's improve it:

``` rust
fn generate_workout(intensity: u32, random_number: u32) {
    let expensive_result =
        simulated_expensive_calculation(intensity);

    if intensity < 25 {
        println!(
            "Today, do {} pushups!",
            expensive_result
        );
        println!(
            "Next, do {} situps!",
            expensive_result
        );
    } else {
        if random_number == 3 {
            println!("Take a break today! Remember to stay hydrated!");
        } else {
            println!(
                "Today, run for {} minutes!",
                expensive_result
            );
        }
    }
}
```

In the above implementation, the expensive computation is computed
only once. Unfortantely for cases where `intensity >= 25 &&
random_number == 3`, we have to perform the expensive computation
although it isn't required. Let's use closures here.

To define a closure, we start with a pair of vertical pipes (`|`),
inside which we specify the parameters to the closure:

``` rust
fn generate_workout(intensity: u32, random_number: u32) {
    let expensive_closure = |num| {
        println!("calculating slowly...");
        thread::sleep(Duration::from_secs(2));
        num
    };

    if intensity < 25 {
        println!(
            "Today, do {} pushups!",
            expensive_closure(intensity)
        );
        println!(
            "Next, do {} situps!",
            expensive_closure(intensity)
        );
    } else {
        if random_number == 3 {
            println!("Take a break today! Remember to stay hydrated!");
        } else {
            println!(
                "Today, run for {} minutes!",
                expensive_closure(intensity)
            );
        }
    }
}
```

However the above implementation has the same problem of the first
variant. We could fix this problem by creating a variable local to
that if block to hold the result of calling the closure, but closures
provide us with another solution. Let's learn something more before
finding out solution to the above problem.

## Closure Type Inference and Annotation

Closures don’t require you to annotate the types of the parameters or
the return value like `fn` functions do. But we can add type
annotations if we want to increase explicitness and clarity at the
cost of being more verbose than is strictly necessary.

``` rust
let expensive_closure = |num: u32| -> u32 {
    println!("calculating slowly...");
    thread::sleep(Duration::from_secs(2));
    num
};
```

Closure definitions will have one concrete type inferred for each of
their parameters and for their return value. The following code won't
compile:

``` rust
let example_closure = |x| x;

let s = example_closure(String::from("hello"));
let n = example_closure(5);
```

## Storing Closures Using Generic Parameters and the `Fn` Traits

One solution to the above function `generate_workout` is to save the
result of the expensive closure in a variable for reuse and use the
variable in each place we need the result.

To make a struct that holds a closure, we need to specify the type of
the closure, because a struct definition needs to know the types of
each of its fields. Each closure instance has its own unique anonymous
type: that is, even if two closures have the same signature, their
types are still considered different.

The `Fn` traits are provided by the standard library. All closures
implement at least one of the traits: `Fn`, `FnMut`, or `FnOnce`.

``` rust
struct Cacher<T>
    where T: Fn(u32) -> u32
{
    calculation: T,
    value: Option<u32>,
}
```

The `Cacher` struct has a `calculation` field of the generic type `T`. The
trait bounds on T specify that it’s a closure by using the Fn
trait. Any closure we want to store in the `calculation` field must have
one `u32` parameter (specified within the parentheses after `Fn`) and must
return a `u32` (specified after the `->`).

``` rust
impl<T> Cacher<T>
    where T: Fn(u32) -> u32
{
    fn new(calculation: T) -> Cacher<T> {
        Cacher {
            calculation,
            value: None,
        }
    }

    fn value(&mut self, arg: u32) -> u32 {
        match self.value {
            Some(v) => v,
            None => {
                let v = (self.calculation)(arg);
                self.value = Some(v);
                v
            },
        }
    }
}
```

And now the implementation:

``` rust
fn generate_workout(intensity: u32, random_number: u32) {
    let mut expensive_result = Cacher::new(|num| {
        println!("calculating slowly...");
        thread::sleep(Duration::from_secs(2));
        num
    });

    if intensity < 25 {
        println!(
            "Today, do {} pushups!",
            expensive_result.value(intensity)
        );
        println!(
            "Next, do {} situps!",
            expensive_result.value(intensity)
        );
    } else {
        if random_number == 3 {
            println!("Take a break today! Remember to stay hydrated!");
        } else {
            println!(
                "Today, run for {} minutes!",
                expensive_result.value(intensity)
            );
        }
    }
}
```


The above implementation doesn't suffer from any of the above cons
discussed above. The function is computed only once when required.

But there is a problem with the above implementation. The code will
fail (obviously) for this scenario:

``` rust
#[test]
fn call_with_different_values() {
    let mut c = Cacher::new(|a| a);

    let v1 = c.value(1);
    let v2 = c.value(2);

    assert_eq!(v2, 2);
}
```

This problem can be fixed by changing the struct implementation to
store the key and value mapping in a hashmap.

## Capturing the Environment with Closures

In the above example, we used closures as inline anonymous
functions. We can also use it to capture their environment and access
variables from the scope in which they're defined.

``` rust
fn main() {
    let x = 4;

    let equal_to_x = |z| z == x;

    let y = 4;

    assert!(equal_to_x(y));
}
```

whereas something like this will result in an compile error:

``` rust
fn main() {
    let x = 4;

    fn equal_to_x(z: i32) -> bool { z == x }

    let y = 4;

    assert!(equal_to_x(y));
}
```

Closures can capture values from their environment in three ways,
which directly map to the three ways a function can take a parameter:
taking ownership, borrowing mutably, and borrowing immutably. These
are encoded in the three `Fn` traits as follows:

* `FnOnce` consumes the variables it captures from its enclosing scope,
  known as the closure’s environment. To consume the captured
  variables, the closure must take ownership of these variables and
  move them into the closure when it is defined. The `Once` part of the
  name represents the fact that the closure can’t take ownership of
  the same variables more than once, so it can be called only once.
* `FnMut` can change the environment because it mutably borrows values.
* `Fn` borrows values from the environment immutably.

When you create a closure, Rust infers which trait to use based on how
the closure uses the values from the environment. All closures
implement `FnOnce` because they can all be called `at least`
once. Closures that don’t move the captured variables also implement
`FnMut`, and closures that don’t need mutable access to the captured
variables also implement `Fn`.

[Reddit thread on usecase of FnOnce](https://www.reddit.com/r/rust/comments/2s7l0m/whats_the_usecase_for_fnonce/)

If you want to force the closure to take ownership of the values it
uses in the environment, you can use the `move` keyword before the
parameter list. This technique is mostly useful when passing a closure
to a new thread to move the data so it’s owned by the new
thread. Example:

``` rust
fn main() {
    let x = vec![1, 2, 3];

    let equal_to_x = move |z| z == x;

    println!("can't use x here: {:?}", x);

    let y = vec![1, 2, 3];

    assert!(equal_to_x(y));
}
```

The above program will result in compile error till you have the
printlin statement in the code.

## Iterators

* [Understand this answer - self, Self](https://stackoverflow.com/a/32310313/1651941)
* [Iterator crate link](https://doc.rust-lang.org/std/iter/trait.Iterator.html)
* [std::iter documentation](https://doc.rust-lang.org/std/iter/index.html)

Three forms of iteration:
* `iter()` iterates over `&T`

``` rust
fn main() {
    let v1 = vec![1, 2, 3];

    let v1_iter = v1.iter();
    println!("{:?}", v1);
    for v in v1_iter {
        println!("Got {}", v);
    }
    println!("{:?}", v1);
}
```

* `iter_mut` iterates over `&mut T`

``` rust
fn main() {
    let mut v1 = vec![1, 2, 3];

    let v1_iter: std::slice::IterMut<u8> = v1.iter_mut();
    for v in v1_iter {
        *v = *v + 2;
        println!("Got {}", v);
    }
    // println!("{:?}", v1); Uncommenting this results in compile error
}
```

The above results in a compile error because mutable references have
one big restriction: you can have only one mutable reference to a
particular piece of data in a particular scope. And in the above code,
`v1`'s mutable borrow has already happened and `v1_iter` has mutable
reference to that in the scope. When you try to print it, you try to
immutably borrow - but the mixing isn't permitted. So, you can
overcome that like this:

``` rust
fn main() {
    let mut v1 = vec![1, 2, 3];

    {
        let v1_iter: std::slice::IterMut<u8> = v1.iter_mut();
        for v in v1_iter {
            *v = *v + 2;
            println!("Got {}", v);
        }
    }
    println!("{:?}", v1);
}
```

Note that even this will work as after the for loop ends, the scope of the borrow ends:

``` rust
fn main() {
    let mut v1 = vec![1, 2, 3];

    for v in v1.iter_mut() {
        *v = *v + 2;
        println!("Got {}", v);
    }
    println!("{:?}", v1);
}
```

* `into_iter()` iterates over `T`

``` rust
fn main() {
    let v1 = vec![1, 2, 3];

    let v1_iter: std::vec::IntoIter<u8> = v1.into_iter();
    for v in v1_iter {
        println!("Got {}", v);
    }
    // println!("{:?}", v1); Uncommenting this results in compile error
}
```

Note that if you restructure it like this, it still won't compile (the reason being `v1` is borrowed):

``` rust
fn main() {
    let v1 = vec![1, 2, 3];
    {
        let v1_iter: std::vec::IntoIter<u8> = v1.into_iter();
        for v in v1_iter {
            println!("Got {}", v);
        }
    }
    println!("{:?}", v1);
}
```

## Other Examples

* `collect` function transforms an iterator into a collection.
* [map function](https://doc.rust-lang.org/core/iter/trait.Iterator.html#method.map)
* [filter function](https://doc.rust-lang.org/core/iter/trait.Iterator.html#method.filter)
* [SO question](https://stackoverflow.com/q/57321971/1651941)

``` rust
fn main() {
    let v1: [i32; 3] = [1, 2, 3];
    let v2: Vec<i32> = v1.iter().map(|x| x * 2).collect();
    let v3: Vec<&i32> = v1.iter().filter(|x| **x == 1).collect();
    println!("{:?}", v1);
    println!("{:?}", v2);
    println!("{:?}", v3);
}
```

Why does v3 is annotated with `Vec<&i32>` and not `Vec<i32>` and why
does it has `**` ?

In `v3`, we do `vi.iter()` which passes `&i32` into filter. But the
type of predicate in filter is `FnMut(&Self::Item) -> Bool`. So the
type of x becomes `&&i32`. So, you do two de-references to get the
value. That answers the second part of the question. The type is
`Vec<i32>` as the type of predicate for map is `FnMut(Self::Item) ->
B` whereas for filter it is `FnMut(&Self::Item -> Bool)`. And hence
the different type signature.


 Different map variants:

``` rust
fn main() {
    let mut v1: Vec<i32> = vec![1, 2, 3];
    let v2: Vec<i32> = v1.iter().map(|x| x * 2).collect();
    let v3: Vec<i32> = v1.iter_mut().map(|x| *x * 2).collect();
    let v4: Vec<()> = v1.iter_mut().map(|x| *x = *x * 2).collect();
    let v5: Vec<&mut i32> = v1
        .iter_mut()
        .map(|x| {
            *x = *x * 2;
            x
        }).collect();

    // println!("{:?}", v1); Uncommenting this will result in an compile error
    println!("{:?}", v2);
    println!("{:?}", v3);
    println!("{:?}", v4);
    println!("{:?}", v5);
}
```

Note that `v4` style is not recommened. Uncommenting the line will
result in compile error because `v5` has a mutuable borrow on `v1`.

Different filter variations:

``` rust
let v1: Vec<i32> = vec![1, 2, 3];
let v2: Vec<i32> = v1.into_iter().filter(|x| *x == 2).collect();
println!("{:?}", v2);
```

``` rust
let v1: Vec<i32> = vec![1, 2, 3];
let v2: Vec<&i32> = v1.iter().filter(|&x| *x == 2).collect();
println!("{:?}", v2);
```

``` rust
let mut v1: Vec<i32> = vec![1, 2, 3];
let v2: Vec<&mut i32> = v1.iter_mut().filter(|x| **x == 2).collect();
println!("{:?}", v2);
```

Note that there are two styles of coding: iterator and loops. Most
rust programmers prefer iterator style. Also, there is no much
performance difference between both of them.
