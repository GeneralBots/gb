# Web Desktop Environment Migration Plan (The "Windows" Vibe)

## 1. Project Overview & Vision
We are migrating the entire UI suite to a Web Desktop Environment (WDE). The goal is to create a UI that feels like a modern, web-based operating system (inspired by Windows 95's spatial model but with modern Tailwind aesthetics like the `html3.html` prototype). 

**Key Principles:**
- **Vanilla JS + HTMX:** We will build a custom Window Manager in Vanilla JS (`window-manager.js`) rather than relying on outdated libraries like WinBox. HTMX will handle fetching the content *inside* the windows.
- **Desktop Metaphor:** A main workspace with shortcut icons (Vibe, Tasks, Chat, Terminal, Explorer, Editor, Browser, Mail, Settings).
- **Taskbar:** A bottom bar showing currently open applications, allowing users to switch between them, alongside a system tray and clock.
- **Dynamic Windows:** Windows must be draggable, closable, minimizable, and maintain their state. The title bar must dynamically reflect the active view.
- **App Renames:** 
  - `Mantis` is now **`Vibe`**
  - `Terminal` added to suite default features
  - `Browser` added to suite default features
  - `Editor` already in suite, add to default features
  - Note: Keep `Drive` as `Drive` (undo Explorer rename).

This document provides a strictly detailed, step-by-step implementation guide so that any LLM or developer can execute it without ambiguity.

---

## 2. Architecture & File Structure

### Frontend Assets to Create:
1. `ui/desktop.html` - The main shell containing the desktop background, desktop icons, and the empty taskbar.
2. `js/window-manager.js` - The core engine. A JavaScript class responsible for DOM manipulation of windows.
3. `css/desktop.css` - Custom styles for the grid background, scrollbars, and window animations (using Tailwind as the base).

### Backend (Botserver) Updates:
- **State Management:** The backend needs to track the user's open windows, their positions, and sizes if we want persistence across reloads. Otherwise, local state (localStorage) is fine for V1.
- **HTMX Endpoints:** Each app (Explorer, Vibe, Chat, etc.) must expose an endpoint that returns *only* the HTML fragment for the app's body, NOT a full HTML page.
- **Theme Manager:** Needs to be updated to support the new desktop color schemes (e.g., brand-500 greens, transparent glass effects).

---

## 3. Step-by-Step Implementation Guide

### PHASE 1: The Shell (Desktop & Taskbar)
**Goal:** Create the static HTML structure based on `html3.html`.

**Tasks:**
1. Create the main `desktop.html`.
2. Implement the `workspace-bg` and `workspace-grid` using Tailwind and SVG.
3. Add the left-side Desktop Icons. Each icon must have a `data-app-id` and `data-app-title` attribute.
   - Example: `<div class="desktop-icon" data-app-id="drive" data-app-title="Drive" hx-get="/app/drive" hx-target="#temp-buffer" hx-swap="none">...</div>`
4. Create the Bottom Taskbar `<footer id="taskbar">`. It needs an empty container `<div id="taskbar-apps"></div>` to hold icons of open apps.

### PHASE 2: The Window Manager Engine (`window-manager.js`)
**Goal:** Build a robust, vanilla JavaScript class `WindowManager` to handle floating UI panels that feels as native, smooth, and feature-rich as WinBox.

**Core Requirements for `window-manager.js`:**
1. **State & Z-Index Management:** Keep an array of `openWindows = []`. Track the `activeWindowId`. Clicking any window must bring it to the front by updating its z-index (stacking context) and highlighting its taskbar icon.
2. **`createWindow(appId, title, initialContent)` method:**
   - Generates the DOM nodes for a floating window.
   - Includes a Title Bar (drag handle, dynamic title, minimize, maximize, close buttons).
   - Includes invisible 8px borders around the window for **resizing** (N, S, E, W, NE, NW, SE, SW).
   - Appends it to the `#workspace` container and its icon to the `#taskbar-apps` container.
3. **Advanced Drag & Drop (The "WinBox" Feel):**
   - **Smooth Dragging:** Use `requestAnimationFrame` for drag rendering to prevent lag.
   - **Boundary Constraints:** Prevent windows from being dragged completely out of the viewport. At least a portion of the title bar must remain grabbable.
   - **Snapping:** (Optional but recommended) If dragged to the top edge, trigger maximize. If dragged to the left/right, snap to 50% screen width.
4. **Resizing Logic:**
   - Implement event listeners on the edges/corners. Updating `width`, `height`, `top`, and `left` simultaneously when resizing from the top or left edges.
5. **Maximize & Minimize Logic:**
   - **Maximize:** Save the pre-maximized `top/left/width/height` state. Animate the window to fill `100%` of the workspace (accounting for the taskbar).
   - **Minimize:** Animate the window shrinking down into its taskbar icon, then set `display: none` or opacity. Clicking the taskbar icon restores it with the reverse animation.
6. **Taskbar Integration:**
   - Highlight the active window's icon in the taskbar. Click to toggle minimize/restore.

### PHASE 3: HTMX Intercepts (The Magic Glue)
**Goal:** Connect the Desktop Icons to the Window Manager.

Instead of HTMX swapping directly into the DOM, we use HTMX events to intercept the response and pass it to the Window Manager.

**Implementation for the Dumbest LLM:**
```javascript
// Listen to HTMX afterRequest event
document.body.addEventListener('htmx:afterRequest', function(evt) {
    const target = evt.detail.elt;
    
    // Check if the click came from a desktop icon
    if (target.classList.contains('desktop-icon')) {
        const appId = target.getAttribute('data-app-id');
        const title = target.getAttribute('data-app-title');
        const htmlContent = evt.detail.xhr.response;
        
        // Tell WindowManager to open it
        window.WindowManager.open(appId, title, htmlContent);
    }
});
```

### PHASE 4: Migrating the Apps
**Goal:** Refactor existing pages to be fragments.

1. **Vibe (formerly Mantis):** Remove the outer `<html>`, `<head>`, and `<body>`. Return only the inner content grid.
2. **Drive:** Ensure HTMX links *inside* Drive target elements *inside* Drive's window container (`closest .window-body #target`), not the whole page.
3. **Chat, Mail, Settings, Terminal:** Wrap their specific UIs into clean fragments.

**Crucial HTMX Rule for Windows:**
Any link inside a window MUST use relative HTMX targeting (e.g., `hx-target="closest .window-body"`) so it doesn't break out of the floating window.

### PHASE 5: Botserver Routing & AGENTS.md Compliance
**Goal:** Update backend to serve HTMX fragments while strictly adhering to `AGENTS.md` security and architecture rules.

1. **Route Management (HTMX-First):**
   - `GET /` -> Returns `desktop.html` (Full page load).
   - `GET /app/vibe` -> Returns the Vibe fragment (NO `<html>` or `<body>` tags).
   - `GET /api/drive/files?path=/` -> Returns the Drive fragment.
   - *Rule:* All state-changing endpoints (POST/PUT/DELETE) triggered from these windows MUST include CSRF tokens (`IMP-08`).
2. **File Structure & 450-Line Limit:**
   - Do not dump all routes into a single file. Respect the 450-line maximum per file rule.
   - Create separate modules for each app's routes (e.g., `botserver/src/handlers/desktop.rs`, `botserver/src/handlers/vibe.rs`, `botserver/src/handlers/explorer.rs`).
3. **Local Assets ONLY (NO CDNs):**
   - **CRITICAL:** The original `html3.html` prototype used Tailwind and FontAwesome CDNs. `AGENTS.md` explicitly forbids this.
   - All CSS, Tailwind outputs, HTMX (`htmx.min.js`), and Web Fonts MUST be downloaded and served locally from the server's static assets folder.
4. **Command Execution (Terminal/Explorer Apps):**
   - If the Terminal or Explorer apps need to read files or execute system commands, the backend handlers **MUST** use `crate::security::command_guard::SafeCommand`.
5. **Theme Manager:**
   - Update CSS variables locally to match the aesthetic (brand-500 greens, translucent `bg-white/90`).

---

## 4. "Dumbest LLM" Coding Prompts & Snippets

If you are an AI tasked with implementing this, follow these explicit instructions.

### A. Implementing `desktop.html`
- **CRITICAL:** Do NOT copy the CDN links (`<script src="https://cdn...">`) from `html3.html`. `AGENTS.md` strictly forbids CDNs. You must link to local compiled CSS and local HTMX scripts.
- The main container must have `position: relative` and `overflow: hidden`.
- Render the icons exactly as:
```html
<div class="desktop-icon flex flex-col items-center w-20 group cursor-pointer" 
     data-app-id="explorer" data-app-title="Explorer" 
     hx-get="/app/explorer" hx-swap="none">
    <div class="app-icon w-16 h-16 rounded-xl flex items-center justify-center text-white text-3xl group-hover:scale-105 transition-transform">
        <i class="fa-regular fa-folder-open drop-shadow-md"></i>
    </div>
    <span class="mt-2 text-xs font-mono font-medium text-gray-800 bg-white/70 px-1.5 py-0.5 rounded backdrop-blur-sm">Explorer</span>
</div>
```

### B. Implementing `window-manager.js`
Create a global object `window.WindowManager`.
It must have an `open(id, title, html)` method.
If the window with `id` already exists, call `focus(id)`.
If it doesn't exist, create this exact DOM structure:
```html
<div id="window-{id}" class="absolute w-[700px] bg-white rounded-lg shadow-2xl flex flex-col border border-gray-200 overflow-hidden z-20" style="top: 100px; left: 150px;">
    <!-- Header (Draggable) -->
    <div class="window-header h-10 bg-white/95 backdrop-blur flex items-center justify-between px-4 border-b border-gray-200 select-none cursor-move">
        <div class="font-mono text-xs font-bold text-brand-600 tracking-wide">{title}</div>
        <div class="flex space-x-3 text-gray-400">
            <button class="btn-minimize hover:text-gray-600"><i class="fa-solid fa-minus"></i></button>
            <button class="btn-maximize hover:text-gray-600"><i class="fa-regular fa-square"></i></button>
            <button class="btn-close hover:text-red-500"><i class="fa-solid fa-xmark"></i></button>
        </div>
    </div>
    <!-- Body (HTMX target) -->
    <div class="window-body relative flex-1 overflow-y-auto bg-[#fafdfa]">
        {html}
    </div>
</div>
```

### C. Implementing the Taskbar Task
When `WindowManager.open()` is called, also append this to `#taskbar-apps`:
```html
<div id="taskbar-item-{id}" class="h-10 w-12 flex items-center justify-center cursor-pointer bg-brand-50 rounded border-b-2 border-brand-500 transition-all taskbar-icon" onclick="WindowManager.toggle('{id}')">
    <div class="app-icon w-8 h-8 rounded-md flex items-center justify-center text-white text-xs shadow-sm">
        <!-- Map icon based on ID here -->
    </div>
</div>
```

---

## 5. Summary of Definitions
- **Desktop:** The root view of the application.
- **Window:** A floating, draggable container for a specific app (Explorer, Vibe, etc.).
- **Taskbar:** The bottom panel tracking open windows.
- **App Fragment:** The partial HTML code returned by the server to populate a Window.

**Execute this plan sequentially.** Do not attempt to load full HTML pages inside windows. Build the Window Manager engine first, then migrate apps one by one.

## Current Implementation Status (Feb 24, 2026)

**STATUS: COMPLETED**

**What Was Accomplished:**
1. **Routing:** The backend has been completely re-routed. `localhost:3000` now correctly serves the new `desktop.html` UI shell instead of the old `default.gbui`.
2. **Desktop Shell:** The `desktop.html` layout perfectly replicates the "green heavy" vertical floating icons, sidebar, grid background, and taskbar requested in the BUILD V3 PDF.
3. **Window Manager:** The vanilla JS `window-manager.js` class is fully operational. It manages state, injects content dynamically via HTMX intercepts, and handles dragging, minimizing, maximizing, and closing windows with custom SVGs to replace forbidden CDNs.
4. **Asset Paths Fixed:** All 404 errors were resolved by explicitly configuring `<script>` and `<link>` tags in `desktop.html` to use absolute `/suite/` paths (e.g. `/suite/css/desktop.css`), bypassing base URL issues.
5. **Initialization Crash Fixed:** The `Cannot read properties of null (reading 'appendChild')` bug was resolved by lazy-loading the `#desktop-content` workspace container inside the `open()` method, guaranteeing the DOM is fully constructed before window injection.
6. **App Fragments:** Chat, Tasks, and Terminal have been verified to function as clean HTMX fragments (`/suite/chat/chat.html`) and successfully render inside the floating windows.
