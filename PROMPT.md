# General Bots Workspace - Master Development Guide

**Version:** 6.2.0 - DO NOT CHANGE  
**Project:** General Bots Workspace (Rust Monorepo)

---

## 📁 WORKSPACE STRUCTURE

| Crate | Purpose | Port | Tech Stack |
|-------|---------|------|------------|
| **botserver** | Main API server, business logic | 8088 | Axum, Diesel, Rhai BASIC |
| **botui** | Web UI server (dev) + proxy | 3000 | Axum, HTML/HTMX/CSS |
| **botapp** | Desktop app wrapper | - | Tauri 2 |
| **botlib** | Shared library | - | Core types, errors |
| **botbook** | Documentation | - | mdBook |
| **bottest** | Integration tests | - | tokio-test |
| **botdevice** | IoT/Device support | - | Rust |
| **botmodels** | Data models visualization | - | - |
| **botplugin** | Browser extension | - | JS |

### Key Paths
- **Binary:** `target/debug/botserver`
- **Run from:** `botserver/` directory
- **Env file:** `botserver/.env`
- **Stack:** `botserver/botserver-stack/`
- **UI Files:** `botui/ui/suite/`

---

## 🔥 ERROR FIXING WORKFLOW

### Mode 1: OFFLINE Batch Fix (PREFERRED)

When given error output:

```
1. Read ENTIRE error list first
2. Group errors by file
3. For EACH file with errors:
   a. View file → understand context
   b. Fix ALL errors in that file
   c. Write once with all fixes
4. Move to next file
5. REPEAT until ALL errors addressed
6. ONLY THEN → verify with build/diagnostics
```

**NEVER run cargo build/check/clippy DURING fixing**  
**Fix ALL errors OFFLINE first, verify ONCE at the end**

### Mode 2: Interactive Loop

```
LOOP UNTIL (0 warnings AND 0 errors):
  1. Run diagnostics → pick file with issues
  2. Read entire file
  3. Fix ALL issues in that file
  4. Write file once with all fixes
  5. Verify with diagnostics
  6. CONTINUE LOOP
END LOOP
```

### Common Error Patterns

| Error | Fix |
|-------|-----|
| `expected i64, found u64` | `value as i64` |
| `expected Option<T>, found T` | `Some(value)` |
| `expected T, found Option<T>` | `value.unwrap_or(default)` |
| `cannot multiply f32 by f64` | `f64::from(f32_val) * f64_val` |
| `no field X on type Y` | Check struct definition |
| `no variant X found` | Check enum definition |
| `function takes N arguments` | Match function signature |
| `cannot find function` | Add missing function or fix import |
| `unused variable` | Delete or use with `..` in patterns |
| `unused import` | Delete the import line |
| `cannot move out of X because borrowed` | Use scoping `{ }` to limit borrow |

---

## 🧠 MEMORY MANAGEMENT

When compilation fails due to memory issues (process "Killed"):

```bash
pkill -9 cargo; pkill -9 rustc; pkill -9 botserver
CARGO_BUILD_JOBS=1 cargo check -p botserver 2>&1 | tail -200
```

---

## 📏 FILE SIZE LIMITS - MANDATORY

### Maximum 1000 Lines Per File

When a file grows beyond this limit:

1. **Identify logical groups** - Find related functions
2. **Create subdirectory module** - e.g., `handlers/`
3. **Split by responsibility:**
   - `crud.rs` - Create, Read, Update, Delete
   - `ai.rs` - AI/ML handlers
   - `export.rs` - Export/import
   - `validation.rs` - Validation
   - `mod.rs` - Re-exports
4. **Keep files focused** - Single responsibility
5. **Update mod.rs** - Re-export all public items

**NEVER let a single file exceed 1000 lines - split proactively at 800 lines**

---

## 🚀 PERFORMANCE & SIZE STANDARDS

