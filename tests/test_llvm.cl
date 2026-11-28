fn calc(a: int, b: int) -> int:
    x := a * b
    y := x + 10
    return y

fn main() -> int:
    put "Running LLVM Direct Code Generation..."
    
    val1 := 5
    val2 := 6
    res := calc(val1, val2)
    
    put "Result of calculation (5 * 6 + 10):"
    put res
    
    return 0
