# nS (number statements)

Imagine `wc` but for the number of statements in a source code for C-like languages

<sub>So, just a basic a string parser that counts the amount of specific bytes, ignoring quoted strings</sub>

---

## Installation

  Go install
  ```sh
  go install github.com/Supraboy981322/misc-scripts/nS@latest
  ```

## Usage

By default, it just counts semi-colons (`;`) and end braces (`}`), ignoring anything in a quoted strings.

#### Args

  - Count newlines:  `-l`, or `--lines`
  - input file:  `-f`, or `--file`
  - use embeded test file (good for demonstration): `--test`
  - silent (no messages): `-s`, or `--silent`
  - count lines:  `-l`, or `--lines`
  - don't count end braces:  `-B`, `--no-brace`, or `--ignore-brace`
  - don't count semi-colons: `-C`, `--no-semi`, `--ignore-semi-colons`
  - print help screen:  `-h`, `--help`
