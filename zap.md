# Configuração WhatsApp - Bot Salesianos

## Status Atual

| Campo | Valor | Status |
|-------|-------|--------|
| Phone Number | +15558293147 | ✅ |
| Phone Number ID | 323250907549153 | ✅ Configurado |
| Business Account ID | 1261667644771701 | ✅ Configurado |
| APP ID | 948641861003702 | ✅ |
| Client Token | 84ba0c232681678376c7693ad2252763 | ⚠️ Temporário |
| API Key (Permanent Token) | EAAQdlso6aM8B... (configured) | ✅ Configurado |
| Verify Token | webhook_verify_salesianos_2024 | ✅ Configurado |

---

## 📱 Comandos Disponíveis

### `/clear` - Limpar Histórico

O comando `/clear` permite ao usuário limpar seu histórico de conversa com o bot.

**Uso**: Digite `/clear` no WhatsApp

**Comportamento**:
- Remove todas as mensagens anteriores da sessão
- Mantém a sessão ativa (não remove o usuário)
- Envia confirmação ao usuário: "✅ Histórico de conversa limpo! Posso ajudar com algo mais?"

**Implementação** (`botserver/src/whatsapp/mod.rs:318-353`):
```rust
if content.trim().to_lowercase() == "/clear" {
    match find_or_create_session(&state, bot_id, &phone, &name).await {
        Ok((session, _)) => {
            clear_session_history(&state, &session.id).await?;
            // Send confirmation
        }
        Err(e) => error!("Failed to get session for /clear: {}", e),
    }
    return Ok(());
}
```

---

## ✅ Problemas Resolvidos (2026-03-07)

### Problema 6: Conteúdo pós-lista enviado junto com a lista (RESOLVIDO - 2026-03-07)

**Sintoma**: Quando uma lista terminava e vinha um novo parágrafo (ex: "Sua Filosofia..."), tudo era enviado como uma mensagem só

**Causa raiz**: A lógica verificava `has_list` mas não detectava quando a lista havia TERMINADO

**Solução aplicada** (`botserver/src/whatsapp/mod.rs:762-832`):
- ✅ Adicionado loop `'process_buffer` aninhado
- ✅ Usa `extract_complete_list()` para detectar fim da lista
- ✅ Envia lista completa separadamente
- ✅ Re-processa conteúdo restante imediatamente (não espera próximo chunk)

```rust
'process_buffer: loop {
    let has_list = contains_list(&buffer);
    if has_list {
        if let Some((list_content, remaining)) = extract_complete_list(&buffer) {
            // List ended! Send list separately, keep remaining in buffer
            send_part(&adapter, &phone, list_content, false).await;
            buffer = remaining;
            continue 'process_buffer; // Process remaining content NOW
        }
        // ... rest of list handling
    } else {
        // Non-list content handling (Sua Filosofia... goes here)
    }
}
```

### Problema 5: Embedding Service HTTP 500 (RESOLVIDO - 2026-03-07)

**Sintoma**: Erro HTTP 500 do embedding service causava falha na busca semântica

**Solução aplicada** (`botserver/src/llm/cache.rs:656-709`):
- ✅ Implementado retry logic com exponential backoff
- ✅ 3 tentativas com delays: 500ms, 1000ms, 2000ms
- ✅ Retry apenas em HTTP 5xx e erros de rede
- ✅ Timeout de 30 segundos por requisição

```rust
const MAX_RETRIES: u32 = 3;
const INITIAL_DELAY_MS: u64 = 500;
// Exponential backoff: 500ms, 1000ms, 2000ms
let delay_ms = INITIAL_DELAY_MS * (1 << (attempt - 1));
```

### Problema 4: Listas separadas item por item (RESOLVIDO - 2026-03-07)

**Sintoma**: Cada item de lista era enviado como mensagem separada

**Solução aplicada** (`botserver/src/whatsapp/mod.rs:634-809`):
- ✅ Lógica simplificada: se buffer contém lista, SÓ envia quando `is_final`
- ✅ Lista inteira é acumulada antes do envio
- ✅ Mensagens longas (>4000 chars) são divididas com `split_message_smart`

