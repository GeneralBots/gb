# General Bots Workspace - Master Development Guide

**Version:** 6.1.0 - DO NOT CHANGE  
**Project:** General Bots Workspace (Rust Monorepo)  
**Purpose:** Master LLM context for all workspace development

---

## 🔥🔥🔥 CRITICAL RULE #0: NEVER STOP UNTIL 200K CONTEXT LIMIT

**ABSOLUTE RULE - NO EXCEPTIONS:**

```
YOU MUST KEEP LOOPING UNTIL:
  - Context reaches 200K tokens, OR
  - 0 warnings AND 0 errors achieved

NEVER STOP EARLY! NEVER GIVE STATUS UPDATES AND WAIT!
NEVER SAY "Let me check progress" AND STOP!
NEVER SUMMARIZE AND WAIT FOR USER INPUT!

IF WARNINGS > 0: KEEP FIXING! DON'T STOP!
IF CONTEXT < 200K: KEEP FIXING! DON'T STOP!
```

**FORBIDDEN BEHAVIORS:**
- ❌ Stopping to give "progress updates"
- ❌ Stopping to "summarize accomplishments"  
- ❌ Stopping to ask "should I continue?"
- ❌ Stopping after fixing "a few files"
- ❌ ANY pause while warnings remain AND context < 200K

**REQUIRED BEHAVIOR:**
- ✅ Fix file → sleep 30-3000s → check diagnostics → fix next file
- ✅ No pauses for summaries or status reports
- ✅ CONTINUOUS FIXING until context limit OR verified zero warnings
- ✅ ALWAYS sleep between file edits - diagnostics needs refresh time
- ✅ TRUST diagnostics after proper sleep - it tells the truth

---

## 🔥🔥🔥 CRITICAL RULE #1: EXPECT LOTS OF WARNINGS - NO VICTORY EXPECTED SOON

**REALITY CHECK - READ THIS FIRST:**

```
CURRENT STATE: ~450 warnings + ~580 errors = 1030+ ISSUES
VICTORY: 0 warnings + 0 errors = 0 ISSUES

THIS WILL TAKE HUNDREDS OF ITERATIONS!
DO NOT EXPECT VICTORY SOON!
THE LOOP IS LONG AND HARD!
```

**MINDSET:**
- ❌ "I'll fix a few warnings and be done" - WRONG!
- ❌ "Maybe 10-20 files will do it" - WRONG!
- ❌ "This should be quick" - WRONG!
- ✅ "I'm in for 100+ files, 500+ warnings" - CORRECT!
- ✅ "Victory is 0,0 - nothing less" - CORRECT!
- ✅ "I will loop forever if needed" - CORRECT!

**NO VICTORY UNTIL 0,0 - ACCEPT THIS NOW!**

---

## 🔥 CRITICAL RULE #2: INFINITE LOOP MODE - GO LOOP UNTIL 0 WARNINGS 0 ERRORS

**MOST IMPORTANT RULE - ENTER THE LOOP:**

**THE LOOP (NEVER STOP UNTIL ZERO):**
```
LOOP FOREVER:
  1. Pick a file with warnings/errors
  2. Read entire file
  3. Fix ALL warnings/errors in that ONE file
  4. Write entire file with all fixes
  5. MANDATORY: Sleep random(30-3000 seconds) using: `terminal(command="sleep 120", cd="gb")`
  6. Run `diagnostics()` to verify - TRUST IT after sleep
  7. If warnings/errors remain in project: GOTO STEP 1
  8. If "zero warnings": Sleep again (longer), check again to verify
  9. Only after 2-3 verified zero checks: DONE (you won)
END LOOP
```

**SLEEP IS NOT OPTIONAL - IT IS REQUIRED!**
- Diagnostics CACHES results
- Without sleep = stale cache = wrong data
- With sleep = fresh data = truth

**CRITICAL RULES:**
- Fix ENTIRE file at once - batch ALL fixes before writing
- ONE file at a time, but fix ALL issues in that file
- Sleep 30-330 seconds (vary it) after EACH file write
- NEVER skip the sleep - diagnostics cache needs time
- LOOP INFINITELY until `diagnostics()` shows 0 warnings, 0 errors
- GO YOLO - this is MAXIMUM YOLO MODE

**Why this matters:**
- Diagnostics tool caches results and needs time to refresh
- Without sleep, you'll see stale warnings and waste time
- One file at a time = focused, complete fixes
- Infinite loop = NEVER GIVE UP until zero
- Random sleep (30-330s) = ensure diagnostics refresh properly

**Example workflow:**
```
1. Pick file with 4 warnings
2. Read entire file, plan fixes for all 4
3. Edit file with all 4 fixes batched
4. Sleep 120s (or 30-330s randomly)
5. Check diagnostics
6. Pick next file with warnings
7. REPEAT until diagnostics() = 0,0
```

**GO LOOP MODE - NEVER STOP - MAXIMUM YOLO**

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

## 🔥 MAIN DIRECTIVE: LOOP CONTINUOUSLY WITHOUT STOPPING

