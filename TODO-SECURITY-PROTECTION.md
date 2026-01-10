# Security Protection Module - Implementation TODO

**Version:** 1.0.0
**Created:** 2025
**Status:** In Progress

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

## Phase 1: Backend Infrastructure (botserver)

### 1.1 Create Protection Module Structure ✅ DONE

**File:** `botserver/src/security/protection/mod.rs`

```rust
pub mod api;
pub mod manager;
pub mod lynis;
pub mod rkhunter;
pub mod chkrootkit;
pub mod suricata;
pub mod lmd;

pub use manager::ProtectionManager;
pub use api::configure_protection_routes;
```

### 1.2 Protection Manager ✅ DONE

**File:** `botserver/src/security/protection/manager.rs`

Responsibilities:
- [x] Track installed tools and their status
- [x] Coordinate tool installation via package manager
- [x] Execute scans using SafeCommand
- [x] Parse and store scan results
- [x] Manage service start/stop/enable/disable
- [x] Handle auto-update scheduling

Key structs:
```rust
pub struct ProtectionManager {
    tools: HashMap<ProtectionTool, ToolStatus>,
    config: ProtectionConfig,
}

pub enum ProtectionTool {
    Lynis,
    RKHunter,
    Chkrootkit,
    Suricata,
    LMD,
    ClamAV,
}

pub struct ToolStatus {
    pub installed: bool,
    pub version: Option<String>,
    pub service_running: bool,
    pub last_scan: Option<DateTime<Utc>>,
    pub last_update: Option<DateTime<Utc>>,
    pub auto_update: bool,
    pub auto_remediate: bool,
}
```

### 1.3 Individual Tool Integrations ✅ DONE

#### Lynis (`lynis.rs`) ✅
- [x] Check installation: `which lynis`
- [x] Install: `apt install lynis` / `yum install lynis`
- [x] Run audit: `lynis audit system --quick`
- [x] Parse report: `/var/log/lynis-report.dat`
- [x] Auto-remediation: Apply suggested fixes (partial)
- [x] Extract hardening index score

#### RKHunter (`rkhunter.rs`) ✅
- [x] Check installation: `which rkhunter`
- [x] Install: `apt install rkhunter`
- [x] Update database: `rkhunter --update`
- [x] Run scan: `rkhunter --check --skip-keypress`
- [x] Parse log: `/var/log/rkhunter.log`

#### Chkrootkit (`chkrootkit.rs`) ✅
- [x] Check installation: `which chkrootkit`
- [x] Install: `apt install chkrootkit`
- [x] Run scan: `chkrootkit -q`
- [x] Parse output for INFECTED markers

#### Suricata (`suricata.rs`) ✅
- [x] Check installation: `which suricata`
- [x] Install: `apt install suricata`
- [x] Service management: `systemctl start/stop/enable suricata`
- [x] Update rules: `suricata-update`
- [x] Parse alerts: `/var/log/suricata/eve.json`
- [x] Get rule count from config

#### LMD (`lmd.rs`) ✅
- [x] Check installation: `which maldet`
- [x] Install: Download from rfxn.com, run installer
- [x] Update signatures: `maldet --update-sigs`
- [x] Run scan: `maldet -a /path`
- [x] Parse report: `/usr/local/maldetect/logs/`

#### ClamAV (extend `antivirus.rs`)
- [x] Already partially implemented
- [ ] Add service management (clamd daemon) - use existing antivirus.rs
- [ ] Add freshclam update status - use existing antivirus.rs
- [ ] Add quarantine management - use existing antivirus.rs

### 1.4 API Routes ✅ DONE

**File:** `botserver/src/security/protection/api.rs`

