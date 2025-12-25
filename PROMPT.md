# General Bots Workspace - Master Development Guide

**Version:** 6.1.0 - DO NOT CHANGE  
**Project:** General Bots Workspace (Rust Monorepo)  
**Purpose:** Master LLM context for all workspace development

---

## ⚠️ CRITICAL: READ PROJECT-SPECIFIC PROMPTS

**Each subproject has its own PROMPT.md with specific guidelines:**

- `botapp/PROMPT.md` - Desktop application (Tauri wrapper)
- `botserver/PROMPT.md` - Main server (business logic, API, database)
- `botlib/PROMPT.md` - Shared library (types, utilities)
- `botui/PROMPT.md` - Web UI (frontend)
- `botbook/PROMPT.md` - Documentation
- `bottest/PROMPT.md` - Integration tests

**ALWAYS read the relevant project PROMPT.md before working on that project.**

---

## 🔥 MAIN DIRECTIVE: LOOP AND COMPACT UNTIL 0 WARNINGS

**MAXIMUM YOLO: 0 warnings, 0 errors**

**Wait for project diagnostics to load before starting work.**

This workspace enforces **ZERO TOLERANCE** for warnings and errors.  
**No `#[allow()]` in source code. REAL CODE FIXES ONLY.**

---

## Critical Rules - NO EXCEPTIONS

```
✅ FULL FILE REWRITES ONLY
✅ BATCH ALL FIXES BEFORE WRITING
✅ VERIFY WITH DIAGNOSTICS AFTER EACH FILE
✅ NO PARTIAL EDITS - ACCUMULATE AND DEPLOY ONCE
✅ TRUST PROJECT DIAGNOSTICS - They are the source of truth
✅ RESPECT ALL RULES - No shortcuts, no "allow" mechanisms

❌ NEVER use #![allow()] or #[allow()] in source code
❌ NEVER use partial edits (edit single warnings)
❌ NEVER run cargo check/clippy/build manually
❌ NEVER leave unused code - USE IT OR DELETE IT
❌ NEVER use .unwrap()/.expect() - use ? or proper error handling
❌ NEVER use panic!/todo!/unimplemented!() - handle all cases
❌ NEVER use _ prefix for unused vars - USE THE VARIABLE
❌ NEVER add comments - code must be self-documenting
```

---

## 🚫 NEVER RUN THESE COMMANDS

```bash
cargo build --release   # NO! Unless shipping production
cargo clippy            # NO! Use diagnostics tool
cargo check             # NO! Use diagnostics tool
cargo test              # NO! Use diagnostics tool
```

**ONLY use the `diagnostics` tool to check for warnings and errors.**

---

## Workspace Structure

```
gb/
├── botapp/          # Desktop application (Tauri)
├── botserver/       # Main server (Axum API + business logic)
├── botlib/          # Shared library (types, utilities)
├── botui/           # Web UI (HTML/CSS/JS)
├── botbook/         # Documentation
├── bottest/         # Integration tests
├── botdevice/       # Device integration
├── botmodels/       # AI models
├── botplugin/       # Plugin system
├── bottemplates/    # Templates
├── Cargo.toml       # Workspace root
└── PROMPT.md        # THIS FILE
```

---

## ABSOLUTE PROHIBITIONS

```
❌ NEVER use #![allow()] or #[allow()] in source code to silence warnings
❌ NEVER use _ prefix for unused variables - DELETE the variable or USE it
❌ NEVER use .unwrap() - use ? or proper error handling
❌ NEVER use .expect() - use ? or proper error handling  
❌ NEVER use panic!() or unreachable!() - handle all cases
❌ NEVER use todo!() or unimplemented!() - write real code
❌ NEVER leave unused imports - DELETE them
❌ NEVER leave dead code - DELETE it or IMPLEMENT it
❌ NEVER use approximate constants (3.14159) - use std::f64::consts::PI
❌ NEVER silence clippy in code - FIX THE CODE or configure in Cargo.toml
❌ NEVER add comments - code must be self-documenting via types and naming
❌ NEVER add file header comments (//! or /*!) - no module docs
❌ NEVER add function doc comments (///) - types are the documentation
❌ NEVER add ASCII art or banners in code
❌ NEVER add TODO/FIXME/HACK comments - fix it or delete it
❌ NEVER use CDN links - all assets must be local
```

---

## CARGO.TOML LINT EXCEPTIONS

