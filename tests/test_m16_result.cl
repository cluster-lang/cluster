import "std/result.cl"

fn step_double(x: int) -> Result:
    if x > 1000:
        return Err("overflow error", 102)
    return Ok(x * 2)

fn step_add_five(x: int) -> Result:
    return Ok(x + 5)

fn compute_pipeline(x: int) -> Result:
    a := step_double(x)?
    b := step_add_five(a)?
    c := step_double(b)?
    return Ok(c)

fn safe_divide(num: int, den: int) -> Result:
    if den == 0:
        return Err("zero division", 100)
    return Ok(num / den)

fn calculate_ratio(a: int, b: int, c: int) -> Result:
    r1 := safe_divide(a, b)?
    r2 := safe_divide(r1, c)?
    return Ok(r2)

fn test_basic_ok_and_err():
    // 1. Ok verification
    r_ok := Ok(42)
    if r_ok.is_ok() != 1:
        put "FAIL: expected is_ok == 1"
        sys_exit(1)
    if r_ok.is_err() != 0:
        put "FAIL: expected is_err == 0"
        sys_exit(1)
    if r_ok.unwrap() != 42:
        put "FAIL: expected unwrap == 42"
        sys_exit(1)
    if r_ok.unwrap_or(999) != 42:
        put "FAIL: expected unwrap_or on Ok to return inner value"
        sys_exit(1)

    // 2. Err verification
    r_err := Err("permission denied", 403)
    if r_err.is_ok() != 0:
        put "FAIL: expected is_ok == 0 for Err"
        sys_exit(1)
    if r_err.is_err() != 1:
        put "FAIL: expected is_err == 1 for Err"
        sys_exit(1)
    if r_err.unwrap_err() != "permission denied":
        put "FAIL: unexpected unwrap_err message"
        sys_exit(1)
    if r_err.err_code() != 403:
        put "FAIL: unexpected err_code"
        sys_exit(1)
    if r_err.unwrap_or(999) != 999:
        put "FAIL: expected unwrap_or on Err to return default"
        sys_exit(1)

    put "PASS: basic Ok and Err construction and inspection"

fn test_qmark_success_propagation():
    // x = 10 -> double(10)=20 -> add5(20)=25 -> double(25)=50
    res := compute_pipeline(10)
    if res.is_ok() != 1:
        put "FAIL: compute_pipeline expected Ok"
        sys_exit(1)
    val := res.unwrap()
    if val != 50:
        put "FAIL: expected 50 from pipeline"
        sys_exit(1)
    put "PASS: ? operator multi-step success unwrapping"

fn test_qmark_error_propagation():
    // x = 2000 causes overflow in first step
    res_err := compute_pipeline(2000)
    if res_err.is_err() != 1:
        put "FAIL: expected compute_pipeline to propagate error"
        sys_exit(1)
    if res_err.unwrap_err() != "overflow error":
        put "FAIL: expected overflow error message"
        sys_exit(1)
    if res_err.err_code() != 102:
        put "FAIL: expected error code 102"
        sys_exit(1)

    // zero division in second step
    res_div_err := calculate_ratio(100, 2, 0)
    if res_div_err.is_err() != 1:
        put "FAIL: expected division error"
        sys_exit(1)
    if res_div_err.unwrap_err() != "zero division":
        put "FAIL: expected zero division message"
        sys_exit(1)
    if res_div_err.err_code() != 100:
        put "FAIL: expected code 100"
        sys_exit(1)

    put "PASS: ? operator zero-cost early return on Err"

fn test_stdlib_helpers():
    r1 := ok(77)
    if is_ok(r1) != true:
        put "FAIL: stdlib is_ok"
        sys_exit(1)
    if unwrap(r1) != 77:
        put "FAIL: stdlib unwrap"
        sys_exit(1)

    r2 := err_with_code("not found", 404)
    if is_err(r2) != true:
        put "FAIL: stdlib is_err"
        sys_exit(1)
    if unwrap_err(r2) != "not found":
        put "FAIL: stdlib unwrap_err"
        sys_exit(1)
    if err_code(r2) != 404:
        put "FAIL: stdlib err_code"
        sys_exit(1)
    if unwrap_or(r2, 123) != 123:
        put "FAIL: stdlib unwrap_or"
        sys_exit(1)

    put "PASS: std/result standard library wrappers"

fn main():
    test_basic_ok_and_err()
    test_qmark_success_propagation()
    test_qmark_error_propagation()
    test_stdlib_helpers()
    put "=== ALL MILESTONE 16 RESULT & ? OPERATOR TESTS PASSED (.cl) ==="