```rust
let has_list = contains_list(&buffer);
if has_list {
    // With lists: only flush when final or too long
    if is_final || buffer.len() >= MAX_WHATSAPP_LENGTH {
        // send complete list as one message
    }
} else {
    // No list: use normal paragraph-based flushing
}
```

### Problema 3: Mensagens duplicadas em respostas (RESOLVIDO - 2026-03-07)

**Sintoma**: Bot enviava a mesma mensagem duas vezes seguidas no WhatsApp

**Causa raiz**:
1. O `stream_response` enviava chunks de streaming com `is_complete: false` e depois enviava uma resposta final com `is_complete: true` contendo TODO o conteúdo acumulado (`full_response`)
2. WhatsApp faz retry de webhooks, causando processamento duplicado da mesma mensagem

**Solução aplicada**:
- ✅ Modificado `botserver/src/core/bot/mod.rs:980-983` para enviar conteúdo vazio na resposta final
- ✅ A resposta final agora serve apenas como sinal de "streaming completo"
- ✅ Removida variável `tool_was_executed` que não era mais necessária
- ✅ Implementado deduplicação de mensagens por ID usando cache Redis (`botserver/src/whatsapp/mod.rs:263-284`)
  - Usa `SET key value NX EX 300` para garantir processamento único
  - TTL de 5 minutos para limpeza automática

**Resultado**: Mensagens agora são enviadas apenas uma vez

### Problema 1: Mensagens ignoradas pelo bot (RESOLVIDO)

**Sintoma**: Mensagens eram recebidas mas ignoradas pelo bot (query vazia no KB)

**Causa raiz**: JSON deserialization estava falhando - array `messages` aparecia vazio

**Solução aplicada**:
- ✅ Adicionado debug logging em `handle_webhook()` e `process_incoming_message()`
- ✅ Verificado estrutura do payload JSON
- ✅ Testado com script de simulação

**Resultado**: Mensagens agora são processadas corretamente

### Problema 2: Listas duplicadas/multipartes (RESOLVIDO)

**Sintoma**: Listas (li/ul) eram enviadas em chunks separados, causando duplicação

**Causa raiz**: Lógica de streaming enviava mensagens em pedaços durante a geração

**Solução aplicada**:
- ✅ Simplificado streaming em `botserver/src/whatsapp/mod.rs:597-623`
- ✅ Removido chunking - agora acumula todo conteúdo antes de enviar
- ✅ Mensagem só é enviada quando `is_final = true`

**Resultado**: Listas e todo conteúdo enviado como uma mensagem completa

---

## Código Modificado

### Arquivo: `botserver/src/whatsapp/mod.rs`

**Função**: `route_to_bot()` - Streaming com particionamento inteligente

```rust
tokio::spawn(async move {
    let mut buffer = String::new();
    const MAX_WHATSAPP_LENGTH: usize = 4000;
    const MIN_FLUSH_PARAGRAPHS: usize = 3;

    // Helper functions
    fn is_list_item(line: &str) -> bool { /* ... */ }
    fn contains_list(text: &str) -> bool { /* ... */ }

    while let Some(response) = rx.recv().await {
        let is_final = response.is_complete;
        if !response.content.is_empty() {
            buffer.push_str(&response.content);
        }

        let has_list = contains_list(&buffer);

        if has_list {
            // List: ONLY flush when final or too long
            if is_final || buffer.len() >= MAX_WHATSAPP_LENGTH {
                // Send complete list as one message
            }
        } else {
            // No list: paragraph-based flushing
            let should_flush = buffer.len() >= MAX_WHATSAPP_LENGTH ||
                (paragraph_count >= MIN_FLUSH_PARAGRAPHS && ends_with_paragraph) ||
                is_final;

            if should_flush { /* send */ }
        }
    }
});
```

### Arquivo: `botserver/src/llm/cache.rs`

**Função**: `get_embedding()` - Retry com backoff exponencial

```rust
const MAX_RETRIES: u32 = 3;
const INITIAL_DELAY_MS: u64 = 500;

for attempt in 0..MAX_RETRIES {
    if attempt > 0 {
        let delay_ms = INITIAL_DELAY_MS * (1 << (attempt - 1));
        tokio::time::sleep(Duration::from_millis(delay_ms)).await;
    }

    match request.timeout(Duration::from_secs(30)).send().await {
        Ok(response) if response.status().is_success() => return Ok(embedding),
        Ok(response) if response.status().as_u16() >= 500 => continue, // retry
        Err(_) => continue, // network error - retry
        _ => return Err(...), // non-retriable
    }
}
```

