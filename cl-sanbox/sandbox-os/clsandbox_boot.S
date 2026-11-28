/* ============================================================================
 * clsandbox_boot.S — Cluster Sandbox Bare-Metal Micro-OS Multiboot 1 Entry
 *
 * GNU as (.intel_syntax noprefix) Multiboot 1 -> x86-64 Long Mode bootstrap:
 *   - Places Multiboot 1 header (magic=0x1BADB002) at 0x00100000
 *   - Saves Multiboot magic (EAX) and info pointer (EBX)
 *   - Builds 2 MiB identity-mapped huge-page tables covering 0..4 GiB
 *   - Enables PAE, LME, SSE2 (CR4.OSFXSR | CR4.OSXMMEXCPT), clears CR0.EM
 *   - Jumps to 64-bit long mode and enters clsandbox_entry(magic, info)
 * ============================================================================ */

.intel_syntax noprefix

.set MB_MAGIC,        0x1BADB002
.set MB_FLAGS,        0x00000003
.set MB_CHECKSUM,     -(MB_MAGIC + MB_FLAGS)

.section .multiboot, "ax"
.align 4
.globl multiboot_header
multiboot_header:
    .long MB_MAGIC
    .long MB_FLAGS
    .long MB_CHECKSUM

.section .bss
.align 4096
.globl boot_pml4
boot_pml4:
    .skip 4096
boot_pdpt:
    .skip 4096
boot_pd0:
    .skip 4096
boot_pd1:
    .skip 4096
boot_pd2:
    .skip 4096
boot_pd3:
    .skip 4096

.align 16
boot_stack_bottom:
    .skip 16384
boot_stack_top:

.section .rodata
.align 8
gdt64:
    .quad 0x0000000000000000          /* 0x00: null */
    .quad 0x00AF9A000000FFFF          /* 0x08: 64-bit code */
    .quad 0x00CF92000000FFFF          /* 0x10: 64-bit data */
gdt64_ptr:
    .word gdt64_ptr - gdt64 - 1
    .long gdt64

.section .text
.code32
.globl _start
_start:
    cli

    /* Preserve Multiboot registers before touching stack/memory */
    mov     ebp, eax                  /* magic */
    mov     esi, ebx                  /* mb_info ptr */

    /* Zero entire .bss (includes page tables, stack, C globals) */
    mov     edi, OFFSET __bss_start
    mov     ecx, OFFSET __bss_end
    sub     ecx, edi
    shr     ecx, 2
    xor     eax, eax
    rep stosd

    mov     esp, OFFSET boot_stack_top

    /* PML4[0] -> PDPT | Present | Write */
    mov     eax, OFFSET boot_pdpt
    or      eax, 0x03
    mov     [boot_pml4], eax

    /* PDPT[0..3] -> PD0..PD3 | Present | Write */
    mov     eax, OFFSET boot_pd0
    or      eax, 0x03
    mov     [boot_pdpt + 0], eax

    mov     eax, OFFSET boot_pd1
    or      eax, 0x03
    mov     [boot_pdpt + 8], eax

    mov     eax, OFFSET boot_pd2
    or      eax, 0x03
    mov     [boot_pdpt + 16], eax

    mov     eax, OFFSET boot_pd3
    or      eax, 0x03
    mov     [boot_pdpt + 24], eax

    /* Fill 2048 x 2 MiB identity pages = 4 GiB */
    mov     edi, OFFSET boot_pd0
    mov     eax, 0x83                 /* Present | Write | PageSize(2M) */
    xor     edx, edx
    mov     ecx, 2048
.Lmap_2m:
    mov     [edi], eax
    mov     [edi + 4], edx
    add     eax, 0x00200000
    adc     edx, 0
    add     edi, 8
    dec     ecx
    jnz     .Lmap_2m

    /* Load CR3 */
    mov     eax, OFFSET boot_pml4
    mov     cr3, eax

    /* Enable PAE + OSFXSR + OSXMMEXCPT */
    mov     eax, cr4
    or      eax, (1 << 5) | (1 << 9) | (1 << 10)
    mov     cr4, eax

    /* Set EFER.LME */
    mov     ecx, 0xC0000080
    rdmsr
    or      eax, (1 << 8)
    wrmsr

    /* Enable PG | MP, clear EM */
    mov     eax, cr0
    or      eax, (1 << 31) | (1 << 1)
    and     eax, ~(1 << 2)
    mov     cr0, eax

    /* Load 64-bit GDT and far jump to long mode */
    lgdt    [gdt64_ptr]
    ljmp    0x08, OFFSET .Llong_mode

.code64
.Llong_mode:
    mov     ax, 0x10
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    mov     ss, ax

    mov     rsp, OFFSET boot_stack_top
    and     rsp, -16

    /* Enter C runtime: clsandbox_entry(uint64_t magic, uint64_t mb_info) */
    mov     edi, ebp
    mov     esi, esi
    call    clsandbox_entry

.Lhalt:
    cli
    hlt
    jmp     .Lhalt
