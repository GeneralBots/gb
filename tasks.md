# Security Audit & Remediation Tasks

## Executive Summary
A security review has been performed on the Rust codebase (server, logic, and core libraries). Earlier concerns regarding the Dynamic Table API acting as an explicit vulnerability have been retracted, as the behavior corresponds to intentional system design relying on role-based access scoping. However, significant vulnerabilities were identified regarding execution isolation and network requests originating from the bot engine.

**Actions Taken:** Both identified active vulnerabilities have been corrected directly in the codebase.

---

## 1. [FIXED] Remote Code Execution (RCE) via `trusted_shell_script_arg` Command Injection
**Status:** Remediated in `botserver/src/llm/local.rs`
**Severity:** CRITICAL

**Description:**
The codebase has a custom wrapper `SafeCommand` in `botserver/src/security/command_guard.rs`, which is designed to prevent shell injections. However, `trusted_shell_script_arg` acts as a bypass to this safety check, accepting arbitrary shell strings. In `botserver/src/llm/local.rs`, `trusted_shell_script_arg` had been executing commands during Llama.cpp server startup by embedding database configuration values (like `llm_server_path`, `n_moe`) directly inside a `sh -c` shell string. If those configuration variables contained shell control operators (like `;`, `&`, `|`), an attacker modifying those configs could achieve arbitrary remote code execution on the host operating system.

**Remediation Applied:**
- Replaced the vulnerable shell orchestrations with pure, safe bindings using `std::process::Command::spawn()`.
- Arguments mapped exclusively via explicit positional `.arg()` blocks rather than shell interpolation, removing the possibility of execution breakout.

---

## 2. [FIXED] Server-Side Request Forgery (SSRF) in Rhai Execution `GET` requests
**Status:** Remediated in `botserver/src/basic/keywords/get.rs`
**Severity:** HIGH

**Description:**
In `botserver/src/basic/keywords/get.rs`, Rhai scripts have a `GET` command that wraps an HTTP client request. It used `is_safe_path` to allegedly prevent abuse. Unfortunately, `is_safe_path` implicitly permitted internal routing by returning `true` whenever the user-provided protocol was `http://` or `https://` without checking the corresponding host IP addresses.
If a user supplied `http://169.254.169.254/latest/meta-data/` or `http://10.0.0.1/admin`, the system evaluated it. This was an open SSRF allowing attackers to scan internal corporate networks, pivot to internal APIs, and steal Cloud Provider IAM Metadata / Instance Profiles.

**Remediation Applied:**
- Introduced `url` crate hostname parsing inside the `is_safe_path` check.
- Added strict evaluation to block the `localhost`, link-local instances (`169.254.x.x`), internal Subnets (`10.x`, `172.16-31.x`, `192.168.x`), and standard metadata API FQDN lookups (like `metadata.google.internal`).

---

## 3. [MEDIUM] Lax CSRF and Cookie Security
**Status:** Pending Review

**Description:**
Upon examining headers in `botserver/src/weba/mod.rs` and other API segments, it appears `SameSite` policies may not be strictly enforced for all configurations, and TLS/Cert Pinning is hand-rolled (`botserver/src/security/cert_pinning.rs`). 

**Recommended Action:**
- Ensure all session cookies have `HttpOnly`, `Secure`, and `SameSite=Lax` (or `Strict`).
- Run `cargo audit` to handle dependency vulnerabilities in any manual implementations of TLS processing.

---

## Informational Notes: Dynamic Database Table Operations

**Observation:**
The `is_table_allowed_with_conn` allows requests targeting general bot administration records, rendering a wide subset of internal tables addressable over the `/api/v1/db/{table_name}` system endpoints when `dynamic_table_definitions` rules don't exist.

**Conclusion:**
This behavior operates **by design** to supply a generic API approach where bots expose privilege data based directly on Bot Identity restrictions and internal User Object role bindings across standard API interactions. This was deemed safe and required for generic bot privilege allocations.
