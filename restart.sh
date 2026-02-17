#!/bin/bash
set -e

echo "🛑 Stopping existing processes..."
pkill -f "botserver --noconsole" || true
pkill -f botui || true
pkill -f rustc || true
# Note: PostgreSQL, Vault, and Valkey are managed by botserver bootstrap, don't kill them

echo "🧹 Cleaning logs..."
rm -f botserver.log botui.log

echo "🔨 Building botserver..."
cargo build -p botserver

echo "🔨 Building botui..."
cargo build -p botui

echo "🗄️ Starting PostgreSQL..."
./botserver-stack/bin/tables/bin/postgres -D botserver-stack/data/tables/pgdata -c config_file=botserver-stack/conf/postgresql.conf > botserver-stack/logs/tables/postgres.log 2>&1 &
echo "  PostgreSQL PID: $!"
sleep 2

echo "🔑 Starting Valkey (cache)..."
./botserver-stack/bin/cache/valkey-server --daemonize no --dir botserver-stack/data/cache > /dev/null 2>&1 &
echo "  Valkey started"
sleep 2

echo "🚀 Starting botserver..."
export VAULT_ADDR="https://localhost:8200"
# Read VAULT_TOKEN from secure location (/tmp) or environment
if [ -f "/tmp/vault-token-gb" ]; then
    export VAULT_TOKEN="$(cat /tmp/vault-token-gb)"
elif [ -n "$VAULT_TOKEN" ]; then
    # Use environment variable if set
    :
else
    echo "⚠️  Warning: VAULT_TOKEN not set - Vault operations may fail"
    echo "   Set VAULT_TOKEN environment variable or place token in /tmp/vault-token-gb"
fi
export VAULT_CACERT="./botserver-stack/conf/system/certificates/ca/ca.crt"
export VAULT_CACHE_TTL="300"
RUST_LOG=info ./target/debug/botserver --noconsole > botserver.log 2>&1 &
BOTSERVER_PID=$!

echo "⏳ Waiting for Vault to start (unsealing in background)..."
(
    sleep 8
    echo "🔓 Unsealing Vault..."
    UNSEAL_KEY_FILE="/tmp/vault-unseal-key-gb"
    if [ -f "$UNSEAL_KEY_FILE" ]; then
        UNSEAL_KEY="$(cat "$UNSEAL_KEY_FILE")"
        if [ -n "$VAULT_TOKEN" ] && [ -n "$UNSEAL_KEY" ]; then
            curl -s --cacert botserver-stack/conf/system/certificates/ca/ca.crt \
                -X POST \
                -H "X-Vault-Token: $VAULT_TOKEN" \
                -d "{\"key\": \"$UNSEAL_KEY\"}" \
                https://localhost:8200/v1/sys/unseal 2>/dev/null && echo "✅ Vault unsealed" || echo "⚠️ Unseal failed"
        else
            echo "⚠️ Could not extract unseal key or token - place them in /tmp/"
        fi
    else
        echo "⚠️ Could not find unseal key at $UNSEAL_KEY_FILE"
    fi
) &

echo "🚀 Starting botui..."
BOTSERVER_URL="http://localhost:9000" ./target/debug/botui > botui.log 2>&1 &
BOTUI_PID=$!

echo "✅ Started botserver (PID: $BOTSERVER_PID) and botui (PID: $BOTUI_PID)"
echo "📊 Monitor with: tail -f botserver.log botui.log"
echo "🌐 Access at: http://localhost:3000"
