# TASKS.md — General Bots Workspace Audit

**Generated:** 2026-02-19  
**Workspace:** `/home/rodriguez/gb` (v6.2.0)  
**Scope:** Full workspace security audit, code quality analysis, and improvement backlog

---

## 🔴 P0 — CRITICAL SECURITY FLAWS (Fix Immediately)

### SEC-01: ✅ RESOLVED — `vault-unseal-keys` removed from Git tracking

**Severity:** 🔴 CRITICAL  
**File:** `vault-unseal-keys`  
**Status:** ✅ Removed from Git tracking. **History purge and key rotation still required.**

The file contained **5 plaintext Vault unseal keys** and had **2 commits** in the git history. It has been removed from tracking via `git rm --cached`.

**Completed:**
- [x] `git rm --cached vault-unseal-keys` — Removed from tracking
- [x] Added to `.gitignore` (was already present)

**Remaining (manual action required):**
- [ ] **Rotate ALL 5 Vault unseal keys immediately**
- [ ] Use `git filter-repo` or BFG Repo-Cleaner to purge from history
- [ ] Force-push to ALL remotes (`origin`, `alm`)
- [ ] Notify all collaborators to re-clone

---

### SEC-02: ✅ PARTIALLY RESOLVED — `.env` exposure mitigated

**Severity:** 🔴 CRITICAL  
**Files:** `.env` (root), `botserver/.env`

