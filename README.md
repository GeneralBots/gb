RULE 0: Never call tool_call while thinking. Ex NEVER do this: Let me check if the API call succeeded:<tool_call>terminal<arg_key>command</arg_key><arg_value>tail -50 botserver.log | grep -E "LLM streaming error|error|Error|SUCCESS|200"</arg_value><arg_key>cd</arg_key><arg_value>gb</arg_value></tool_call>. First finish Thinking, then emit a explanation and tool!
# General Bots Workspace


**Version:** 6.2.0  
**Type:** Rust Workspace (Monorepo with Independent Subproject Repos)

---

## Overview

General Bots is a comprehensive automation platform built with Rust, providing a unified workspace for building AI-powered bots, web interfaces, desktop applications, and integration tools. The workspace follows a modular architecture with independent subprojects that can be developed and deployed separately while sharing common libraries and standards.

For comprehensive documentation, see **[docs.pragmatismo.com.br](https://docs.pragmatismo.com.br)** or the **[BotBook](./botbook)** for detailed guides, API references, and tutorials.

---

## 📁 Workspace Structure

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
- **Stack:** `botserver-stack/`
- **UI Files:** `botui/ui/suite/`

---

## 🏗️ BotServer Component Architecture

### 🔧 Infrastructure Components (Auto-Managed)

BotServer automatically installs, configures, and manages all infrastructure components on first run. **DO NOT manually start these services** - BotServer handles everything.

| Component | Purpose | Port | Binary Location | Managed By |
|-----------|---------|------|-----------------|------------|
| **Vault** | Secrets management | 8200 | `botserver-stack/bin/vault/vault` | botserver |
| **PostgreSQL** | Primary database | 5432 | `botserver-stack/bin/tables/bin/postgres` | botserver |
| **MinIO** | Object storage (S3-compatible) | 9000/9001 | `botserver-stack/bin/drive/minio` | botserver |
| **Zitadel** | Identity/Authentication | 8300 | `botserver-stack/bin/directory/zitadel` | botserver |
| **Qdrant** | Vector database (embeddings) | 6333 | `botserver-stack/bin/vector_db/qdrant` | botserver |
| **Valkey** | Cache/Queue (Redis-compatible) | 6379 | `botserver-stack/bin/cache/valkey-server` | botserver |
| **Llama.cpp** | Local LLM server | 8081 | `botserver-stack/bin/llm/build/bin/llama-server` | botserver |

### 📦 Component Installation System

Components are defined in `botserver/3rdparty.toml` and managed by the `PackageManager` (`botserver/src/core/package_manager/`):

```toml
[components.cache]
name = "Valkey Cache (Redis-compatible)"
url = "https://github.com/valkey-io/valkey/archive/refs/tags/8.0.2.tar.gz"
filename = "valkey-8.0.2.tar.gz"

[components.llm]
name = "Llama.cpp Server"
url = "https://github.com/ggml-org/llama.cpp/releases/download/b7345/llama-b7345-bin-ubuntu-x64.zip"
filename = "llama-b7345-bin-ubuntu-x64.zip"
```

**Installation Flow:**
1. **Download:** Components downloaded to `botserver-installers/` (cached)
2. **Extract/Build:** Binaries placed in `botserver-stack/bin/<component>/`
3. **Configure:** Config files generated in `botserver-stack/conf/<component>/`
4. **Start:** Components started with proper TLS certificates
5. **Monitor:** Components monitored and auto-restarted if needed

**Bootstrap Process:**
- First run: Full bootstrap (downloads, installs, configures all components)
- Subsequent runs: Only starts existing components (uses cached binaries)
- Config stored in: `botserver-stack/conf/system/bootstrap.json`

### 🚀 PROPER STARTUP PROCEDURES

**❌ FORBIDDEN:**
- NEVER manually start infrastructure components (Vault, PostgreSQL, MinIO, etc.)
- NEVER run `cargo run` or `cargo build` for botserver directly without ./restart.sh
- NEVER modify botserver-stack/ files manually (use botserver API)

**✅ REQUIRED:**

**Option 1: Development (Recommended)**
```bash
./restart.sh
```
This script:
1. Kills existing processes cleanly
2. Builds botserver and botui sequentially (no race conditions)
3. Starts botserver in background with logging to `botserver.log`
4. Starts botui in background with logging to `botui.log`
5. Shows process IDs and access URLs

**Option 2: Production/Release**
```bash
# Build release binary first
cargo build --release -p botserver

# Start with release binary
RUST_LOG=info ./target/release/botserver --noconsole 2>&1 | tee botserver.log &
```

**Option 3: Using Exec (Systemd/Supervisord)**
```bash
# In systemd service or similar
ExecStart=/home/rodriguez/src/gb/target/release/botserver --noconsole
```

### 🔒 Component Communication

All components communicate through internal networks with mTLS:
- **Vault**: mTLS for secrets access
- **PostgreSQL**: TLS encrypted connections
- **MinIO**: TLS with client certificates
- **Zitadel**: mTLS for user authentication

Certificates auto-generated in: `botserver-stack/conf/system/certificates/`

### 📊 Component Status

Check component status anytime:
```bash
# Check if all components are running
ps aux | grep -E "vault|postgres|minio|zitadel|qdrant|valkey" | grep -v grep

# View component logs
tail -f botserver-stack/logs/vault/vault.log
tail -f botserver-stack/logs/tables/postgres.log
tail -f botserver-stack/logs/drive/minio.log

# Test component connectivity
cd botserver-stack/bin/vault && ./vault status
cd botserver-stack/bin/cache && ./valkey-cli ping
```

---

## 🏗️ Component Dependency Graph

```
┌─────────────────────────────────────────────────────────────────┐
│                         Client Layer                            │
├─────────────────────────────────────────────────────────────────┤
│  botui (Web UI)    │  botapp (Desktop)   │  botplugin (Ext)   │
│  HTMX + Axum       │  Tauri 2 Wrapper    │  Browser Extension  │
└─────────┬───────────────────┬──────────────────┬─────────────────┘
          │                   │                  │
          └───────────────────┼──────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │   botlib          │
                    │  (Shared Types)   │
                    └─────────┬─────────┘
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
    ┌─────▼─────┐      ┌─────▼─────┐      ┌─────▼─────┐
    │ botserver │      │ bottest   │      │ botdevice  │
    │ API Core  │      │ Tests     │      │ IoT/Device │
    └───────────┘      └───────────┘      └───────────┘
```

### Dependency Rules

| Crate | Depends On | Why |
|-------|-----------|-----|
| **botserver** | botlib | Shared types, error handling, models |
| **botui** | botlib | Common data structures, API client |
| **botapp** | botlib | Shared types, desktop-specific utilities |
| **bottest** | botserver, botlib | Integration testing with real components |
| **botdevice** | botlib | Device types, communication protocols |
| **botplugin** | - | Standalone browser extension (JS) |

**Key Principle:** `botlib` contains ONLY shared types and utilities. No business logic. All business logic lives in botserver or specialized crates.

## 📦 Module Responsibility Matrix

### botserver/src/ Module Structure

| Module | Responsibility | Key Types | Dependencies |
|--------|---------------|-----------|--------------|
| **core/bot/** | WebSocket handling, bot orchestration | BotOrchestrator, UserMessage | basic, shared |
| **core/session/** | Session management, conversation history | SessionManager, UserSession | shared, database |
| **basic/** | Rhai BASIC scripting engine | ScriptService, Engine | rhai, keywords |
| **basic/keywords/** | BASIC keyword implementations (TALK, HEAR, etc.) | Keyword functions | basic, state |
| **llm/** | Multi-vendor LLM API integration | LLMClient, ModelConfig | reqwest, shared |
| **drive/** | S3 file storage and monitoring | DriveMonitor, compile_tool | s3, basic |
| **security/** | Security guards (command, SQL, error) | SafeCommand, ErrorSanitizer | state |
| **shared/** | Database models, schema definitions | Bot, Session, Message | diesel |
| **tasks/** | AutoTask execution system | TaskRunner, TaskScheduler | core/basic |
| **auto_task/** | LLM-powered app generation | AppGenerator, template engine | llm, tasks |
| **learn/** | Knowledge base management | KBManager, vector storage | database, drive |
| **attendance/** | LLM-assisted customer service | AttendantManager, queue | core/bot |

### Data Flow Patterns

```
1. User Request Flow:
   Client → WebSocket → botserver/src/core/bot/mod.rs
                          ↓
                    BotOrchestrator::stream_response()
                          ↓
              ┌───────────┴───────────┐
              │                       │
         LLM API Call            Script Execution
         (llm/mod.rs)            (basic/mod.rs)
              │                       │
              └───────────┬───────────┘
                          ↓
                    Response → WebSocket → Client

2. File Sync Flow:
   S3 Drive → drive_monitor/src/drive_monitor/mod.rs
                          ↓
                    Download .bas files
                          ↓
              compile_file() → Generate .ast
                          ↓
              Store in ./work/{bot_name}.gbai/

3. Script Execution Flow:
   .bas file → ScriptService::compile()
                    ↓
              preprocess_basic_script()
                    ↓
              engine.compile() → AST
                    ↓
              ScriptService::run() → Execute
                    ↓
              TALK commands → WebSocket messages
```

### Common Architectural Patterns

| Pattern | Where Used | Purpose |
|---------|-----------|---------|
| **State via Arc<AppState>** | All handlers | Shared async state (DB, cache, config) |
| **Extension(state) extractor** | Axum handlers | Inject Arc<AppState> into route handlers |
| **tokio::spawn_blocking** | CPU-intensive tasks | Offload blocking work from async runtime |
| **WebSocket with split()** | Real-time comms | Separate sender/receiver for WS streams |
| **ErrorSanitizer for responses** | All HTTP errors | Prevent leaking sensitive info in errors |
| **SafeCommand for execution** | Command running | Whitelist-based command validation |
| **Rhai for scripting** | BASIC interpreter | Embeddable scripting language |
| **Diesel ORM** | Database access | Type-safe SQL queries |
| **Redis for cache** | Session data | Fast key-value storage |
| **S3 for storage** | File system | Scalable object storage |

---

## Quick Start

### 🚀 Simple Startup (ALWAYS USE restart.sh)

```bash
./restart.sh
```

**⚠️ CRITICAL: ALWAYS use restart.sh - NEVER start servers individually!**

The script handles BOTH servers properly:
1. Stop existing processes cleanly
2. Build botserver and botui sequentially (no race conditions)
3. Start botserver in background → auto-bootstrap infrastructure
4. Start botui in background → proxy to botserver
5. Show process IDs and monitoring commands

**Monitor startup:**
```bash
tail -f botserver.log botui.log
```

**Access:**
- Web UI: http://localhost:3000
- API: http://localhost:8088

### 📊 Monitor & Debug

```bash
tail -f botserver.log botui.log
```

**Quick status check:**
```bash
ps aux | grep -E "botserver|botui" | grep -v grep
```

**Quick error scan:**
```bash
grep -E " E |W |CLIENT:" botserver.log | tail -20
```

### 🔧 Manual Startup (If needed)

**⚠️ WARNING: Only use if restart.sh fails. Always prefer restart.sh!**

```bash
cd botserver && cargo run -- --noconsole > ../botserver.log 2>&1 &
cd botui && BOTSERVER_URL="http://localhost:8088" cargo run > ../botui.log 2>&1 &
```

### 🛑 Stop Servers

```bash
pkill -f botserver; pkill -f botui
```

### ⚠️ Common Issues

**Vault init error?** Delete stale state:
```bash
rm -rf botserver-stack/data/vault botserver-stack/conf/vault/init.json && ./restart.sh
```

**Port in use?** Find and kill:
```bash
lsof -ti:8088 | xargs kill -9
lsof -ti:3000 | xargs kill -9
```

**⚠️ IMPORTANT: Stack Services Management**
All infrastructure services (PostgreSQL, Vault, Redis, Qdrant, MinIO, etc.) are **automatically started by botserver** and managed through `botserver-stack/` directory, NOT global system installations. The system uses:

- **Local binaries:** `botserver-stack/bin/` (PostgreSQL, Vault, Redis, etc.)
- **Configurations:** `botserver-stack/conf/`
- **Data storage:** `botserver-stack/data/`
- **Service logs:** `botserver-stack/logs/` (check here for troubleshooting)

**Do NOT install or reference global PostgreSQL, Redis, or other services.** When botserver starts, it automatically launches all required stack services. If you encounter service errors, check the individual service logs in `./botserver-stack/logs/[service]/` directories.

### UI File Deployment - Production Options

**Option 1: Embedded UI (Recommended for Production)**

The `embed-ui` feature compiles UI files directly into the botui binary, eliminating the need for separate file deployment:

```bash
# Build with embedded UI files
cargo build --release -p botui --features embed-ui

# The binary now contains all UI files - no additional deployment needed!
# The botui binary is self-contained and production-ready
```

**Benefits of embed-ui:**
- ✅ Single binary deployment (no separate UI files)
- ✅ Faster startup (no filesystem access)
- ✅ Smaller attack surface
- ✅ Simpler deployment process

**Option 2: Filesystem Deployment (Development Only)**

For development, UI files are served from the filesystem:

```bash
# UI files must exist at botui/ui/suite/
# This is automatically available in development builds
```

**Option 3: Manual File Deployment (Legacy)**

If you need to deploy UI files separately (not recommended):

```bash
# Deploy UI files to production location
./botserver/deploy/deploy-ui.sh /opt/gbo

# Verify deployment
ls -la /opt/gbo/bin/ui/suite/index.html
```

See `botserver/deploy/README.md` for deployment scripts.

### Start Both Servers (Automated)
```bash
# Use restart script (RECOMMENDED)
./restart.sh
```

### Start Both Servers (Manual)
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

## 🧭 LLM Navigation Guide

### Quick Context Jump
- [Primary Purpose](#overview) - Unified workspace for AI automation platform
- [Crate Structure](#-workspace-structure) - 9 independent crates with shared libraries
- [Dependencies](#-component-dependency-graph) - How crates depend on each other
- [Quick Start](#quick-start) - Get running in 2 commands
- [Error Patterns](#common-error-patterns) - Fix compilation errors efficiently
- [Security Rules](#-security-directives---mandatory) - MUST-FOLLOW security patterns
- [Code Patterns](#-mandatory-code-patterns) - Required coding conventions
- [Testing](#testing-strategy) - How to test changes
- [Debugging](#debugging-guide) - Troubleshoot common issues

### Reading This Workspace

**For LLMs analyzing this codebase:**
1. Start with [Component Dependency Graph](#-component-dependency-graph) to understand relationships
2. Review [Module Responsibility Matrix](#-module-responsibility-matrix) for what each module does
3. Study [Data Flow Patterns](#-data-flow-patterns) to understand execution flow
4. Reference [Common Architectural Patterns](#-common-architectural-patterns) before making changes
5. Check [Security Rules](#-security-directives---mandatory) - violations are blocking issues
6. Follow [Code Patterns](#-mandatory-code-patterns) - consistency is mandatory

**For Humans working on this codebase:**
1. Follow [Error Fixing Workflow](#-error-fixing-workflow) for compilation errors
2. Observe [File Size Limits](#-file-size-limits---mandatory) - max 450 lines per file
3. Run [Weekly Maintenance Tasks](#-weekly-maintenance-tasks) to keep codebase healthy
4. Read project-specific READMEs in [Project-Specific Guidelines](#-project-specific-guidelines)

## 🧪 Testing Strategy

### Unit Tests
- **Location**: Each crate has `tests/` directory or inline `#[cfg(test)]` modules
- **Naming**: Test functions use `test_` prefix or describe what they test
- **Running**: `cargo test -p <crate_name>` or `cargo test` for all

### Integration Tests
- **Location**: `bottest/` crate contains integration tests
- **Scope**: Tests full workflows across multiple crates
- **Running**: `cargo test -p bottest`
- **Database**: Uses test database, automatically migrates on first run

### Test Utilities Available
- **TestAppStateBuilder** (`bottest/src/harness.rs`) - Build test state with mocked components
- **TestBot** (`bottest/src/bot/mod.rs`) - Mock bot for testing
- **Test Database**: Auto-created, migrations run automatically

### Coverage Goals
- **Critical paths**: 80%+ coverage required
- **Error handling**: ALL error paths must have tests
- **Security**: All security guards must have tests

## 🚨 CRITICAL ERROR HANDLING RULE

**STOP EVERYTHING WHEN ERRORS APPEAR**

When ANY error appears in logs during startup or operation:
1. **IMMEDIATELY STOP** - Do not continue with other tasks
2. **IDENTIFY THE ERROR** - Read the full error message and context
3. **FIX THE ERROR** - Address the root cause, not symptoms
4. **VERIFY THE FIX** - Ensure error is completely resolved
5. **ONLY THEN CONTINUE** - Never ignore or work around errors

**NEVER restart servers to "fix" errors - FIX THE ACTUAL PROBLEM**

Examples of errors that MUST be fixed immediately:
- Database connection errors
- Component initialization failures  
- Service startup errors
- Configuration errors
- Any error containing "Error:", "Failed:", "Cannot", "Unable"

## 🐛 Debugging Guide

### Log Locations

| Component | Log File | What's Logged |
|-----------|----------|---------------|
| **botserver** | `botserver.log` | API requests, errors, script execution, **client navigation events** |
| **botui** | `botui.log` | UI rendering, WebSocket connections |
| **drive_monitor** | In botserver logs with `[drive_monitor]` prefix | File sync, compilation |
| **script execution** | In botserver logs with `[ScriptService]` prefix | BASIC compilation, runtime errors |
| **client errors** | In botserver logs with `CLIENT:` prefix | JavaScript errors, navigation events |

### Client-Side Logging

**Navigation Tracking:** All client-side navigation is logged to botserver.log with `CLIENT:` prefix:
```
CLIENT:NAVIGATION: click: home -> drive
CLIENT:NAVIGATION: hashchange: drive -> chat
```

**Error Reporting:** JavaScript errors automatically appear in server logs:
```
CLIENT:ERROR: Uncaught TypeError: Cannot read property 'x' of undefined at /suite/js/app.js:123
```

**For LLM Troubleshooting:** ALWAYS check both:
1. `botserver.log` - Server errors + client navigation/errors (prefixed with `CLIENT:`)
2. `botui.log` - UI server logs

### USE WEBSITE Feature - Vector DB Context Injection

**FIXED (v6.2.0+):** The `USE WEBSITE` BASIC command now properly injects vector database embeddings into chat context.

**How it works:**
1. **Preprocessing:** When a `.bas` file containing `USE WEBSITE "https://..."` is compiled, the website is registered for crawling
2. **Crawling:** Content is extracted, chunked, and embedded into Qdrant vector DB (collection name: `website_<url_hash>`)
3. **Runtime Association:** The compiled `.ast` file contains `USE_WEBSITE()` function call that creates session-website association
4. **Context Injection:** During chat, `inject_kb_context()` searches active websites' embeddings and includes relevant chunks in LLM prompt

**Example BASIC script:**
```basic
USE WEBSITE "https://docs.pragmatismo.com.br" REFRESH "1h"

TALK "Hello! I can now answer questions about the documentation."
```

**Database tables involved:**
- `session_website_associations` - Links sessions to websites
- `website_embeddings` - Stores crawled content vectors in Qdrant

**Verification:**
```sql
-- Check if website is associated with session
SELECT * FROM session_website_associations WHERE session_id = '<uuid>';

-- Check if embeddings exist in Qdrant (via HTTP API)
curl http://localhost:6333/collections/website_<hash>/points/scroll
```

**Previous Issue:** In earlier versions, `USE WEBSITE` was removed during preprocessing and never executed at runtime, preventing context injection. Now the function call is preserved in the compiled AST.

### Common Error Messages

| Error | Meaning | Fix |
|-------|---------|-----|
| `Session not found` | Invalid session_id in request | Check auth flow, verify session exists in DB |
| `Bot not found` | Invalid bot_name or bot_id | Verify bot exists in `bots` table |
| `Script compilation error` | BASIC syntax error in .bas file | Check .bas file syntax, look for typos |
| `Failed to send TALK message` | WebSocket disconnected | Check client connection, verify web_adapter running |
| `Drive sync failed` | S3 connection or permission issue | Verify S3 credentials, check bucket exists |
| `unwrap() called on None value` | Panic in production code | MUST FIX - replace with proper error handling |
| `Component not responding: <component_name>` | Infrastructure component not accessible | Check component status: `ps aux | grep <component>`. View logs: `tail -f botserver-stack/logs/<component>/`. Restart via ./restart.sh |
| `Config key not found: <key>` | Missing configuration in database | Check `bot_configuration` table. Set correct value via API or direct SQL update. |
| `403 Forbidden on POST /api/client-errors` | RBAC blocking client error reporting | FIXED in v6.2.0+ - endpoint now allows anonymous access |

### Useful Debugging Commands

```bash
# Check if botserver is running
ps aux | grep botserver

# View botserver logs in real-time
tail -f botserver/logs/botserver.log

# Check work directory structure
ls -la ./work/*.gbai/*/

# Test database connection
cd botserver && cargo run --bin botserver -- --test-db

# Run specific test with output
cargo test -p botserver test_name -- --nocapture

# Check for memory leaks during compilation
CARGO_BUILD_JOBS=1 cargo check -p botserver 2>&1 | grep -i error
```

### Troubleshooting Workflows

**Problem: Script not executing**
1. Check if .bas file exists in `./work/{bot_name}.gbai/{bot_name}.gbdialog/`
2. Verify file has correct syntax (compile with ScriptService)
3. Check logs for compilation errors
4. Verify drive_monitor is running and syncing files

**Problem: WebSocket messages not received**
1. Check browser console for WebSocket errors
2. Verify session_id is valid in database
3. Check web_adapter is registered for session
4. Look for TALK execution in botserver logs

**Problem: Component not starting or crashing**
1. Identify the component from error message (e.g., Vault, PostgreSQL, MinIO, Qdrant, Valkey)
2. Check if process is running: `ps aux | grep <component_name>`
3. Check component logs: `tail -f botserver-stack/logs/<component_name>/`
4. Common fixes:
   - Config error: Check `botserver-stack/conf/<component_name>/` for valid configuration
   - Port conflict: Ensure no other process using the component's port
   - Permission error: Check file permissions in `botserver-stack/data/<component_name>/`
   - Missing binary: Re-run `./reset.sh && ./restart.sh` to reinstall components
5. Restart: `./restart.sh`

**Problem: Component configuration errors**
1. All component configs stored in database `bot_configuration` table
2. Check current value: `SELECT * FROM bot_configuration WHERE config_key = '<key_name>';`
3. Update incorrect config: `UPDATE bot_configuration SET config_value = '<correct_value>' WHERE config_key = '<key_name>';`
4. For path configs: Ensure paths are relative to component binary or absolute
5. Restart botserver after config changes

**Problem: File not found errors**
1. Check if file exists in expected location
2. Verify config paths use correct format (relative/absolute)
3. Check file permissions: `ls -la <file_path>`
4. For model/data files: Ensure downloaded to `botserver-stack/data/<component>/`

**Problem: LLM not responding**
1. Check LLM API credentials in config
2. Verify API key has available quota
3. Check network connectivity to LLM provider
4. Review request/response logs for API errors

### Performance Profiling

```bash
# Profile compilation time
cargo build --release --timings

# Profile runtime performance
cargo flamegraph --bin botserver

# Check binary size
ls -lh target/release/botserver

# Memory usage
valgrind --leak-check=full target/release/botserver
```

## 📖 Glossary

| Term | Definition | Usage |
|------|-----------|-------|
| **Bot** | AI agent with configuration, scripts, and knowledge bases | Primary entity in system |
| **Session** | Single conversation instance between user and bot | Stored in `sessions` table |
| **Dialog** | Collection of BASIC scripts (.bas files) for bot logic | Stored in `{bot_name}.gbdialog/` |
| **Tool** | Reusable function callable by LLM | Defined in .bas files, compiled to .ast |
| **Knowledge Base (KB)** | Vector database of documents for semantic search | Managed in `learn/` module |
| **Scheduler** | Time-triggered task execution | Cron-like scheduling in BASIC scripts |
| **Drive** | S3-compatible storage for files | Abstracted in `drive/` module |
| **Rhai** | Embedded scripting language for BASIC dialect | Rhai engine in `basic/` module |
| **WebSocket Adapter** | Component that sends messages to connected clients | `web_adapter` in state |
| **AutoTask** | LLM-generated task automation system | In `auto_task/` and `tasks/` modules |
| **Orchestrator** | Coordinates LLM, tools, KBs, and user input | `BotOrchestrator` in `core/bot/` |

---

## 🔥 Error Fixing Workflow

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

## 🧠 Memory Management

When compilation fails due to memory issues (process "Killed"):

```bash
pkill -9 cargo; pkill -9 rustc; pkill -9 botserver
CARGO_BUILD_JOBS=1 cargo check -p botserver 2>&1 | tail -200
```

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

### Current Files Requiring Immediate Refactoring

| File | Lines | Target Split |
|------|-------|--------------|
| `botserver/src/drive/mod.rs` | 1522 | → 4 files |
| `botserver/src/auto_task/app_generator.rs` | 2981 | → 7 files |
| `botui/ui/suite/sheet/sheet.js` | 3220 | → 8 files |
| `botserver/src/tasks/mod.rs` | 2651 | → 6 files |
| `botserver/src/learn/mod.rs` | 2306 | → 5 files |

See `TODO-refactor1.md` for detailed refactoring plans.

---

## 🔍 Continuous Monitoring

**YOLO Forever Monitoring Pattern:**

The system includes automated log monitoring to catch errors in real-time:

```bash
# Continuous monitoring (check every 5 seconds)
while true; do 
  sleep 5
  echo "=== Check at $(date +%H:%M:%S) ===" 
  tail -50 botserver.log | grep -E "ERROR|WARN|CLIENT:" | tail -5 || echo "✓ Clean"
done
```

**Quick Status Check:**
```bash
# Check last 200 lines for any issues
tail -200 botserver.log | grep -E "ERROR|WARN|CLIENT:" | tail -10

# Show recent server activity
tail -30 botserver.log

# Check if server is running
ps aux | grep botserver | grep -v grep
```

**Monitoring Dashboard:**
- **Server Status**: https://localhost:8088 (health endpoint)
- **Logs**: `tail -f botserver.log`
- **Client Errors**: Look for `CLIENT:` prefix
- **Server Errors**: Look for `ERROR` or `WARN` prefixes

**Status Indicators:**
- ✅ **Clean**: No ERROR/WARN/CLIENT: entries in logs
- ⚠️ **Warnings**: Non-critical issues that should be reviewed
- ❌ **Errors**: Critical issues requiring immediate attention

**When Errors Appear:**
1. Capture the full error context (50 lines before/after)
2. Identify the component (server, client, database, etc.)
3. Check troubleshooting section for specific fixes
4. Update this README with discovered issues and resolutions

---

## 🚀 Performance & Size Standards

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
- **Cloning**: Avoid unnecessary `.clone()` calls. Use references or `Cow` types.

### Code Quality Issues Found
- **955 instances** of `unwrap()`/`expect()` in codebase - ALL must be replaced with proper error handling
- **12,973 instances** of excessive `clone()`/`to_string()` calls - optimize for performance
- **Test code exceptions**: `unwrap()` allowed in test files only

### Linting & Code Quality
- **Clippy**: Code MUST pass `cargo clippy --all-targets --all-features` with **0 warnings**.
- **No Allow**: Do not use `#[allow(clippy::...)]` unless absolutely necessary and documented. Fix the underlying issue.

---

## 🔐 Security Directives - MANDATORY

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

## ❌ Absolute Prohibitions

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
❌ NEVER use cargo clean - causes 30min rebuilds, use ./reset.sh for database issues
❌ NEVER create .md documentation files without checking botbook/ first - documentation belongs there
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

### Vendor Libraries Location
```
ui/suite/js/vendor/
├── htmx.min.js
├── htmx-ws.js
├── marked.min.js
└── gsap.min.js
```

---

## 📋 Project-Specific Guidelines

Each crate has its own README.md with specific guidelines:

| Crate | README.md Location | Focus |
|-------|-------------------|-------|
| botserver | `botserver/README.md` | API, security, Rhai BASIC |
| botui | `botui/README.md` | UI, HTMX, CSS design system |
| botapp | `botapp/README.md` | Tauri, desktop features |
| botlib | `botlib/README.md` | Shared types, errors |
| botbook | `botbook/README.md` | Documentation, mdBook |
| bottest | `bottest/README.md` | Test infrastructure |

### Special Prompts
| File | Purpose |
|------|---------|
| `botserver/src/tasks/README.md` | AutoTask LLM executor |
| `botserver/src/auto_task/APP_GENERATOR_PROMPT.md` | App generation |

---

## 📚 Documentation

For complete documentation, guides, and API references:

- **[docs.pragmatismo.com.br](https://docs.pragmatismo.com.br)** - Full online documentation
- **[BotBook](./botbook)** - Local comprehensive guide with tutorials and examples
- **[General Bots Repository](https://github.com/GeneralBots/BotServer)** - Main project repository

---

## 🔧 Immediate Technical Debt

### Critical Issues to Address

1. **Error Handling Debt**: 955 instances of `unwrap()`/`expect()` in production code
2. **Performance Debt**: 12,973 excessive `clone()`/`to_string()` calls
3. **File Size Debt**: 7 files exceed 450 lines (largest: 3220 lines)
4. **Test Coverage**: Missing integration tests for critical paths
5. **Documentation**: Missing inline documentation for complex algorithms

### Weekly Maintenance Tasks

```bash
# Check for duplicate dependencies
cargo tree --duplicates

# Remove unused dependencies  
cargo machete

# Check binary size
cargo build --release && ls -lh target/release/botserver

# Performance profiling
cargo bench

# Security audit
cargo audit
```

---

## Git Structure

**Note:** Each subproject has its own git repository. This root repository only tracks workspace-level files:

- `Cargo.toml` - Workspace configuration
- `README.md` - This file
- `.gitignore` - Ignore patterns
- `ADDITIONAL-SUGGESTIONS.md` - Enhancement ideas
- `TODO-*.md` - Task tracking files

Subprojects (botapp, botserver, botui, etc.) are **independent repositories referenced as git submodules**.

### ⚠️ CRITICAL: Submodule Push Workflow

When making changes to any submodule (botserver, botui, botlib, etc.):

1. **Commit and push changes within the submodule directory:**
   ```bash
   cd botserver
   git add .
   git commit -m "Your changes"
   git push pragmatismo main
   git push github main
   ```

2. **Update the global gb repository submodule reference:**
   ```bash
   cd ..  # Back to gb root
   git add botserver
   git commit -m "Update botserver submodule to latest commit"
   git push pragmatismo main
   git push github main
   ```

**Failure to push the global gb repository will cause submodule changes to not trigger CI/CD pipelines.**

Both repositories must be pushed for changes to take effect in production.

---

## Development Workflow

1. Read this README.md (workspace-level rules)
2. **BEFORE creating any .md file, search botbook/ for existing documentation**
3. Read `<project>/README.md` (project-specific rules)
4. Use diagnostics tool to check warnings
5. Fix all warnings with full file rewrites
6. Verify with diagnostics after each file
7. Never suppress warnings with `#[allow()]`

---

## Main Directive

**LOOP AND COMPACT UNTIL 0 WARNINGS - MAXIMUM PRECISION**

- 0 warnings
- 0 errors
- Trust project diagnostics
- Respect all rules
- No `#[allow()]` in source code
- Real code fixes only

---

## 🔑 Remember

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

---

## License

See individual project repositories for license information.
