#!/usr/bin/env python3
"""tape_walk_tree — generate aggregate inter-repo tree from all dancinlab AGENTS.tape files.

Per tape v1.2 §"Project-tree convention". Usage:
  tape_walk_tree.py                    # render tree to stdout
  tape_walk_tree.py --check            # compare against ~/core/atlas/.golden-tree.txt
  tape_walk_tree.py --write-golden     # write current tree as new golden baseline
  tape_walk_tree.py --md > tree.md     # markdown output (default is ascii tree)
"""
import os, re, sys
from pathlib import Path

GLOB = "*/AGENTS.tape"

def parse_id001(path: Path):
    """Extract @I id001 fields from an AGENTS.tape."""
    content = path.read_text()
    lines = content.split("\n")
    node = {"repo": "", "kind": "", "brief": "", "parent": "dancinlab", "siblings": []}
    in_block = False
    for line in lines:
        if line.startswith("@I id001"):
            in_block = True
            m = re.search(r'"([^"]+)"', line)
            if m: node["repo"] = m.group(1)
            continue
        if in_block:
            if not line.startswith("  ") or line.strip() == "":
                break
            stripped = line.strip()
            m = re.match(r'(\w[\w-]*)\s*=\s*(.+)', stripped)
            if not m: continue
            key, val = m.group(1), m.group(2).strip()
            if val.startswith('"') and val.endswith('"'):
                val = val[1:-1]
            elif val.startswith('[') and val.endswith(']'):
                val = [s.strip() for s in val[1:-1].split(",") if s.strip()]
            if key in node:
                node[key] = val
    return node if node["repo"] else None


def normalize_parent(p):
    """Canonical form: 'dancinlab' or 'dancinlab/<repo>'."""
    if not p or p == "dancinlab": return "dancinlab"
    if isinstance(p, list): return "dancinlab"  # shouldn't happen but safe
    p = p.strip()
    if p.startswith("dancinlab/"):
        return p.split(" ")[0]  # drop trailing prose
    return "dancinlab"


def emoji_from_kind(kind):
    """Extract leading emoji from kind string (if any)."""
    if not kind: return ""
    # First char if it's an emoji-ish (non-ASCII)
    if kind and len(kind) > 0 and ord(kind[0]) > 127:
        # might be multi-byte emoji; take chars until space
        end = kind.find(" ")
        if end > 0:
            return kind[:end]
        return kind[0]
    return ""


def render_tree(adjacency, nodes_by_repo, key="dancinlab", depth=0, prefix="", is_last=True):
    """Render tree starting from key, return list of lines."""
    lines = []
    children = sorted(adjacency.get(key, []))
    for i, child_repo in enumerate(children):
        node = nodes_by_repo.get(child_repo, {})
        emoji = emoji_from_kind(node.get("kind", ""))
        brief = node.get("brief", "") or "(no brief)"
        branch = "└── " if i == len(children) - 1 else "├── "
        label = f"{emoji} **{child_repo}**" if emoji else f"**{child_repo}**"
        lines.append(f"{prefix}{branch}{label} — {brief}")
        # Recurse: this child's parent-key for its own children
        child_key = f"dancinlab/{child_repo}"
        if child_key in adjacency:
            ext = "    " if i == len(children) - 1 else "│   "
            sub = render_tree(adjacency, nodes_by_repo, key=child_key, depth=depth+1, prefix=prefix+ext, is_last=(i == len(children)-1))
            lines.extend(sub)
    return lines


def main():
    base = Path.home() / "core"
    tapes = sorted(base.glob(GLOB))
    nodes = []
    for p in tapes:
        n = parse_id001(p)
        if n:
            nodes.append(n)
    
    # Build adjacency: parent → [child-repo]
    adjacency = {}
    nodes_by_repo = {}
    for n in nodes:
        p = normalize_parent(n["parent"])
        adjacency.setdefault(p, []).append(n["repo"])
        nodes_by_repo[n["repo"]] = n
    
    # Render
    md_mode = "--md" in sys.argv
    header = "# dancinlab project tree" if md_mode else "dancinlab/"
    tree_lines = render_tree(adjacency, nodes_by_repo)
    output = header + "\n" + "\n".join(tree_lines) + "\n"
    
    # Modes
    golden_path = base / "atlas" / ".golden-tree.txt"
    if "--write-golden" in sys.argv:
        golden_path.parent.mkdir(exist_ok=True)
        golden_path.write_text(output)
        print(f"# Wrote {golden_path}", file=sys.stderr)
        print(output)
        return 0
    if "--check" in sys.argv:
        if not golden_path.exists():
            print(f"# ERROR: golden tree {golden_path} does not exist; run --write-golden first", file=sys.stderr)
            return 2
        golden = golden_path.read_text()
        if output == golden:
            print("# OK: tree matches golden", file=sys.stderr)
            return 0
        else:
            print("# DRIFT detected — diff:", file=sys.stderr)
            import difflib
            for line in difflib.unified_diff(golden.split("\n"), output.split("\n"), fromfile="golden", tofile="current", lineterm=""):
                print(line)
            return 1
    
    # default: stdout
    print(output)
    return 0

if __name__ == "__main__":
    sys.exit(main())
