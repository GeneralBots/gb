pkill botserver -9
pkill botui -9
cd botserver
cargo run -- --noconsole &
cd ../botui
cargo run &



