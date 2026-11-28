/* ============================================================================
 * clsandbox.ld — Linker script for Cluster Sandbox Micro-OS (< 24 KB target)
 * ============================================================================ */
OUTPUT_FORMAT("elf64-x86-64")
ENTRY(_start)

SECTIONS
{
    . = 0x00100000;

    .text ALIGN(4) :
    {
        KEEP(*(.multiboot))
        *(.text .text.*)
    }

    .rodata ALIGN(16) :
    {
        *(.rodata .rodata.*)
    }

    .data ALIGN(16) :
    {
        *(.data .data.*)
    }

    .bss ALIGN(4096) :
    {
        __bss_start = .;
        *(COMMON)
        *(.bss .bss.*)
        *(.tdata .tdata.*)
        *(.tbss .tbss.*)
        __bss_end = .;
    }

    . = ALIGN(4096);
    _sandbox_heap_start = .;

    /DISCARD/ :
    {
        *(.comment)
        *(.eh_frame*)
        *(.note*)
    }
}
