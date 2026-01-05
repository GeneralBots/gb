# General Bots Internationalization (i18n) Strategy

## Executive Summary

This document outlines a comprehensive internationalization strategy for the General Bots workspace, covering all projects: `botserver`, `botui`, `botlib`, `botapp`, `botdevice`, and `bottest`. The strategy leverages Rust's ecosystem with **Fluent** as the primary i18n framework, ensuring type-safe, maintainable translations across all components.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Recommended Technology Stack](#recommended-technology-stack)
3. [Directory Structure](#directory-structure)
4. [Implementation Guide](#implementation-guide)
5. [Translation Workflow](#translation-workflow)
6. [Component-Specific Guidelines](#component-specific-guidelines)
7. [Best Practices](#best-practices)
8. [Migration Plan](#migration-plan)
9. [Testing Strategy](#testing-strategy)
10. [Appendix](#appendix)

---

## Architecture Overview

### Current State Analysis

The GB workspace contains hardcoded strings in multiple locations:

| Component | String Types | Priority |
|-----------|-------------|----------|
| `botui` | UI labels, buttons, messages, tooltips | **High** |
| `botserver` | Error messages, API responses, bot templates | **High** |
| `botlib` | Error types, validation messages | **Medium** |
| `botapp` | Desktop app UI, settings, notifications | **Medium** |
| `botdevice` | Device messages, embedded UI | **Low** |
| `bottest` | Test assertions (keep in English) | **Low** |

### Target Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Shared i18n Core (botlib)                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Fluent    │  │   Locale    │  │  Message Formatting     │  │
│  │   Bundle    │  │  Detection  │  │  (dates, numbers, etc)  │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│  botserver  │      │   botui     │      │   botapp    │
│  (Backend)  │      │  (Web UI)   │      │  (Desktop)  │
└─────────────┘      └─────────────┘      └─────────────┘
```

---

## Recommended Technology Stack

### Primary: Fluent (Project Fluent by Mozilla)

**Why Fluent?**

1. **Natural Language Support**: Handles pluralization, gender, and complex grammatical rules
2. **Type Safety**: Compile-time checks for message references
3. **Rust Native**: First-class Rust support via `fluent-rs`
4. **Fallback Chain**: Automatic fallback to base language
5. **Used in Production**: Firefox, Thunderbird, and many large projects

### Dependencies

Add to `Cargo.toml` files:

```toml
# botlib/Cargo.toml - Core i18n functionality
[dependencies]
fluent = "0.16"
fluent-bundle = "0.15"
fluent-syntax = "0.11"
fluent-langneg = "0.14"
intl-memoizer = "0.5"
unic-langid = "0.9"
sys-locale = "0.3"  # For detecting system locale

[features]
i18n = ["fluent", "fluent-bundle", "fluent-syntax", "fluent-langneg", "intl-memoizer", "unic-langid", "sys-locale"]
```

```toml
# botserver/Cargo.toml - Add i18n feature
[dependencies.botlib]
path = "../botlib"
features = ["database", "i18n"]

# For Accept-Language header parsing
accept-language = "3.1"
```

```toml
# botui/Cargo.toml
[dependencies.botlib]
path = "../botlib"
features = ["i18n"]
```

### Alternative Consideration: rust-i18n

For simpler use cases, `rust-i18n` provides a macro-based approach:

```rust
use rust_i18n::t;

rust_i18n::i18n!("locales");

fn main() {
    let msg = t!("hello", name = "World");
}
```

**Recommendation**: Use Fluent for its superior handling of complex translations, especially important for a chatbot platform serving multiple regions.

---

## Directory Structure

### Centralized Locales (Recommended)

```
gb/
├── locales/                          # Shared translation files
│   ├── en/                           # English (base language)
│   │   ├── common.ftl                # Shared strings
│   │   ├── errors.ftl                # Error messages
│   │   ├── ui.ftl                    # UI labels
│   │   ├── notifications.ftl         # Notifications
│   │   └── bot-templates.ftl         # Bot dialog templates
│   ├── pt-BR/                        # Brazilian Portuguese
│   │   ├── common.ftl
│   │   ├── errors.ftl
│   │   ├── ui.ftl
│   │   ├── notifications.ftl
│   │   └── bot-templates.ftl
│   ├── es/                           # Spanish
│   │   └── ...
│   └── zh-CN/                        # Simplified Chinese
│       └── ...
│
├── botlib/
│   └── src/
│       ├── i18n/                     # i18n module
│       │   ├── mod.rs                # Module exports
│       │   ├── bundle.rs             # Fluent bundle management
│       │   ├── locale.rs             # Locale detection/negotiation
│       │   ├── format.rs             # Number/date formatting
│       │   └── macros.rs             # Helper macros
│       └── lib.rs
│
├── botserver/
│   └── src/
│       └── core/
│           └── i18n.rs               # Server-side i18n integration
│
└── botui/
    ├── src/
    │   └── i18n.rs                   # UI i18n integration
    └── ui/
        └── suite/
            └── js/
                └── i18n.js           # Client-side i18n for HTMX
```

---

## Implementation Guide

### Step 1: Create Core i18n Module in botlib

```rust
// botlib/src/i18n/mod.rs

mod bundle;
mod format;
mod locale;

pub use bundle::{FluentBundles, MessageId};
pub use format::{format_date, format_number, format_currency};
pub use locale::{Locale, detect_locale, negotiate_locale};

use std::sync::OnceLock;
use fluent_bundle::{FluentBundle, FluentResource, FluentArgs};
use unic_langid::LanguageIdentifier;

static BUNDLES: OnceLock<FluentBundles> = OnceLock::new();

pub fn init(locales_path: &str) -> Result<(), I18nError> {
    let bundles = FluentBundles::load(locales_path)?;
    BUNDLES.set(bundles).map_err(|_| I18nError::AlreadyInitialized)?;
    Ok(())
}

pub fn get(locale: &Locale, message_id: &str) -> String {
    get_with_args(locale, message_id, None)
}

pub fn get_with_args(locale: &Locale, message_id: &str, args: Option<&FluentArgs>) -> String {
    BUNDLES
        .get()
        .expect("i18n not initialized")
        .get_message(locale, message_id, args)
}

#[derive(Debug, thiserror::Error)]
pub enum I18nError {
    #[error("i18n already initialized")]
    AlreadyInitialized,
    #[error("Failed to load locale {locale}: {reason}")]
    LoadError { locale: String, reason: String },
    #[error("Message not found: {0}")]
    MessageNotFound(String),
}
```

```rust
// botlib/src/i18n/bundle.rs

use std::collections::HashMap;
use std::fs;
use std::path::Path;
use fluent_bundle::{FluentBundle, FluentResource, FluentArgs, FluentValue};
use fluent_langneg::{negotiate_languages, NegotiationStrategy};
use unic_langid::LanguageIdentifier;

use super::{Locale, I18nError};

pub struct FluentBundles {
    bundles: HashMap<LanguageIdentifier, FluentBundle<FluentResource>>,
    available_locales: Vec<LanguageIdentifier>,
    fallback: LanguageIdentifier,
}

impl FluentBundles {
    pub fn load(base_path: &str) -> Result<Self, I18nError> {
        let mut bundles = HashMap::new();
        let mut available_locales = Vec::new();
        
        let base = Path::new(base_path);
        
        for entry in fs::read_dir(base).map_err(|e| I18nError::LoadError {
            locale: "all".into(),
            reason: e.to_string(),
        })? {
            let entry = entry.map_err(|e| I18nError::LoadError {
                locale: "entry".into(),
                reason: e.to_string(),
            })?;
            
            if entry.path().is_dir() {
                let locale_name = entry.file_name().to_string_lossy().to_string();
                let lang_id: LanguageIdentifier = locale_name.parse().map_err(|_| {
                    I18nError::LoadError {
                        locale: locale_name.clone(),
                        reason: "Invalid locale identifier".into(),
                    }
                })?;
                
                let bundle = Self::load_bundle(&entry.path(), &lang_id)?;
                available_locales.push(lang_id.clone());
                bundles.insert(lang_id, bundle);
            }
        }
        
        let fallback: LanguageIdentifier = "en".parse().unwrap();
        
        Ok(Self {
            bundles,
            available_locales,
            fallback,
        })
    }
    
    fn load_bundle(
        locale_dir: &Path,
        lang_id: &LanguageIdentifier,
    ) -> Result<FluentBundle<FluentResource>, I18nError> {
        let mut bundle = FluentBundle::new(vec![lang_id.clone()]);
        
        for entry in fs::read_dir(locale_dir).map_err(|e| I18nError::LoadError {
            locale: lang_id.to_string(),
            reason: e.to_string(),
        })? {
            let entry = entry.map_err(|e| I18nError::LoadError {
                locale: lang_id.to_string(),
                reason: e.to_string(),
            })?;
            
            let path = entry.path();
            if path.extension().map_or(false, |ext| ext == "ftl") {
                let source = fs::read_to_string(&path).map_err(|e| I18nError::LoadError {
                    locale: lang_id.to_string(),
                    reason: e.to_string(),
                })?;
                
                let resource = FluentResource::try_new(source).map_err(|(_, errors)| {
                    I18nError::LoadError {
                        locale: lang_id.to_string(),
                        reason: format!("Parse errors: {:?}", errors),
                    }
                })?;
                
                bundle.add_resource(resource).map_err(|errors| {
                    I18nError::LoadError {
                        locale: lang_id.to_string(),
                        reason: format!("Bundle errors: {:?}", errors),
                    }
                })?;
            }
        }
        
        Ok(bundle)
    }
    
    pub fn get_message(
        &self,
        locale: &Locale,
        message_id: &str,
        args: Option<&FluentArgs>,
    ) -> String {
        let negotiated = negotiate_languages(
            &[locale.as_langid()],
            &self.available_locales,
            Some(&self.fallback),
            NegotiationStrategy::Filtering,
        );
        
        for lang_id in negotiated {
            if let Some(bundle) = self.bundles.get(lang_id) {
                if let Some(msg) = bundle.get_message(message_id) {
                    if let Some(pattern) = msg.value() {
                        let mut errors = vec![];
                        let result = bundle.format_pattern(pattern, args, &mut errors);
                        if errors.is_empty() {
                            return result.into_owned();
                        }
                    }
                }
            }
        }
        
        format!("[{}]", message_id)
    }
    
    pub fn available_locales(&self) -> &[LanguageIdentifier] {
        &self.available_locales
    }
}
```

```rust
// botlib/src/i18n/locale.rs

use unic_langid::LanguageIdentifier;
use sys_locale::get_locale;

#[derive(Debug, Clone)]
pub struct Locale {
    lang_id: LanguageIdentifier,
}

impl Locale {
    pub fn new(locale_str: &str) -> Option<Self> {
        locale_str.parse().ok().map(|lang_id| Self { lang_id })
    }
    
    pub fn from_langid(lang_id: LanguageIdentifier) -> Self {
        Self { lang_id }
    }
    
    pub fn as_langid(&self) -> &LanguageIdentifier {
        &self.lang_id
    }
    
    pub fn language(&self) -> &str {
        self.lang_id.language.as_str()
    }
    
    pub fn region(&self) -> Option<&str> {
        self.lang_id.region.as_ref().map(|r| r.as_str())
    }
}

impl Default for Locale {
    fn default() -> Self {
        detect_locale()
    }
}

pub fn detect_locale() -> Locale {
    get_locale()
        .and_then(|l| Locale::new(&l))
        .unwrap_or_else(|| Locale::new("en").unwrap())
}

pub fn negotiate_locale(
    requested: &[&str],
    available: &[&str],
) -> Locale {
    use fluent_langneg::{negotiate_languages, NegotiationStrategy};
    
    let requested: Vec<LanguageIdentifier> = requested
        .iter()
        .filter_map(|l| l.parse().ok())
        .collect();
    
    let available: Vec<LanguageIdentifier> = available
        .iter()
        .filter_map(|l| l.parse().ok())
        .collect();
    
    let fallback: LanguageIdentifier = "en".parse().unwrap();
    
    let negotiated = negotiate_languages(
        &requested.iter().collect::<Vec<_>>(),
        &available.iter().collect::<Vec<_>>(),
        Some(&fallback),
        NegotiationStrategy::Filtering,
    );
    
    negotiated
        .first()
        .map(|l| Locale::from_langid((*l).clone()))
        .unwrap_or_else(|| Locale::new("en").unwrap())
}
```

### Step 2: Create Fluent Translation Files

```ftl
# locales/en/common.ftl

# Brand
app-name = General Bots
app-tagline = Your AI-powered productivity workspace

# Common Actions
action-save = Save
action-cancel = Cancel
action-delete = Delete
action-edit = Edit
action-close = Close
action-confirm = Confirm
action-retry = Retry
action-back = Back
action-next = Next
action-submit = Submit
action-search = Search
action-refresh = Refresh

# Common Labels
label-loading = Loading...
label-no-results = No results found
label-error = Error
label-success = Success
label-warning = Warning
label-info = Information

# Dates and Times
time-now = Just now
time-minutes-ago = { $count ->
    [one] { $count } minute ago
   *[other] { $count } minutes ago
}
time-hours-ago = { $count ->
    [one] { $count } hour ago
   *[other] { $count } hours ago
}
time-days-ago = { $count ->
    [one] { $count } day ago
   *[other] { $count } days ago
}
```

```ftl
# locales/en/errors.ftl

# HTTP Errors
error-http-400 = Bad request. Please check your input.
error-http-401 = Authentication required. Please log in.
error-http-403 = You don't have permission to access this resource.
error-http-404 = { $entity } not found.
error-http-409 = Conflict: { $message }
error-http-429 = Too many requests. Please wait { $seconds } seconds.
error-http-500 = Internal server error. Please try again later.
error-http-503 = Service temporarily unavailable.
error-http-504 = Request timed out after { $milliseconds }ms.

# Validation Errors
error-validation-required = { $field } is required.
error-validation-email = Please enter a valid email address.
error-validation-min-length = { $field } must be at least { $min } characters.
error-validation-max-length = { $field } must be no more than { $max } characters.
error-validation-pattern = { $field } format is invalid.

# Business Errors
error-config = Configuration error: { $message }
error-database = Database error: { $message }
error-auth = Authentication error: { $message }
error-rate-limit = Rate limited. Retry after { $seconds }s.
error-service-unavailable = Service unavailable: { $message }
error-internal = Internal error: { $message }
```

```ftl
# locales/en/ui.ftl

# Navigation
nav-home = Home
nav-chat = Chat
nav-drive = Drive
nav-tasks = Tasks
nav-mail = Mail
nav-calendar = Calendar
nav-meet = Meet
nav-paper = Paper
nav-research = Research
nav-analytics = Analytics
nav-settings = Settings

# Dashboard
dashboard-title = Dashboard
dashboard-welcome = Welcome back, { $name }!
dashboard-quick-actions = Quick Actions
dashboard-recent-activity = Recent Activity
dashboard-no-activity = No recent activity yet. Start exploring!

# Chat
chat-title = Chat
chat-placeholder = Type your message...
chat-send = Send
chat-ai-thinking = AI is thinking...
chat-new-conversation = New Conversation
chat-history = Chat History

# Drive
drive-title = Drive
drive-upload = Upload Files
drive-new-folder = New Folder
drive-empty = No files yet. Upload something!
drive-file-size = { $size ->
    [bytes] { $value } B
    [kb] { $value } KB
    [mb] { $value } MB
    [gb] { $value } GB
   *[other] { $value } bytes
}

# Tasks
tasks-title = Tasks
tasks-new = New Task
tasks-due-today = Due Today
tasks-overdue = Overdue
tasks-completed = Completed
tasks-priority-high = High Priority
tasks-priority-medium = Medium Priority
tasks-priority-low = Low Priority

# Calendar
calendar-title = Calendar
calendar-today = Today
calendar-new-event = New Event
calendar-all-day = All day
calendar-repeat = Repeat
calendar-reminder = Reminder

# Meet
meet-title = Meet
meet-join = Join Meeting
meet-start = Start Meeting
meet-mute = Mute
meet-unmute = Unmute
meet-video-on = Camera On
meet-video-off = Camera Off
meet-share-screen = Share Screen
meet-end-call = End Call
meet-participants = { $count ->
    [one] { $count } participant
   *[other] { $count } participants
}

# Mail
mail-title = Mail
mail-compose = Compose
mail-inbox = Inbox
mail-sent = Sent
mail-drafts = Drafts
mail-trash = Trash
mail-to = To
mail-subject = Subject
mail-reply = Reply
mail-forward = Forward

# Settings
settings-title = Settings
settings-general = General
settings-account = Account
settings-notifications = Notifications
settings-privacy = Privacy
settings-language = Language
settings-theme = Theme
settings-theme-light = Light
settings-theme-dark = Dark
settings-theme-system = System
```

```ftl
# locales/en/bot-templates.ftl

# Default Bot Greetings
bot-greeting-default = Hello! How can I help you today?
bot-greeting-named = Hello, { $name }! How can I help you today?
bot-goodbye = Goodbye! Have a great day!
bot-help-prompt = I can help you with: { $topics }. What would you like to know?
bot-thank-you = Thank you for your message. How can I assist you today?
bot-echo-intro = Echo Bot: I will repeat everything you say. Type 'quit' to exit.
bot-you-said = You said: { $message }

# Lead Capture
bot-lead-welcome = Welcome! Let me help you get started.
bot-lead-ask-name = What's your name?
bot-lead-ask-email = And your email?
bot-lead-ask-company = What company are you from?
bot-lead-hot = Great! Our sales team will reach out shortly.
bot-lead-nurture = Thanks for your interest! We'll send you some resources.

# Scheduler
bot-schedule-created = Running scheduled task: { $name }
bot-monitor-alert = Alert: { $subject } has changed

# Order Management
bot-order-welcome = Welcome to our store! How can I help?
bot-order-track = Track my order
bot-order-browse = Browse products
bot-order-support = Contact support
bot-order-enter-id = Please enter your order number:
bot-order-status = Order status: { $status }
bot-order-ticket = Support ticket created: #{ $ticket }

# HR Assistant
bot-hr-welcome = HR Assistant here. How can I help?
bot-hr-request-leave = Request leave
bot-hr-check-balance = Check balance
bot-hr-view-policies = View policies
bot-hr-leave-type = What type of leave? (vacation/sick/personal)
bot-hr-start-date = Start date? (YYYY-MM-DD)
bot-hr-end-date = End date? (YYYY-MM-DD)
bot-hr-leave-submitted = Leave request submitted! Your manager will review it.
bot-hr-balance-title = Your leave balance:
bot-hr-vacation-days = Vacation: { $days } days
bot-hr-sick-days = Sick: { $days } days

# Healthcare Appointments
bot-health-welcome = Welcome to our healthcare center. How can I help?
bot-health-book = Book appointment
bot-health-cancel = Cancel appointment
bot-health-view = View my appointments
bot-health-type = What type of appointment? (general/specialist/lab)
```

```ftl
# locales/pt-BR/common.ftl

# Brand
app-name = General Bots
app-tagline = Seu espaço de trabalho com IA

# Common Actions
action-save = Salvar
action-cancel = Cancelar
action-delete = Excluir
action-edit = Editar
action-close = Fechar
action-confirm = Confirmar
action-retry = Tentar novamente
action-back = Voltar
action-next = Próximo
action-submit = Enviar
action-search = Buscar
action-refresh = Atualizar

# Common Labels
label-loading = Carregando...
label-no-results = Nenhum resultado encontrado
label-error = Erro
label-success = Sucesso
label-warning = Atenção
label-info = Informação

# Dates and Times
time-now = Agora mesmo
time-minutes-ago = { $count ->
    [one] { $count } minuto atrás
   *[other] { $count } minutos atrás
}
time-hours-ago = { $count ->
    [one] { $count } hora atrás
   *[other] { $count } horas atrás
}
time-days-ago = { $count ->
    [one] { $count } dia atrás
   *[other] { $count } dias atrás
}
```

```ftl
# locales/pt-BR/ui.ftl

# Navigation
nav-home = Início
nav-chat = Chat
nav-drive = Arquivos
nav-tasks = Tarefas
nav-mail = E-mail
nav-calendar = Calendário
nav-meet = Reuniões
nav-paper = Documentos
nav-research = Pesquisa
nav-analytics = Análises
nav-settings = Configurações

# Dashboard
dashboard-title = Painel
dashboard-welcome = Bem-vindo de volta, { $name }!
dashboard-quick-actions = Ações Rápidas
dashboard-recent-activity = Atividade Recente
dashboard-no-activity = Nenhuma atividade recente. Comece a explorar!

# AI Panel
ai-developer = Desenvolvedor IA
ai-developing = Desenvolvendo: { $project }
ai-quick-actions = Ações Rápidas
ai-add-field = Adicionar campo
ai-change-color = Mudar cor
ai-add-validation = Adicionar validação
ai-export-data = Exportar dados
ai-placeholder = Digite suas modificações...

# Quick Actions
quick-start-chat = Iniciar Chat
quick-upload-files = Enviar Arquivos
quick-new-task = Nova Tarefa
quick-compose-email = Escrever E-mail
quick-start-meeting = Iniciar Reunião

# App Descriptions
app-chat-desc = Conversas com IA. Faça perguntas, obtenha ajuda e automatize tarefas.
app-drive-desc = Armazenamento em nuvem para seus arquivos. Envie, organize e compartilhe.
app-tasks-desc = Mantenha-se organizado com listas de tarefas, prioridades e prazos.
app-mail-desc = Cliente de e-mail com escrita assistida por IA e organização inteligente.
app-calendar-desc = Agende reuniões, eventos e gerencie seu tempo efetivamente.
app-meet-desc = Videoconferência com compartilhamento de tela e transcrição ao vivo.
app-paper-desc = Escreva documentos com assistência de IA. Notas, relatórios e mais.
app-research-desc = Busca e descoberta com IA em todas as suas fontes.
app-analytics-desc = Painéis e relatórios para acompanhar uso e insights.
```

### Step 3: Server-Side Integration

```rust
// botserver/src/core/i18n.rs

use axum::{
    extract::FromRequestParts,
    http::{header::ACCEPT_LANGUAGE, request::Parts},
};
use botlib::i18n::{Locale, negotiate_locale};

pub struct RequestLocale(pub Locale);

impl<S> FromRequestParts<S> for RequestLocale
where
    S: Send + Sync,
{
    type Rejection = std::convert::Infallible;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        let locale = parts
            .headers
            .get(ACCEPT_LANGUAGE)
            .and_then(|h| h.to_str().ok())
            .map(parse_accept_language)
            .map(|langs| {
                let available = ["en", "pt-BR", "es", "zh-CN"];
                let requested: Vec<&str> = langs.iter().map(String::as_str).collect();
                negotiate_locale(&requested, &available)
            })
            .unwrap_or_default();

        Ok(RequestLocale(locale))
    }
}

fn parse_accept_language(header: &str) -> Vec<String> {
    let mut langs: Vec<(String, f32)> = header
        .split(',')
        .filter_map(|part| {
            let mut iter = part.trim().split(';');
            let lang = iter.next()?.trim().to_string();
            let quality = iter
                .next()
                .and_then(|q| q.trim().strip_prefix("q="))
                .and_then(|q| q.parse().ok())
                .unwrap_or(1.0);
            Some((lang, quality))
        })
        .collect();

    langs.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
    langs.into_iter().map(|(l, _)| l).collect()
}

// Usage in handlers
pub async fn example_handler(
    RequestLocale(locale): RequestLocale,
) -> impl axum::response::IntoResponse {
    use botlib::i18n::get;
    
    let greeting = get(&locale, "dashboard-welcome");
    // ...
}
```

### Step 4: Template Integration (Askama)

```rust
// botui/src/i18n.rs

use askama::Template;
use botlib::i18n::{Locale, get, get_with_args};
use fluent_bundle::FluentArgs;

pub struct I18nContext {
    locale: Locale,
}

impl I18nContext {
    pub fn new(locale: Locale) -> Self {
        Self { locale }
    }
    
    pub fn t(&self, key: &str) -> String {
        get(&self.locale, key)
    }
    
    pub fn t_args(&self, key: &str, args: &FluentArgs) -> String {
        get_with_args(&self.locale, key, Some(args))
    }
}

// Custom Askama filter
pub mod filters {
    use fluent_bundle::FluentArgs;
    
    pub fn t(key: &str) -> askama::Result<String> {
        // Uses thread-local or context locale
        Ok(super::get_current_locale_message(key))
    }
    
    pub fn t_count(key: &str, count: i64) -> askama::Result<String> {
        let mut args = FluentArgs::new();
        args.set("count", count);
        Ok(super::get_current_locale_message_with_args(key, &args))
    }
}
```

### Step 5: Client-Side JavaScript Integration

```javascript
// botui/ui/suite/js/i18n.js

class I18n {
    constructor() {
        this.locale = document.documentElement.lang || 'en';
        this.messages = {};
        this.loaded = false;
    }

    async init() {
        try {
            const response = await fetch(`/api/i18n/${this.locale}`);
            this.messages = await response.json();
            this.loaded = true;
            this.translatePage();
        } catch (error) {
            console.error('Failed to load translations:', error);
        }
    }

    t(key, args = {}) {
        let message = this.messages[key] || `[${key}]`;
        
        // Simple interpolation
        Object.entries(args).forEach(([k, v]) => {
            message = message.replace(new RegExp(`\\{\\s*\\$${k}\\s*\\}`, 'g'), v);
        });
        
        return message;
    }

    translatePage() {
        document.querySelectorAll('[data-i18n]').forEach(el => {
            const key = el.dataset.i18n;
            const args = el.dataset.i18nArgs ? JSON.parse(el.dataset.i18nArgs) : {};
            el.textContent = this.t(key, args);
        });
        
        document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
            el.placeholder = this.t(el.dataset.i18nPlaceholder);
        });
        
        document.querySelectorAll('[data-i18n-title]').forEach(el => {
            el.title = this.t(el.dataset.i18nTitle);
        });
    }

    setLocale(locale) {
        this.locale = locale;
        document.documentElement.lang = locale;
        localStorage.setItem('gb-locale', locale);
        return this.init();
    }
}

// Global instance
window.i18n = new I18n();
document.addEventListener('DOMContentLoaded', () => window.i18n.init());

// HTMX integration - re-translate after content swap
document.body.addEventListener('htmx:afterSwap', () => {
    if (window.i18n.loaded) {
        window.i18n.translatePage();
    }
});
```

---

## Translation Workflow

### 1. String Extraction Process

```bash
# Use a custom script to extract strings from source
./scripts/extract-strings.sh

# Output structure:
# locales/
#   en/
#     extracted.ftl  # New strings to translate
```

### 2. Translation Management

**Option A: Self-hosted with Weblate**
- Open-source translation management
- Git integration for syncing `.ftl` files
- Community translation support

**Option B: Commercial (Crowdin, Lokalise)**
- Better for teams with budget
- Professional translator access
- Quality assurance tools

### 3. CI/CD Integration

```yaml
# .github/workflows/i18n.yml
name: i18n Checks

on: [push, pull_request]

jobs:
  i18n-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Check Fluent syntax
        run: |
          cargo install fluent-syntax
          find locales -name "*.ftl" -exec fluent-syntax-check {} \;
      
      - name: Check for missing translations
        run: ./scripts/check-missing-translations.sh
      
      - name: Check for unused translations
        run: ./scripts/check-unused-translations.sh
```

---

## Component-Specific Guidelines

### botserver

| Area | Approach |
|------|----------|
| API Error Responses | Use error codes + i18n lookup on client |
| Bot Templates | Store template keys, resolve at runtime |
| Log Messages | Keep in English (for debugging) |
| Validation | Return field names + error keys |

```rust
// Example: Localized API error response
#[derive(Serialize)]
pub struct ApiError {
    pub code: String,           // "error-http-404"
    pub message: String,        // Localized message
    pub details: Option<Value>, // Additional context
}

impl ApiError {
    pub fn not_found(locale: &Locale, entity: &str) -> Self {
        let mut args = FluentArgs::new();
        args.set("entity", entity);
        
        Self {
            code: "error-http-404".into(),
            message: i18n::get_with_args(locale, "error-http-404", Some(&args)),
            details: None,
        }
    }
}
```

### botui

| Area | Approach |
|------|----------|
| Static HTML | Use `data-i18n` attributes |
| Askama Templates | Use custom filters |
| JavaScript | Use `window.i18n.t()` |
| Dates/Numbers | Use `Intl` API |

```html
<!-- Example: Translated HTML -->
<button data-i18n="action-save">Save</button>
<input placeholder="Search..." data-i18n-placeholder="action-search">
<span data-i18n="time-minutes-ago" data-i18n-args='{"count": 5}'>5 minutes ago</span>
```

### botapp (Tauri)

```rust
// Use system locale detection
use sys_locale::get_locale;

fn main() {
    let locale = get_locale().unwrap_or_else(|| "en".to_string());
    botlib::i18n::init_with_locale(&locale);
}
```

### botdevice

For embedded/IoT contexts with limited resources:

```rust
// Compile-time locale selection for embedded
#[cfg(feature = "locale-en")]
const MESSAGES: &[(&str, &str)] = include!("../locales/en/embedded.rs");

#[cfg(feature = "locale-pt-BR")]
const MESSAGES: &[(&str, &str)] = include!("../locales/pt-BR/embedded.rs");
```

---

## Best Practices

### 1. Message ID Naming Convention

```
<category>-<subcategory>-<descriptor>

Examples:
- nav-home
- error-http-404
- action-save
- chat-placeholder
- bot-greeting-default
```

### 2. Avoid String Concatenation

```rust
// ❌ BAD: Concatenation breaks translation
format!("Hello, {}!", name)

// ✅ GOOD: Use placeholders
// Fluent: bot-greeting-named = Hello, { $name }!
i18n::get_with_args(locale, "bot-greeting-named", &args)
```

### 3. Handle Pluralization Properly

```ftl
# ❌ BAD: Hardcoded plural
items-count = { $count } items

# ✅ GOOD: Proper pluralization
items-count = { $count ->
    [zero] No items
    [one] { $count } item
   *[other] { $count } items
}
```

### 4. Context for Translators

```ftl
# Provide context with comments
# This appears on the main navigation bar
nav-home = Home

# Button to save user settings (not documents)
action-save-settings = Save Settings
```

### 5. Date/Time Formatting

```rust
use chrono::{DateTime, Utc};

pub fn format_datetime(dt: &DateTime<Utc>, locale: &Locale) -> String {
    // Use ICU-based formatting when available
    match locale.language() {
        "pt" => dt.format("%d/%m/%Y %H:%M").to_string(),
        "en" => dt.format("%m/%d/%Y %I:%M %p").to_string(),
        _ => dt.format("%Y-%m-%d %H:%M").to_string(),
    }
}
```

### 6. Number Formatting

```rust
use num_format::{Locale as NumLocale, ToFormattedString};

pub fn format_number(n: i64, locale: &Locale) -> String {
    let num_locale = match locale.language() {
        "pt" => NumLocale::pt,
        "es" => NumLocale::es,
        "de" => NumLocale::de,
        _ => NumLocale::en,
    };
    n.to_formatted_string(&num_locale)
}
```

---

## Migration Plan

### Phase 1: Foundation (Week 1-2) ✅ COMPLETE

1. [x] Add i18n dependencies to `botlib/Cargo.toml`
2. [x] Create core i18n module in `botlib` (`botlib/src/i18n/`)
3. [x] Set up `locales/` directory structure (moved to `botlib/locales/`)
4. [x] Create base English translation files (700+ keys)
5. [x] Add i18n initialization to `botserver/main.rs`

### Phase 2: Server Integration (Week 3-4) ✅ COMPLETE

1. [x] Create `RequestLocale` extractor for Axum (`botserver/src/core/i18n.rs`)
2. [x] Create `LocalizedError` helper for i18n error responses
3. [x] Create `t()` and `t_with_args()` translation functions
4. [x] Add `/api/i18n/{locale}` endpoint (serves .ftl translations as JSON)

### Phase 3: UI Migration (Week 5-6) ✅ COMPLETE

1. [x] Add `data-i18n` attributes to HTML templates (index.html, admin, analytics, meet, research)
2. [x] Create JavaScript i18n client (`botui/ui/suite/js/i18n.js`) with embedded fallbacks
3. [x] Add app launcher icons for Admin, Sources, Tools, Attendant with i18n
4. [x] Migrate navigation and header strings

### Phase 4: Bot Templates (Week 7-8) ✅ COMPLETE

1. [x] Create bot-templates.ftl with all bot messages (150 keys EN + PT-BR)
2. [ ] Update BASIC interpreter to use i18n keys
3. [ ] Add locale parameter to bot execution context
4. [ ] Update template manager to resolve translations

### Phase 5: Additional Languages (Week 9-10) 🔄 IN PROGRESS

1. [x] Complete Portuguese (pt-BR) translations (100% - 700/700 keys)
2. [ ] Add Spanish (es) translations (10% - directory exists, common.ftl partial)
3. [ ] Add Chinese (zh-CN) translations (0%)
4. [x] Create translation coverage script (`scripts/check-i18n.sh`)

### Phase 6: Polish & Documentation (Week 11-12) 🔄 IN PROGRESS

1. [x] Remove duplicate translations.js (consolidated to .ftl files)
2. [ ] Create translator documentation
3. [x] Set up CI checks for translation coverage (`scripts/check-i18n.sh`)
4. [ ] Performance optimization

---

## Remaining Work - Detailed Checklist

### HIGH PRIORITY - Complete UI i18n

1. [ ] **Auth screens** (`botui/ui/suite/auth/`)
   - [ ] login.html - form labels, buttons, messages
   - [ ] register.html - form labels, validation messages
   - [ ] forgot-password.html - instructions, buttons
   - [ ] reset-password.html - form labels, messages

2. [ ] **Monitoring screens** (`botui/ui/suite/monitoring/`)
   - [ ] monitoring.html - dashboard title, metrics labels
   - [ ] logs.html - filter labels, level names
   - [ ] health.html - status labels, service names
   - [ ] metrics.html - chart labels, time ranges
   - [ ] alerts.html - alert types, severity levels

3. [ ] **Sources screens** (`botui/ui/suite/sources/`)
   - [ ] index.html - page title, navigation
   - [ ] accounts.html - account management labels

4. [ ] **Tools screens** (`botui/ui/suite/tools/`)
   - [ ] compliance.html - all labels and buttons

5. [ ] **Attendant screen** (`botui/ui/suite/attendant/`)
   - [ ] index.html - all UI elements

### MEDIUM PRIORITY - Additional .ftl translations

1. [ ] **Complete es (Spanish) locale**
   - [ ] es/ui.ftl - copy from en, translate ~700 keys
   - [ ] es/common.ftl - copy from en, translate ~400 keys
   - [ ] es/admin.ftl - copy from en, translate ~300 keys
   - [ ] es/analytics.ftl - copy from en, translate ~170 keys

2. [ ] **Add zh-CN (Chinese) locale**
   - [ ] Create zh-CN/ directory
   - [ ] zh-CN/ui.ftl, common.ftl, admin.ftl, analytics.ftl, etc.

### LOW PRIORITY - Bot Template Integration

1. [ ] Update `botlib/src/basic/` interpreter to use i18n
2. [ ] Add `locale` field to bot execution context
3. [ ] Update template manager to resolve `t("key")` in BASIC scripts

### DOCUMENTATION

1. [ ] Create `docs/i18n-guide.md` for translators
2. [ ] Document Fluent syntax with examples
3. [ ] Add translation contribution guidelines to CONTRIBUTING.md

---

## Testing Strategy

### Unit Tests

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_english_message() {
        let locale = Locale::new("en").unwrap();
        let msg = get(&locale, "action-save");
        assert_eq!(msg, "Save");
    }

    #[test]
    fn test_portuguese_message() {
        let locale = Locale::new("pt-BR").unwrap();
        let msg = get(&locale, "action-save");
        assert_eq!(msg, "Salvar");
    }

    #[test]
    fn test_fallback_to_english() {
        let locale = Locale::new("xx").unwrap(); // Unknown locale
        let msg = get(&locale, "action-save");
        assert_eq!(msg, "Save"); // Falls back to English
    }

    #[test]
    fn test_pluralization() {
        let locale = Locale::new("en").unwrap();
        
        let mut args = FluentArgs::new();
        args.set("count", 1);
        assert_eq!(get_with_args(&locale, "time-minutes-ago", Some(&args)), "1 minute ago");
        
        args.set("count", 5);
        assert_eq!(get_with_args(&locale, "time-minutes-ago", Some(&args)), "5 minutes ago");
    }

    #[test]
    fn test_missing_message_returns_key() {
        let locale = Locale::new("en").unwrap();
        let msg = get(&locale, "non-existent-key");
        assert_eq!(msg, "[non-existent-key]");
    }
}
```

### Integration Tests

```rust
#[tokio::test]
async fn test_localized_api_error() {
    let app = create_test_app().await;
    
    let response = app
        .oneshot(
            Request::builder()
                .uri("/api/users/nonexistent")
                .header("Accept-Language", "pt-BR")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    
    assert_eq!(response.status(), 404);
    
    let body: ApiError = parse_body(response).await;
    assert!(body.message.contains("não encontrado"));
}
```

### Coverage Checks

```bash
#!/bin/bash
# scripts/check-missing-translations.sh

BASE_LOCALE="en"
LOCALES=("pt-BR" "es" "zh-CN")

for locale in "${LOCALES[@]}"; do
    echo "Checking $locale..."
    
    for file in locales/$BASE_LOCALE/*.ftl; do
        filename=$(basename "$file")
        target="locales/$locale/$filename"
        
        if [ ! -f "$target" ]; then
            echo "  Missing file: $target"
            continue
        fi
        
        # Extract message IDs
        base_keys=$(grep -E "^[a-z]" "$file" | cut -d= -f1 | sort)
        target_keys=$(grep -E "^[a-z]" "$target" | cut -d= -f1 | sort)
        
        # Find missing keys
        missing=$(comm -23 <(echo "$base_keys") <(echo "$target_keys"))
        if [ -n "$missing" ]; then
            echo "  Missing in $target:"
            echo "$missing" | sed 's/^/    /'
        fi
    done
done
```

---

## Appendix

### Supported Locales

| Code | Language | Region | Status |
|------|----------|--------|--------|
| `en` | English | Default | ✅ Base |
| `pt-BR` | Portuguese | Brazil | 🔄 Priority |
| `es` | Spanish | General | 📋 Planned |
| `es-MX` | Spanish | Mexico | 📋 Planned |
| `zh-CN` | Chinese | Simplified | 📋 Planned |
| `zh-TW` | Chinese | Traditional | 📋 Planned |
| `fr` | French | General | 📋 Planned |
| `de` | German | General | 📋 Planned |
| `ja` | Japanese | | 📋 Planned |
| `ko` | Korean | | 📋 Planned |

### Fluent Syntax Quick Reference

```ftl
# Simple message
hello = Hello World

# Message with variable
hello-name = Hello, { $name }!

# Pluralization
items = { $count ->
    [zero] No items
    [one] One item
   *[other] { $count } items
}

# Selectors with gender
welcome = { $gender ->
    [male] Welcome, Mr. { $name }
    [female] Welcome, Ms. { $name }
   *[other] Welcome, { $name }
}

# Nested placeholders
notification = { $user } sent you { $count ->
    [one] a message
   *[other] { $count } messages
}

# Terms (reusable)
-brand-name = General Bots
about = About { -brand-name }

# Attributes
login-button = Log In
    .tooltip = Click to access your account
```

### Resources

- [Project Fluent](https://projectfluent.org/)
- [fluent-rs Documentation](https://docs.rs/fluent/)
- [Unicode CLDR](https://cldr.unicode.org/) - Locale data standards
- [ICU Message Format](https://unicode-org.github.io/icu/userguide/format_parse/messages/)

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-XX-XX | Initial strategy document |
| 1.1 | 2025-01-05 | Updated progress: Phase 1-4 complete, Phase 5-6 in progress |
| 1.2 | 2025-01-05 | Added detailed remaining work checklist |
| 1.3 | 2025-01-05 | Moved locales to botlib/locales/, removed duplicate translations.js |

## Current File Structure

```
gb/
├── botlib/
│   ├── locales/                    # ✅ Centralized translations
│   │   ├── en/
│   │   │   ├── admin.ftl          # 326 keys
│   │   │   ├── analytics.ftl      # 174 keys
│   │   │   ├── bot-templates.ftl  # 150 keys
│   │   │   ├── channels.ftl       # Channel-specific messages
│   │   │   ├── common.ftl         # 400+ shared keys
│   │   │   ├── errors.ftl         # Error messages
│   │   │   ├── notifications.ftl  # Notification messages
│   │   │   └── ui.ftl             # 680+ UI keys
│   │   ├── pt-BR/                 # ✅ 100% translated
│   │   │   └── (same structure)
│   │   └── es/                    # 🔄 10% translated
│   │       └── common.ftl (partial)
│   └── src/
│       └── i18n/
│           ├── mod.rs             # ✅ Public API
│           ├── bundle.rs          # ✅ FluentBundles implementation
│           └── locale.rs          # ✅ Locale negotiation
│
├── botui/
│   └── ui/
│       └── suite/
│           ├── js/
│           │   └── i18n.js        # ✅ Client-side i18n with fallbacks
│           ├── index.html         # ✅ i18n for nav, apps dropdown
│           ├── admin/             # ✅ i18n added
│           ├── analytics/         # ✅ i18n added
│           ├── meet/              # ✅ i18n added
│           ├── research/          # ✅ i18n added
│           ├── auth/              # ❌ Needs i18n
│           ├── monitoring/        # ❌ Needs i18n
│           ├── sources/           # ❌ Needs i18n
│           ├── tools/             # ❌ Needs i18n
│           └── attendant/         # ❌ Needs i18n
│
└── botserver/
    └── src/
        └── core/
            └── i18n.rs            # ✅ RequestLocale extractor
```

## Summary Statistics

| Metric | Value |
|--------|-------|
| Total translation keys (EN) | ~1,700 |
| PT-BR coverage | 100% |
| ES coverage | ~10% |
| UI screens with i18n | 10/18 (56%) |
| Remaining UI screens | 8 |