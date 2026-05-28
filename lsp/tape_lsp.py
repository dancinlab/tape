#!/usr/bin/env python3
# tape-lsp — canonical LSP server for the .tape grammar (v1.2).
# Stdio JSON-RPC, zero dependencies (Python 3.8+). Diagnostics + hover,
# grounded in spec/tape.md. Conservative: near-zero false positives —
# unrecognised body forms are hints (sev 2), not errors (consumers
# skip-not-reject per the forward-compatibility rule).
#
#   tape-lsp                 # speak LSP on stdin/stdout
#   tape-lsp --check FILE    # one-shot lint (exit 1 if any error)
import json
import re
import sys

TYPES = {
    "S": "Session boundary — start / resume / end / cancel",
    "U": "User input (Message{role=user})",
    "A": "Assistant reply (Message{role=assistant})",
    "T": "Tool invocation",
    "R": "Tool result",
    "H": "Hook fire — event@phase with optional priority",
    "D": "Decision — governance allow / deny + reason",
    "K": "Cost sample — tokens / ucents",
    "P": "Provider event — open / close / stream-delta",
    "?": "Anomaly — error / abort / cancel-with-cause",
    "I": "Foundational identity claim",
    "X": "External citation",
    "F": "Forbidden-pattern declaration",
    "N": "Note",
    "C": "Config",
    "L": "Layout",
    "V": "Spec-version",
}
EDGES = {
    "<-": "caused_by", "->": "triggers", "=>": "produces",
    "==": "continues", "~>": "supersedes", "|>": "verified_by",
    "!!": "aborts", "<:": "specializes", ":>": "generalizes",
    "?>": "soft_depends", "!>": "conflicts_with", "@>": "projects_to",
}
# header: @<type> <freeform (id / := subject / args)> :: <domain> [grade]?
HDR = re.compile(r"^@[A-Z?]\s+.+?::\s*\S+\s*(?:\[[^\]\n]*\])?\s*$")
KV = re.compile(r"^\S+\s*:?=")                # key = / key := ...
HEREDOC = re.compile(r"<<~?([A-Za-z_][\w-]*)\s*$")


def diag(ln, c0, c1, msg, sev=1):
    return {"range": {"start": {"line": ln, "character": c0},
                      "end": {"line": ln, "character": c1}},
            "severity": sev, "source": "tape-lsp", "message": msg}


def validate(text):
    out = []
    if text.startswith("﻿"):
        out.append(diag(0, 0, 1,
                   "invariant 1: .tape must be UTF-8 with no BOM"))
    if "\r" in text:
        out.append(diag(0, 0, 1,
                   "invariant 1: LF line endings only (CR/CRLF found)"))
    heredoc = None                     # active heredoc terminator token
    for i, raw in enumerate(text.split("\n")):
        s = raw.rstrip("\r")
        if heredoc is not None:
            if s.strip() == heredoc:
                heredoc = None
            continue                   # heredoc body — never validated
        t = s.strip()
        if t == "" or t.startswith("#"):     # blank / comment / divider
            continue
        indent = len(s) - len(s.lstrip(" "))
        if s.startswith("@"):
            if indent:
                out.append(diag(i, 0, len(s),
                           "entry header must start at column 0"))
                continue
            ty = s[1] if len(s) > 1 else ""
            if ty not in TYPES:
                out.append(diag(i, 1, 2,
                    "unknown entry type @%s (17-type alphabet: @%s)"
                    % (ty, " @".join(TYPES))))
            if not HDR.match(s):
                out.append(diag(i, 0, len(s),
                    "malformed header — expected "
                    "`@<type> <id>[ := \"subject\"] :: <domain> [<grade>]`"))
        else:
            if indent != 2:
                out.append(diag(i, 0, len(s),
                    "invariant 4: body/edge line indented exactly "
                    "2 spaces"))
                continue
            m = HEREDOC.search(t)
            if m:                              # `key <<~EOF` (no `=`)
                heredoc = m.group(1)
                continue
            tok = t.split(" ", 1)[0]
            ok = (tok in EDGES or t.startswith('"') or t.startswith("`")
                  or KV.match(t))
            if not ok:
                out.append(diag(i, 2, len(s),
                    "unrecognised body form — expected an edge (%s), "
                    "`key = val` / `key <<~EOF` / \"prose\""
                    % " ".join(list(EDGES)[:7]), sev=2))
    if heredoc is not None:
        out.append(diag(len(text.split("\n")) - 1, 0, 1,
                   "unterminated heredoc (missing %r line)" % heredoc))
    return out


