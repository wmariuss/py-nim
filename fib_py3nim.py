import sys
import time

# fib_nimpy.so, built from fib_nimpy.nim. Run `make` first.
from fib_nimpy import fib

if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 35
    start = time.perf_counter()
    res = fib(n)
    elapsed = time.perf_counter() - start
    print(f"{'python + nim':<13} fib({n}) = {res} in {elapsed:.3f} s")
