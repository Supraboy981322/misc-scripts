# a bad memory leak

Why? Because.

This continuously allocates memory an arena in a `while (true)` loop, which's only broken by a failed allocation. The arena is based on a GPA and is freed entirely when the `main()` function returns.
