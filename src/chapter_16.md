# Chapter 16 - Fearless Concurrency

Problems writing multithreaded code:
* Race conditions, where threads are accessing data or resources in an
  inconsistent order
* Deadlocks, where two threads are waiting for each other to finish
  using a resource the other thread has, preventing both threads from
  continuing

This model where a language calls the operating system APIs to create
threads is sometimes called 1:1, meaning one operating system thread
per one language thread.

Programming language-provided threads are known as green threads, and
languages that use these green threads will execute them in the
context of a different number of operating system threads. For this
reason, the green-threaded model is called the M:N model: there are M
green threads per N operating system threads, where M and N are not
necessarily the same number.

Rust standard library only provides an implementation of 1:1
threading. But there are various libraries which provides M:N model.

## Thread Primitives

* spawn
* join

``` rust
use std::thread;
use std::time::Duration;

fn main() {
    let handle = thread::spawn(|| {
        for i in 1..10 {
            println!("hi number {} from the spawned thread!", i);
            thread::sleep(Duration::from_millis(1));
        }
    });

    for i in 1..5 {
        println!("hi number {} from the main thread!", i);
        thread::sleep(Duration::from_millis(1));
    }

    handle.join().unwrap();
}
```

You will use the `move` keyword to make the closure take ownership of
the values in threads:

``` rust
use std::thread;

fn main() {
    let v = vec![1, 2, 3];

    let handle = thread::spawn(move || {
        println!("Here's a vector: {:?}", v);
    });

    handle.join().unwrap();
}
```

The above code won't work without using `move` as you can very well
write invalid code like this:

``` rust
use std::thread;

fn main() {
    let v = vec![1, 2, 3];

    let handle = thread::spawn(|| {
        println!("Here's a vector: {:?}", v);
    });

    drop(v); // oh no!

    handle.join().unwrap();
}
```

## Message passing between Threads

One major tool Rust has for accomplishing message-sending concurrency
is the `channel`.

A channel in programming has two halves: a transmitter and a
receiver. One part of your code calls methods on the transmitter with
the data you want to send, and another part checks the receiving end
for arriving messages. A channel is said to be closed if either the
transmitter or receiver half is dropped.

``` rust
use std::thread;
use std::sync::mpsc;
use std::time::Duration;

fn main() {
    let (tx, rx) = mpsc::channel();

    thread::spawn(move || {
        let vals = vec![
            String::from("hi"),
            String::from("from"),
            String::from("the"),
            String::from("thread"),
        ];

        for val in vals {
            tx.send(val).unwrap();
            thread::sleep(Duration::from_secs(1));
        }
    });

    for received in rx {
        println!("Got: {}", received);
    }
}
```

* mpsc: multiple producer, single consumer
* tx: transmitter
* rx: receiver

## Shared state Concurrency

Mutexes are one of the concurrency primitives for shared memory.

Mutex is an abbreviation for mutual exclusion, as in, a mutex allows
only one thread to access some data at any given time. To access the
data in a mutex, a thread must first signal that it wants access by
asking to acquire the mutex’s lock. The lock is a data structure that
is part of the mutex that keeps track of who currently has exclusive
access to the data.

``` rust
use std::sync::{Mutex, Arc};
use std::thread;

fn main() {
    let counter = Arc::new(Mutex::new(0));
    let mut handles = vec![];

    for _ in 0..10 {
        let counter = Arc::clone(&counter);
        let handle = thread::spawn(move || {
            let mut num = counter.lock().unwrap();

            *num += 1;
        });
        handles.push(handle);
    }

    for handle in handles {
        handle.join().unwrap();
    }

    println!("Result: {}", *counter.lock().unwrap());
}
```

The result will be 10.

## Sync and Send Traits

The `Send` marker trait indicates that ownership of the type
implementing `Send` can be transferred between threads. Almost every
Rust type is `Send`

The `Sync` marker trait indicates that it is safe for the type
implementing `Sync` to be referenced from multiple threads. In other
words, any type T is Sync if &T (a reference to T) is Send, meaning
the reference can be sent safely to another thread.
