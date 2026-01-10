# General Bots Workspace - Master Development Guide

**Version:** 6.2.0 - DO NOT CHANGE  
**Project:** General Bots Workspace (Rust Monorepo)

---

## 🔥 CRITICAL: OFFLINE-FIRST ERROR FIXING

### Primary Mode: OFFLINE Batch Fix (PREFERRED)

When given an error.out file or error list or in last instance cargo build once:

```
1. Read the ENTIRE error list first
2. Group errors by file
3. For EACH file with errors:
   a. read_file() → understand context
   b. Fix ALL errors in that file
   c. edit_file() → write once
4. Move to next file
5. REPEAT until ALL errors addressed
6. ONLY THEN → compile/diagnostics to verify
```

**NEVER run cargo build/check/clippy DURING fixing**  
**NEVER run diagnostics() DURING fixing**  
**Fix ALL errors OFFLINE first, verify ONCE at the end**

### Secondary Mode: Interactive Loop (when no error list)

```
LOOP UNTIL (0 warnings AND 0 errors):
  1. diagnostics() → pick file with issues
  2. Read entire file
  3. Fix ALL issues in that file
  4. Write file once with all fixes
  5. Sleep 30-300s: terminal(command="sleep 120", cd="gb")
  6. diagnostics() → verify
  7. CONTINUE LOOP
END LOOP
```

---

## 🔐 SECURITY DIRECTIVES - MANDATORY FOR ALL NEW CODE

### Error Handling - NO PANICS IN PRODUCTION

```rust
// ❌ FORBIDDEN - causes panic
value.unwrap()
value.expect("message")
panic!("error")
todo!()
unimplemented!()

// ✅ REQUIRED - proper error handling
value?
value.ok_or_else(|| Error::NotFound)?
value.unwrap_or_default()
value.unwrap_or_else(|e| { log::error!("{}", e); default })
if let Some(v) = value { ... }
match value { Ok(v) => v, Err(e) => return Err(e.into()) }
```

### Command Execution - USE SafeCommand

```rust
// ❌ FORBIDDEN - direct command execution
Command::new("some_command").arg(user_input).output()

// ✅ REQUIRED - use SafeCommand from security module
use crate::security::command_guard::SafeCommand;
SafeCommand::new("allowed_command")?
    .arg("safe_arg")?
    .execute()
```

### Error Responses - USE ErrorSanitizer

```rust
// ❌ FORBIDDEN - leaks internal details
Json(json!({ "error": e.to_string() }))
format!("Database error: {}", e)

// ✅ REQUIRED - sanitize errors
use crate::security::error_sanitizer::log_and_sanitize;
let sanitized = log_and_sanitize(&e, "context", None);
(StatusCode::INTERNAL_SERVER_ERROR, sanitized)
```

### SQL - USE sql_guard

```rust
// ❌ FORBIDDEN - SQL injection risk
format!("SELECT * FROM {}", user_table)

// ✅ REQUIRED - use sql_guard functions
use crate::security::sql_guard::{sanitize_identifier, validate_table_name};
let safe_table = sanitize_identifier(&user_table);
validate_table_name(&safe_table)?;
```

---

## ABSOLUTE PROHIBITIONS

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
❌ NEVER run cargo check/clippy/build DURING offline fixing
❌ NEVER run diagnostics() DURING offline fixing
❌ NEVER modify Cargo.toml lints section!
```

---

## FIXING WARNINGS - DO NOT SUPPRESS

When you encounter warnings, FIX them properly:

### Dead Code
```rust
// ❌ WRONG - suppressing
#[allow(dead_code)]
struct Unused { field: String }

// ✅ CORRECT - delete unused code or use it
// DELETE the struct entirely, or add code that uses it
```

### Unused Variables
```rust
// ❌ WRONG - underscore prefix
fn foo(_unused: String) { }

// ✅ CORRECT - remove parameter or use it
fn foo() { }  // remove if not needed
fn foo(used: String) { println!("{used}"); }  // or use it
```

### Unused Fields in Pattern Match
```rust
// ✅ CORRECT - use .. to ignore unused fields
WhiteboardOperation::RotateShape { shape_id, .. } => { }
```

### Unreachable Code
```rust
// ❌ WRONG - allow attribute
#[allow(unreachable_code)]
{ unreachable_statement(); }

// ✅ CORRECT - restructure code so it's reachable or delete it
```

### Unused Async
```rust
// ❌ WRONG - allow attribute  
#[allow(clippy::unused_async)]
async fn handler() { sync_code(); }

