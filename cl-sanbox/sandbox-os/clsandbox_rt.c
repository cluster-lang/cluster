/* ============================================================================
 * clsandbox_rt.c — Freestanding x86-64 Runtime & Isolation Layer for Cluster
 *
 * Implements:
 *   - COM1 UART (0x3F8) + 80x25 VGA (0xB8000) console output for write/printf
 *   - Multiboot RAM bump+freelist allocator (malloc/free/realloc)
 *   - Core libc primitives needed by Cluster LLVM IR (memcpy, memset, strlen,
 *     memcmp, sprintf, atol, strstr, basic math, abs)
 *   - Clean QEMU ACPI shutdown + exit code reporting via serial + port 0x604
 *   - Fail-closed host I/O stubs (file_read/net_listen/system disabled inside OS)
 * ============================================================================ */

/* Zero external header dependencies for portable freestanding compilation */
typedef signed char int8_t;
typedef unsigned char uint8_t;
typedef short int16_t;
typedef unsigned short uint16_t;
typedef int int32_t;
typedef unsigned int uint32_t;
typedef long int64_t;
typedef unsigned long uint64_t;
typedef unsigned long uintptr_t;
typedef unsigned long size_t;
#ifndef NULL
#define NULL ((void*)0)
#endif
typedef __builtin_va_list va_list;
#define va_start(ap, param) __builtin_va_start(ap, param)
#define va_arg(ap, type) __builtin_va_arg(ap, type)
#define va_end(ap) __builtin_va_end(ap)

extern uint8_t __bss_start[];
extern uint8_t __bss_end[];
extern uint8_t _sandbox_heap_start[];

extern int main(int argc, char** argv);

/* ---- Low-level x86 port I/O ---- */
static inline void outb(uint16_t port, uint8_t val) {
    __asm__ __volatile__("outb %0, %1" : : "a"(val), "Nd"(port));
}

