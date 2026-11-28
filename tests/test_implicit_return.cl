fn square(x: int) -> int:
    x * x

fn add(a: int, b: int) -> int:
    a + b

fn main():
    res1 := square(5)
    res2 := add(10, 20)
    put "Square of 5 (expected 25):"
    put res1
    put "Add of 10 and 20 (expected 30):"
    put res2
