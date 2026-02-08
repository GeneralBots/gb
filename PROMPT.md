# General Bots Workspace - Master Development Guide

**Version:** 6.2.0 - DO NOT CHANGE
**Project:** General Bots Workspace (Rust Monorepo)

---

## 🎯 FOR AI ASSISTANTS: READ THIS FIRST

### If You Are Claude Code, ChatGPT, or Any AI Assistant

**This file is your instruction manual for helping with this codebase.**

**Your Mission:**
1. Help with this Rust workspace
2. Follow ALL rules strictly
3. Achieve ZERO warnings, ZERO errors
4. Never suppress warnings - fix the code
5. Ask for clarification when unsure

**What This File Contains:**
- How to fix errors properly
- Security rules you MUST follow
- Code patterns to use
- Workflows for common tasks
- Decision-making frameworks

**Before You Do Anything:**
1. Read this entire file
2. Read the project-specific PROMPT.md for the crate you're working on
3. Understand the existing code before changing it

---

## 📁 WORKSPACE STRUCTURE

| Crate | Purpose | Port | Tech Stack |
|-------|---------|------|------------|
| **botserver** | Main API server, business logic | 9000 | Axum, Diesel, Rhai BASIC |
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
- **Env file:** `.env` (root level, not in botserver/)
- **Stack:** `botserver-stack/`
- **UI Files:** `botui/ui/suite/`

---

## 🔥 ERROR FIXING WORKFLOW

### The Golden Rule: FIX ALL ISSUES AT ONCE

**Never** fix one error, compile, fix another error, compile again.

**Instead:**
1. Read ALL errors
2. Group them by file
3. Fix ALL errors in each file
4. Write the complete file
5. Verify at the end

### Mode 1: OFFLINE Batch Fix (PREFERRED)

When given error output:

```
STEP 1: Read ENTIRE error list
STEP 2: Group errors by file
STEP 3: For EACH file with errors:
         a. Read the entire file
         b. Understand the context
         c. Fix ALL errors in that file
         d. Write the file once with all fixes
STEP 4: Move to next file
STEP 5: Repeat until ALL errors addressed
STEP 6: ONLY THEN → verify with build/diagnostics
```

**DO NOT** run cargo build/check/clippy during fixing
**FIX ALL errors OFFLINE first, verify ONCE at the end

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

### Why This Matters

- **Speed:** Compiling is slow. Fixing offline is fast.
- **Context:** Reading the whole file helps you understand patterns.
- **Quality:** Seeing all issues at once prevents partial fixes.
- **Reliability:** One write per file reduces mistakes.

---

## 🧠 MEMORY MANAGEMENT

When compilation fails due to memory issues (process "Killed"):

```bash
# Kill all cargo processes
pkill -9 cargo; pkill -9 rustc; pkill -9 botserver

# Build with single job
CARGO_BUILD_JOBS=1 cargo check -p botserver 2>&1 | tail -200
```

---

## 📏 FILE SIZE LIMITS - MANDATORY

### Maximum 1000 Lines Per File

When a file grows beyond this limit:

**STEP 1: Identify logical groups**
- Find related functions
- Look for natural boundaries
- Identify separate concerns

**STEP 2: Create subdirectory module**
- Example: `handlers/` for HTTP handlers
- Example: `models/` for data structures
- Example: `utils/` for helper functions

**STEP 3: Split by responsibility**

Common patterns:
```
handlers/
├── crud.rs          # Create, Read, Update, Delete
├── ai.rs            # AI/ML handlers
├── export.rs        # Export/import
├── validation.rs    # Validation
└── mod.rs           # Re-exports
```

**STEP 4: Keep files focused**
- Single responsibility per file
- Related functions together
- Clear naming

**STEP 5: Update mod.rs**
- Re-export all public items
- Maintain the same external API

**NEVER** let a single file exceed 1000 lines - split proactively at 800 lines

---