def hover(line):
    s = line.strip()
    if s.startswith("@") and len(s) > 1 and s[1] in TYPES:
        return "**@%s** — %s" % (s[1], TYPES[s[1]])
    for e, meaning in EDGES.items():
        if s.startswith(e):
            return "**%s** — %s edge" % (e, meaning)
    return None


# ── stdio JSON-RPC ───────────────────────────────────────────────────
def _read():
    h = {}
    while True:
        ln = sys.stdin.buffer.readline()
        if not ln:
            return None
        ln = ln.decode("ascii", "replace").strip()
        if not ln:
            break
        if ":" in ln:
            k, v = ln.split(":", 1)
            h[k.strip().lower()] = v.strip()
    n = int(h.get("content-length", "0"))
    try:
        return json.loads(sys.stdin.buffer.read(n).decode("utf-8", "replace"))
    except Exception:
        return {}


def _send(o):
    b = json.dumps(o).encode("utf-8")
    sys.stdout.buffer.write(b"Content-Length: %d\r\n\r\n" % len(b) + b)
    sys.stdout.buffer.flush()


# Files whose name ends with one of these suffixes use a DIFFERENT tape
# dialect than the canonical commons/governance grammar, so the validator
# would emit false positives against them. They share the `.tape` extension
# (so the editor still routes them here) but carry a free-form schema:
#   .mining.tape — /mining idea-cart (@goal: header + @P<n>/@X promotion rows)
# For these we publish an empty diagnostic set (no grammar check) rather than
# flag every line as malformed. See sidecar INBOX 2026-05-28 (tape-lsp ×
# mining false-positive).
_NO_GRAMMAR_SUFFIXES = (".mining.tape",)


def _grammar_exempt(uri):
    u = uri.split("?", 1)[0].split("#", 1)[0]
    return any(u.endswith(sfx) for sfx in _NO_GRAMMAR_SUFFIXES)


def _publish(uri, text):
    if _grammar_exempt(uri):
        # free-form dialect — skip the commons grammar check entirely
        _send({"jsonrpc": "2.0", "method": "textDocument/publishDiagnostics",
               "params": {"uri": uri, "diagnostics": []}})
        return
    try:
        d = validate(text)
    except Exception as e:
        d = [diag(0, 0, 1, "tape-lsp internal: %s" % e, 2)]
    _send({"jsonrpc": "2.0", "method": "textDocument/publishDiagnostics",
           "params": {"uri": uri, "diagnostics": d}})


def serve():
    docs = {}
    while True:
        m = _read()
        if m is None:
            break
        meth = m.get("method")
        if meth == "initialize":
            _send({"jsonrpc": "2.0", "id": m.get("id"), "result": {
                "capabilities": {"textDocumentSync": 1,
                                 "hoverProvider": True},
                "serverInfo": {"name": "tape-lsp"}}})
        elif meth == "shutdown":
            _send({"jsonrpc": "2.0", "id": m.get("id"), "result": None})
        elif meth == "exit":
            break
        elif meth == "textDocument/didOpen":
            d = m["params"]["textDocument"]
            docs[d["uri"]] = d.get("text", "")
            _publish(d["uri"], docs[d["uri"]])
        elif meth == "textDocument/didChange":
            p = m["params"]
            ch = p.get("contentChanges") or [{}]
            docs[p["textDocument"]["uri"]] = ch[-1].get("text", "")
            _publish(p["textDocument"]["uri"],
                     docs[p["textDocument"]["uri"]])
        elif meth == "textDocument/didClose":
            u = m["params"]["textDocument"]["uri"]
            docs.pop(u, None)
            _send({"jsonrpc": "2.0",
                   "method": "textDocument/publishDiagnostics",
                   "params": {"uri": u, "diagnostics": []}})
        elif meth == "textDocument/hover":
            p = m["params"]
            txt = docs.get(p["textDocument"]["uri"], "")
            ln = p["position"]["line"]
            lines = txt.split("\n")
            hv = hover(lines[ln]) if 0 <= ln < len(lines) else None
            _send({"jsonrpc": "2.0", "id": m.get("id"),
                   "result": ({"contents": {"kind": "markdown",
                                            "value": hv}} if hv else None)})
        elif m.get("id") is not None:
            _send({"jsonrpc": "2.0", "id": m["id"], "result": None})


def main():
    if len(sys.argv) > 2 and sys.argv[1] == "--check":
        text = open(sys.argv[2], encoding="utf-8", errors="replace").read()
        ds = validate(text)
        for d in ds:
            print("%s:%d: %s%s" % (
                sys.argv[2], d["range"]["start"]["line"] + 1,
                "" if d["severity"] == 1 else "[hint] ", d["message"]))
        sys.exit(1 if any(d["severity"] == 1 for d in ds) else 0)
    serve()


if __name__ == "__main__":
    main()
