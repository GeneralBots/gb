#!/bin/bash
set -e

echo "🛑 Stopping existing processes..."
pkill -f botserver || true
pkill -f botui || true
pkill -f rustc || true

echo "🧹 Cleaning logs..."
rm -f botserver.log botui.log

echo "🔨 Building botserver..."
cargo build -p botserver

echo "🔨 Building botui..."
cargo build -p botui

echo "🚀 Starting botserver..."
RUST_LOG=info ./target/debug/botserver --noconsole > botserver.log 2>&1 &
BOTSERVER_PID=$!

echo "🚀 Starting botui..."
BOTSERVER_URL="https://localhost:8088" ./target/debug/botui > botui.log 2>&1 &
BOTUI_PID=$!

echo "✅ Started botserver (PID: $BOTSERVER_PID) and botui (PID: $BOTUI_PID)"
echo "📊 Monitor with: tail -f botserver.log botui.log"
echo "🌐 Access at: http://localhost:3000"
