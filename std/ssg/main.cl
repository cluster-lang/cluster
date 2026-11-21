// ==============================================================================
// Cluster-SSG: Main Application Driver (src/main.cl)
// 100% Pure Cluster Language · Zero External Dependencies
// ==============================================================================

import "std/cld.cl"
import "std/ssg/document.cl"
import "std/ssg/template.cl"
import "std/ssg/islands.cl"
import "std/ssg/builder.cl"
import "std/ssg/server.cl"
import "std/ssg/cli.cl"

fn main() -> int:
    cli_print_banner()

    let mut is_binary: int = 0
    if file_exists("site/.binary") == 1 or file_exists(".binary") == 1:
        is_binary = 1

    cfg := config_default()
    if is_binary == 1:
        cfg.output_binary = 1
        println("\n--- Building Static Site (Jekyll Conventions + Hugo Speed) ---")
        println("Binary Mode: ENABLED (Generating .clb binary bundles alongside .html)")
    else:
        cfg.output_binary = 0
        println("\n--- Building Static Site (Jekyll Conventions + Hugo Speed) ---")
        println("Binary Mode: DISABLED (Lean static site: clean .html, .css & .js only)")

    cli_run_build(cfg)
    return 0
