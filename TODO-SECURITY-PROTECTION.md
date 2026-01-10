# Security Protection Module - Implementation TODO

**Version:** 1.0.0
**Created:** 2025
**Status:** ✅ COMPLETE

---

## Overview

Implement a comprehensive Security Protection module that allows administrators to manage Linux server security tools (Lynis, RKHunter, Chkrootkit, Suricata, LMD, ClamAV) through the General Bots UI.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         botui (Port 3000)                        │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  /suite/tools/security.html                                 ││
│  │  ├── Tab: API Compliance Report (existing code_scanner)     ││
│  │  └── Tab: Protection (NEW - security tools management)      ││
│  └─────────────────────────────────────────────────────────────┘│
│                              │                                   │
│                              ▼ HTMX/API calls                    │
└──────────────────────────────┼───────────────────────────────────┘
                               │
┌──────────────────────────────┼───────────────────────────────────┐
│                         botserver (Port 8088)                    │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  src/security/protection/                                   ││
│  │  ├── mod.rs           # Module exports                      ││
│  │  ├── manager.rs       # ProtectionManager orchestrator      ││
│  │  ├── api.rs           # Axum API routes                     ││
│  │  ├── lynis.rs         # Lynis integration                   ││
│  │  ├── rkhunter.rs      # RKHunter integration                ││
│  │  ├── chkrootkit.rs    # Chkrootkit integration              ││
│  │  ├── suricata.rs      # Suricata IDS/IPS integration        ││
│  │  ├── lmd.rs           # Linux Malware Detect integration    ││
│  │  └── clamav.rs        # ClamAV integration (extend existing)││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Backend Infrastructure (botserver) ✅ COMPLETE

### 1.1 Create Protection Module Structure ✅ DONE

### 1.2 Protection Manager ✅ DONE

### 1.3 Individual Tool Integrations ✅ DONE

- [x] Lynis (`lynis.rs`)
- [x] RKHunter (`rkhunter.rs`)
- [x] Chkrootkit (`chkrootkit.rs`)
- [x] Suricata (`suricata.rs`)
- [x] LMD (`lmd.rs`)

### 1.4 API Routes ✅ DONE

### 1.5 Update security/mod.rs ✅ DONE

### 1.6 Register Routes in Main ✅ DONE

### 1.7 Update command_guard.rs ✅ DONE

---

## Phase 2: Frontend Updates (botui) ✅ COMPLETE

### 2.1 Security Page ✅ DONE

### 2.2 Navigation Updates ✅ DONE

### 2.3 Report Modal ✅ DONE

---

## Phase 3: Documentation (botbook) ✅ COMPLETE

### 3.1 Create Protection Documentation ✅ DONE

**File:** `botbook/src/23-security/protection-tools.md`

### 3.2 Update SUMMARY.md ✅ DONE

---

## Phase 4: BASIC/ETL Integration (botlib) ✅ COMPLETE

### 4.1 Add BASIC Keywords ✅ DONE

**File:** `botserver/src/basic/keywords/security_protection.rs`

New keywords added:
- `SECURITY TOOL STATUS`
- `SECURITY RUN SCAN`
- `SECURITY GET REPORT`
- `SECURITY UPDATE DEFINITIONS`
- `SECURITY START SERVICE`
- `SECURITY STOP SERVICE`
- `SECURITY INSTALL TOOL`
- `SECURITY HARDENING SCORE`

### 4.2 ETL Functions ✅ DONE

- [x] `security_tool_status(tool_name)` - Returns tool status
- [x] `security_run_scan(tool_name)` - Runs scan
- [x] `security_get_report(tool_name)` - Gets latest report
- [x] `security_hardening_score()` - Gets Lynis hardening index
- [x] `security_update_definitions(tool_name)` - Updates signatures
- [x] `security_start_service(tool_name)` - Starts service
- [x] `security_stop_service(tool_name)` - Stops service
- [x] `security_install_tool(tool_name)` - Installs tool

---

## Phase 5: Cleanup ✅ COMPLETE

### 5.1 Remove Unused Dependencies ✅ DONE

- [x] Removed `askama` from botui (not being used)
- [x] Removed `askama_axum` from botui
- [x] Deleted `askama.toml` configuration file

---

## File Checklist ✅ ALL COMPLETE

### botserver/src/security/protection/

- [x] `mod.rs` ✅
- [x] `manager.rs` ✅
- [x] `api.rs` ✅
- [x] `lynis.rs` ✅
- [x] `rkhunter.rs` ✅
- [x] `chkrootkit.rs` ✅
- [x] `suricata.rs` ✅
- [x] `lmd.rs` ✅
- [x] `installer.rs` ✅

### botserver/src/security/

- [x] `mod.rs` - Updated with protection module exports ✅
- [x] `command_guard.rs` - Added security tools to whitelist ✅

### botserver/src/basic/keywords/

- [x] `security_protection.rs` ✅
- [x] `mod.rs` - Updated with security_protection module ✅

### botserver/src/

- [x] `main.rs` - Registered protection routes ✅

### botui/ui/suite/tools/

- [x] `security.html` ✅

### botui/

- [x] `Cargo.toml` - Removed askama dependencies ✅
- [x] `askama.toml` - Deleted ✅

### botbook/src/23-security/

- [x] `protection-tools.md` ✅
- [x] `SUMMARY.md` - Entry added ✅

---

## Summary

All phases of the Security Protection Module have been completed:

1. **Backend Infrastructure** - Full protection module with manager, API routes, and individual tool integrations
2. **Frontend UI** - Security page with Protection tab showing all 6 tools
3. **Documentation** - Comprehensive documentation in botbook
4. **BASIC Keywords** - 8 new keywords for scripting security operations
5. **Cleanup** - Removed unused askama dependencies from botui

The module is ready for integration testing with actual security tools installed on a Linux host.