fn get_coords() -> tuple[int, int]:
    return (10, 20)

fn main():
    // Unpack (destructuring declaration)
    x, y := get_coords()
    put "x (expected 10):"
    put x
    put "y (expected 20):"
    put y
    
    // Assign (destructuring assignment to existing variables)
    x, y = get_coords()
    put "x after assignment (expected 10):"
    put x