**Mudanças principais**:
- ✅ Adicionado: Retry logic para embedding service
- ✅ Adicionado: Particionamento inteligente de mensagens
- ✅ Adicionado: `split_message_smart` para mensagens longas
- ✅ Adicionado: Detecção de listas para envio completo

---

## Fase 1: Configuração Básica ✅

- [x] **Obter Permanent Access Token** - ✅ CONFIGURADO
- [x] **Verificar config.csv atual** - ✅ TODOS OS CAMPOS CONFIGURADOS
  - Arquivo: `/opt/gbo/data/salesianos.gbai/salesianos.gbot/config.csv`
  - Campos: `whatsapp-phone-number-id`, `whatsapp-business-account-id`, `whatsapp-api-key`, `whatsapp-verify-token`

---

## Fase 2: Configuração do Webhook (PENDENTE PRODUÇÃO)

- [ ] **Configurar webhook na Meta Business Suite**
  - URL de produção: `https://<seu-dominio>/webhook/whatsapp/<bot_id>`
  - Verify Token: `webhook_verify_salesianos_2024`
  - Subscrever eventos: `messages`, `messaging_postbacks`

- [ ] **Verificar se webhook está acessível externamente**
  - Configurar reverse proxy (nginx/traefik)
  - Configurar SSL/TLS (obrigatório para produção)

- [ ] **Testar verificação do webhook**
  ```bash
  curl "https://<seu-dominio>/webhook/whatsapp/<bot_id>?hub.mode=subscribe&hub.challenge=test&hub.verify_token=webhook_verify_salesianos_2024"
  ```

---

## Fase 3: Testes

### Teste Local ✅

- [x] **Script de teste**: `/tmp/test_whatsapp_webhook.sh`
- [x] **Webhook local funcionando**: `http://localhost:8080/webhook/whatsapp/<bot_id>`
- [x] **Extração de conteúdo**: Funcionando
- [x] **Streaming de listas**: Corrigido

### Teste Produção (PENDENTE)

- [ ] **Testar com mensagem real do WhatsApp**
  - Enviar mensagem para +15558293147
  - Verificar se resposta vem completa (sem duplicação)

### Comandos de Debug

```bash
# Ver mensagens WhatsApp em tempo real
tail -f botserver.log | grep -iE "(whatsapp|Extracted|content)"

# Testar webhook localmente
/tmp/test_whatsapp_webhook.sh

# Verificar configuração do bot
cat /opt/gbo/data/salesianos.gbai/salesianos.gbot/config.csv | grep whatsapp

# Verificar saúde do servidor
curl http://localhost:8080/health
```

---

## Fase 4: Produção

- [ ] **Configurar SSL/TLS**
  - Certificado válido para o domínio
  - HTTPS obrigatório para webhooks

- [ ] **Rate Limiting**
  - Verificar limites da API do WhatsApp
  - Implementar throttling se necessário

- [ ] **Monitoramento**
  - Alertas para falhas de webhook
  - Logs estruturados

- [ ] **Backup do config.csv**
  - Salvar configurações em local seguro
  - Documentar credenciais (exceto secrets)

---

## Referências

- [WhatsApp Business API Docs](https://developers.facebook.com/docs/whatsapp/business-platform-api)
- [Meta Business Suite](https://business.facebook.com/)
- Arquivo de config: `/opt/gbo/data/salesianos.gbai/salesianos.gbot/config.csv`
- Webhook handler: `botserver/src/whatsapp/mod.rs`
- Test script: `/tmp/test_whatsapp_webhook.sh`

---

## Notas

- **Client Token** fornecido é temporário - necessário Permanent Access Token ✅ OBTIDO
- Token permanente armazenado no config.csv
- Webhook local funcionando - pendente configuração de produção

---

## Próximos Passos

1. [ ] Testar com mensagens reais do WhatsApp
2. [ ] Configurar webhook na Meta Business Suite para produção
3. [ ] Configurar SSL/TLS no servidor de produção
4. [ ] Monitorar logs em produção
5. [ ] Documentar processo de deploy
