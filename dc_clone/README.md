# a clone of UNIX `dc`

- zero runtime allocation
- only stdlib functions used are wrappers for `errno`, `write` and `read` syscalls
(`std.posix.system.(write|read|errno|)`)
- stack based (and therefore reverse polish notation) (like `dc`)
- all numbers are `i32`