### Binary Size Optimization
- **Release Profile**: Always maintain `opt-level = "z"`, `lto = true`, `codegen-units = 1`, `strip = true`, `panic = "abort"`.
- **Dependencies**: 
  - Run `cargo tree --duplicates` weekly to find and resolve duplicate versions.
  - Run `cargo machete` to remove unused dependencies.
  - Use `default-features = false` and explicitly opt-in to needed features.

### Memory Optimization
- **Strings**: Prefer `&str` over `String` where possible. Use `Cow<str>` for conditional ownership.
- **Collections**: Use `Vec::with_capacity` when size is known. Consider `SmallVec` for hot paths.
- **Allocations**: Minimize heap allocations in hot paths.

### Linting & Code Quality
- **Clippy**: Code MUST pass `cargo clippy --all-targets --all-features` with **0 warnings**.
- **No Allow**: Do not use `#[allow(clippy::...)]` unless absolutely necessary and documented. Fix the underlying issue.

---

## 🔐 SECURITY DIRECTIVES - MANDATORY

### Error Handling - NO PANICS IN PRODUCTION

```rust
// ❌ FORBIDDEN
value.unwrap()
value.expect("message")
panic!("error")
todo!()
unimplemented!()

// ✅ REQUIRED
value?
value.ok_or_else(|| Error::NotFound)?
value.unwrap_or_default()
value.unwrap_or_else(|e| { log::error!("{}", e); default })
if let Some(v) = value { ... }
match value { Ok(v) => v, Err(e) => return Err(e.into()) }
```

### Command Execution - USE SafeCommand

```rust
// ❌ FORBIDDEN
Command::new("some_command").arg(user_input).output()

// ✅ REQUIRED
use crate::security::command_guard::SafeCommand;
SafeCommand::new("allowed_command")?
    .arg("safe_arg")?
    .execute()
```

### Error Responses - USE ErrorSanitizer

```rust
// ❌ FORBIDDEN
Json(json!({ "error": e.to_string() }))
format!("Database error: {}", e)

// ✅ REQUIRED
use crate::security::error_sanitizer::log_and_sanitize;
let sanitized = log_and_sanitize(&e, "context", None);
(StatusCode::INTERNAL_SERVER_ERROR, sanitized)
```

### SQL - USE sql_guard

```rust
// ❌ FORBIDDEN
format!("SELECT * FROM {}", user_table)

// ✅ REQUIRED
use crate::security::sql_guard::{sanitize_identifier, validate_table_name};
let safe_table = sanitize_identifier(&user_table);
validate_table_name(&safe_table)?;
```

---

## ❌ ABSOLUTE PROHIBITIONS

```
❌ NEVER use .unwrap() or .expect() in production code (tests OK)
❌ NEVER use panic!(), todo!(), unimplemented!()
❌ NEVER use Command::new() directly - use SafeCommand
❌ NEVER return raw error strings to HTTP clients
❌ NEVER use #[allow()] in source code - FIX the code instead
❌ NEVER add lint exceptions to Cargo.toml - FIX the code instead
❌ NEVER use _ prefix for unused variables - DELETE or USE them
❌ NEVER leave unused imports or dead code
❌ NEVER add comments - code must be self-documenting
❌ NEVER modify Cargo.toml lints section!
❌ NEVER use CDN links - all assets must be local
```

---

## ✅ MANDATORY CODE PATTERNS

### Use Self in Impl Blocks
```rust
impl MyStruct {
    fn new() -> Self { Self { } }  // ✅ Not MyStruct
}
```

### Derive Eq with PartialEq
```rust
#[derive(PartialEq, Eq)]  // ✅ Always both
struct MyStruct { }
```

### Inline Format Args
```rust
format!("Hello {name}")  // ✅ Not format!("{}", name)
```

### Combine Match Arms
```rust
match x {
    A | B => do_thing(),  // ✅ Combine identical arms
    C => other(),
}
```

---

## 🖥️ UI Architecture (botui + botserver)

### Two Servers During Development

| Server | Port | Purpose |
|--------|------|---------|
| **botui** | 3000 | Serves UI files + proxies API to botserver |
| **botserver** | 8088 | Backend API + embedded UI fallback |

### How It Works

