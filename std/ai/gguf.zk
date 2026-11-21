// Cluster Standard Library: GGUF Module (std::ai::gguf)
// llama.cpp / GGUF binary format constants and calculations

const GGUF_MAGIC: string = "GGUF"
const GGUF_VERSION_V2: int = 2
const GGUF_VERSION_V3: int = 3
const GGUF_DEFAULT_ALIGNMENT: int = 32

fn is_gguf_file(path: string) -> bool:
    return string_ends_with(path, ".gguf")

fn gguf_align_offset(offset: int, alignment: int) -> int:
    rem := offset % alignment
    if rem == 0:
        return offset
    return offset + (alignment - rem)