When a clippy lint has **technical false positives** that cannot be fixed in code,
disable it in the project's `Cargo.toml` with a comment explaining why:

```toml
[lints.clippy]
# Disabled: has false positives for functions with mut self, heap types (Vec, String)
missing_const_for_fn = "allow"
# Disabled: Tauri commands require owned types (Window) that cannot be passed by reference
needless_pass_by_value = "allow"
# Disabled: transitive dependencies we cannot control
multiple_crate_versions = "allow"
```

**Approved exceptions (with justification required):**
- `missing_const_for_fn` - false positives for `mut self`, heap types
- `needless_pass_by_value` - framework requirements (Tauri, Axum)
- `multiple_crate_versions` - transitive dependencies
- `future_not_send` - when async traits require non-Send futures

**NEVER add exceptions without a clear technical reason in the comment.**

---

## Common Warning Patterns & Mandatory Fixes

### 1. match_same_arms (50+ occurrences across codebase)

```rust
// ❌ WRONG
match x {
    A => do_thing(),
    B => do_thing(),
    C => other(),
}

// ✅ CORRECT
match x {
    A | B => do_thing(),
    C => other(),
}
```

### 2. significant_drop_tightening (30+ occurrences)

```rust
// ❌ WRONG
let guard = lock.lock()?;
do_other_stuff();  // guard still held

// ✅ CORRECT
{
    let guard = lock.lock()?;
    use_guard(&guard);
}
do_other_stuff();  // guard dropped
```

### 3. unnecessary_debug_formatting (40+ occurrences)

```rust
// ❌ WRONG
info!("Path: {:?}", path);

// ✅ CORRECT
info!("Path: {}", path.display());
```

### 4. trivially_copy_pass_by_ref (15+ occurrences)

```rust
// ❌ WRONG
fn method(&self) where Self: Copy { }

// ✅ CORRECT
fn method(self) where Self: Copy { }
```

### 5. use_self (30+ occurrences)

```rust
// ❌ WRONG
impl MyStruct {
    fn new() -> MyStruct { MyStruct { } }
}

// ✅ CORRECT
impl MyStruct {
    fn new() -> Self { Self { } }
}
```

### 6. if_same_then_else (20+ occurrences)

```rust
// ❌ WRONG
if condition {
    do_thing();
} else {
    do_thing();
}

// ✅ CORRECT
do_thing();
```

### 7. needless_borrow (25+ occurrences)

```rust
// ❌ WRONG
fn method(&x: &String) { }

// ✅ CORRECT
fn method(x: &str) { }
```

### 8. or_fun_call (15+ occurrences)

```rust
// ❌ WRONG
.unwrap_or(expensive_fn())

// ✅ CORRECT
.unwrap_or_else(|| expensive_fn())
```

---

## MANDATORY CODE PATTERNS

### Error Handling - Use `?` Operator

```rust
// ❌ WRONG
let value = something.unwrap();
let value = something.expect("msg");

// ✅ CORRECT
let value = something?;
let value = something.ok_or_else(|| Error::NotFound)?;
```

### Self Usage in Impl Blocks

```rust
// ❌ WRONG
impl MyStruct {
    fn new() -> MyStruct { MyStruct { } }
}

// ✅ CORRECT
impl MyStruct {
    fn new() -> Self { Self { } }
}
```

### Format Strings - Inline Variables

```rust
// ❌ WRONG
format!("Hello {}", name)

// ✅ CORRECT
format!("Hello {name}")
```

### Derive Eq with PartialEq

```rust
// ❌ WRONG
#[derive(PartialEq)]
struct MyStruct { }

// ✅ CORRECT
#[derive(PartialEq, Eq)]
struct MyStruct { }
```

### Match with Single Arm

```rust
// ❌ WRONG
match value {
    Some(x) => x,
    None => default,
}

// ✅ CORRECT
value.unwrap_or(default)
```

---

## Zero Comments Policy

**NO COMMENTS ANYWHERE IN CODE.**

```rust
// ❌ WRONG - any comments at all
/// Returns the user's full name
fn get_full_name(&self) -> String { }

// Validate input before processing
fn process(data: &str) { }

//! This module handles user authentication

// ✅ CORRECT - self-documenting code, no comments
fn full_name(&self) -> String { }

fn process_validated_input(data: &str) { }
```

**Why zero comments:**

With Rust's strong type system, **zero comments** is the right approach:

**Rust provides:**
- Type signatures = documentation
- `Result<T, E>` = documents errors
- `Option<T>` = documents nullability
- Trait bounds = documents requirements
- Expressive naming = self-documenting

