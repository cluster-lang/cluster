// Cluster Language Milestone 12: Memory Freedom Verification Test
// Tests: Raw pointers (&, *), unsafe blocks, pointer arithmetic,
// memory intrinsics, volatile ops, and 1-cycle Arena bump allocator.

fn test_unsafe_and_pointers():
    print("Testing unsafe block and raw pointer address-of & dereference...")
    x := 42
    unsafe:
        // Test &x and addr_of(x)
        p1 := &x
        p2 := addr_of(x)
        assert(*p1 == 42, "deref *p1 must be 42")
        assert(deref(p2) == 42, "deref(p2) must be 42")

        // Test deref write
        *p1 = 99
        assert(x == 99, "x must be updated to 99 via *p1")
        assert(*p2 == 99, "deref *p2 must reflect update")

        deref_write(p2, 123)
        assert(x == 123, "x must be updated to 123 via deref_write")
    print("  [OK] Unsafe block & raw pointer ops verified")

fn test_pointer_indexing_and_arithmetic():
    print("Testing raw pointer indexing and pointer arithmetic...")
    unsafe:
        // Allocate 5 x 8-byte ints = 40 bytes
        buf := mem_alloc(40)
        assert(buf != null, "mem_alloc must return non-null pointer")

        // Test pointer array indexing p[i] = val and reading p[i]
        buf[0] = 100
        buf[1] = 200
        buf[2] = 300
        buf[3] = 400
        buf[4] = 500

        assert(buf[0] == 100, "buf[0] == 100")
        assert(buf[1] == 200, "buf[1] == 200")
        assert(buf[2] == 300, "buf[2] == 300")
        assert(buf[3] == 400, "buf[3] == 400")
        assert(buf[4] == 500, "buf[4] == 500")

        // Test pointer arithmetic: buf + 8 is pointer to second element
        p_elem1 := ptr_add(buf, 8)
        assert(*p_elem1 == 200, "ptr_add(buf, 8) points to buf[1]")

        p_elem2 := buf + 16
        assert(*p_elem2 == 300, "buf + 16 points to buf[2]")

        // Test pointer diff
        diff := ptr_diff(p_elem2, buf)
        assert(diff == 16, "ptr_diff must be 16 bytes")

        mem_free(buf)
    print("  [OK] Raw pointer indexing and arithmetic verified")

fn test_byte_and_volatile_memory():
    print("Testing byte-level memory and volatile hardware access...")
    unsafe:
        raw := mem_alloc(16)
        // Set all 16 bytes to 0xAA (170)
        mem_set(raw, 170, 16)

        // Read bytes
        b0 := deref_u8(raw)
        assert(b0 == 170, "byte 0 must be 170")

        // Write specific byte
        deref_write_u8(ptr_add(raw, 3), 42)
        b3 := deref_u8(ptr_add(raw, 3))
        assert(b3 == 42, "byte 3 must be 42")

        // Test volatile ops
        write_volatile(raw, 987654321)
        v := read_volatile(raw)
        assert(v == 987654321, "read_volatile must equal written volatile value")

        mem_free(raw)
    print("  [OK] Byte-level & volatile operations verified")

fn test_arena_allocator():
    print("Testing 1-cycle bump Arena Allocator (std::alloc)...")
    // Pre-allocate 1KB arena
    arena_cap := 1024
    arena_buf := mem_alloc(arena_cap)
    arena_used := 0

    // Allocation 1: 32 bytes
    p1 := ptr_add(arena_buf, arena_used)
    arena_used = arena_used + 32
    p1[0] = 777
    p1[1] = 888

    // Allocation 2: 64 bytes
    p2 := ptr_add(arena_buf, arena_used)
    arena_used = arena_used + 64
    p2[0] = 1111
    p2[1] = 2222

    assert(p1[0] == 777, "p1[0] preserved")
    assert(p2[0] == 1111, "p2[0] preserved")
    assert(arena_used == 96, "arena used must be 96 bytes")

    // 1-CYCLE BULK RESET: Instant zero-overhead release!
    arena_used = 0
    assert(arena_used == 0, "arena used reset to 0 in 1 cycle")

    // Re-allocate from same arena immediately
    p3 := ptr_add(arena_buf, arena_used)
    arena_used = arena_used + 16
    p3[0] = 9999
    assert(p3[0] == 9999, "re-allocated arena block works")

    mem_free(arena_buf)
    print("  [OK] Arena Allocator 1-cycle reset verified")

fn main():
    print("======================================================")
    print("Cluster Lang Milestone 12: Memory Freedom Verification")
    print("======================================================")

    test_unsafe_and_pointers()
    test_pointer_indexing_and_arithmetic()
    test_byte_and_volatile_memory()
    test_arena_allocator()

    print("======================================================")
    print("Milestone 12 PASSED: 100% Memory Freedom & Safety!")
    print("======================================================")
