#!/usr/bin/env python3
"""
Generate a human-readable diff between two ei.proto files.
Usage: protodiff.py <old_proto> <new_proto> [output_file]

Ignores namespace-only changes (ei., aux. prefix additions/removals).
Groups changes by message with full nested path.
"""
import sys
import re
import difflib
from collections import OrderedDict

NAMESPACE_RE = re.compile(r'\b(ei|aux)\.')


def normalize(line):
    return NAMESPACE_RE.sub('', line)


def parse_proto(filename):
    """Returns OrderedDict: message_path -> list of content lines.
    Only 'message' blocks create new sections; enums/oneofs are content of parent.
    """
    messages = OrderedDict()
    stack = []  # (kind, name, depth_when_opened); kind: 'message' | 'other'
    depth = 0

    with open(filename, encoding='utf-8') as f:
        lines = f.readlines()

    for line in lines:
        s = line.strip()

        m = re.match(r'^message\s+(\w+)\s*\{', s)
        if m:
            stack.append(('message', m.group(1), depth))
            depth += s.count('{') - s.count('}')
            continue

        m = re.match(r'^(enum|oneof|extend|service)\s+(\w+)\s*\{', s)
        if m:
            path = _path(stack)
            if path is not None:
                _add(messages, path, line)
            stack.append(('other', m.group(2), depth))
            depth += s.count('{') - s.count('}')
            continue

        if s == '}':
            depth -= 1
            if stack and stack[-1][2] == depth:
                kind, _, _ = stack.pop()
                if kind == 'other':
                    path = _path(stack)
                    if path is not None:
                        _add(messages, path, line)
            continue

        depth += s.count('{') - s.count('}')

        path = _path(stack)
        if path is not None:
            _add(messages, path, line)

    return messages


def _add(messages, path, line):
    if path not in messages:
        messages[path] = []
    messages[path].append(line)


def _path(stack):
    parts = [name for kind, name, _ in stack if kind == 'message']
    if not parts:
        return None
    if len(parts) == 1:
        return f"message {parts[0]}"
    return f"message ({'.'.join(parts[:-1])}.){parts[-1]}"


def diff_proto(old_file, new_file, output_file=None):
    old = parse_proto(old_file)
    new = parse_proto(new_file)

    # new file order first, then old-only paths
    seen = set()
    paths = []
    for p in new:
        paths.append(p)
        seen.add(p)
    for p in old:
        if p not in seen:
            paths.append(p)

    sections = []

    for path in paths:
        old_lines = old.get(path, [])
        new_lines = new.get(path, [])

        old_norm = [normalize(l) for l in old_lines]
        new_norm = [normalize(l) for l in new_lines]

        if old_norm == new_norm:
            continue

        sm = difflib.SequenceMatcher(None, old_norm, new_norm, autojunk=False)
        diff_lines = []

        for tag, i1, i2, j1, j2 in sm.get_opcodes():
            if tag == 'equal':
                continue
            elif tag == 'insert':
                diff_lines.extend('+' + new_lines[j].rstrip('\n') for j in range(j1, j2))
            elif tag == 'delete':
                diff_lines.extend('-' + old_lines[i].rstrip('\n') for i in range(i1, i2))
            elif tag == 'replace':
                diff_lines.extend('-' + old_lines[i].rstrip('\n') for i in range(i1, i2))
                diff_lines.extend('+' + new_lines[j].rstrip('\n') for j in range(j1, j2))

        if diff_lines:
            sections.append(f"@@ {path} @@")
            sections.extend(diff_lines)
            sections.append('')

    result = '\n'.join(sections)

    if output_file:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(result)
        print(f"Diff written to {output_file}")

    return result


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <old_proto> <new_proto> [output_file]", file=sys.stderr)
        sys.exit(1)
    result = diff_proto(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None)
    if len(sys.argv) < 4:
        print(result)
