# GUTTING.md — what was taken from `jetbrains-cc-gui`

This repo is a fork-gut: the valuable core of
[`ahmad-parr-dev/jetbrains-cc-gui`](https://github.com/ahmad-parr-dev/jetbrains-cc-gui)
stripped of the JetBrains plugin shell (`src/`, `build.gradle`), the webview GUI
(`webview/`), docs, and Node/npm packaging — then rebuilt from scratch in pure
x86-64 assembly with a TCP MCP transport and a PyTorch harness.

## The good parts (extracted)

| # | Source in `jetbrains-cc-gui` | Essence | Where it lives now |
|---|---|---|---|
| 1 | `ai-bridge/daemon.js` — NDJSON JSON-RPC protocol (`{"id","method","params"}` → `{"id","done","success"}`, warm long-lived process) | Line-delimited JSON-RPC 2.0 request/response discipline, persistent server | `asm/mcpd.asm` — TCP accept loop, `\n`-framed JSON-RPC 2.0, sequential connections |
| 2 | `ai-bridge/channel-manager.js` + `ai-bridge/channels/*.js` (10 engine channels: claude, codex, dsh, grok, kimi, minimax, omp, opencode, pi, zcode) | Tool dispatch table: named capabilities routed to handlers | `asm/mcpd.asm` — MCP `tools/list` + `tools/call` dispatch (`bridge.echo`, `bridge.policy_check`, `bridge.exec`, `bridge.identity`) |
| 3 | `ai-bridge/permission-safety.js` — temp-path rewrite (`/tmp`,`/var/tmp`,`/private/tmp` → project root), `..` escape detection, root-containment check | Permission gate on tool inputs | `asm/mcpd.asm` — `policy_check`: prefix rewrite, lexical `..` resolution, root-containment verdict (`ok`/`rewritten`/`blocked`); enforced on every `bridge.exec` argument |
| 4 | `ai-bridge/services/claude/mcp-status/mcp-protocol.js` — `initialize` handshake, `protocolVersion: 2024-11-05`, JSON-RPC shapes | MCP handshake | `asm/mcpd.asm` — `initialize` returns the same protocol version, capabilities, and serverInfo; see `mcp/PROTOCOL.md` |

## What was deliberately dropped

- `src/` (IntelliJ plugin Java), `webview/` (GUI), `docs/`, `build.gradle`, all npm
  packaging — host-specific shells, not the protocol core.
- Per-engine CLI spawning (`channels/`) — engine CLIs are environment-specific;
  the *dispatch-table* idea survives as the MCP tool registry.
- `permission-ipc.js` / `permission-handler.js` IPC plumbing — replaced by the
  in-process assembly gate (no IPC needed when the gate lives in the server).

## Honest limits

- The JSON field extractor is a pragmatic scanner, not a full JSON parser
  (documented in `mcp/PROTOCOL.md`).
- `bridge.exec` runs real commands via `fork`/`execve` — the permission gate is
  the safety boundary; run the server from the intended project root.
- Single-process, sequential connections — throughput is not the goal; the
  protocol core is.
