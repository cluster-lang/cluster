// ============================================================================
// Cluster Lang Milestone 13: C/C++ Zero-Glue Integration Test Suite (.cl)
// ============================================================================

c_include "math.h"
c_include "stdio.h"
c_include "stdlib.h"
link "m"

fn test_c_math():
    puts("Testing direct C math functions (cos, sin, sqrt, fabs, ceil, floor)...")
    c := cos(0.0)
    assert(c == 1.0, "cos(0.0) must be 1.0")

    s := sin(0.0)
    assert(s == 0.0, "sin(0.0) must be 0.0")

    sq := sqrt(144.0)
    assert(sq == 12.0, "sqrt(144.0) must be 12.0")

    f := floor(7.9)
    assert(f == 7.0, "floor(7.9) must be 7.0")

    cl := ceil(7.1)
    assert(cl == 8.0, "ceil(7.1) must be 8.0")

    ab := fabs(-55.5)
    assert(ab == 55.5, "fabs(-55.5) must be 55.5")

    puts("  [OK] C math functions verified")

fn test_c_stdlib():
    puts("Testing C stdlib & stdio interop (puts, abs)...")
    a1 := abs(-42)
    assert(a1 == 42, "abs(-42) must be 42")

    a2 := abs(100)
    assert(a2 == 100, "abs(100) must be 100")

    puts("  [OK] C stdlib & stdio verified")

fn test_float_arithmetic():
    puts("Testing floating-point arithmetic & comparisons...")
    x := 10.5
    y := 2.5

    sum := x + y
    assert(sum == 13.0, "10.5 + 2.5 == 13.0")

    diff := x - y
    assert(diff == 8.0, "10.5 - 2.5 == 8.0")

    prod := x * y
    assert(prod == 26.25, "10.5 * 2.5 == 26.25")

    quot := x / y
    assert(quot == 4.2, "10.5 / 2.5 == 4.2")

    assert(x > y, "10.5 > 2.5")
    assert(y < x, "2.5 < 10.5")
    assert(x != y, "10.5 != 2.5")

    puts("  [OK] Floating-point operations verified")

fn main():
    puts("======================================================")
    puts("Cluster Lang Milestone 13: C/C++ Zero-Glue Integration")
    puts("======================================================")
    test_c_math()
    test_c_stdlib()
    test_float_arithmetic()
    puts("======================================================")
    puts("Milestone 13 PASSED: 100% C/C++ Zero-Glue Interop!")
    puts("======================================================")
