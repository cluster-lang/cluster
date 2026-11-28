model Address:
    city: string

model User:
    address: box[Address]

fn main():
    // 1. Coalescing check
    name: string = ""
    res1 := name ?? "DefaultName"
    put "Coalesce None (expected DefaultName):"
    put res1
    
    // 2. Optional Chaining on non-null object
    addr := box Address(city="Paris")
    user1 := box User(address=move(addr))
    res2 := user1?.address?.city ?? "Unknown"
    put "Chaining non-null (expected Paris):"
    put res2
    
    // 3. Optional Chaining on null object
    user2: box[User] := nullptr
    res3 := user2?.address?.city ?? "Unknown"
    put "Chaining null (expected Unknown):"
    put res3