## 🚀 PERFORMANCE & SIZE STANDARDS

### Binary Size Optimization

**Release Profile** (in Cargo.toml):
```toml
[profile.release]
opt-level = "z"      # Optimize for size
lto = true           # Link-time optimization
codegen-units = 1    # Better optimization
strip = true         # Remove debug symbols
panic = "abort"      # Reduce binary size
```

**Dependencies:**
- Run `cargo tree --duplicates` weekly - find and fix duplicate versions
- Run `cargo machete` monthly - remove unused dependencies
- Use `default-features = false` - only enable what you need
- Explicitly opt-in to needed features

### Memory Optimization

**Strings:**
- Prefer `&str` over `String` where possible
- Use `Cow<str>` for conditional ownership
- Avoid string copies in hot paths

**Collections:**
- Use `Vec::with_capacity` when size is known
- Consider `SmallVec` for hot paths
- Pre-allocate when possible

**Allocations:**
- Minimize heap allocations in hot paths
- Use stack allocation when possible
- Profile before optimizing

### Linting & Code Quality

**Clippy:**
- Code MUST pass `cargo clippy --all-targets --all-features`
- ZERO warnings allowed
- Do not use `#[allow(clippy::...)]` unless absolutely necessary
- If you use `#[allow()]`, document WHY in a comment

---

## 🔐 SECURITY DIRECTIVES - MANDATORY

### Error Handling - NO PANICS IN PRODUCTION

**FORBIDDEN:**
```rust
// ❌ NEVER use these in production code
value.unwrap()
value.expect("message")
panic!("error")
todo!()
unimplemented!()
```

**REQUIRED:**
```rust
// ✅ Use proper error handling
value?  // Propagate error
value.ok_or_else(|| Error::NotFound)?  // Convert to error
value.unwrap_or_default()  // Provide default
value.unwrap_or_else(|e| { log::error!("{}", e); default })  // Log and default
if let Some(v) = value { ... }  // Pattern match
match value {
    Ok(v) => v,
    Err(e) => return Err(e.into()),  // Convert error
}
```

**Tests are different:** You can use `.unwrap()`, `.expect()` in tests.

### Command Execution - USE SafeCommand

**FORBIDDEN:**
```rust
// ❌ NEVER execute commands directly
use std::process::Command;
Command::new("some_command").arg(user_input).output()
```

**REQUIRED:**
```rust
// ✅ ALWAYS use SafeCommand
use crate::security::command_guard::SafeCommand;
SafeCommand::new("allowed_command")?
    .arg("safe_arg")?
    .execute()
```

**Why?** SafeCommand:
- Only allows whitelisted commands
- Sanitizes arguments
- Prevents command injection
- Logs all command execution

### Error Responses - USE ErrorSanitizer

**FORBIDDEN:**
```rust
// ❌ NEVER return raw errors to clients
Json(json!({ "error": e.to_string() }))
format!("Database error: {}", e)
```

**REQUIRED:**
```rust
// ✅ ALWAYS sanitize errors
use crate::security::error_sanitizer::log_and_sanitize;
let sanitized = log_and_sanitize(&e, "context", None);
(StatusCode::INTERNAL_SERVER_ERROR, sanitized)
```

**Why?** Prevents information leakage:
- Hides internal paths
- Hides database details
- Hides system information
- Logs full error locally

### SQL - USE sql_guard

**FORBIDDEN:**
```rust
// ❌ NEVER build SQL with user input
format!("SELECT * FROM {}", user_table)
```

**REQUIRED:**
```rust
// ✅ ALWAYS use SQL guards
use crate::security::sql_guard::{sanitize_identifier, validate_table_name};
let safe_table = sanitize_identifier(&user_table);
validate_table_name(&safe_table)?;
```