// ✅ CORRECT - add .await or remove async
fn handler() { sync_code(); }  // remove async if not needed
async fn handler() { some_future.await; }  // or add await
```

### Type Mismatches
```rust
// ✅ CORRECT - use proper type conversions
value as i64                    // simple cast
f64::from(value)               // safe conversion
Some(value)                    // wrap in Option
value.unwrap_or(default)       // unwrap with default
```

---

## MANDATORY CODE PATTERNS

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

## Workspace Structure

```
gb/
├── botapp/      # Desktop app (Tauri)
├── botserver/   # Main server (Axum API) - port 8088
├── botlib/      # Shared library
├── botui/       # Web UI server - port 3000
├── botbook/     # Documentation
├── bottest/     # Integration tests
└── PROMPT.md    # THIS FILE
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

When adding a new app (e.g., `video`, `learn`):

1. Create folder: `botui/ui/suite/<appname>/`
2. Add to `SUITE_DIRS` in `botui/src/ui_server/mod.rs`:
```rust
const SUITE_DIRS: &[&str] = &[
    "chat", "mail", "calendar", ...,
    "video",  // ← add new app here
    "learn",
];
```
3. Rebuild botui: `cargo build -p botui`
4. Add menu entry in `botui/ui/suite/index.html`

### Hot Reload

- **UI files (HTML/CSS/JS)**: Edit & refresh browser (no restart)
- **botui Rust code**: Rebuild + restart botui
- **botserver Rust code**: Rebuild + restart botserver

### Production (Single Binary)

When `botui/ui/suite/` folder not found, botserver uses **embedded UI** compiled into binary via `rust-embed`.

---

## 🚀 OFFLINE ERROR FIXING WORKFLOW

### Step 1: Analyze Error List
```
- Read entire error.out or error list or cargo build once
- Group by file path
- Note line numbers and error types
- Understand dependencies between errors
```

### Step 2: Fix Each File
```
For each file:
1. read_file(path, start_line, end_line) - get context
2. Understand the struct/function signatures
3. Fix ALL errors in that file at once
4. edit_file() - single write operation
```

### Step 3: Common Error Patterns

| Error | Fix |
|-------|-----|
| `expected i64, found u64` | `value as i64` |
| `expected Option<T>, found T` | `Some(value)` |
| `expected T, found Option<T>` | `value.unwrap_or(default)` |
| `cannot multiply f32 by f64` | `f64::from(f32_val) * f64_val` |
| `no field X on type Y` | Check struct definition, use correct field |
| `no variant X found` | Check enum definition, use correct variant |
| `function takes N arguments` | Match function signature |
| `cannot find function` | Add missing function or fix import |
| `unused variable` | Delete or use with `..` in patterns |
| `unused import` | Delete the import line |
| `cannot move out of X because borrowed` | Use scoping `{ }` to limit borrow |

### Step 4: Verify (ONLY AT END)
```bash
cargo build -p botserver 2>&1 | tee error.out
```

---

## 🚀 BOTSERVER RUN LOOP - FOR RUNTIME FIXES

```
LOOP UNTIL botserver starts successfully:
  1. cargo build -p botserver 2>&1 | tail -20
  2. IF build fails → fix errors → CONTINUE LOOP
  3. cd botserver && timeout 30 ../target/debug/botserver --noconsole 2>&1 | head -80
  4. Analyze output for errors/warnings
  5. Fix issues in code
  6. CONTINUE LOOP
END LOOP
```

### Key Paths (relative to gb/)
- Binary: `target/debug/botserver`
- Run from: `botserver/` directory
- Env file: `botserver/.env`
- Stack: `botserver/botserver-stack/`
- Logs: `botserver/botserver-stack/logs/<component>/`

---

## Quick Reference

- Read: `read_file(path="botserver/src/main.rs")`
- Read section: `read_file(path="...", start_line=100, end_line=200)`
- Edit: `edit_file(path="...", mode="edit")`
- Find: `find_path(glob="**/*.rs")`
- Search: `grep(regex="pattern")`
- Check: `diagnostics()` or `diagnostics(path="file.rs")`

---

## 📋 CONTINUATION PROMPT FOR NEXT SESSION

### For OFFLINE error fixing:
```
Fix all errors in error.out OFFLINE:

1. Read the entire error list first
2. Group errors by file
3. Fix ALL errors in each file before moving to next
4. DO NOT run cargo build or diagnostics until ALL fixes done
5. Write each file ONCE with all fixes

Follow PROMPT.md strictly:
- No #[allow()] attributes
- Delete unused code, don't suppress
- Use proper type conversions
- Check struct/enum definitions before fixing
```

### For interactive fixing:
```
Continue working on gb/ workspace. Follow PROMPT.md strictly:

1. Run diagnostics() first
2. Fix ALL warnings and errors - NO #[allow()] attributes
3. Delete unused code, don't suppress warnings
4. Remove unused parameters, don't prefix with _
5. Sleep after edits, verify with diagnostics
6. Loop until 0 warnings, 0 errors
```

---

## Remember

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