```
Browser → localhost:3000 → botui (serves HTML/CSS/JS)
                        → /api/* proxied to botserver:8088
                        → /suite/* served from botui/ui/suite/
```

### Adding New Suite Apps

1. Create folder: `botui/ui/suite/<appname>/`
2. Add to `SUITE_DIRS` in `botui/src/ui_server/mod.rs`
3. Rebuild botui: `cargo build -p botui`
4. Add menu entry in `botui/ui/suite/index.html`

### Hot Reload

- **UI files (HTML/CSS/JS)**: Edit & refresh browser (no restart)
- **botui Rust code**: Rebuild + restart botui
- **botserver Rust code**: Rebuild + restart botserver

### Production (Single Binary)

When `botui/ui/suite/` folder not found, botserver uses **embedded UI** compiled into binary via `rust-embed`.

---

## 🎨 FRONTEND STANDARDS

### HTMX-First Approach
- Use HTMX to minimize JavaScript
- Server returns HTML fragments, not JSON
- Use `hx-get`, `hx-post`, `hx-target`, `hx-swap`
- WebSocket via htmx-ws extension

### Local Assets Only - NO CDN
```html
<!-- ✅ CORRECT -->
<script src="js/vendor/htmx.min.js"></script>

<!-- ❌ WRONG -->
<script src="https://unpkg.com/htmx.org@1.9.10"></script>
```

### Vendor Libraries Location
```
ui/suite/js/vendor/
├── htmx.min.js
├── htmx-ws.js
├── marked.min.js
└── gsap.min.js
```

---

## 📋 PROJECT-SPECIFIC PROMPTS

Each crate has its own PROMPT.md with specific guidelines:

| Crate | PROMPT.md Location | Focus |
|-------|-------------------|-------|
| botserver | `botserver/PROMPT.md` | API, security, Rhai BASIC |
| botui | `botui/PROMPT.md` | UI, HTMX, CSS design system |
| botapp | `botapp/PROMPT.md` | Tauri, desktop features |
| botlib | `botlib/PROMPT.md` | Shared types, errors |
| botbook | `botbook/PROMPT.md` | Documentation, mdBook |
| bottest | `bottest/PROMPT.md` | Test infrastructure |

### Special Prompts
| File | Purpose |
|------|---------|
| `botserver/src/tasks/PROMPT.md` | AutoTask LLM executor |
| `botserver/src/auto_task/APP_GENERATOR_PROMPT.md` | App generation |

---

## 🚀 STARTING DEVELOPMENT

### Start Both Servers
```bash
# Terminal 1: botserver
cd botserver && cargo run -- --noconsole

# Terminal 2: botui  
cd botui && BOTSERVER_URL="http://localhost:8088" cargo run
```

### Build Commands
```bash
# Check single crate
cargo check -p botserver

# Build workspace
cargo build

# Run tests
cargo test -p bottest
```

---

## 📋 CONTINUATION PROMPT

When starting a new session or continuing work:

```
Continue on gb/ workspace. Follow PROMPT.md strictly:

1. Check current state with build/diagnostics
2. Fix ALL warnings and errors - NO #[allow()] attributes
3. Delete unused code, don't suppress warnings
4. Remove unused parameters, don't prefix with _
5. Verify after each fix batch
6. Loop until 0 warnings, 0 errors
```

---

## 🔑 REMEMBER

- **OFFLINE FIRST** - Fix all errors from list before compiling
- **ZERO WARNINGS, ZERO ERRORS** - The only acceptable state
- **FIX, DON'T SUPPRESS** - No #[allow()], no Cargo.toml lint exceptions
- **SECURITY FIRST** - No unwrap, no raw errors, no direct commands
- **READ BEFORE FIX** - Always understand context first
- **BATCH BY FILE** - Fix ALL errors in a file at once
- **WRITE ONCE** - Single edit per file with all fixes
- **VERIFY LAST** - Only compile/diagnostics after ALL fixes
- **DELETE DEAD CODE** - Don't keep unused code around
- **Version 6.2.0** - Do not change without approval
