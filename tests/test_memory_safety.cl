fn main():
    // 1. Declare optional primitive types
    x: int? := None
    y: string? := "Hello"
    
    // Assign values
    x = 42
    y = None
    
    put "Optional int (expected 42):"
    put x ?? 0
    put "Optional string (expected Default):"
    put y ?? "Default"
