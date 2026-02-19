# TASKS.md — General Bots Workspace Audit

**Generated:** 2026-02-19
**Workspace:** `/home/rodriguez/gb` (v6.2.0)
**Scope:** Security Audit and Improvements Execution

---

## 🔴 P0 — CRITICAL SECURITY FLAWS

### SEC-01: ✅ RESOLVED — History Clean
**Status:** ✅ Repositor history rewritten (git-filter-repo).
- [x] `vault-unseal-keys`, `init.json` removed
- [x] Remote `origin` force-pushed

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
**Status:** Features partially implemented.
- [x] Cleaned stale README references
- [x] **IMPLEMENTED `drive_handlers.rs`** (S3 Integration Active)
- [ ] Implement `admin_invitations.rs` (Stubbed)
- [ ] Remaining minor TODOs

### IMP-15: 🟡 READY — Integration Tests
**Status:** Tool installed (`cargo-tarpaulin` available).
- [ ] Generate coverage report (Run `cargo tarpaulin --out Html`)

---

## 🟡 P2 — POLICIES (Completed)

### IMP-07 to IMP-10: ✅ RESOLVED — Policies Added
- [x] Rate Limiting, CSRF, Headers, Dependency Management documented in `AGENTS.md`.

### IMP-16: ✅ RESOLVED — Tool Consolidation
- [x] Removed Puppeteer.

### IMP-17: ✅ RESOLVED — Lockfile
- [x] Tracked `Cargo.lock`.