**Completed:**
- [x] Verified `botserver/.env` is NOT tracked by git
- [x] Root `.env` confirmed NOT tracked (properly `.gitignore`'d)
- [x] Created `.env.example` template with placeholder values
- [x] Added `*.pem`, `*.key`, `*.crt`, `*.cert` to `.gitignore`

**Remaining (manual action required):**
- [ ] **Rotate both Vault tokens immediately**
- [ ] Implement short-TTL Vault tokens (e.g., 1h) with auto-renewal
- [ ] Consider using Vault Agent for automatic token management

---

### SEC-03: ✅ RESOLVED — `init.json` removed from Git tracking

**Severity:** 🟠 HIGH  
**File:** `init.json`

**Completed:**
- [x] `git rm --cached init.json` — Removed from tracking
- [x] Added `init.json` to `.gitignore`

---

### SEC-04: ✅ RESOLVED — All `Command::new()` replaced with `SafeCommand`

**Severity:** 🟠 HIGH  
**File:** `botserver/src/security/protection/installer.rs`

**Completed:**
- [x] Replaced all 8 `Command::new()` calls with `SafeCommand::new()` (including verify() Windows path)
- [x] Added `id` and `netsh` to SafeCommand whitelist in `command_guard.rs`
- [x] Removed unused `use std::process::Command;` import
- [x] Fixed 3 duplicate `#[cfg(not(windows))]` attributes
- [x] Build verified — compiles cleanly

---

### SEC-05: ✅ RESOLVED — SQL injection vectors fixed with parameterized queries

**Severity:** 🟠 HIGH  
**Files fixed:**
- `botserver/src/basic/keywords/db_api.rs`
- `botserver/src/security/sql_guard.rs` (already safe — uses validated identifiers)

**Completed:**
- [x] `search_records_handler`: User search term now uses `$1` bind parameter instead of `format!()` interpolation
- [x] `get_record_handler`: Changed to use `build_safe_select_by_id_query()` from sql_guard
- [x] `count_records_handler`: Changed to use `build_safe_count_query()` from sql_guard
- [x] Added wildcard escaping (`%`, `_`) on search terms before passing to ILIKE
- [x] Build verified — compiles cleanly

**Remaining:**
- [ ] Audit `contacts/contacts_api/service.rs` for similar patterns
- [ ] Add SQL injection fuzzing tests
- [ ] Consider migrating fully to Diesel query builder

---

### SEC-06: ✅ PARTIALLY RESOLVED — `unwrap()`/`expect()` reduction started

**Severity:** 🟠 HIGH  
**Scope:** `botserver/src/` (~637 non-test instances remaining)

**Completed:**
- [x] Fixed `rate_limiter.rs`: Replaced `expect()` with compile-time const `NonZeroU32` values
- [x] Security module production code reviewed and fixed

**Remaining:**
- [ ] Continue systematic elimination in: `core/`, `llm/`, `main.rs`, `auto_task/`
- [ ] Replace with `?`, `.ok_or_else()`, `.unwrap_or_default()`, or `if let`
- [ ] Add a CI clippy lint to deny new `unwrap()`/`expect()` in non-test code
- [ ] Target: eliminate 50 instances per week

---

## 🟠 P1 — HIGH PRIORITY IMPROVEMENTS

### IMP-01: Massive file sizes violating 450-line rule

**Severity:** 🟠 HIGH  
**Total codebase:** 289,453 lines across `botserver/src/`

Top offenders (vs 450 max policy):

| File | Lines | Oversize By |
|------|-------|-------------|
| `auto_task/app_generator.rs` | 3,586 | 7.9× |
| `auto_task/autotask_api.rs` | 2,301 | 5.1× |
| `basic/mod.rs` | 2,095 | 4.7× |
| `core/bot/mod.rs` | 1,584 | 3.5× |
| `channels/pinterest.rs` | 1,565 | 3.5× |
| `drive/mod.rs` | 1,525 | 3.4× |
| `whatsapp/mod.rs` | 1,516 | 3.4× |
| `channels/snapchat.rs` | 1,500 | 3.3× |
| `security/rbac_middleware.rs` | 1,498 | 3.3× |
| `basic/keywords/crm/attendance.rs` | 1,495 | 3.3× |
| `core/package_manager/installer.rs` | 1,473 | 3.3× |
| `workspaces/mod.rs` | 1,370 | 3.0× |
| `drive/drive_monitor/mod.rs` | 1,329 | 3.0× |
| `video/engine.rs` | 1,318 | 2.9× |
| `core/package_manager/facade.rs` | 1,313 | 2.9× |

**Actions:**
- [ ] Split `auto_task/app_generator.rs` (3586 lines) → ~8 modules
- [ ] Split `auto_task/autotask_api.rs` (2301 lines) → ~5 modules
- [ ] Split `basic/mod.rs` (2095 lines) → ~5 modules
- [ ] Split `core/bot/mod.rs` (1584 lines) → ~4 modules
- [ ] Continue down the list — 20+ files exceed 450 lines

---

### IMP-02: Shell scripts lack proper safety measures

**Severity:** 🟡 MEDIUM  
**Files:** `reset.sh`, `stop.sh`, `DEPENDENCIES.sh`

| Script | Issue |
|--------|-------|
| `reset.sh` | No shebang, no `set -e`, destructive `rm -rf` without confirmation |
| `stop.sh` | No shebang, no `set -e`, uses `pkill -9` (SIGKILL) without graceful shutdown |
| `DEPENDENCIES.sh` | Excessive indentation, no `set -e` after shebang, missing `apt-get update` before install |

**Actions:**
- [ ] Add `#!/bin/bash` and `set -euo pipefail` to `reset.sh` and `stop.sh`
- [ ] Add confirmation prompt to `reset.sh` before deleting data
- [ ] In `stop.sh`, try SIGTERM first, then SIGKILL after timeout
- [ ] In `DEPENDENCIES.sh`, add `apt-get update` before `apt-get install`
- [ ] Fix indentation in `DEPENDENCIES.sh` (8-space indent throughout)

---

### IMP-03: Repository root polluted with debug/test artifacts

**Severity:** 🟡 MEDIUM  
**Files in root that don't belong:**

| File | Should Be |
|------|-----------|
| `cristo-batizado.png`, `cristo-home.png`, etc. (10 PNGs) | In `.gitignore` (already) or deleted |
| `start.bas`, `test_begin_blocks.bas` | Move to `bottemplates/` or `tests/` |
| `init.json` | Tracked by git — remove (see SEC-03) |
| `COMPILATION_FIXES_SUMMARY.md` | Move to `botbook/` or delete |
| `PROMPT.md` | Move to `botbook/` or `.todo/` |
| `botserver-new.log` | Add to `.gitignore` |
| `vault-unseal-keys` | DELETE and purge history (see SEC-01) |

**Actions:**
- [ ] Delete or move all `.png` screenshot files from root
- [ ] Move `start.bas`, `test_begin_blocks.bas` to appropriate directories
- [ ] Move documentation `.md` files to `botbook/`
- [ ] Add `*-new.log` pattern to `.gitignore`
- [ ] Clean up root to contain only essential workspace files

---

### IMP-04: `unsafe` block in production code

**Severity:** 🟡 MEDIUM  
**File:** `botserver/src/llm/rate_limiter.rs:99`

```rust
.unwrap_or_else(|| unsafe { NonZeroU32::new_unchecked(1) })
```

While this specific case is sound (1 is non-zero), using `unsafe` sets a bad precedent and can be replaced with safe alternatives.

**Actions:**
- [ ] Replace with `NonZeroU32::new(1).unwrap()` (compile-time guaranteed) or `NonZeroU32::MIN`
- [ ] Add a workspace-wide `#![deny(unsafe_code)]` policy (with exceptions documented)

---

### IMP-05: Missing `cargo-audit` for dependency vulnerability scanning

**Severity:** 🟡 MEDIUM  

`cargo-audit` is not installed, meaning no automated dependency vulnerability scanning is happening. The README recommends weekly `cargo audit` runs but the tool isn't available.

**Actions:**
- [ ] Install `cargo-audit`: `cargo install cargo-audit`
- [ ] Run `cargo audit` and fix any findings
- [ ] Add `cargo audit` to CI pipeline
- [ ] Set up `dependabot` or `renovate` for automated dependency updates

---

### IMP-06: CORS configuration may be too permissive

**Severity:** 🟡 MEDIUM  
**File:** `botserver/src/security/cors.rs`

Multiple `allow_origin` patterns exist including predicate-based validation. Need to verify the predicate function properly validates origins and doesn't allow wildcards in production.

**Actions:**
- [ ] Audit `validate_origin` predicate function
- [ ] Ensure production CORS is restricted to specific known domains
- [ ] Add CORS configuration tests
- [ ] Document allowed origins in configuration

---

## 🟡 P2 — MEDIUM PRIORITY IMPROVEMENTS

### IMP-07: Rate limiter defaults may be too generous

**Severity:** 🟡 MEDIUM  
**File:** `botserver/src/security/rate_limiter.rs`

Default rate limits:
- General: 100 req/s, 200 burst
- Auth: 50 req/s, 100 burst
- API: 500 req/s, 1000 burst

500 req/s for API with 1000 burst is very high for a bot platform and may not protect against DDoS.

**Actions:**
- [ ] Review rate limits against actual traffic patterns
- [ ] Add per-IP and per-user rate limiting (not just global)
- [ ] Add rate limiting for WebSocket connections
- [ ] Consider tiered rate limits based on authentication status

---

### IMP-08: CSRF protection implementation needs validation

**Severity:** 🟡 MEDIUM  
**File:** `botserver/src/security/csrf.rs`

CSRF token system exists but needs verification that it's properly integrated into all state-changing endpoints.

**Actions:**
- [ ] Verify CSRF middleware is applied to ALL POST/PUT/DELETE routes
- [ ] Ensure CSRF tokens are properly bound to user sessions
- [ ] Add CSRF bypass tests (attempt requests without valid token)
- [ ] Document CSRF exemptions (if any, e.g., API key-authenticated routes)

---

### IMP-09: Missing security headers audit

**Severity:** 🟡 MEDIUM  
**File:** `botserver/src/security/headers.rs`

Security headers module exists but needs verification of completeness.

**Actions:**
- [ ] Verify all headers are set: `X-Frame-Options`, `X-Content-Type-Options`, `Strict-Transport-Security`, `Content-Security-Policy`, `Referrer-Policy`, `Permissions-Policy`
- [ ] Test with security header scanners (Mozilla Observatory, securityheaders.com)
- [ ] Ensure CSP is properly restrictive (no `unsafe-inline` or `unsafe-eval`)

---

### IMP-10: No dependency pinning — using caret versions

**Severity:** 🟡 MEDIUM  
**File:** `Cargo.toml`

Most dependencies use minimum version specifiers (e.g., `"1.0"`, `"0.4"`) which resolve to the latest compatible version. While `Cargo.lock` pins exact versions, the lock file is `.gitignore`'d, meaning different developers/CI will get different dependency versions.

**Actions:**
- [ ] Remove `Cargo.lock` from `.gitignore` — it should be tracked for applications (not libraries)
- [ ] Consider using exact versions for critical dependencies (security, crypto)
- [ ] Document dependency update procedure

---

### IMP-11: Stale submodule references

**Severity:** 🟡 MEDIUM  

`git status` shows 5 submodules with uncommitted changes:
```
 m botapp
 m botbook
 m botlib
 m bottemplates
 m bottest
```

**Actions:**
- [ ] For each dirty submodule: commit, push, and update parent reference
- [ ] Add submodule status check to CI
- [ ] Document submodule workflow more prominently

---

## 🔵 P3 — LOW PRIORITY / NICE-TO-HAVE

### IMP-12: Add git pre-commit hook for secret scanning

**Actions:**
- [ ] Install `gitleaks` or `trufflehog` as a pre-commit hook
- [ ] Scan for patterns: API keys, tokens, passwords, private keys
- [ ] Block commits containing secrets

---

### IMP-13: ✅ RESOLVED — README.md refactored
**Severity:** 🟡 MEDIUM  
**Status:** ✅ Split into `README.md` (architecture) and `AGENTS.md` (LLM rules).

Original issue: README was 1335 lines. Now split for better AI/human separation.

**Completed:**
- [x] Extract security policy & LLM rules → `AGENTS.md`
- [x] Keep README focused: overview, quick start, architecture

---

### IMP-14: ~40 TODO/FIXME/HACK/XXX comments in codebase

**Actions:**
- [ ] Triage all 40 TODO comments — either fix them or create issues
- [ ] Remove stale TODOs
- [ ] Replace `HACK`/`XXX` with proper solutions

---

### IMP-15: Missing integration test coverage

**Severity:** 🔵 LOW  
**File:** `bottest/`

README mentions 80%+ coverage goal for critical paths but no coverage reports are generated.

**Actions:**
- [ ] Set up `cargo-tarpaulin` or `llvm-cov` for coverage reports
- [ ] Add coverage gate to CI (fail if below threshold)
- [ ] Prioritize tests for: auth flows, session management, script execution, drive sync

---

### IMP-16: `package.json` has both `puppeteer` and `@playwright/test`

**Severity:** 🔵 LOW  
**File:** `package.json`

Two browser automation tools installed. Choose one and remove the other.

**Actions:**
- [ ] Decide on Playwright or Puppeteer
- [ ] Remove unused tool dependency
- [ ] Clean up `node_modules`

---

### IMP-17: `Cargo.lock` is gitignored

**Severity:** 🟡 MEDIUM  
**File:** `.gitignore` line 37

For applications (not libraries), `Cargo.lock` should be committed to ensure reproducible builds. This workspace produces binaries (`botserver`, `botui`, `botapp`) — so the lock file should be tracked.

**Actions:**
- [ ] Remove `Cargo.lock` from `.gitignore`
- [ ] Commit the current `Cargo.lock`
- [ ] Update contributing guidelines

---

### IMP-18: Missing Dockerfile / container deployment

**Severity:** 🔵 LOW  

No Dockerfile or container configuration found, despite having container dependencies (LXC in `DEPENDENCIES.sh`).

**Actions:**
- [ ] Create multi-stage `Dockerfile` for production builds
- [ ] Create `docker-compose.yml` for development environment
- [ ] Document container deployment process

---

### IMP-19: No CI/CD configuration found in `.github/` or `.forgejo/`

**Severity:** 🟡 MEDIUM  

`.github/` and `.forgejo/` directories exist but need verification of CI pipeline configuration.

**Actions:**
- [ ] Verify CI runs: `cargo check`, `cargo clippy`, `cargo test`, `cargo audit`
- [ ] Add security scanning step to CI
- [ ] Add binary size tracking to CI
- [ ] Add coverage reporting to CI

---

## 📊 Summary

| Priority | Count | Category |
|----------|-------|----------|
| 🔴 P0 Critical | 6 | **4 fully resolved, 2 partially resolved** |
| 🟠 P1 High | 6 | Significant improvements for stability/security |
| 🟡 P2 Medium | 5 | Important quality and security improvements |
| 🔵 P3 Low | 8 | Nice-to-have improvements and cleanup |
| **Total** | **25** | **6 P0 items addressed this session** |

### ✅ Completed This Session (2026-02-19)

1. **SEC-01**: ✅ `vault-unseal-keys` removed from git tracking
2. **SEC-02**: ✅ Verified `.env` files untracked, created `.env.example`
3. **SEC-03**: ✅ `init.json` removed from git tracking, added to `.gitignore`
4. **SEC-04**: ✅ All 8 `Command::new()` replaced with `SafeCommand`, whitelist updated
5. **SEC-05**: ✅ SQL injection fixed — parameterized queries in search/get/count handlers
6. **SEC-06**: ✅ Started — `rate_limiter.rs` expect() calls replaced with const NonZeroU32
7. **Bonus**: ✅ `.gitignore` hardened with `*.pem`, `*.key`, `*.crt`, `*.cert` patterns
8. **Bonus**: ✅ Fixed 3 duplicate `#[cfg(not(windows))]` attributes in `installer.rs`

### 🔴 Still Requires Manual Action

1. **Rotate Vault unseal keys** (SEC-01)
2. **Rotate Vault tokens in .env** (SEC-02)
3. **Purge secrets from git history** using `git filter-repo` (SEC-01)

---

*This document should be reviewed and updated weekly. Tasks should be moved to the project's issue tracker once triaged.*
