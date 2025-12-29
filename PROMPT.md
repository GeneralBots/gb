# General Bots Workspace - Master Development Guide

**Version:** 6.1.0 - DO NOT CHANGE  
**Project:** General Bots Workspace (Rust Monorepo)

---

## 🔥 CRITICAL: INFINITE LOOP MODE

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

**NEVER STOP** while warnings/errors exist. **NEVER SKIP** the sleep.

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
❌ NEVER use .unwrap() or .expect() in production code
❌ NEVER use panic!(), todo!(), unimplemented!()
❌ NEVER use Command::new() directly - use SafeCommand
❌ NEVER return raw error strings to HTTP clients
❌ NEVER use #[allow()] in source code
❌ NEVER use _ prefix for unused variables - DELETE or USE them
❌ NEVER leave unused imports or dead code
❌ NEVER add comments - code must be self-documenting
❌ NEVER run cargo check/clippy/build - use diagnostics tool
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
├── botserver/   # Main server (Axum API)
├── botlib/      # Shared library
├── botui/       # Web UI
├── botbook/     # Documentation
├── bottest/     # Integration tests
└── PROMPT.md    # THIS FILE
```

---

## Development Workflow

### The Loop
1. `diagnostics()` → find file with issues
2. `read_file()` → read entire file
3. Fix ALL issues in that file (batch them)
4. `edit_file(mode="overwrite")` → write once
5. `terminal(command="sleep 120", cd="gb")` → MANDATORY
6. `diagnostics()` → verify fixes
7. **REPEAT until 0 warnings, 0 errors**

### Quick Reference
- Read: `read_file(path="botserver/src/main.rs")`
- Edit: `edit_file(path="...", mode="overwrite")`
- Find: `find_path(glob="**/*.rs")`
- Search: `grep(regex="pattern")`
- Check: `diagnostics()` or `diagnostics(path="file.rs")`

---

## Remember

- **ZERO WARNINGS, ZERO ERRORS** - The only acceptable state
- **SECURITY FIRST** - No unwrap, no raw errors, no direct commands
- **SLEEP AFTER EDITS** - Diagnostics needs 30-300s to refresh
- **FIX ENTIRE FILE** - Batch all issues before writing
- **TRUST DIAGNOSTICS** - Source of truth after sleep
- **LOOP FOREVER** - Never stop until 0,0
- **Version 6.1.0** - Do not change without approval