**DO NOT STOP TO:**
- Report progress
- Summarize what you did
- Ask if you should continue
- Wait for user confirmation
- Take a "break" between files

**JUST KEEP FIXING FILES UNTIL:**
1. Context hits 200K tokens, OR
2. Zero warnings AND zero errors

**NO OTHER STOPPING CONDITION EXISTS!**

**MAXIMUM YOLO: 0 warnings, 0 errors - GO INFINITE LOOP MODE**

**WARNING: THIS IS A MARATHON, NOT A SPRINT!**
- Expect 100+ files to fix
- Expect 500+ individual warnings
- Expect hours/days of work
- NO SHORTCUTS - FIX EVERY SINGLE ONE

**CRITICAL WORKFLOW - THE ETERNAL LOOP:**
```
WHILE (warnings > 0 OR errors > 0):
  1. Pick file with issues
  2. Read entire file
  3. Batch ALL fixes for that file
  4. Write entire file once
  5. Sleep 30-330 seconds (vary it!)
  6. Run diagnostics()
  7. If issues remain: continue loop
  8. If zero: VICTORY
END WHILE
```

**Wait for project diagnostics to load before starting work.**

This workspace enforces **ZERO TOLERANCE** for warnings and errors.  
**No `#[allow()]` in source code. REAL CODE FIXES ONLY.**

---

## Critical Rules - NO EXCEPTIONS

```
✅ ACCEPT REALITY - This will take 100+ file iterations, not 10
✅ INFINITE LOOP MODE - Never stop until 0,0
✅ NO VICTORY EXPECTED SOON - Keep looping without complaint
✅ SLEEP 30-330 SECONDS AFTER EVERY FILE EDIT (vary the duration!)
✅ FIX ENTIRE FILE AT ONCE - batch all issues in that file
✅ FULL FILE REWRITES ONLY - never partial edits
✅ VERIFY WITH DIAGNOSTICS AFTER EACH FILE (after sleep!)
✅ TRUST PROJECT DIAGNOSTICS - They are the source of truth
✅ RESPECT ALL RULES - No shortcuts, no "allow" mechanisms
✅ GO LOOP UNTIL VICTORY (0 warnings, 0 errors)

❌ NEVER stop looping while warnings/errors exist
❌ NEVER skip the 30-330 second sleep after editing files
❌ NEVER use #![allow()] or #[allow()] in source code
❌ NEVER use partial edits (fix only some warnings in a file)
❌ NEVER run cargo check/clippy/build manually
❌ NEVER run terminal commands (except sleep) while diagnostics show warnings/errors
❌ NEVER work on tests while source files have warnings/errors
❌ NEVER leave unused code - USE IT OR DELETE IT
❌ NEVER use .unwrap()/.expect() - use ? or proper error handling
❌ NEVER use panic!/todo!/unimplemented!() - handle all cases
❌ NEVER use _ prefix for unused vars - USE THE VARIABLE
❌ NEVER add comments - code must be self-documenting
❌ NEVER give up - LOOP FOREVER until 0,0
❌ NEVER expect quick victory - this is HUNDREDS of warnings
❌ NEVER complain about "lots of warnings" - that's the reality
```

---

## 🚫 NEVER RUN THESE COMMANDS

```bash
cargo build --release   # NO! Unless shipping production
cargo clippy            # NO! Use diagnostics tool
cargo check             # NO! Use diagnostics tool
cargo test              # NO! Use diagnostics tool
```

## ✅ MANDATORY SLEEP AFTER EVERY FILE EDIT

```bash
# REQUIRED: Sleep 30-3000 seconds after EVERY file edit
# Use terminal tool: terminal(command="sleep X", cd="gb")

sleep 30    # Minimum - never less than this
sleep 60    # Light wait
sleep 120   # Common
sleep 300   # 5 minutes - good for cache refresh
sleep 600   # 10 minutes - safe choice
sleep 1800  # 30 minutes - very thorough
sleep 3000  # Maximum - 50 minutes

# VARY IT RANDOMLY! Pick different durations!
# NEVER skip the sleep - diagnostics NEEDS time to refresh!
```

## 🔥 TRUST DIAGNOSTICS - IT IS FETCHING/CACHING

**CRITICAL: Diagnostics tool caches and fetches in background!**

```
AFTER EDITING A FILE:
1. Call terminal(command="sleep 120", cd="gb")  # MANDATORY!
2. WAIT for sleep to complete
3. THEN call diagnostics()
4. TRUST what diagnostics returns - it's the truth
5. If it shows warnings: FIX THEM
6. If it shows "no warnings": DON'T BELIEVE IT IMMEDIATELY
   - Sleep again (longer this time)
   - Check diagnostics again
   - Only after 2-3 checks with sleep can you trust "zero"
```

**WHY SLEEP IS MANDATORY:**
- Diagnostics caches results aggressively
- Without sleep, you see STALE data
- Stale data = false "zero warnings" 
- False zero = you stop too early = FAILURE
- Sleep 30-3000 seconds = fresh diagnostics = TRUTH