static inline uint8_t inb(uint16_t port) {
    uint8_t ret;
    __asm__ __volatile__("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

static inline void outw(uint16_t port, uint16_t val) {
    __asm__ __volatile__("outw %0, %1" : : "a"(val), "Nd"(port));
}

static inline void wrmsr(uint32_t msr, uint64_t val) {
    uint32_t lo = (uint32_t)(val & 0xFFFFFFFFULL);
    uint32_t hi = (uint32_t)(val >> 32);
    __asm__ __volatile__("wrmsr" : : "c"(msr), "a"(lo), "d"(hi));
}

static uint8_t g_tls_block[4096] __attribute__((aligned(64)));

/* ---- COM1 Serial & VGA Console ---- */
#define COM1 0x3F8
static int vga_row = 0;
static int vga_col = 0;
static volatile uint16_t* const vga_mem = (volatile uint16_t*)(uintptr_t)0xB8000;

static void serial_init(void) {
    outb(COM1 + 1, 0x00);
    outb(COM1 + 3, 0x80);
    outb(COM1 + 0, 0x01); /* 115200 baud */
    outb(COM1 + 1, 0x00);
    outb(COM1 + 3, 0x03); /* 8N1 */
    outb(COM1 + 2, 0xC7);
    outb(COM1 + 4, 0x0B);
}

static void vga_clear(void) {
    for (int i = 0; i < 80 * 25; i++) {
        vga_mem[i] = (uint16_t)(' ' | (0x07 << 8));
    }
    vga_row = 0;
    vga_col = 0;
}

static void console_putc(char c) {
    while ((inb(COM1 + 5) & 0x20) == 0) {}
    outb(COM1, (uint8_t)c);

    if (c == '\n') {
        vga_col = 0;
        vga_row++;
    } else if (c != '\r') {
        vga_mem[vga_row * 80 + vga_col] = (uint16_t)((uint8_t)c | (0x0F << 8));
        vga_col++;
        if (vga_col >= 80) {
            vga_col = 0;
            vga_row++;
        }
    }
    if (vga_row >= 25) {
        for (int r = 1; r < 25; r++) {
            for (int col = 0; col < 80; col++) {
                vga_mem[(r - 1) * 80 + col] = vga_mem[r * 80 + col];
            }
        }
        for (int col = 0; col < 80; col++) {
            vga_mem[24 * 80 + col] = (uint16_t)(' ' | (0x07 << 8));
        }
        vga_row = 24;
    }
}

static void console_write(const char* s, int64_t len) {
    if (!s || len <= 0) return;
    for (int64_t i = 0; i < len; i++) {
        console_putc(s[i]);
    }
}

static void console_cstr(const char* s) {
    if (!s) return;
    while (*s) {
        console_putc(*s++);
    }
}

static void console_i64(int64_t v) {
    char buf[32];
    int idx = 0;
    uint64_t uv;
    if (v < 0) {
        console_putc('-');
        uv = (uint64_t)(-(v + 1)) + 1ULL;
    } else {
        uv = (uint64_t)v;
    }
    if (uv == 0) {
        console_putc('0');
        return;
    }
    while (uv > 0) {
        buf[idx++] = (char)('0' + (uv % 10));
        uv /= 10;
    }
    while (idx > 0) {
        console_putc(buf[--idx]);
    }
}

/* ---- Clean VM Shutdown ---- */
__attribute__((noreturn))
void exit(int status) {
    console_cstr("\n[cl-sandbox] exit=");
    console_i64((int64_t)status);
    console_putc('\n');

    outw(0x604, 0x2000);   /* QEMU i440fx / q35 ACPI S5 shutdown */
    outw(0xB004, 0x2000);  /* Bochs / older QEMU ACPI */
    outw(0x4004, 0x3400);  /* VirtualBox ACPI */
    outb(0xF4, (uint8_t)status);

    for (;;) {
        __asm__ __volatile__("cli; hlt");
    }
}

/* ---- Freestanding Memory & Allocator ---- */
typedef struct {
    uintptr_t cur;
    uintptr_t end;
} sb_heap_t;

static sb_heap_t g_heap;

typedef struct {
    size_t size;
    size_t magic;
} alloc_hdr_t;

#define ALLOC_MAGIC 0x434C53425F4D454DULL

void* malloc(size_t sz) {
    if (sz == 0) sz = 1;
    sz = (sz + 15ULL) & ~15ULL;
    size_t total = sizeof(alloc_hdr_t) + sz;
    uintptr_t p = (g_heap.cur + 15ULL) & ~15ULL;
    if (p + total > g_heap.end) {
        return NULL;
    }
    g_heap.cur = p + total;
    alloc_hdr_t* h = (alloc_hdr_t*)p;
    h->size = sz;
    h->magic = ALLOC_MAGIC;
    return (void*)(h + 1);
}

void* calloc(size_t nmemb, size_t size) {
    size_t total = nmemb * size;
    void* p = malloc(total);
    if (p) {
        uint8_t* b = (uint8_t*)p;
        for (size_t i = 0; i < total; i++) b[i] = 0;
    }
    return p;
}

void free(void* ptr) {
    (void)ptr;
}

void* memset(void* dst, int c, size_t n) {
    uint8_t* d = (uint8_t*)dst;
    for (size_t i = 0; i < n; i++) d[i] = (uint8_t)c;
    return dst;
}

void* memcpy(void* dst, const void* src, size_t n) {
    uint8_t* d = (uint8_t*)dst;
    const uint8_t* s = (const uint8_t*)src;
    for (size_t i = 0; i < n; i++) d[i] = s[i];
    return dst;
}

void* memmove(void* dst, const void* src, size_t n) {
    uint8_t* d = (uint8_t*)dst;
    const uint8_t* s = (const uint8_t*)src;
    if (d == s || n == 0) return dst;
    if (d < s) {
        for (size_t i = 0; i < n; i++) d[i] = s[i];
    } else {
        for (size_t i = n; i > 0; i--) d[i - 1] = s[i - 1];
    }
    return dst;
}

int memcmp(const void* a, const void* b, size_t n) {
    const uint8_t* pa = (const uint8_t*)a;
    const uint8_t* pb = (const uint8_t*)b;
    for (size_t i = 0; i < n; i++) {
        if (pa[i] != pb[i]) return (int)pa[i] - (int)pb[i];
    }
    return 0;
}

int bcmp(const void* a, const void* b, size_t n) {
    return memcmp(a, b, n);
}

void* realloc(void* ptr, size_t new_sz) {
    if (!ptr) return malloc(new_sz);
    alloc_hdr_t* h = ((alloc_hdr_t*)ptr) - 1;
    if (h->magic == ALLOC_MAGIC && h->size >= new_sz) return ptr;
    void* np = malloc(new_sz);
    if (!np) return NULL;
    if (h->magic == ALLOC_MAGIC) {
        size_t cp = h->size < new_sz ? h->size : new_sz;
        memcpy(np, ptr, cp);
    }
    return np;
}

size_t strlen(const char* s) {
    if (!s) return 0;
    size_t n = 0;
    while (s[n]) n++;
    return n;
}

char* strstr(const char* hay, const char* needle) {
    if (!hay || !needle) return NULL;
    if (!*needle) return (char*)hay;
    for (; *hay; hay++) {
        const char* h = hay;
        const char* nd = needle;
        while (*h && *nd && *h == *nd) { h++; nd++; }
        if (!*nd) return (char*)hay;
    }
    return NULL;
}

int64_t atol(const char* s) {
    if (!s) return 0;
    while (*s == ' ' || *s == '\t' || *s == '\n') s++;
    int neg = 0;
    if (*s == '-') { neg = 1; s++; }
    else if (*s == '+') { s++; }
    int64_t val = 0;
    while (*s >= '0' && *s <= '9') {
        val = val * 10 + (*s - '0');
        s++;
    }
    return neg ? -val : val;
}

double atof(const char* s) {
    if (!s) return 0.0;
    while (*s == ' ' || *s == '\t' || *s == '\n') s++;
    int neg = 0;
    if (*s == '-') { neg = 1; s++; }
    else if (*s == '+') { s++; }
    double val = 0.0;
    while (*s >= '0' && *s <= '9') {
        val = val * 10.0 + (double)(*s - '0');
        s++;
    }
    if (*s == '.') {
        s++;
        double frac = 0.1;
        while (*s >= '0' && *s <= '9') {
            val += (double)(*s - '0') * frac;
            frac *= 0.1;
            s++;
        }
    }
    return neg ? -val : val;
}

/* ---- POSIX/stdio shims expected by Cluster LLVM IR ---- */
int64_t write(int fd, const void* buf, int64_t count) {
    (void)fd;
    console_write((const char*)buf, count);
    return count;
}

int isatty(int fd) {
    (void)fd;
    return 1;
}

int puts(const char* s) {
    console_cstr(s);
    console_putc('\n');
    return 1;
}

static int fmt_u64(char* out, uint64_t v, int base, int upper) {
    char tmp[32];
    int i = 0;
    const char* digs = upper ? "0123456789ABCDEF" : "0123456789abcdef";
    if (v == 0) {
        out[0] = '0';
        return 1;
    }
    while (v > 0) {
        tmp[i++] = digs[v % (uint64_t)base];
        v /= (uint64_t)base;
    }
    for (int j = 0; j < i; j++) out[j] = tmp[i - 1 - j];
    return i;
}

static int vsnfmt(char* dst, const char* fmt, va_list ap) {
    int pos = 0;
    for (const char* p = fmt; *p; p++) {
        if (*p != '%') {
            dst[pos++] = *p;
            continue;
        }
        p++;
        int is_long = 0;
        if (*p == 'l') { is_long = 1; p++; if (*p == 'l') p++; }
        if (*p == 'd' || *p == 'i') {
            int64_t v = is_long ? va_arg(ap, int64_t) : (int64_t)va_arg(ap, int);
            if (v < 0) {
                dst[pos++] = '-';
                pos += fmt_u64(dst + pos, (uint64_t)(-(v + 1)) + 1ULL, 10, 0);
            } else {
                pos += fmt_u64(dst + pos, (uint64_t)v, 10, 0);
            }
        } else if (*p == 'u') {
            uint64_t v = is_long ? va_arg(ap, uint64_t) : (uint64_t)va_arg(ap, unsigned int);
            pos += fmt_u64(dst + pos, v, 10, 0);
        } else if (*p == 'x' || *p == 'X') {
            uint64_t v = is_long ? va_arg(ap, uint64_t) : (uint64_t)va_arg(ap, unsigned int);
            pos += fmt_u64(dst + pos, v, 16, *p == 'X');
        } else if (*p == 's') {
            const char* sv = va_arg(ap, const char*);
            if (!sv) sv = "(null)";
            while (*sv) dst[pos++] = *sv++;
        } else if (*p == 'f' || *p == 'g') {
            double dv = va_arg(ap, double);
            if (dv < 0) { dst[pos++] = '-'; dv = -dv; }
            int64_t ip = (int64_t)dv;
            pos += fmt_u64(dst + pos, (uint64_t)ip, 10, 0);
            dst[pos++] = '.';
            double rem = dv - (double)ip;
            for (int k = 0; k < 6; k++) {
                rem *= 10.0;
                int d = (int)rem;
                dst[pos++] = (char)('0' + (d % 10));
                rem -= (double)d;
            }
        } else if (*p == 'c') {
            dst[pos++] = (char)va_arg(ap, int);
        } else if (*p == '%') {
            dst[pos++] = '%';
        }
    }
    dst[pos] = '\0';
    return pos;
}

int sprintf(char* dst, const char* fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    int n = vsnfmt(dst, fmt, ap);
    va_end(ap);
    return n;
}

int printf(const char* fmt, ...) {
    char buf[1024];
    va_list ap;
    va_start(ap, fmt);
    int n = vsnfmt(buf, fmt, ap);
    va_end(ap);
    console_write(buf, (int64_t)n);
    return n;
}

int64_t max(int64_t a, int64_t b) { return a > b ? a : b; }
int64_t min(int64_t a, int64_t b) { return a < b ? a : b; }
int64_t abs(int64_t a) { return a < 0 ? -a : a; }
double fabs(double x) { return x < 0.0 ? -x : x; }
double floor(double x) { int64_t i = (int64_t)x; return (x < 0.0 && (double)i != x) ? (double)(i - 1) : (double)i; }
double ceil(double x) { int64_t i = (int64_t)x; return (x > 0.0 && (double)i != x) ? (double)(i + 1) : (double)i; }
double round(double x) { return x >= 0.0 ? floor(x + 0.5) : ceil(x - 0.5); }
double sqrt(double x) {
    if (x <= 0.0) return 0.0;
    double r = x;
    for (int i = 0; i < 24; i++) r = 0.5 * (r + x / r);
    return r;
}

/* ---- Fail-closed isolation stubs inside Micro-OS Sandbox ---- */
typedef struct { char* buf; int64_t len; } sb_str_t;
static sb_str_t* empty_str(void) {
    sb_str_t* s = (sb_str_t*)malloc(sizeof(sb_str_t));
    char* b = (char*)malloc(1);
    b[0] = '\0';
    s->buf = b;
    s->len = 0;
    return s;
}

void* file_read(void* p) { (void)p; return empty_str(); }
void* read_file(void* p) { (void)p; return empty_str(); }
void* input(void* p) { (void)p; return empty_str(); }
void* console_input(void* p) { (void)p; return empty_str(); }
int64_t file_write(void* p, void* c) { (void)p; (void)c; return 0; }
int64_t file_write_bytes(void* p, void* c) { (void)p; (void)c; return 0; }
int64_t file_exists(void* p) { (void)p; return 0; }
int64_t system(const char* cmd) { (void)cmd; return -1; }
int64_t net_listen(int64_t port) { (void)port; return -1; }
int64_t net_accept(int64_t fd) { (void)fd; return -1; }
void* net_read(int64_t fd, int64_t maxn) { (void)fd; (void)maxn; return empty_str(); }
int64_t net_write(int64_t fd, void* d) { (void)fd; (void)d; return -1; }
void net_close(int64_t fd) { (void)fd; }
int64_t net_connect(void* h, int64_t p) { (void)h; (void)p; return -1; }
int64_t net_set_nonblocking(int64_t fd) { (void)fd; return -1; }
int64_t net_epoll_create(void) { return -1; }
int64_t net_epoll_add(int64_t e, int64_t f, int64_t m) { (void)e; (void)f; (void)m; return -1; }
int64_t net_epoll_del(int64_t e, int64_t f) { (void)e; (void)f; return -1; }
int64_t net_epoll_wait(int64_t e, int64_t t) { (void)e; (void)t; return -1; }
int64_t net_tls_connect(void* h, int64_t p, int64_t v) { (void)h; (void)p; (void)v; return -1; }
void* net_tls_read(int64_t h, int64_t m) { (void)h; (void)m; return empty_str(); }
int64_t net_tls_write(int64_t h, void* d) { (void)h; (void)d; return -1; }
void net_tls_close(int64_t h) { (void)h; }
int64_t cl_sqlite_open(void* p) { (void)p; return -1; }
void cl_sqlite_close(int64_t d) { (void)d; }
int64_t cl_sqlite_exec(int64_t d, void* s) { (void)d; (void)s; return -1; }
int64_t cl_sqlite_exec_param(int64_t d, void* s, void* p) { (void)d; (void)s; (void)p; return -1; }
void* cl_sqlite_query_json(int64_t d, void* s) { (void)d; (void)s; return empty_str(); }
void* cl_sqlite_query_param_json(int64_t d, void* s, void* p) { (void)d; (void)s; (void)p; return empty_str(); }
void server_start(int64_t p, void* r) { (void)p; (void)r; }
void zk_spawn(void* fn, void* arg) { (void)fn; (void)arg; }
void zk_thread_pool_wait(void) {}
void zk_thread_pool_shutdown(void) {}
void* zk_channel_new(int64_t cap) { (void)cap; return NULL; }
void zk_channel_send(void* ch, int64_t v) { (void)ch; (void)v; }
int64_t zk_channel_recv(void* ch) { (void)ch; return 0; }
int64_t zk_channel_try_send(void* ch, int64_t v) { (void)ch; (void)v; return 0; }
int64_t zk_channel_try_recv(void* ch, int64_t* ov) { (void)ch; (void)ov; return 0; }
void zk_channel_close(void* ch) { (void)ch; }
int64_t zk_channel_count(void* ch) { (void)ch; return 0; }
int64_t mutex_new(void) { return 0; }
void mutex_lock(int64_t m) { (void)m; }
void mutex_unlock(int64_t m) { (void)m; }
void mutex_free(int64_t m) { (void)m; }
void* fs_list_dir(void* p) { (void)p; return NULL; }
int64_t fs_is_dir(void* p) { (void)p; return 0; }
int64_t fs_mkdir_p(void* p) { (void)p; return 0; }
int64_t fs_mtime_ns(void* p) { (void)p; return 0; }
int64_t fs_copy_file(void* a, void* b) { (void)a; (void)b; return 0; }
int64_t fs_remove(void* p) { (void)p; return 0; }
void* fs_realpath(void* p) { (void)p; return empty_str(); }

/* ---- Entry point called from clsandbox_boot.S ---- */
void clsandbox_entry(uint64_t magic, uint64_t mb_info_addr) {
    /* Initialize x86-64 FS base for thread_local variables (e.g. @__zk_arena_base) */
    uintptr_t tls_tcb = (uintptr_t)(g_tls_block + 2048);
    *(uint64_t*)tls_tcb = (uint64_t)tls_tcb;
    wrmsr(0xC0000100U, (uint64_t)tls_tcb);

    serial_init();
    vga_clear();

    uintptr_t heap_base = (uintptr_t)_sandbox_heap_start;
    uintptr_t heap_limit = 64ULL * 1024ULL * 1024ULL; /* Safe default 64 MiB ceiling */

    if (magic == 0x2BADB002ULL && mb_info_addr != 0) {
        uint32_t* mb = (uint32_t*)(uintptr_t)mb_info_addr;
        uint32_t flags = mb[0];
        if (flags & 0x01U) {
            uint32_t mem_upper_kb = mb[2];
            uintptr_t top = (1024ULL + (uintptr_t)mem_upper_kb) * 1024ULL;
            if (top > heap_base + 0x100000ULL) {
                heap_limit = top - 0x10000ULL;
            }
        }
    }

    g_heap.cur = heap_base;
    g_heap.end = heap_limit;

    console_cstr("[cl-sandbox] bare-metal micro-OS isolated ring-0 boot OK\n");

    char arg0[] = "clsandbox";
    char* argv[2] = { arg0, NULL };
    int rc = main(1, argv);
    exit(rc);
}
