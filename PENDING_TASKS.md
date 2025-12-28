# General Bots - Pending Tasks for Next Sessions

**Created:** Session cleanup
**Purpose:** Consolidated list of pending work for LLM continuation

---

## ✅ COMPLETED THIS SESSION

### 1. Sources Module - Knowledge Base Backend ✅
**Location:** `botserver/src/sources/knowledge_base.rs`

**Implemented:**
- `POST /api/sources/kb/upload` - Upload documents for ingestion
- `GET /api/sources/kb/list` - List ingested sources
- `POST /api/sources/kb/query` - Query knowledge base with full-text search
- `GET /api/sources/kb/:id` - Get source details
- `DELETE /api/sources/kb/:id` - Remove source
- `POST /api/sources/kb/reindex` - Re-process sources
- `GET /api/sources/kb/stats` - Get knowledge base statistics

**Features:**
- Document chunking with configurable size/overlap
- Text extraction for PDF, DOCX, TXT, Markdown, HTML, CSV, XLSX
- Full-text search with PostgreSQL ts_rank
- Status tracking (pending, processing, indexed, failed, reindexing)

---

### 2. Research Module - Web Search Backend ✅
**Location:** `botserver/src/research/web_search.rs`

**Implemented:**
- `POST /api/research/web/search` - Web search via DuckDuckGo
- `POST /api/research/web/summarize` - Summarize search results
- `POST /api/research/web/deep` - Deep research with multiple queries
- `GET /api/research/web/history` - Search history
- `GET /api/research/web/instant` - Instant answers from DuckDuckGo API

**Features:**
- DuckDuckGo HTML scraping (no API key required)
- Result parsing with favicon extraction
- Related query generation
- Citation tracking

---

### 3. App Generator - Full LLM-Based Generation ✅
**Location:** `botserver/src/auto_task/app_generator.rs`

**Completely rewritten to:**
- Generate ALL files (HTML, CSS, JS, BAS) via LLM
- Removed ALL hardcoded templates
- Single LLM call generates complete app structure
- Includes tables, pages, tools, schedulers

---

### 4. App Logging System ✅
**Location:** `botserver/src/auto_task/app_logs.rs`

**Implemented:**
- Server-side log storage per app
- Client-side JavaScript logger (`/api/app-logs/logger.js`)
- Error context injection into Designer prompts
- Auto-cleanup scheduler (D-1 retention)

**Endpoints:**
- `POST /api/app-logs/client` - Receive client logs
- `GET /api/app-logs/list` - List logs with filters
- `GET /api/app-logs/stats` - Log statistics
- `POST /api/app-logs/clear/{app_name}` - Clear app logs
- `GET /api/app-logs/logger.js` - Client logger script

---

### 5. Database Migration ✅
**Location:** `botserver/migrations/6.1.3_knowledge_base_sources/`

**Created tables:**
- `knowledge_sources` - Uploaded documents metadata
- `knowledge_chunks` - Text chunks for RAG
- `research_search_history` - Search history tracking

---

## 🔴 HIGH PRIORITY

### 1. Calendar UI Completion

**Location:** `botui/ui/suite/calendar/`
**Backend exists:** `botserver/src/calendar/` (fully implemented with CalDAV)

**What's missing:**
- Week view
- Day view
- Drag-and-drop event moving
- Recurring events UI
- Calendar sharing UI

**Backend is complete** - just needs frontend polish.

---

### 2. Vector Embeddings Integration

**Location:** `botserver/src/sources/knowledge_base.rs`

**What's needed:**
- Connect to LLM for embedding generation
- Store embeddings in PostgreSQL pgvector
- Implement semantic search alongside full-text search
- Integrate with existing `drive/vectordb.rs`

---

## 🟡 MEDIUM PRIORITY

### 3. Meet Module - LiveKit Integration

**Location:** `botserver/src/meet/`
**UI exists:** `botui/ui/suite/meet/`

**What's missing:**
- LiveKit server configuration documentation
- Room creation and management
- Participant tracking
- Recording integration

**Requires external setup:**
- LiveKit server (self-hosted or cloud)
- TURN/STUN servers for WebRTC

---

### 4. Custom Domain - Config.csv Integration

**Location:** `botserver/src/core/dns/`

**Current state:** DNS routes exist but config.csv parsing not connected

**What's needed:**
```csv
# In bot's config.csv
appname-domain,app.customerdomain.com
```

- Parse `appname-domain` from config.csv during bot load
- Register with DNS service automatically
- Auto-provision SSL via Let's Encrypt

---

### 5. Designer Magic Button - LLM Integration

**Location:** 
- `botui/ui/suite/designer.html` (dialog designer - DONE)
- `botui/ui/suite/editor.html` (code editor - DONE)
- `botserver/src/designer/mod.rs` (endpoints - DONE)

**What's missing:**
- Connect `/api/v1/editor/magic` to actual LLM when `feature = "llm"` is enabled
- Currently uses fallback suggestions only
- Need to test with LLM enabled

---

## 🟢 LOW PRIORITY / POLISH

### 6. SEO Meta Tags Verification

Verify all HTMX pages have proper SEO:
- `botui/ui/suite/**/*.html`
- Generated apps from `app_generator.rs`

Required tags:
```html
<meta name="description" content="...">
<meta name="robots" content="noindex, nofollow">
<meta property="og:title" content="...">
<meta property="og:description" content="...">
```

---

### 7. Login Flow Documentation

**Credentials shown during setup:**
- Displayed in terminal with box formatting
- Pauses for user to copy
- NOT saved to file (security)

**Location of display:** `botserver/src/core/package_manager/setup/directory_setup.rs`

Consider adding:
- First-login wizard to change password
- Email verification flow
- Password recovery

---

## 📋 Session Continuation Notes

### Files Modified This Session:
- `botserver/src/auto_task/app_generator.rs` - Complete rewrite for LLM-only generation
- `botserver/src/auto_task/app_logs.rs` - NEW: App logging system
- `botserver/src/auto_task/mod.rs` - Added app_logs exports and routes
- `botserver/src/sources/mod.rs` - Added knowledge_base module
- `botserver/src/sources/knowledge_base.rs` - NEW: KB ingestion backend
- `botserver/src/research/mod.rs` - Added web_search module
- `botserver/src/research/web_search.rs` - NEW: Web search backend
- `botserver/src/designer/mod.rs` - Added error context to prompts
- `botserver/migrations/6.1.3_knowledge_base_sources/` - NEW: DB migration

### Build Status:
- `cargo check -p botserver` - ✅ 0 errors, 0 warnings

### How to Continue:
1. Pick a HIGH PRIORITY task
2. Read the relevant source files
3. Implement missing functionality
4. Test with `cargo check`
5. Update this file when complete

---

## 🎯 Quick Start for Next Session

```
Start with:
1. "Complete Calendar UI - add week/day views"
   OR
2. "Add vector embeddings to knowledge base"
   OR  
3. "Test app generator with LLM enabled"

Context files to read first:
- botui/ui/suite/calendar/
- botserver/src/sources/knowledge_base.rs
- botserver/src/auto_task/app_generator.rs
```
