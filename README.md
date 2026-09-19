# py-nim

[![CI](https://github.com/wmariuss/py-nim/actions/workflows/ci.yml/badge.svg)](https://github.com/wmariuss/py-nim/actions/workflows/ci.yml)
[![Nim](https://img.shields.io/badge/nim-2.0%2B-FFE953)](https://nim-lang.org/)
[![Python](https://img.shields.io/badge/python-3.10%2B-3776AB)](https://www.python.org/)
[![License](https://img.shields.io/github/license/wmariuss/py-nim)](LICENSE)

A small, runnable demonstration of **speeding up Python with Nim**. The same
naive recursive Fibonacci is written twice, once in Python and once in Nim,
and the Nim version is compiled into a module that Python imports and calls
like any other:

```python
from fib_nimpy import fib

fib(35)
```

No C, no ctypes, no cffi, no build system to learn. One pragma on one proc.

## The result

| | fib(35) | time | vs Python |
| --- | --- | --- | --- |
| Python | 9227465 | 0.539 s | 1x |
| Python calling Nim | 9227465 | 0.025 s | 22x |
| Nim, standalone binary | 9227465 | 0.013 s | 41x |

Python 3.12.1, Nim 2.2.12, gcc 11.4, one ordinary Linux laptop. Absolute
numbers will differ on your machine; the ratios are the point. Reproduce them
with `make bench`.

The middle row is the whole point. The work runs at compiled speed, and the
call still starts and ends in Python.

The last row is a ceiling, not an option. It is faster than the same code
inside the module because a shared library is compiled as position independent
code, which a recursion this tight notices. Twelve milliseconds is what you
give up for staying in Python, and it buys back everything else Python is
there for.

## How it works

The Nim side, `fib_nimpy.nim`, in full:

```nim
import nimpy

proc fib(n: int): int {.exportpy.} =
    if n <= 2:
        return 1
    else:
        return fib(n - 1) + fib(n - 2)
```

`{.exportpy.}` comes from [nimpy](https://github.com/yglukhov/nimpy). It
writes the CPython glue: the module init function, the argument unpacking,
the return value conversion. Compiling as a shared library produces a file
CPython imports by its ordinary rules:

```bash
nim c -d:release --mm:orc --app:lib --out:fib_nimpy.so fib_nimpy.nim
```

Three names have to agree: the Nim file, the `.so`, and the name you import.
nimpy generates `PyInit_fib_nimpy` from the module name, and that is the
symbol CPython goes looking for when it loads `fib_nimpy.so`.

## Requirements

* Python 3.10 or newer
* Nim 2.0 or newer, with `nimble` (see [install](https://nim-lang.org/install.html))
* A C compiler, because Nim compiles through C

CI builds this on Nim 2.2.12 and Python 3.13.

## Build and run

```bash
make deps     # fetch nimpy
make          # build fib_nimpy.so and the standalone fib_nim binary
make bench    # run all three, side by side
```

`make bench` takes the Fibonacci index from `N`, which defaults to 35:

```bash
make bench N=38
```

Each program also runs on its own and takes the index as its first argument:

```bash
python3 fib_py3.py 35
python3 fib_py3nim.py 35
./fib_nim 35
```

Raise `N` carefully. The cost is exponential, and it is the pure Python row
that pays: each step up multiplies the work by about 1.6, so fib(40) takes
roughly eleven times longer than fib(35), and fib(47), the value this demo
used to hardcode, takes about three hundred times longer.

## Layout

| file | what it is |
| --- | --- |
| `fib_py3.py` | the baseline, plain recursive Python |
| `fib_nimpy.nim` | the same function in Nim, exported to Python |
| `fib_py3nim.py` | Python importing that module and calling it |
| `fib_nim.nim` | the same function again, as a standalone Nim program |
| `Makefile` | build flags and the three ways to run it |
| `py_nim.nimble` | the Nim dependencies |

The two Python runners are deliberately identical apart from where `fib`
comes from, so the diff between them is the entire integration.

## Make targets

| target | what it does |
| --- | --- |
| `make deps` | install the Nim dependencies with nimble |
| `make` | build both the Python module and the standalone binary |
| `make module` | build `fib_nimpy.so` only |
| `make binary` | build `fib_nim` only |
| `make bench` | run all three at `N` and print their timings |
| `make check` | run all three at `N` and fail if they disagree |
| `make clean` | remove the build output |

## What this does not show

This is a microbenchmark, and a flattering one. Naive recursion is close to
the worst case for an interpreter and close to the best case for a compiler:
eighteen million function calls, no allocation, no I/O, nothing a C library is
already doing on Python's behalf. Real code rarely looks like this, and the
gap has been closing from the other side too: CPython 3.11 and 3.12 made
Python-to-Python calls much cheaper, so this margin is narrower than the same
demo would have shown on the Python 3.6 it was first written for.

Crossing the boundary is not free either. On the machine above, a call into
the module costs about 100 ns against about 36 ns for a plain Python call, so
a trivial function is three times slower through Nim than it was in Python.
Driving a tight loop across the boundary one iteration at a time gives back
everything the compiler won. The pattern that pays is the one here: hand Nim a
whole unit of work and let it come back once.

If the hot loop is numeric and array shaped, reach for NumPy first. Nim earns
its place when the work is branchy, recursive or otherwise awkward to express
as array operations, and when you would rather write it in a language with a
garbage collector than in C.

## License

MIT, see [LICENSE](LICENSE).
