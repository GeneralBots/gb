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

## ✅ Problemas Resolvidos (2026-03-06)

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

**Função**: `route_to_bot()` - Streaming simplificado

```rust
tokio::spawn(async move {
    let mut buffer = String::new();

    while let Some(response) = rx.recv().await {
        let is_final = response.is_complete;

        if !response.content.is_empty() {
            buffer.push_str(&response.content);
        }

        // Only send when the complete message is ready
        // This ensures lists and all content are sent as one complete message
        if is_final && !buffer.is_empty() {
            let mut wa_response = response;
            wa_response.user_id.clone_from(&phone);
            wa_response.channel = "whatsapp".to_string();
            wa_response.content = buffer.clone();
            wa_response.is_complete = true;

            if let Err(e) = adapter_for_send.send_message(wa_response).await {
                error!("Failed to send WhatsApp response: {}", e);
            }

            buffer.clear();
        }
    }
});
```

**Mudanças principais**:
- ❌ Removido: `MIN_CHUNKS_TO_SEND`, `chunk_count`, `in_list`, `list_indentation`
- ✅ Adicionado: Buffer simples, envio único quando `is_final`

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
