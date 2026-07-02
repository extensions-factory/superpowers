# Ecosystem-native init commands (anchors, not a lookup table)

These are illustrative starting points. Prefer the ecosystem's own current
official tool; if a stack isn't here, ask the user for the exact command.

- **Node / TS (Vite app):** `npm create vite@latest <name>`
- **Node library:** `npm init -y` then add the chosen test runner
- **Python:** `uv init <name>` (or `poetry new <name>`)
- **Rust:** `cargo new <name>`
- **Go:** `go mod init <module-path>`
- **Ruby gem:** `bundle gem <name>`

Never ship or copy a bundled template — always run the real tool.
