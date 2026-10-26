#!/usr/bin/env python3
"""Heuristic usage checker for this Flutter project.

There is no Dart compiler in the delivery sandbox, so this script approximates
one narrow class of errors:

  1. member check: calling a member the receiving class never declares
     (e.g. `ble.nearest` before the getter exists),
  2. constructor check: passing a named argument the project widget's
     constructor does not accept (e.g. `NeonIconButton(colour: ...)`).

How it works
  * Every class / enum / extension body in `lib/` is indexed with the members it
    declares (fields, getters, methods, enum values, extension members mapped to
    their `on` type) and with its public constructor signature.
  * Every file is scanned for receivers whose static type is inferable from a
    nearby declaration, parameter or `context.watch<T>()` call, and for calls to
    project classes.
  * Anything that cannot be resolved confidently is skipped, so a clean run
    means "no obvious mismatches", not "compiles".

Usage:  python3 tool/api_check.py [-v]
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
VERBOSE = "-v" in sys.argv

# Members every Dart object/collection/enum has; kept intentionally small.
UNIVERSAL = {
    "toString", "hashCode", "runtimeType", "noSuchMethod", "then", "catchError",
    "whenComplete", "timeout", "ignore", "call", "wait", "name", "index",
    "length", "isEmpty", "isNotEmpty", "first", "last", "single", "add", "addAll",
    "insert", "remove", "removeAt", "removeWhere", "clear", "contains", "any",
    "every", "where", "map", "forEach", "reduce", "fold", "toList", "toSet",
    "sort", "reversed", "indexOf", "sublist", "join", "take", "skip", "expand",
    "firstWhere", "lastWhere", "whereType", "asMap", "keys", "values", "entries",
    "putIfAbsent", "update", "updateAll", "containsKey", "containsValue", "cast",
    "elementAt", "singleWhere", "retainWhere", "shuffle", "followedBy",
    "indexWhere", "removeLast", "getRange", "setRange", "fillRange",
    "addListener", "removeListener", "notifyListeners", "dispose", "setState",
    "mounted", "context", "widget", "key", "watch", "read", "select", "of",
    "maybeOf", "value", "hasValue", "isSupported", "isGranted",
    "clamp", "abs", "round", "toDouble", "toInt", "compareTo", "isFinite",
}

IGNORED_RECEIVERS = {"this", "super", "oldDelegate", "other", "delegate", "a", "b"}

SKIP_TYPES = {
    "List", "Map", "Set", "Iterable", "Future", "Stream", "StreamController",
    "ValueNotifier", "ChangeNotifier", "AnimationController", "Animation",
    "BuildContext", "Widget", "State", "TextEditingController",
    "ScrollController", "TabController", "PageController", "Timer",
    "DateTime", "Duration", "String", "Object", "Complete",
    "ScaffoldMessenger", "Navigator", "MediaQuery", "Theme", "SharedPreferences",
}

CLASS_RE = re.compile(r"\b(?:abstract\s+|sealed\s+|base\s+|final\s+)*class\s+([A-Za-z_]\w*)")
ENUM_RE = re.compile(r"\benum\s+([A-Za-z_]\w*)")
EXTENSION_RE = re.compile(r"\bextension\s+([A-Za-z_]\w*)\s+on\s+([A-Za-z_]\w*)")
MEMBER_RE = re.compile(
    r"\n  (?:@\w+(?:\([^)]*\))?\s+)*"
    r"(?:static\s+)?(?:external\s+)?(?:factory\s+)?"
    r"(?:[A-Za-z_][\w<>,?.\[\]\s]*?\s+)?"
    r"(?:get\s+|set\s+)?([a-zA-Z_]\w*)\s*[(=;{]"
)
DECL_RE = re.compile(
    r"(?:final|const|late|var|static)?\s*"
    r"(?P<type>[A-Z]\w*)"
    r"(?:<[^;=()]*>)?\??\s+"
    r"(?P<name>[a-z_]\w*)\s*[=;,){(]"
)
WATCH_RE = re.compile(
    r"(?:(?:final|const|late|var)\s+)?(?P<type>[A-Z]\w*)\??\s+(?P<name>[a-z_]\w*)\s*=\s*"
    r"context\.(?:watch|read|select)<(?P<generic>[A-Za-z_]\w*)>"
)
MEMBER_USE_RE = re.compile(r"\b([a-z_]\w*)\.([a-zA-Z_]\w*)")
CALL_RE = re.compile(r"\b([A-Z]\w*)\s*\(")
SKIP_ARG_CLASSES = {"DateTime", "Duration", "Uri", "Rect", "Offset", "Color"}


# ---------------------------------------------------------------------------
# Lexical helpers
# ---------------------------------------------------------------------------


def strip_comments(text: str) -> str:
    """Remove comments while preserving every newline (keeps line numbers)."""

    def blank(match: re.Match[str]) -> str:
        return "\n" * match.group(0).count("\n")

    text = re.sub(r"/\*.*?\*/", blank, text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)


def blank_strings(text: str) -> str:
    """Blank the contents of string literals (keeps newlines and quotes)."""
    out: list[str] = []
    i = 0
    length = len(text)
    while i < length:
        ch = text[i]
        if ch not in "'\"":
            out.append(ch)
            i += 1
            continue
        triple = text[i : i + 3] == ch * 3
        quote = ch * 3 if triple else ch
        out.append(quote)
        i += len(quote)
        while i < length:
            if text[i] == "\\":
                out.append(" ")
                if i + 1 < length and text[i + 1] == "\n":
                    out.append("\n")
                else:
                    out.append(" ")
                i += 2
                continue
            if text[i : i + len(quote)] == quote:
                out.append(quote)
                i += len(quote)
                break
            out.append("\n" if text[i] == "\n" else " ")
            i += 1
    return "".join(out)


def body_start(text: str, search_from: int) -> int:
    """First `{` at parenthesis depth 0, skipping parameter lists."""
    depth = 0
    for i in range(search_from, len(text)):
        ch = text[i]
        if ch in "([":
            depth += 1
        elif ch in ")]":
            depth = max(0, depth - 1)
        elif ch == "{" and depth == 0:
            return i
        elif ch == ";" and depth == 0:
            return -1
    return -1


def match_block(text: str, open_index: int) -> int:
    """Index just past the brace matching the one at `open_index`."""
    depth = 0
    for i in range(open_index, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return i + 1
    return len(text)


def matching_paren(text: str, open_index: int) -> int:
    depth = 0
    for i in range(open_index, len(text)):
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
            if depth == 0:
                return i
    return -1


def split_top_level(text: str) -> list[str]:
    parts: list[str] = []
    depth = 0
    current = ""
    for ch in text:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == "," and depth == 0:
            parts.append(current)
            current = ""
            continue
        current += ch
    if current.strip():
        parts.append(current)
    return parts


# ---------------------------------------------------------------------------
# Indexing
# ---------------------------------------------------------------------------


def declarations_in(body: str) -> set[str]:
    return {match.group(1) for match in MEMBER_RE.finditer("\n" + body)}


def index_library() -> tuple[dict[str, set[str]], list[tuple[str, int, int, Path]]]:
    members: dict[str, set[str]] = {}
    spans: list[tuple[str, int, int, Path]] = []

    for path in sorted(LIB.rglob("*.dart")):
        text = strip_comments(path.read_text())
        for pattern in (CLASS_RE, ENUM_RE):
            for match in pattern.finditer(text):
                brace = body_start(text, match.end())
                if brace == -1:
                    continue
                end = match_block(text, brace)
                body = text[brace + 1 : end - 1]
                bucket = members.setdefault(match.group(1), set())
                bucket.update(declarations_in(body))
                if pattern is ENUM_RE:
                    for token in split_top_level(body):
                        token = token.strip().split("(")[0].strip()
                        if re.fullmatch(r"[a-z_]\w*", token):
                            bucket.add(token)
                spans.append((match.group(1), brace, end, path))
        for match in EXTENSION_RE.finditer(text):
            brace = body_start(text, match.end())
            if brace == -1:
                continue
            end = match_block(text, brace)
            members.setdefault(match.group(2), set()).update(
                declarations_in(text[brace + 1 : end - 1])
            )
    return members, spans


def constructor_signature(body: str, class_name: str) -> tuple[int, set[str], int] | None:
    """(positional count, named params, offset inside `body`) of the ctor."""
    pattern = re.compile(r"(?:const\s+|factory\s+)*\b" + re.escape(class_name) + r"\s*\(")
    for match in pattern.finditer(body):
        open_paren = body.find("(", match.start())
        close = matching_paren(body, open_paren)
        if close == -1:
            continue
        params = body[open_paren + 1 : close]
        named: set[str] = set()
        positional = 0
        brace_start = params.find("{")
        brace_end = params.rfind("}")
        bare = params
        if brace_start != -1 and brace_end > brace_start:
            bare = params[:brace_start] + params[brace_end + 1 :]
            for part in split_top_level(params[brace_start + 1 : brace_end]):
                part = re.sub(r"^(?:required\s+|covariant\s+)+", "", part.strip())
                if not part:
                    continue
                this_match = re.match(r"(?:this|super)\.(\w+)", part)
                if this_match:
                    named.add(this_match.group(1))
                    continue
                head = part.split("=")[0].strip()
                colon_match = re.match(r"([a-zA-Z_]\w*)\s*:", head)
                if colon_match:
                    named.add(colon_match.group(1))
                    continue
                identifiers = re.findall(r"[a-zA-Z_]\w*", head)
                if identifiers:
                    named.add(identifiers[-1])
        for part in split_top_level(bare):
            if part.strip():
                positional += 1
        return positional, named, match.start() + match.group(0).find(class_name)
    return None


# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------


def inferred_types(segment: str) -> dict[str, str]:
    types: dict[str, str] = {}
    for match in WATCH_RE.finditer(segment):
        types[match.group("name")] = match.group("generic")
    for match in DECL_RE.finditer(segment):
        types.setdefault(match.group("name"), match.group("type"))
    return types


def check_members(
    path: Path,
    text: str,
    start: int,
    end: int,
    members: dict[str, set[str]],
    problems: list[str],
) -> None:
    types = inferred_types(text[start:end])
    if not types:
        return
    line_offset = text.count("\n", 0, start)
    for local_line, line in enumerate(text[start:end].splitlines(), 1):
        for match in MEMBER_USE_RE.finditer(line):
            receiver, member = match.group(1), match.group(2)
            if receiver in IGNORED_RECEIVERS:
                continue
            type_name = types.get(receiver)
            if not type_name or type_name in SKIP_TYPES or type_name not in members:
                continue
            if member in members[type_name] or member in UNIVERSAL:
                continue
            problems.append(
                f"{path.relative_to(ROOT)}:{line_offset + local_line}: "
                f"`{receiver}.{member}` is not declared by {type_name}"
            )


def check_constructors(
    texts: dict[Path, str], spans: list[tuple[str, int, int, Path]]
) -> list[str]:
    problems: list[str] = []
    signatures: dict[str, tuple[int, set[str]]] = {}
    declaration_sites: set[tuple[Path, int]] = set()

    for path, text in texts.items():
        for name, start, end, span_path in spans:
            if span_path != path:
                continue
            signature = constructor_signature(text[start:end], name)
            if signature is None:
                continue
            positional, named, offset = signature
            signatures.setdefault(name, (positional, named))
            declaration_sites.add((path, start + offset))

    for path, raw in texts.items():
        text = blank_strings(raw)
        for match in CALL_RE.finditer(text):
            name = match.group(1)
            if name not in signatures or name in SKIP_ARG_CLASSES:
                continue
            if (path, match.start()) in declaration_sites:
                continue
            close = matching_paren(text, match.end() - 1)
            if close == -1:
                continue
            args = split_top_level(text[match.end() : close])
            positional_allowed, named_allowed = signatures[name]
            positional_seen = 0
            line = text.count("\n", 0, match.start()) + 1
            for arg in args:
                arg = arg.strip()
                if not arg:
                    continue
                named_match = re.match(r"([a-zA-Z_]\w*)\s*:(?!:)", arg)
                if named_match:
                    if named_match.group(1) not in named_allowed:
                        problems.append(
                            f"{path.relative_to(ROOT)}:{line}: {name}(...) has no "
                            f"named parameter `{named_match.group(1)}`"
                        )
                elif not arg.startswith("super."):
                    positional_seen += 1
            if positional_seen > positional_allowed:
                problems.append(
                    f"{path.relative_to(ROOT)}:{line}: {name}(...) got "
                    f"{positional_seen} positional argument(s), declared {positional_allowed}"
                )
    return problems


def main() -> int:
    members, spans = index_library()
    texts = {
        path: strip_comments(path.read_text())
        for root in (LIB, ROOT / "test")
        for path in sorted(root.rglob("*.dart"))
        if path.exists()
    }
    problems: list[str] = []

    for path, text in texts.items():
        own_spans = sorted(
            ((start, end) for name, start, end, span_path in spans if span_path == path),
            key=lambda span: span[0],
        )
        cursor = 0
        for start, end in own_spans:
            check_members(path, text, cursor, start, members, problems)
            check_members(path, text, start, end, members, problems)
            cursor = end
        check_members(path, text, cursor, len(text), members, problems)

    problems.extend(check_constructors(texts, spans))

    if problems:
        for problem in problems:
            print("  " + problem)
        print(f"\n{len(problems)} possible API mismatch(es)")
        return 1

    print(f"API check: clean ({len(texts)} dart files, {len(spans)} class/enum bodies)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
