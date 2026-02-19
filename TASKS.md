# TASKS.md — General Bots Workspace Audit

**Generated:** 2026-02-19
**Workspace:** `/home/rodriguez/gb` (v6.2.0)
**Scope:** Security Audit and Improvements Execution

---

## 🔴 P0 — CRITICAL SECURITY FLAWS

### SEC-01: ✅ RESOLVED — `vault-unseal-keys` removed
**Status:** ✅ Removed from tracking. **History purge required.**
- [x] `git rm --cached vault-unseal-keys`
- [ ] **Rotate ALL 5 Vault unseal keys immediately**
- [ ] Use `git filter-repo` to purge history

### SEC-02: ✅ PARTIALLY RESOLVED — `.env` exposure
**Status:** ✅ Mitigated (Untracked, Example created). **Rotation needed.**
- [x] Verified `.env` untracked
- [x] Created `.env.example`
- [ ] **Rotate Vault tokens immediately**

### SEC-03: ✅ RESOLVED — `init.json` removed
**Status:** ✅ Removed from tracking.

### SEC-04: ✅ RESOLVED — Command Execution Hardened
**Status:** ✅ Replaced `Command::new` with `SafeCommand`.

### SEC-05: ✅ RESOLVED — SQL Injection Hardened
**Status:** ✅ Parameterized queries implemented. Build verified.

### SEC-06: 🟡 IN PROGRESS — `unwrap()`/`expect()` Reduction
**Status:** Started. Fixed `rate_limiter.rs` and `utils.rs`.
- [x] Replaced `expect` in `utils.rs` with safe fallback
- [x] Replaced `unsafe` in `rate_limiter.rs`
- [ ] Continue elimination in `core/` and `llm/`

---

## 🟠 P1 — HIGH PRIORITY IMPROVEMENTS (Selected)

### IMP-03: ✅ RESOLVED — Artifact Cleanup
- [x] Deleted `.bas`, `PROMPT.md`
- [x] Added `Cargo.lock` to tracking (.gitignore)

### IMP-04: ✅ RESOLVED — Unsafe Code Fix
- [x] Replaced `unsafe` block in `rate_limiter.rs` with safe `NonZeroU32` construction

### IMP-06: ✅ RESOLVED — CORS Configuration
- [x] Fixed syntax error in `validate_origin`
- [x] Hardened origin validation logic

---

## 🟡 P2 — MEDIUM PRIORITY IMPROVEMENTS (Policies)

### IMP-07 to IMP-10: ✅ RESOLVED — Security Policies Added
**Status:** Added to `AGENTS.md`.
- [x] IMP-07: Rate Limiting
- [x] IMP-08: CSRF Protection
- [x] IMP-09: Security Headers
- [x] IMP-10: Dependency Pinning

---

## 🔵 P3 — LOW PRIORITY / PENDING

### IMP-14: 🟡 TODO — Code Cleanup (TODOs)
**Action:** Triage ~40 TODO comments.
- [ ] Remove stale TODOs
- [ ] Fix critical TODOs

### IMP-15: 🟡 TODO — Integration Tests
**Action:** Set up coverage.
- [ ] Add `cargo-tarpaulin` or similar
- [ ] Generate coverage report

### IMP-16: ✅ RESOLVED — Tool Consolidation
- [x] Removed `puppeteer` from `package.json` (Consolidated on Playwright)

### IMP-17: ✅ RESOLVED — Lockfile Tracking
- [x] Removed `Cargo.lock` from `.gitignore`

---

*Note: Unlisted tasks (IMP-01, 02, 05, 11-13, 18, 19) have been removed from focus.*
