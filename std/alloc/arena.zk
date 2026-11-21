// Cluster Standard Library: Memory & Custom Allocators (std::alloc)
// High-performance bump allocator with single-cycle O(1) bulk release.

model Arena:
    buf: ptr
    cap: int
    used: int

    fn alloc(& self, size: int) -> ptr:
        // Align to 8 bytes for 64-bit alignment and maximum SIMD/cache speed
        aligned := (size + 7) & (~7)
        if self.used + aligned > self.cap:
            return null
        p := ptr_add(self.buf, self.used)
        self.used = self.used + aligned
        return p

    fn alloc_u8(& self, size: int) -> ptr:
        if self.used + size > self.cap:
            return null
        p := ptr_add(self.buf, self.used)
        self.used = self.used + size
        return p

    fn reset(& self):
        // 1-cycle O(1) bulk release of all allocations in this arena
        self.used = 0

    fn free(& self):
        if self.buf != null:
            mem_free(self.buf)
            self.buf = null
            self.cap = 0
            self.used = 0

    fn bytes_used(& self) -> int:
        return self.used

    fn bytes_remaining(& self) -> int:
        return self.cap - self.used

    fn capacity(& self) -> int:
        return self.cap

fn arena_new(capacity: int) -> Arena:
    a := Arena()
    a.buf = mem_alloc(capacity)
    a.cap = capacity
    a.used = 0
    return a

fn arena_alloc(& a: Arena, size: int) -> ptr:
    return a.alloc(size)

fn arena_reset(& a: Arena):
    a.reset()

fn arena_free(& a: Arena):
    a.free()

fn mem_zero(p: ptr, size: int):
    mem_set(p, 0, size)

fn mem_clone(src: ptr, size: int) -> ptr:
    dst := mem_alloc(size)
    if dst != null:
        mem_copy(dst, src, size)
    return dst