**LLMs can:**
- Infer intent from code structure
- Understand patterns without comments
- Generate docs on-demand if needed

**Comments become:**
- Stale/wrong (code changes, comments don't)
- Noise that obscures actual logic
- Maintenance burden

---

## Workflow for Warning Removal

### Step 1: Load Diagnostics

Use the `diagnostics` tool to check current state:

```
diagnostics() → Get project-wide summary
diagnostics(path="botserver/src/main.rs") → Get file-specific warnings
```

### Step 2: Batch Fixes

**DO NOT fix warnings one at a time.**

1. Read the entire file
2. Identify ALL warnings in that file
3. Plan fixes for all warnings
4. Rewrite the entire file with all fixes applied

### Step 3: Verify

After writing the file, immediately run diagnostics again:

```
diagnostics(path="botserver/src/main.rs") → Verify fixes worked
```

### Step 4: Iterate

If warnings remain, repeat steps 2-3 until the file has zero warnings.

---

## Real Coder Mentality

**You are a real coder. Act like it.**

- **No shortcuts** - Fix the actual problem, don't suppress warnings
- **No half-measures** - Rewrite entire files, don't do partial edits
- **No excuses** - If clippy says it's wrong, fix it
- **Trust the tools** - Diagnostics are the source of truth
- **Own the code** - Make it correct, performant, and maintainable

**"Allow" mechanisms are for giving up. We don't give up.**

---

## Development Workflow

### Starting a Session

1. Run `diagnostics()` to get workspace-wide summary
2. Identify which project needs work
3. Read that project's `PROMPT.md`
4. Run `diagnostics(path="project/src/file.rs")` for specific files
5. Fix all warnings in each file using full rewrites
6. Verify with diagnostics after each file

### During Development

1. Make changes
2. Run diagnostics immediately
3. Fix any new warnings before moving on
4. Never accumulate warnings

### Ending a Session

1. Run `diagnostics()` to verify zero warnings workspace-wide
2. Document any remaining work in session notes
3. Commit only when diagnostics show zero warnings

---

## Quick Reference

### File Operations
- Read: `read_file(path="botserver/src/main.rs")`
- Edit: `edit_file(path="botserver/src/main.rs", mode="overwrite")`
- Find: `find_path(glob="**/*.rs")`
- Search: `grep(regex="fn main", include_pattern="**/*.rs")`

### Diagnostics
- Summary: `diagnostics()`
- File: `diagnostics(path="botserver/src/main.rs")`

### Never Use
- ❌ `terminal(command="cargo clippy")`
- ❌ `terminal(command="cargo check")`
- ❌ `terminal(command="cargo build")`

---

## Remember

- **ZERO WARNINGS** - Every clippy warning must be fixed
- **ZERO COMMENTS** - No comments, no doc comments, no file headers, no ASCII art
- **NO ALLOW IN CODE** - Never use #[allow()] in source files
- **CARGO.TOML EXCEPTIONS OK** - Disable lints with false positives in Cargo.toml with comment
- **NO DEAD CODE** - Delete unused code, never prefix with _
- **NO UNWRAP/EXPECT** - Use ? operator or proper error handling
- **INLINE FORMAT ARGS** - format!("{name}") not format!("{}", name)
- **USE SELF** - In impl blocks, use Self not the type name
- **DERIVE EQ** - Always derive Eq with PartialEq
- **USE DIAGNOSTICS** - Use diagnostics tool, never call cargo directly
- **FULL REWRITES** - Never do partial edits, rewrite entire files
- **BATCH FIXES** - Fix all warnings in a file at once
- **VERIFY IMMEDIATELY** - Run diagnostics after each file change
- **TRUST DIAGNOSTICS** - They are the source of truth
- **RESPECT RULES** - No shortcuts, no "allow" mechanisms
- **REAL CODER** - Fix problems, don't suppress them
- **Version**: Always 6.1.0 - do not change without approval
- **Read project PROMPT.md** - Each project has specific guidelines

---

## Session Continuation Protocol

When running out of context, create a detailed summary containing:

1. **What was done**: Specific files modified, warnings fixed
2. **What remains**: Exact count and types of warnings remaining
3. **Specific locations**: Files and line numbers with issues
4. **Exact next steps**: Concrete actions to continue work
5. **Blockers**: Any issues that need user input

**Be specific. Vague summaries waste the next session's time.**