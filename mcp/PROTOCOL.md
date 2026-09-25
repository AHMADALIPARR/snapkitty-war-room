# PROTOCOL.md — MCP over custom TCP transport

`mcpd` speaks **MCP-style JSON-RPC 2.0 over a custom TCP transport** instead of
the usual stdio/SSE transports.

## Transport

- TCP, default `127.0.0.1:7341` (override: `./build/mcpd <port>`).
- One JSON-RPC 2.0 object per line, `\n`-delimited, UTF-8.
- Client → server: `{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{...}}`
- Server → client: `{"jsonrpc":"2.0","id":1,"result":{...}}`
- Errors: `{"jsonrpc":"2.0","id":1,"error":{"code":-32601,"message":"Method not found"}}`
- A request **without** `id` is a notification: it is processed, no reply is sent.

## Methods

| Method | Params | Result |
|---|---|---|
| `initialize` | `{protocolVersion, capabilities, clientInfo}` | `{protocolVersion:"2024-11-05", capabilities:{tools:{}}, serverInfo:{name,version}}` |
| `ping` | — | `{}` |
| `tools/list` | — | `{tools:[{name, description, inputSchema}...]}` |
| `tools/call` | `{name, arguments}` | `{...tool-specific...}` |
| `notifications/*` | — | *(no reply)* |

## Tools

| Tool | Arguments | Result |
|---|---|---|
| `bridge.echo` | any object | `{echo: <arguments>}` |
| `bridge.identity` | — | `{name, version, transport, pid-ish}` |
| `bridge.policy_check` | `{path}` | `{verdict: "ok"\|"rewritten"\|"blocked", path: "<final>"}` — port of `ai-bridge/permission-safety.js`: rewrites `/tmp`, `/var/tmp`, `/private/tmp` prefixes to the server root, lexically resolves `.`/`..`, blocks root escapes |
| `bridge.exec` | `{cmd, args: [...]}` | `{stdout: "<captured>", exit_code: N}` — every arg is policy-gated first; blocked args abort with error `44001` |

## Error codes

`-32700` parse error · `-32600` invalid request · `-32601` method not found ·
`-32602` invalid params · `-32603` internal error · `44001` policy blocked.

## Parser limits (by design)

The server uses a pragmatic JSON field scanner, not a full parser:
`method`/`id`/`name` are located by key search with `:` lookahead; string
escapes `\"` and `\\` are honored; `arguments` is captured by brace matching.
Deeply adversarial JSON is out of scope — the threat model is a cooperative
local harness, with the permission gate as the safety boundary.
