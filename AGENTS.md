# General Bots AI Agent Guidelines

> **⚠️ CRITICAL SECURITY WARNING**
>
> **NEVER CREATE FILES WITH SECRETS IN THE REPOSITORY ROOT**
>
> Secret files MUST be placed in `/tmp/` only:
> - ✅ `/tmp/vault-token-gb` - Vault root token
> - ✅ `/tmp/vault-unseal-key-gb` - Vault unseal key
> - ❌ `vault-unseal-keys` - FORBIDDEN (tracked by git)
> - ❌ `start-and-unseal.sh` - FORBIDDEN (contains secrets)
>
> **Why `/tmp/`?**
> - Cleared on reboot (ephemeral)
> - Not tracked by git
> - Standard Unix security practice
> - Prevents accidental commits

---

## 🧭 LLM Navigation Guide

### Reading This Workspace

**For LLMs analyzing this codebase:**
1. Start with **[Component Dependency Graph](../README.md#-component-dependency-graph)** in README to understand relationships
2. Review **[Module Responsibility Matrix](../README.md#-module-responsibility-matrix)** for what each module does
3. Study **[Data Flow Patterns](../README.md#-data-flow-patterns)** to understand execution flow
4. Reference **[Common Architectural Patterns](../README.md#-common-architectural-patterns)** before making changes
5. Check **[Security Rules](#-security-directives---mandatory)** below - violations are blocking issues
6. Follow **[Code Patterns](#-mandatory-code-patterns)** below - consistency is mandatory

---

## 🔐 Security Directives - MANDATORY

### 1. Error Handling - NO PANICS IN PRODUCTION

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

### 2. Command Execution - USE SafeCommand

```rust
// ❌ FORBIDDEN
Command::new("some_command").arg(user_input).output()

// ✅ REQUIRED
use crate::security::command_guard::SafeCommand;
SafeCommand::new("allowed_command")?
    .arg("safe_arg")?
    .execute()
```

### 3. Error Responses - USE ErrorSanitizer

```rust
// ❌ FORBIDDEN
Json(json!({ "error": e.to_string() }))
format!("Database error: {}", e)

// ✅ REQUIRED
use crate::security::error_sanitizer::log_and_sanitize;
let sanitized = log_and_sanitize(&e, "context", None);
(StatusCode::INTERNAL_SERVER_ERROR, sanitized)
```

### 4. SQL - USE sql_guard

```rust
// ❌ FORBIDDEN
format!("SELECT * FROM {}", user_table)

// ✅ REQUIRED
use crate::security::sql_guard::{sanitize_identifier, validate_table_name};
let safe_table = sanitize_identifier(&user_table);
validate_table_name(&safe_table)?;
```

---

## ✅ Mandatory Code Patterns

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

## ❌ Absolute Prohibitions

- ❌ **NEVER** use `.unwrap()` or `.expect()` in production code (tests OK)
- ❌ **NEVER** use `panic!()`, `todo!()`, `unimplemented!()`
- ❌ **NEVER** use `Command::new()` directly - use `SafeCommand`
- ❌ **NEVER** return raw error strings to HTTP clients
- ❌ **NEVER** use `#[allow()]` in source code - FIX the code instead
- ❌ **NEVER** add lint exceptions to `Cargo.toml` - FIX the code instead
- ❌ **NEVER** use `_` prefix for unused variables - DELETE or USE them
- ❌ **NEVER** leave unused imports or dead code
- ❌ **NEVER** use CDN links - all assets must be local
- ❌ **NEVER** use `cargo clean` - causes 30min rebuilds, use `./reset.sh` for database issues
- ❌ **NEVER** create `.md` documentation files without checking `botbook/` first

---

## 📏 File Size Limits - MANDATORY

### Maximum 450 Lines Per File

When a file grows beyond this limit:

1. **Identify logical groups** - Find related functions
2. **Create subdirectory module** - e.g., `handlers/`
3. **Split by responsibility:**
   - `types.rs` - Structs, enums, type definitions
   - `handlers.rs` - HTTP handlers and routes
   - `operations.rs` - Core business logic
   - `utils.rs` - Helper functions
   - `mod.rs` - Re-exports and configuration
4. **Keep files focused** - Single responsibility
5. **Update mod.rs** - Re-export all public items

**NEVER let a single file exceed 450 lines - split proactively at 350 lines**

---

## 🔥 Error Fixing Workflow

### Mode 1: OFFLINE Batch Fix (PREFERRED)

When given error output:

1. **Read ENTIRE error list first**
2. **Group errors by file**
3. **For EACH file with errors:**
   a. View file → understand context
   b. Fix ALL errors in that file
   c. Write once with all fixes
4. **Move to next file**
5. **REPEAT until ALL errors addressed**
6. **ONLY THEN → verify with build/diagnostics**

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

---

## 🎭 Playwright Browser Testing - YOLO Mode

**When user requests to start YOLO mode with Playwright:**

1. **Start the browser** - Use `mcp__playwright__browser_navigate` to open http://localhost:3000
2. **Take snapshot** - Use `mcp__playwright__browser_snapshot` to see current page state
3. **Test user flows** - Use click, type, fill_form, etc.
4. **Verify results** - Check for expected content, errors in console, network requests
5. **Validate backend** - Check database and services to confirm process completion
6. **Report findings** - Always include screenshot evidence with `browser_take_screenshot`

**Bot-Specific Testing URL Pattern:**
`http://localhost:3000/<botname>`

**Backend Validation Checks:**
After UI interactions, validate backend state via `psql` or `tail` logs.

---

## 🧪 Testing Strategy

### Unit Tests
- **Location**: Each crate has `tests/` directory or inline `#[cfg(test)]` modules
- **Naming**: Test functions use `test_` prefix or describe what they test
- **Running**: `cargo test -p <crate_name>` or `cargo test` for all

### Integration Tests
- **Location**: `bottest/` crate contains integration tests
- **Scope**: Tests full workflows across multiple crates
- **Running**: `cargo test -p bottest`

### Coverage Goals
- **Critical paths**: 80%+ coverage required
- **Error handling**: ALL error paths must have tests
- **Security**: All security guards must have tests

---

## 🐛 Debugging Rules

### 🚨 CRITICAL ERROR HANDLING RULE

**STOP EVERYTHING WHEN ERRORS APPEAR**

When ANY error appears in logs during startup or operation:
1. **IMMEDIATELY STOP** - Do not continue with other tasks
2. **IDENTIFY THE ERROR** - Read the full error message and context
3. **FIX THE ERROR** - Address the root cause, not symptoms
4. **VERIFY THE FIX** - Ensure error is completely resolved
5. **ONLY THEN CONTINUE** - Never ignore or work around errors

**NEVER restart servers to "fix" errors - FIX THE ACTUAL PROBLEM**

### Log Locations

| Component | Log File | What's Logged |
|-----------|----------|---------------|
| **botserver** | `botserver.log` | API requests, errors, script execution, **client navigation events** |
| **botui** | `botui.log` | UI rendering, WebSocket connections |
| **drive_monitor** | In botserver logs with `[drive_monitor]` prefix | File sync, compilation |
| **client errors** | In botserver logs with `CLIENT:` prefix | JavaScript errors, navigation events |

---

## 🎨 Frontend Standards

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

---

## 🚀 Performance & Size Standards

### Binary Size Optimization
- **Release Profile**: Always maintain `opt-level = "z"`, `lto = true`, `codegen-units = 1`, `strip = true`, `panic = "abort"`.
- **Dependencies**: 
  - Run `cargo tree --duplicates` weekly
  - Run `cargo machete` to remove unused dependencies
  - Use `default-features = false` and explicitly opt-in to needed features

### Linting & Code Quality
- **Clippy**: Code MUST pass `cargo clippy --all-targets --all-features` with **0 warnings**.
- **No Allow**: Do not use `#[allow(clippy::...)]` unless absolutely necessary and documented.

---

## 🔑 Memory & Main Directives

**LOOP AND COMPACT UNTIL 0 WARNINGS - MAXIMUM PRECISION**

- 0 warnings
- 0 errors
- Trust project diagnostics
- Respect all rules
- No `#[allow()]` in source code
- Real code fixes only

**Remember:**
- **OFFLINE FIRST** - Fix all errors from list before compiling
- **BATCH BY FILE** - Fix ALL errors in a file at once
- **WRITE ONCE** - Single edit per file with all fixes
- **VERIFY LAST** - Only compile/diagnostics after ALL fixes
- **DELETE DEAD CODE** - Don't keep unused code around
- **GIT WORKFLOW** - ALWAYS push to ALL repositories (github, pragmatismo)
