# TASKS.md — General Bots Workspace Audit

**Generated:** 2026-02-19
**Workspace:** `/home/rodriguez/gb` (v6.2.0)
**Scope:** Security Audit and Improvements Execution

---

## 🔴 P0 — CRITICAL SECURITY FLAWS

### SEC-01: ✅ RESOLVED — History Clean
**Status:** ✅ Repositor history rewritten. Sensitive files removed and ignored.
- [x] `vault-unseal-keys`, `init.json` removed from history (git-filter-repo)
- [x] Files ignored in `.gitignore`
- [x] Remote `origin` updated (force pushed)

### SEC-02: ✅ PARTIALLY RESOLVED — `.env` exposure
**Status:** ✅ Mitigated (Untracked). **Rotation needed.**
- [ ] **Rotate Vault tokens immediately**

### SEC-03: ✅ RESOLVED — `init.json` removed
**Status:** ✅ Removed from tracking.

### SEC-04: ✅ RESOLVED — Command Execution Hardened
**Status:** ✅ Replaced `Command::new` with `SafeCommand`.

### SEC-05: ✅ RESOLVED — SQL Injection Hardened
**Status:** ✅ Parameterized queries implemented. Build verified.

### SEC-06: ✅ RESOLVED — `unwrap()`/`expect()` verified
**Status:** ✅ Core/LLM production code verified clean.
- [x] `botserver/src/core`: Clean (Unwraps confined to tests/stubs)
- [x] `botserver/src/llm`: Clean (Unwraps confined to tests)
- [x] Fixed `rate_limiter.rs` (unsafe) & `utils.rs` (expect)

---

## 🟠 P1 — HIGH PRIORITY IMPROVEMENTS

### IMP-03: ✅ RESOLVED — Artifact Cleanup
- [x] Deleted `.bas`, `PROMPT.md`
- [x] Added `Cargo.lock` to tracking

### IMP-04: ✅ RESOLVED — Unsafe Code Fix
- [x] Replaced `unsafe` block in `rate_limiter.rs`

### IMP-06: ✅ RESOLVED — CORS Configuration
- [x] Fixed syntax and logic in `validate_origin`

### IMP-14: 🟡 IN PROGRESS — Code Cleanup (TODOs)
**Status:** References cleaned. Features pending.
- [x] Removed stale references to `TODO-refactor1.md`
- [ ] Implement `drive_handlers.rs` (Drive stubbed)
- [ ] Implement `admin_invitations.rs` (Schema missing)

### IMP-15: 🟡 IN PROGRESS — Integration Tests
**Status:** Tool installing (`cargo-tarpaulin` compiling in background).
- [ ] Generate coverage report once installed

---

## 🟡 P2 — POLICIES (Completed)

### IMP-07 to IMP-10: ✅ RESOLVED — Policies Added
- [x] Rate Limiting, CSRF, Headers, Dependency Management documented in `AGENTS.md`.

### IMP-16: ✅ RESOLVED — Tool Consolidation
- [x] Removed Puppeteer.

### IMP-17: ✅ RESOLVED — Lockfile
- [x] Tracked `Cargo.lock`.
