clear
pkill rustc -9
pkill botserver -9
pkill botui -9
rm botserver.log
cd botui
cargo build &
cd ../botserver
cargo build
cd ..
cargo run -p botserver -- --noconsole &
cargo run -p botui &
