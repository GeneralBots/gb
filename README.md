# General Bots Workspace

**Version:** 6.1.0  
**Type:** Rust Workspace (Monorepo with Independent Subproject Repos)

---

## Structure

This workspace contains multiple General Bots projects:

```
gb/
├── PROMPT.md          ← Workspace-level development guide (READ THIS FIRST)
├── Cargo.toml         ← Workspace configuration
├── README.md          ← This file
│
├── botapp/            ← Desktop application (Tauri)
├── botserver/         ← Main server (API + business logic)
├── botlib/            ← Shared library (types, utilities)
├── botui/             ← Web UI (HTML/CSS/JS)
├── botbook/           ← Documentation
├── bottest/           ← Integration tests
├── botdevice/         ← Device integration
├── botmodels/         ← AI models
├── botplugin/         ← Plugin system
├── bottemplates/      ← Templates
└── target/            ← Build artifacts
```

---

## CRITICAL: PROMPT.md Files

**Each project has a PROMPT.md that defines its development rules.**

The diagnostics tool reads and respects these PROMPT.md files.

### Hierarchy

1. **`PROMPT.md`** (this directory) - Workspace-wide rules
2. **`botapp/PROMPT.md`** - Desktop app specifics
3. **`botserver/PROMPT.md`** - Server specifics
4. **`botlib/PROMPT.md`** - Library specifics
5. **`botui/PROMPT.md`** - UI specifics
6. **`botbook/PROMPT.md`** - Documentation specifics
7. **`bottest/PROMPT.md`** - Test specifics

**ALWAYS read the relevant PROMPT.md before working on a project.**

---

## Main Directive

**LOOP AND COMPACT UNTIL 0 WARNINGS - MAXIMUM YOLO**

- 0 warnings
- 0 errors
- Trust project diagnostics
- Respect all rules
- No `#[allow()]` in source code
- Real code fixes only

---

## Quick Start

```bash
cargo build
cargo test
```

---

## Development Workflow

1. Read `PROMPT.md` (workspace-level rules)
2. Read `<project>/PROMPT.md` (project-specific rules)
3. Use diagnostics tool to check warnings
4. Fix all warnings with full file rewrites
5. Verify with diagnostics after each file
6. Never suppress warnings with `#[allow()]`

---

## Git Structure

**Note:** Each subproject has its own git repository. This root repository only tracks workspace-level files:

- `PROMPT.md` - Development guide
- `Cargo.toml` - Workspace configuration
- `README.md` - This file
- `.gitignore` - Ignore patterns

Subprojects (botapp, botserver, etc.) are **not** git submodules - they are independent repositories.

---

## Rules Summary

```
✅ FULL FILE REWRITES ONLY
✅ BATCH ALL FIXES BEFORE WRITING
✅ VERIFY WITH DIAGNOSTICS AFTER EACH FILE
✅ TRUST PROJECT DIAGNOSTICS
✅ RESPECT ALL RULES

❌ NEVER use #[allow()] in source code
❌ NEVER use partial edits
❌ NEVER run cargo check/clippy manually
❌ NEVER leave unused code
❌ NEVER use .unwrap()/.expect()
❌ NEVER use panic!/todo!/unimplemented!()
❌ NEVER add comments
```

---

## Links

- Main Server: http://localhost:8081
- Desktop App: Uses Tauri to wrap botui
- Documentation: See botbook/

---

## License

See individual project repositories for license information.