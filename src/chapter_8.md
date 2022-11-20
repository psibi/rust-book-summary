# Chapter 8 - Common Collections

* The data these collections point to is stored in the heap.

## Vectors

* Type: `Vec<T>`
* Puts all the value next to each other in the memory.

Example:

``` rust
let v: Vec<i32> = Vec::new();
let v = vec![1, 2, 3]; // Macro style

let mut v = Vec::new();

v.push(5);
v.push(6);
v.push(7);
v.push(8);

// Example of looping through immutable referece
let v = vec![100, 32, 57];
for i in &v {
    println!("{}", i);
}

// Example of looping through mutable referece
let mut v = vec![100, 32, 57];
for i in &mut v {
    println!("{}", i);
}
```

## Strings

Example:

``` rust
let mut s = String::new();

let s = String::from("initial contents");

let mut s = String::from("foo");
s.push_str("bar");
```

## HashMap

``` rust
use std::collections::HashMap;

let mut scores = HashMap::new();

scores.insert(String::from("Blue"), 10);
scores.insert(String::from("Yellow"), 50);

let team_name = String::from("Blue");
let score = scores.get(&team_name);
```

### Hashmap and ownership

For types that implement the Copy trait, like i32, the values are
copied into the hash map. For owned values like String, the values
will be moved and the hash map will be the owner of those values.

``` rust
use std::collections::HashMap;

let field_name = String::from("Favorite color");
let field_value = String::from("Blue");

let mut map = HashMap::new();
map.insert(field_name, field_value);
// field_name and field_value are invalid at this point, try using them and
// see what compiler error you get!
```
