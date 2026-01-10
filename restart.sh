pkill rustc -9
pkill botserver -9
pkill botui -9
cd botserver
cargo build
cargo run -- --noconsole &
cd ../botui
cargo run &



