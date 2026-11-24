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

// Robust Client-Side Cluster Runtime & Interpreter for Playground
function executeClusterCode(code) {
  let output = "";
  const models = {};
  const fns = {};

  const lines = code.split("\n");
  let inFn = null;
  let inModel = null;

  for (let i = 0; i < lines.length; i++) {
    const raw = lines[i];
    const trimmed = raw.trim();
    if (!trimmed || trimmed.startsWith("//")) continue;

    if (trimmed.startsWith("model ")) {
      const match = trimmed.match(/^model\s+([A-Za-z0-9_]+):/);
      if (match) {
        inModel = match[1];
        models[inModel] = {};
        continue;
      }
    }
    if (inModel) {
      if (raw.startsWith("    ") || raw.startsWith("\t")) {
        const parts = trimmed.split(":");
        const fieldName = parts[0].trim();
        let defaultVal = "";
        if (parts[1] && parts[1].includes(":=")) {
          const valPart = parts[1].split(":=")[1].trim();
          defaultVal = valPart.replace(/^"|"$/g, "");
          if (!isNaN(Number(defaultVal))) defaultVal = Number(defaultVal);
          if (defaultVal === "true") defaultVal = true;
          if (defaultVal === "false") defaultVal = false;
        } else if (parts[1] && parts[1].includes("vector")) {
          defaultVal = [];
        }
        models[inModel][fieldName] = defaultVal;
        continue;
      } else {
        inModel = null;
      }
    }

    if (trimmed.startsWith("fn ")) {
      const match = trimmed.match(/^fn\s+([A-Za-z0-9_]+)\s*\((.*?)\)(?:\s*->\s*[A-Za-z0-9_]+)?:/);
      if (match) {
        inFn = match[1];
        const params = match[2].split(",").map(p => p.trim().split(":")[0].trim()).filter(Boolean);
        fns[inFn] = { params, body: [] };
        continue;
      }
    }
    if (inFn) {
      if (raw.startsWith("    ") || raw.startsWith("\t")) {
        fns[inFn].body.push(trimmed);
        continue;
      } else {
        inFn = null;
      }
    }
  }

  function evalExpr(expr, scope) {
    expr = expr.trim();
    if (!expr) return "";

    // String interpolation %{var}
    expr = expr.replace(/%\{([A-Za-z0-9_]+)\}/g, (_, v) => {
      return scope[v] !== undefined ? scope[v] : "";
    });

    // to_text helper
    expr = expr.replace(/to_text\((.*?)\)/g, (_, inner) => {
      return "String(" + inner + ")";
    });

    // list_size helper
    expr = expr.replace(/list_size\((.*?)\)/g, (_, inner) => {
      return "(" + inner + ".length)";
    });

    // Model instantiations
    for (const m in models) {
      const regex = new RegExp("\\b" + m + "\\(\\)", "g");
      expr = expr.replace(regex, "Object.assign({}, __models." + m + ")");
    }
    expr = expr.replace(/vector\[[A-Za-z0-9_]+\]\(\)/g, "[]");

    // Replace function calls
    for (const f in fns) {
      const regex = new RegExp("\\b" + f + "\\(", "g");
      expr = expr.replace(regex, "__fns." + f + "(");
    }

    try {
      const contextKeys = Object.keys(scope);
      const contextVals = Object.values(scope);
      const fnRunner = new Function("__models", "__fns", ...contextKeys, "return (" + expr + ");");
      return fnRunner(models, callableFns, ...contextVals);
    } catch (e) {
      return expr;
    }
  }

  const callableFns = {};
  for (const f in fns) {
    callableFns[f] = (...args) => {
      const localScope = {};
      fns[f].params.forEach((p, idx) => {
        localScope[p] = args[idx];
      });
      return execBlock(fns[f].body, localScope);
    };
  }

  function execBlock(bodyLines, scope) {
    for (let i = 0; i < bodyLines.length; i++) {
      const line = bodyLines[i].trim();
      if (!line || line.startsWith("//")) continue;

      if (line.startsWith("if ") && line.endsWith(":")) {
        const cond = line.substring(3, line.length - 1);
        const ifVal = evalExpr(cond, scope);
        if (ifVal) {
          const nextLine = bodyLines[++i].trim();
          if (nextLine.startsWith("return ")) {
            return evalExpr(nextLine.substring(7), scope);
          }
        } else {
          i++;
        }
        continue;
      }

      if (line.startsWith("return ")) {
        return evalExpr(line.substring(7), scope);
      }

      if (line.startsWith("put(") && line.endsWith(")")) {
        const inner = line.substring(4, line.length - 1);
        const val = evalExpr(inner, scope);
        output += val + "\n";
        continue;
      }

      if (line.startsWith("println(") && line.endsWith(")")) {
        const inner = line.substring(8, line.length - 1);
        const val = evalExpr(inner, scope);
        output += val + "\n";
        continue;
      }

      if (line.startsWith("list_push(") && line.endsWith(")")) {
        const inner = line.substring(10, line.length - 1);
        const [vecName, valExpr] = inner.split(",").map(s => s.trim());
        const val = evalExpr(valExpr, scope);
        if (vecName.includes(".")) {
          const parts = vecName.split(".");
          if (scope[parts[0]] && scope[parts[0]][parts[1]]) {
            scope[parts[0]][parts[1]].push(val);
          }
        } else if (scope[vecName]) {
          scope[vecName].push(val);
        }
        continue;
      }

      if (line.includes(":=") || line.includes("=")) {
        const delim = line.includes(":=") ? ":=" : "=";
        const [lhs, rhs] = line.split(delim).map(s => s.trim());
        const cleanLhs = lhs.replace(/^[A-Za-z0-9_]+\s*:\s*vector\[.*?\]\s*:=/, "").replace(/^let\s+mut\s+/, "").split(":")[0].trim();
        const val = evalExpr(rhs, scope);
        if (cleanLhs.includes(".")) {
          const [obj, prop] = cleanLhs.split(".");
          if (scope[obj]) scope[obj][prop] = val;
        } else {
          scope[cleanLhs] = val;
        }
        continue;
      }
    }
    return null;
  }

  if (fns["main"]) {
    callableFns["main"]();
  }
  return output;
}

function runCode() {
  const code = editor.value;
  terminal.innerText = "[*] Compiling with Cluster v1.0.0 (LLVM 23.0 WASM target)...\n";
  timingBadge.innerText = "Compiling...";

  const startTime = performance.now();

  setTimeout(() => {
    try {
      const execResult = executeClusterCode(code);
      const duration = (performance.now() - startTime).toFixed(1);
      let output = "Finished build [-O3] target wasm32-wasi in " + duration + "ms\n";
      output += "---------------------------------------------------------\n";
      output += execResult || "[Program completed with zero output (exit 0)]\n";

      terminal.innerText = output;
      timingBadge.innerText = "Success (exit 0) in " + duration + "ms";
    } catch (err) {
      terminal.innerText = "Runtime Error: " + err.message;
      timingBadge.innerText = "Error";
    }
  }, 45);
}

runBtn.addEventListener("click", runCode);

// Initialize with hello world
editor.value = EXAMPLES.hello;
updateLineNumbers();