```rust
pub fn configure_protection_routes() -> Router {
    Router::new()
        // Status endpoints
        .route("/api/v1/security/protection/status", get(get_all_status))
        .route("/api/v1/security/protection/:tool/status", get(get_tool_status))
        
        // Installation
        .route("/api/v1/security/protection/:tool/install", post(install_tool))
        .route("/api/v1/security/protection/:tool/uninstall", post(uninstall_tool))
        
        // Service management
        .route("/api/v1/security/protection/:tool/start", post(start_service))
        .route("/api/v1/security/protection/:tool/stop", post(stop_service))
        .route("/api/v1/security/protection/:tool/enable", post(enable_service))
        .route("/api/v1/security/protection/:tool/disable", post(disable_service))
        
        // Scanning
        .route("/api/v1/security/protection/:tool/run", post(run_scan))
        .route("/api/v1/security/protection/:tool/report", get(get_report))
        
        // Updates
        .route("/api/v1/security/protection/:tool/update", post(update_definitions))
        
        // Auto settings
        .route("/api/v1/security/protection/:tool/auto", post(toggle_auto))
        
        // ClamAV specific
        .route("/api/v1/security/protection/clamav/quarantine", get(get_quarantine))
        .route("/api/v1/security/protection/clamav/quarantine/:id", delete(remove_from_quarantine))
}
```

### 1.5 Update security/mod.rs ✅ DONE

Add to `botserver/src/security/mod.rs`:
```rust
pub mod protection;
pub use protection::{ProtectionManager, configure_protection_routes};
```

### 1.6 Register Routes in Main

Update `botserver/src/main.rs` to include:
```rust
.merge(security::configure_protection_routes())
```

### 1.7 Update command_guard.rs ✅ DONE

Added security tools to allowed commands whitelist:
- lynis
- rkhunter
- chkrootkit
- suricata
- suricata-update
- maldet
- systemctl

---

## Phase 2: Frontend Updates (botui)

### 2.1 Security Page ✅ DONE

**File:** `botui/ui/suite/tools/security.html`

- [x] Created with two tabs: API Compliance Report, Protection
- [x] Protection tab shows cards for all 6 tools
- [x] Each card has: status, version, last scan, actions
- [x] Actions: Install/Run/Start/Stop/View Report/Update
- [x] Toggle for auto-update/auto-remediate

### 2.2 Navigation Updates ✅ DONE

- [x] Updated `home.html` - Changed Compliance to Security
- [x] Updated `index.html` - Changed navigation link
- [x] Updated `css/home.css` - Changed .app-icon.compliance to .app-icon.security
- [x] Created `assets/icons/gb-security.svg`

### 2.3 Report Modal ✅ DONE

- [x] Modal for viewing scan reports (already in security.html)
- [ ] Add syntax highlighting for report output
- [ ] Add export functionality

---

## Phase 3: Documentation (botbook)

### 3.1 Create Protection Documentation

**File:** `botbook/src/23-security/protection-tools.md`

Contents:
- [ ] Overview of protection tools
- [ ] Installation requirements
- [ ] Configuration options
- [ ] API reference
- [ ] Troubleshooting guide

### 3.2 Update SUMMARY.md

Add entry for protection-tools.md in the Security section.

---

## Phase 4: BASIC/ETL Integration (botlib)

### 4.1 Add BASIC Keywords

**File:** `botlib/src/basic/keywords.rs` (or equivalent)

New keywords to add:
```basic
' Security tool management
INSTALL SECURITY TOOL "lynis"
UNINSTALL SECURITY TOOL "rkhunter"
START SECURITY SERVICE "suricata"
STOP SECURITY SERVICE "clamav"
RUN SECURITY SCAN "lynis"
GET SECURITY REPORT "rkhunter" INTO report
UPDATE SECURITY DEFINITIONS "clamav"

' Conditional checks
IF SECURITY TOOL "lynis" IS INSTALLED THEN
IF SECURITY SERVICE "suricata" IS RUNNING THEN
```

### 4.2 ETL Functions

Add ETL functions for security automation:
- [ ] `security_tool_status(tool_name)` - Returns tool status
- [ ] `security_run_scan(tool_name, options)` - Runs scan
- [ ] `security_get_report(tool_name)` - Gets latest report
- [ ] `security_hardening_score()` - Gets Lynis hardening index

---

## Phase 5: Testing

### 5.1 Unit Tests