**Why?** Prevents SQL injection.

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
    fn new() -> Self {
        Self { field: value }  // ✅ Use Self, not MyStruct
    }
}
```

**Why:** Makes refactoring easier - only change the struct name once.

### Derive Eq with PartialEq

```rust
#[derive(PartialEq, Eq)]  // ✅ Always derive both
struct MyStruct { }
```

**Why:** Eq requires PartialEq, and you usually need both for collections.

### Inline Format Args

```rust
format!("Hello {name}")  // ✅ Use inline format args
// NOT: format!("{}", name)  // ❌
```

**Why:** More readable, less error-prone.

### Combine Match Arms

```rust
match x {
    A | B => do_thing(),  // ✅ Combine identical arms
    C => other(),
}
```

**Why:** Less duplication, clearer intent.

---

## 🖥️ UI ARCHITECTURE (botui + botserver)

### Two Servers During Development

| Server | Port | Purpose |
|--------|------|---------|
| **botui** | 3000 | Serves UI files + proxies API to botserver |
| **botserver** | 9000 | Backend API + embedded UI fallback |

### How It Works

```
Browser → localhost:3000 → botui (serves HTML/CSS/JS)
                        → /api/* proxied to botserver:9000
                        → /suite/* served from botui/ui/suite/
```

### Adding New Suite Apps

**STEP 1: Create folder**
```
botui/ui/suite/<appname>/
├── index.html
├── app.css
└── app.js
```

**STEP 2: Add to SUITE_DIRS**
- File: `botui/src/ui_server/mod.rs`
- Add your appname to the `SUITE_DIRS` constant

**STEP 3: Rebuild botui**
```bash
cargo build -p botui
```

**STEP 4: Add menu entry**
- File: `botui/ui/suite/index.html`
- Add link to your new app

### Hot Reload

- **UI files (HTML/CSS/JS):** Edit & refresh browser (no restart needed)
- **botui Rust code:** Rebuild + restart botui
- **botserver Rust code:** Rebuild + restart botserver

### Production (Single Binary)

When `botui/ui/suite/` folder not found:
- BotServer uses **embedded UI** compiled into binary
- Uses `rust-embed` to include UI files
- Single binary deployment

---

## 🎨 FRONTEND STANDARDS

### HTMX-First Approach

**Use HTMX to minimize JavaScript:**
- Server returns HTML fragments, not JSON
- Use `hx-get`, `hx-post`, `hx-target`, `hx-swap`
- WebSocket via htmx-ws extension

**Benefits:**
- Less JavaScript to maintain
- Better progressive enhancement
- Simpler state management
- More accessible

### Local Assets Only - NO CDN

**CORRECT:**
```html
<!-- ✅ Use local assets -->
<script src="js/vendor/htmx.min.js"></script>
<link rel="stylesheet" href="css/vendor/bulma.min.css">
```

**WRONG:**
```html
<!-- ❌ NEVER use CDN links -->
<script src="https://unpkg.com/htmx.org@1.9.10"></script>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@0.9.4/css/bulma.min.css">
```

**Why?**
- Offline support
- No external dependencies
- Faster loading
- Privacy
- Security

### Vendor Libraries Location

```
ui/suite/js/vendor/
├── htmx.min.js
├── htmx-ws.js
├── marked.min.js
└── gsap.min.js

ui/suite/css/vendor/
├── bulma.min.css
└── fontawesome/
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

**ALWAYS read the relevant PROMPT.md before working on a project.**

---

## 🚀 STARTING DEVELOPMENT

### Start Both Servers

**Terminal 1: botserver**
```bash
cd botserver
cargo run -- --noconsole
```

**Terminal 2: botui**
```bash
cd botui
BOTSERVER_URL="http://localhost:9000" cargo run
```

### Build Commands

```bash
# Check single crate (fastest)
cargo check -p botserver

# Build workspace
cargo build

# Build release (optimized)
cargo build --release -p botserver

# Run tests
cargo test -p bottest

# Run with specific port
BOTSERVER_PORT=9000 ./target/debug/botserver
```

---

## 🤖 HOW TO WORK LIKE CLAUDE CODE

### Decision-Making Framework

When you need to make a decision:

**1. Is there an existing pattern?**
- Search the codebase for similar code
- Follow the existing pattern
- Consistency > your preference

**2. Is it covered in PROMPT.md?**
- Check the workspace PROMPT.md
- Check the project-specific PROMPT.md
- Follow the rules strictly

**3. Is it a security issue?**
- Default to the most secure option
- Never bypass security for convenience
- Ask if unsure

**4. Will it affect other parts?**
- Check for dependencies
- Update related files
- Test thoroughly

### Common Workflows

#### Workflow 1: Fix Compilation Errors

```
INPUT: Error messages from cargo build

STEP 1: Read all error messages
STEP 2: Group errors by file
STEP 3: For each file:
         a. Read the entire file
         b. Understand the context
         c. Fix ALL errors in the file
         d. Write the complete fixed file
STEP 4: Run cargo build to verify
STEP 5: Repeat if needed

OUTPUT: Clean build
```

#### Workflow 2: Add a New Feature

```
INPUT: Feature request

STEP 1: Understand the requirement
STEP 2: Find similar existing features (search codebase)
STEP 3: Read the relevant files
STEP 4: Design the implementation (follow existing patterns)
STEP 5: Write the code
STEP 6: Update tests if needed
STEP 7: Verify with build/diagnostics

OUTPUT: Working feature
```

#### Workflow 3: Debug an Issue

```
INPUT: Bug report or unexpected behavior

STEP 1: Read the error message carefully
STEP 2: Read the relevant code
STEP 3: Understand the context
STEP 4: Identify the root cause
STEP 5: Fix the issue
STEP 6: Verify the fix

OUTPUT: Fixed bug
```

### What NOT to Do

❌ **Don't** make partial edits - fix everything in a file at once
❌ **Don't** suppress warnings with `#[allow()]` - fix the code
❌ **Don't** use `.unwrap()` or `.expect()` - handle errors properly
❌ **Don't** add secrets to `.env` - use Vault
❌ **Don't** run build after each small fix - batch your fixes
❌ **Don't** guess - read the code and understand it first
❌ **Don't** add comments - make code self-documenting
❌ **Don't** leave unused code - delete it

### What TO Do

✅ **Do** read files before editing
✅ **Do** fix all issues in a file at once
✅ **Do** follow existing patterns
✅ **Do** handle errors properly with `?` operator
✅ **Do** use `SafeCommand` for external commands
✅ **Do** store secrets in Vault
✅ **Do** verify after all fixes are complete
✅ **Do** delete unused code
✅ **Do** ask for clarification when unsure

### Core Principles

**1. READ BEFORE EDITING**
- Always read the full file before making changes
- Understand the existing patterns and conventions
- Look at similar files to understand the pattern

**2. FIX ALL ISSUES AT ONCE**
- When you find multiple errors in a file, fix ALL of them
- Do NOT make partial edits - rewrite the full file if needed
- Group changes by file, not by error type

**3. ZERO TOLERANCE FOR WARNINGS**
- Warnings are treated as errors
- Never use `#[allow()]` to suppress warnings
- Fix the underlying issue, don't hide it

**4. SECURITY FIRST**
- No `.unwrap()`, `.expect()`, `panic!()`, `todo!()` in production code
- Use `SafeCommand` for all external command execution
- Use `ErrorSanitizer` for error messages sent to clients
- All secrets go in Vault, never in environment variables

**5. VERIFICATION LAST**
- Fix all issues offline first
- Only run build/diagnostics after ALL fixes are complete
- Loop until 0 warnings, 0 errors

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

## 🔧 COMMON ERROR PATTERNS

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
- **GIT WORKFLOW** - ALWAYS push to ALL repositories (github, pragmatismo)
- **PORT 9000** - Default botserver port (can override with BOTSERVER_PORT)