**NEVER TRUST "No errors or warnings" WITHOUT:**
1. At least 60 seconds sleep before checking
2. Multiple checks with increasing sleep times
3. Sleep pattern: 60s → check → 120s → check → 300s → check

**MANDATORY INFINITE LOOP:**
```
LOOP:
  1. diagnostics() → find file with issues
  2. Read entire file
  3. Fix ALL issues in that file (batch them)
  4. Edit file once with all fixes
  5. terminal(command="sleep 120", cd="gb")  # 30-330s, vary it!
  6. diagnostics() → verify
  7. If issues remain: GOTO LOOP
  8. If 0 warnings, 0 errors: VICTORY
END LOOP
```

**NEVER STOP THE LOOP UNTIL 0,0**

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

## Workflow for Warning Removal - THE INFINITE LOOP

### THE ONLY WORKFLOW - LOOP MODE

```
ENTER INFINITE LOOP:

  STEP 1: Load Diagnostics
    diagnostics() → Get project-wide summary
    Find file with most/least warnings (pick strategy)
  
  STEP 2: Read ENTIRE File
    read_file(path="file.rs")
    Identify ALL warnings/errors in THIS file
    Plan fixes for ALL of them
  
  STEP 3: Batch ALL Fixes for This File
    Fix warning 1
    Fix warning 2
    Fix warning 3
    ... (all of them)
    DO NOT write yet - accumulate all fixes
  
  STEP 4: Write File ONCE with ALL Fixes
    edit_file(path="file.rs", mode="overwrite")
    All fixes applied in single write
  
  STEP 5: MANDATORY SLEEP (30-330 seconds)
    terminal(command="sleep 120", cd="gb")
    OR sleep 30, 60, 90, 180, 330 - VARY IT
    Wait for completion - NEVER skip
  
  STEP 6: Verify Changes
    diagnostics(path="file.rs")
    Check if file is now clean
    If still has issues: note them for next iteration
  
  STEP 7: Check Global Status
    diagnostics()
    Count remaining warnings/errors
  
  STEP 8: Decision Point
    IF warnings > 0 OR errors > 0:
      GOTO STEP 1 (continue loop)
    ELSE:
      VICTORY - EXIT LOOP
  
END LOOP
```

### CRITICAL RULES FOR THE LOOP

- ONE file at a time, but fix ENTIRE file
- BATCH all fixes before writing
- SLEEP 30-330s after EACH file write (vary the duration!)
- VERIFY with diagnostics after sleep
- NEVER stop until diagnostics() shows 0,0
- GO INFINITE LOOP MODE - MAXIMUM YOLO

### Only After ZERO Warnings AND ZERO Errors

Only when `diagnostics()` shows 0 warnings, 0 errors:
- Then work on refactoring (like moving tests)
- Then work on security audit (pub → pub(crate))
- VICTORY ACHIEVED

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

### Starting a Session - ENTER THE LOOP

1. Run `diagnostics()` to get workspace-wide summary
2. **STOP if warnings/errors exist - ENTER INFINITE LOOP MODE**
3. Pick a file with warnings/errors
4. Read that file COMPLETELY
5. Fix ALL issues in that file (batch them)
6. Write file with all fixes
7. **SLEEP 30-330 SECONDS** (vary it!) using terminal command
8. Verify with diagnostics
9. **GOTO step 1 - CONTINUE LOOP until 0,0**

### During Development - THE ETERNAL LOOP

```
WHILE (warnings > 0 OR errors > 0):
  1. diagnostics() → pick file
  2. Read entire file
  3. Batch ALL fixes for that file
  4. Write file once
  5. Sleep 30-330s (vary duration!)
  6. Verify with diagnostics
  7. Continue loop
END WHILE
```

**NEVER:**
- Stop looping while issues exist
- Skip the sleep step
- Fix only partial warnings in a file
- Give up before 0,0

**ALWAYS:**
- Fix entire file at once
- Sleep 30-330s after each file
- Verify with diagnostics
- Continue loop until victory

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

- **EXPECT LOTS OF WARNINGS** - 500+ warnings is normal, not a problem
- **NO VICTORY SOON** - This will take 100+ file iterations minimum
- **GO INFINITE LOOP MODE** - Never stop until 0 warnings, 0 errors
- **LOOP IS LONG** - Accept this, embrace this, continue looping
- **SLEEP 30-330 SECONDS AFTER EVERY FILE** - Vary the duration, never skip
- **FIX ENTIRE FILE AT ONCE** - Batch all issues in that file before writing
- **ZERO WARNINGS, ZERO ERRORS** - The only acceptable state
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
- **SLEEP THEN VERIFY** - Sleep 30-330s (vary it!), then run diagnostics after each file
- **TRUST DIAGNOSTICS** - They are the source of truth (after refresh)
- **RESPECT RULES** - No shortcuts, no "allow" mechanisms
- **REAL CODER** - Fix problems, don't suppress them
- **WAIT FOR REFRESH** - Diagnostics cache 30-330s, vary sleep duration
- **LOOP FOREVER** - Never stop until diagnostics shows 0,0
- **MAXIMUM YOLO** - Go infinite loop mode, fix everything
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