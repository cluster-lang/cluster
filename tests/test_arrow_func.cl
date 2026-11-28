fn main():
    add := (a, b) => a + b
    square := x => x * x
    
    res1 := add(5, 10)
    res2 := square(6)
    
    put "Result of add(5, 10) (expected 15):"
    put res1
    put "Result of square(6) (expected 36):"
    put res2
