import sys
import time


def fib(n):
    if n <= 2:
        return 1
    return fib(n - 1) + fib(n - 2)


if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 35
    start = time.perf_counter()
    res = fib(n)
    elapsed = time.perf_counter() - start
    print(f"{'python':<13} fib({n}) = {res} in {elapsed:.3f} s")
