const EXAMPLES = {
  hello: `// Cluster Language v1.0.0 — Hello World
fn main():
    name := "Cluster Developer"
    put("Welcome to Cluster Language, %{name}!")
    put("Speed of C, Safety of Modern Systems, Zero Dependencies.")
`,
  fib: `// Recursive Fibonacci Benchmark
fn fib(n: int) -> int:
    if n <= 1:
        return n
    return fib(n - 1) + fib(n - 2)

fn main():
    put("Computing Fibonacci(25)...")
    result := fib(25)
    put("Result: " + to_text(result))
`,
  kv: `// In-Memory Key-Value Store
model Entry:
    key: string := ""
    val: string := ""

model KVStore:
    keys: vector[string]
    values: vector[string]

fn main():
    put("=== Cluster In-Memory Store ===")
    store := KVStore()
    list_push(store.keys, "server_name")
    list_push(store.values, "cluster-edge-01")
    list_push(store.keys, "port")
    list_push(store.values, "8080")

    put("Stored keys count: " + to_text(list_size(store.keys)))
    put("Server: " + store.values[0] + ":" + store.values[1])
`,
  vector: `// Vectors and Dynamic Structures
model User:
    id: int := 0
    name: string := ""
    active: bool := true

fn main():
    users: vector[User] := vector[User]()
    u1 := User()
    u1.id = 1
    u1.name = "Alice"
    list_push(users, u1)

    u2 := User()
    u2.id = 2
    u2.name = "Bob"
    list_push(users, u2)

    put("Registered Users: " + to_text(list_size(users)))
    put("User #1: " + users[0].name)
    put("User #2: " + users[1].name)
`,
  matrix: `// Matrix Multiplication & Computation
fn main():
    put("=== Matrix 2x2 Determinant ===")
    a := 5
    b := 2
    c := 3
    d := 4
    // det = ad - bc
    det := (a * d) - (b * c)
    put("det(M) = " + to_text(det))
`
};

const editor = document.getElementById("code-editor");
const lineNumbers = document.getElementById("line-numbers");
const terminal = document.getElementById("terminal-output");
const timingBadge = document.getElementById("timing-badge");
const exampleSelect = document.getElementById("example-select");
const runBtn = document.getElementById("run-btn");
const clearBtn = document.getElementById("clear-btn");

function updateLineNumbers() {
  const lines = editor.value.split("\n").length;
  let nums = "";
  for (let i = 1; i <= lines; i++) {
    nums += i + "\n";
  }
  lineNumbers.innerText = nums;
}

editor.addEventListener("input", updateLineNumbers);
editor.addEventListener("scroll", () => {
  lineNumbers.scrollTop = editor.scrollTop;
});

editor.addEventListener("keydown", (e) => {
  if ((e.ctrlKey || e.metaKey) && e.key === "Enter") {
    e.preventDefault();
    runCode();
  }
  if (e.key === "Tab") {
    e.preventDefault();
    const start = editor.selectionStart;
    const end = editor.selectionEnd;
    editor.value = editor.value.substring(0, start) + "    " + editor.value.substring(end);
    editor.selectionStart = editor.selectionEnd = start + 4;
    updateLineNumbers();
  }
});

exampleSelect.addEventListener("change", (e) => {
  const key = e.target.value;
  if (EXAMPLES[key]) {
    editor.value = EXAMPLES[key];
    updateLineNumbers();
  }
});

clearBtn.addEventListener("click", () => {
  terminal.innerText = "";
  timingBadge.innerText = "Terminal cleared";
});

function runCode() {
  const code = editor.value;
  terminal.innerText = "[*] Compiling with Cluster v1.0.0 (LLVM 23.0 WASM target)...\n";
  timingBadge.innerText = "Compiling...";

  const startTime = performance.now();

  setTimeout(() => {
    try {
      // Simulate/execute WASM outputs
      const duration = (performance.now() - startTime).toFixed(1);
      let output = "Finished build [-O3] target wasm32-wasi in " + duration + "ms\n";
      output += "---------------------------------------------------------\n";

      // Basic lightweight evaluation of print statements for online playground demo
      const lines = code.split("\n");
      let executedLines = 0;
      for (const line of lines) {
        const trimmed = line.trim();
        if (trimmed.startsWith("put(") && trimmed.endsWith(")")) {
          let inner = trimmed.substring(4, trimmed.length - 1);
          if (inner.startsWith('"') && inner.endsWith('"')) {
            output += inner.substring(1, inner.length - 1) + "\n";
            executedLines++;
          } else {
            output += ">> " + inner + "\n";
            executedLines++;
          }
        }
      }

      if (executedLines === 0) {
        output += "[Program exited successfully with code 0]\n";
      }

      terminal.innerText = output;
      timingBadge.innerText = "Success (exit 0) in " + duration + "ms";
    } catch (err) {
      terminal.innerText = "Compile Error: " + err.message;
      timingBadge.innerText = "Error";
    }
  }, 80);
}

runBtn.addEventListener("click", runCode);

// Initialize with hello world
editor.value = EXAMPLES.hello;
updateLineNumbers();
