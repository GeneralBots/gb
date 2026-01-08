# General Bots - Video Module TODO

**Status:** In Progress  
**Priority:** HIGH

---

## Files to Complete

### Partially Created (need completion)
- [ ] `botserver/src/video/handlers.rs` - truncated at line 824, needs remaining handlers
- [ ] `botserver/src/video/mod.rs` - needs to wire up all submodules and routes

### Not Yet Created
- [ ] `botserver/src/video/analytics.rs` - video analytics tracking
- [ ] `botserver/src/video/websocket.rs` - WebSocket for real-time export progress
- [ ] `botserver/src/video/render.rs` - FFmpeg render worker with .gbdrive storage
- [ ] `botserver/src/video/mcp_tools.rs` - MCP tools for AI agents

---

## Features to Implement

### Core (Partially Done)
- [x] Schema definitions (`schema.rs`)
- [x] Data models (`models.rs`)
- [x] VideoEngine core methods (`engine.rs`)
- [ ] HTTP handlers completion (`handlers.rs`)
- [ ] Route configuration (`mod.rs`)

### AI Features (Engine methods exist, handlers needed)
- [x] Transcription (Whisper)
- [x] Auto-captions generation
- [x] Text-to-speech
- [x] Scene detection
- [x] Auto-reframe
- [x] Background removal
- [x] Video enhancement/upscaling
- [x] Beat sync for music
- [x] Waveform generation

### New Features
- [ ] WebSocket real-time export progress
- [ ] Video analytics (views, engagement)
- [ ] Save exports to `.gbdrive/videos`
- [ ] Keyframe animations
- [ ] MCP tools for video operations

---

## Handlers Needed in handlers.rs

```rust
// Missing handlers to add:
pub async fn generate_waveform_handler
pub async fn list_templates
pub async fn apply_template_handler
pub async fn add_transition_handler
pub async fn chat_edit
pub async fn start_export
pub async fn get_export_status
pub async fn video_ui
```

---

## mod.rs Structure Needed

```rust
mod analytics;
mod engine;
mod handlers;
mod models;
mod render;
mod schema;
mod websocket;

pub mod mcp_tools;

pub use engine::VideoEngine;
pub use handlers::*;
pub use models::*;
pub use render::{start_render_worker, VideoRenderWorker};
pub use schema::*;

// Route configuration with all endpoints
pub fn configure_video_routes() -> Router<Arc<AppState>>
pub fn configure(router: Router<Arc<AppState>>) -> Router<Arc<AppState>>
```

---

## Migration Required

File: `botserver/migrations/20250716000001_add_video_tables/up.sql`

Tables needed:
- video_projects
- video_clips
- video_layers
- video_audio_tracks
- video_exports
- video_command_history
- video_analytics
- video_keyframes

---

## Notes

- All code must follow PROMPT.md guidelines
- Use SafeCommand instead of Command::new()
- Use ErrorSanitizer for HTTP error responses
- No comments in code
- No .unwrap() or .expect() in production code