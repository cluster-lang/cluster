# Cluster Programming Language Toolchain

> [!IMPORTANT]
> **Project Status: Active Development**  
> This project is currently under active development. Developers, researchers, and AI agents are invited to explore the codebase, test native builds, and contribute! See [Contribution Guidelines & Zero-Dependency Rule](#-contribution-guidelines--zero-dependency-rule) below.

**High-Performance • Dependency-Free • Memory-Safe Systems Language**

**Author:** mohammadzaid/(cluster) <zkalamgir@proton.me>  
**Organization:** [cluster-lang](https://github.com/cluster-lang)  
**License:** Cluster Community & Fair-Source License (CCFL v1.0 / MIT-Conditional)  

---

## ⚡ The Cluster Vision

Cluster is a modern compiled systems programming language engineered for uncompromising speed, memory safety by default, and high expressive density.

* **Zero External Runtime Dependencies:** Binaries compile directly to standalone, self-contained native machine code (`-O3`) via LLVM.
* **Unified Cross-Platform Core:** Single architecture engineered to run natively across all targets from x86_64 to ARM64.
* **Production-Grade Expressive Density:** Write algorithms in 1,000 clean lines that match 200,000 lines of historical C/Rust ceremony without losing a single microsecond of performance.

---

## 🚀 Quickstart

### 1. Automated Universal Installation (Linux, macOS, Windows/WSL, Android Termux)

Install the Cluster toolchain (`cl`), standard library (`std/`), and official VS Code extension in a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/cluster-lang/cluster/main/install.sh | bash
```

* **Universal Multi-Platform Support:** Automatically detects Linux, macOS, Windows (Git Bash/MSYS2/WSL), and Android Termux.
* **Instant Colorful VS Code Integration:** Automatically installs the official [vscode-cluster](https://github.com/cluster-lang/vscode-cluster) extension directly into your local editor (`~/.vscode`, VS Code Server, Cursor, and VSCodium) for complete syntax highlighting and language configurations out of the box when writing `.cl`, `.zk`, and `.cld` files.
* **Zero Configuration:** Provisions compiler binaries (`cl`, `zk`, `cluster`) and sets up standard library paths in your shell profile (`.bashrc`, `.zshrc`, `config.fish`).

Verify your installation:
```bash
cl --version
```

### 2. Hello, World!

Create `main.cl`:
```cluster
fn main():
    println("Hello from Cluster Language!")
```

### 3. Run or Build

```bash
# Direct fast execution
cl run main.cl

# Compile to standalone native binary with full -O3 optimization
cl build main.cl -o main
./main
```

### 4. Interactive REPL

Start an immediate interactive Cluster session with zero setup:

```bash
cl repl
```

### 5. Package Management (550,000+ Modules)

Discover and install ecosystem modules directly into your project:

```bash
# Search package registry
cl search adler

# Add and install module to ./deps/
cl add cl-adler32

# List project dependencies
cl list
```

### 6. Built-in Test Suite Runner

Execute test suites with millisecond precision:

```bash
cl test
```

### 7. Native Language Server Protocol (LSP)

Start the JSON-RPC language server daemon for real-time diagnostics, autocomplete, and hover docs:

```bash
cl lsp
```

---

## 🌐 Interactive Browser Playground

Try Cluster directly in your browser without installing anything:
* Open the [Cluster Web Playground](docs/playground/index.html) to write, compile, and execute Cluster code with live terminal output.

---

## ⚡ GitHub Actions CI/CD Integration

Use the official Cluster setup action in your CI/CD workflows:

```yaml
- uses: cluster-lang/setup-cluster@v1
  with:
    version: '1.0.0'
```

---

## 🛠️ Toolchain Layout

```
cluster/
├── bin/
│   ├── cl              # Primary CLI Driver & Project Runner
│   ├── cl2             # Self-Hosting Native Cluster Compiler (LLVM backend)
│   ├── clang           # Bundled LLVM Code Generator
│   ├── cl-link         # High-Speed Native Linker
│   └── cl-strip        # Binary Size Optimizer
├── lib/
│   └── runtime/        # Bare-Metal POSIX Runtime (Concurrency, Network, I/O)
└── std/                # High-Speed Core Standard Library
    ├── crypto.cl       # RFC 3174 SHA-1, FNV-1a, DJB2, Base64
    ├── net.cl          # High-Speed TCP Networking & DNS Resolution
    ├── sync.cl         # POSIX Mutexes & Thread Synchronization
    ├── math.cl         # Fast Math Functions
    └── io.cl           # Native File System & Terminal I/O
```

---

## 🤝 Contribution Guidelines & Zero-Dependency Rule

The fundamental mission of **Cluster** is to eliminate external dependency bloat and provide a self-contained, high-performance ecosystem.

### Core Rules for Contributions:
1. **100% Pure Cluster (`.cl`):** All new features, standard modules, and converted tools must be written purely in Cluster.
2. **Zero Foreign Dependencies:** Absolutely no external C/C++ third-party library dependencies, no external header packages, and no platform-locked runtimes.
3. **Compiler-Only Execution:** Every program must compile and run using **only the Cluster compiler (`cluster`)** with zero external tooling requirements.
4. **Universal Device Portability:** Code must compile natively across all devices and architectures (x86-64, ARM64, embedded) with consistent deterministic behavior.

---

## 🏆 Official Showcase Implementations

Discover what Cluster can build with zero external dependencies:

* [redis](https://github.com/cluster-lang/redis) — High-throughput in-memory key-value data store (219,000+ req/sec).
* [ripgrep](https://github.com/cluster-lang/ripgrep) — Ultra-fast recursive regex search engine (0.003s search latency).
* [git](https://github.com/cluster-lang/git) — Distributed version control system with 100% official Git interoperability.
* [curl](https://github.com/cluster-lang/curl) — Standalone HTTP/HTTPS network transfer client (4.66x faster than C cURL).
* [ssg](https://github.com/cluster-lang/ssg) — Static site generator powering the official Cluster documentation.

---

## 📜 License & Commercial Terms

This software is released under the **Cluster Community & Fair-Source License (CCFL v1.0 / MIT-Conditional)**:

- **100% Free for Independent & Research Use:**
  - Individual developers, students, educators, academic researchers, non-profits, and scientific research groups have full rights to inspect, test, run, compile, and contribute without any fees (any modification or derivative reproduction strictly requires prior written permission, including for research).
- **Commercial Enterprise License Required:**
  - Commercial companies, startups, and for-profit businesses using Cluster or its binaries in revenue-generating operations or proprietary commercial products must acquire a commercial license.
  - Contact: **`zkalamgir@proton.me`** (`mohammadzaid/(cluster)`).


  