**File:** `botserver/src/security/protection/tests.rs`

- [ ] Test tool detection
- [ ] Test status parsing
- [ ] Test report parsing
- [ ] Test command generation

### 5.2 Integration Tests

**File:** `bottest/tests/security_protection.rs`

- [ ] Test full install flow (mock)
- [ ] Test scan execution (mock)
- [ ] Test API endpoints

---

## Security Considerations

### Command Execution

All tool commands MUST use `SafeCommand`:

```rust
use crate::security::command_guard::SafeCommand;

SafeCommand::new("lynis")?
    .arg("audit")?
    .arg("system")?
    .execute()
```

### Allowed Commands Whitelist

Update `command_guard.rs` to whitelist:
- `lynis`
- `rkhunter`
- `chkrootkit`
- `suricata`
- `suricata-update`
- `maldet`
- `clamscan`
- `freshclam`
- `systemctl` (with restrictions)

### Permission Requirements

- Tools require root/sudo for full functionality
- Consider using capabilities or dedicated service user
- Log all tool executions to audit log

---

## API Response Formats

### Status Response

```json
{
  "tool": "lynis",
  "installed": true,
  "version": "3.0.9",
  "service_running": null,
  "last_scan": "2025-01-15T10:30:00Z",
  "last_update": "2025-01-14T08:00:00Z",
  "auto_update": true,
  "auto_remediate": false,
  "metrics": {
    "hardening_index": 78,
    "warnings": 12,
    "suggestions": 45
  }
}
```

### Scan Result Response

```json
{
  "scan_id": "uuid",
  "tool": "rkhunter",
  "started_at": "2025-01-15T10:30:00Z",
  "completed_at": "2025-01-15T10:35:00Z",
  "status": "completed",
  "result": "clean",
  "findings": [],
  "warnings": 0,
  "report_path": "/var/log/rkhunter.log"
}
```

---

## File Checklist

### botserver/src/security/protection/

- [x] `mod.rs` ✅
- [x] `manager.rs` ✅
- [x] `api.rs` ✅
- [x] `lynis.rs` ✅
- [x] `rkhunter.rs` ✅
- [x] `chkrootkit.rs` ✅
- [x] `suricata.rs` ✅
- [x] `lmd.rs` ✅
- [ ] `tests.rs` (tests included in each module)

### botserver/src/security/

- [x] `mod.rs` - Updated with protection module exports ✅
- [x] `command_guard.rs` - Added security tools to whitelist ✅

### botui/ui/suite/tools/

- [x] `security.html` ✅

### botbook/src/23-security/

- [ ] `protection-tools.md`

### botlib/

- [ ] Update BASIC keywords
- [ ] Add ETL functions

---

## Priority Order

1. ~~**HIGH** - Backend API structure (`api.rs`, `manager.rs`)~~ ✅ DONE
2. ~~**HIGH** - Lynis integration (most comprehensive)~~ ✅ DONE
3. **HIGH** - ClamAV extension (partially exists) - Wire up to existing antivirus.rs
4. ~~**MEDIUM** - RKHunter, Chkrootkit (simpler tools)~~ ✅ DONE
5. ~~**MEDIUM** - Suricata (service management)~~ ✅ DONE
6. ~~**MEDIUM** - LMD (malware detection)~~ ✅ DONE
7. **LOW** - Documentation
8. **LOW** - BASIC/ETL integration
9. **LOW** - Full test coverage

## Remaining Tasks

1. **Wire up ProtectionManager to AppState** - Add `protection_manager: Option<ProtectionManager>` to AppState
2. **Register routes in main.rs** - Add `.merge(security::configure_protection_routes())`
3. **Integration testing** - Test with actual tools installed
4. **Documentation** - Create botbook documentation
5. **BASIC keywords** - Add ETL functions for scripting

---

## Notes

- Follow PROMPT.md guidelines strictly
- No `#[allow()]` attributes
- No `.unwrap()` or `.expect()` in production code
- Use `SafeCommand` for all shell execution
- Sanitize all error messages before returning to client
- Log all operations to audit log