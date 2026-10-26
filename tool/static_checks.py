#!/usr/bin/env python3
"""Lightweight consistency checks for the Flutter sources.

The project is developed in an environment without the Flutter SDK, so this
script guards the most common compile-time mistakes that a pure Dart parser
cannot catch:

* broken relative imports,
* missing AppStrings translations (localization is hand written),
* references to unknown AppConstants / RadarColors / AppTheme / Formatters
  members,
* `strings.*` usages that are not declared in the AppStrings interface.

Usage:  python3 tool/static_checks.py
Exit code 0 = all good.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
errors: list[str] = []


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def dart_files() -> list[Path]:
    return sorted(LIB.rglob("*.dart"))


# ---------------------------------------------------------------------------
# 1. Relative imports resolve to real files
# ---------------------------------------------------------------------------
def check_imports() -> None:
    pattern = re.compile(r"^\s*import\s+'([^']+)';", re.M)
    for path in dart_files():
        for target in pattern.findall(read(path)):
            if target.startswith("package:") or target.startswith("dart:"):
                continue
            resolved = (path.parent / target).resolve()
            if not resolved.exists():
                errors.append(f"{path.relative_to(ROOT)}: import not found -> {target}")


# ---------------------------------------------------------------------------
# 2. Static members exist
# ---------------------------------------------------------------------------
def class_statics(source: str, class_name: str) -> set[str]:
    match = re.search(rf"class {class_name} \{{(.*?)\n\}}", source, re.S)
    if not match:
        errors.append(f"class {class_name} not found")
        return set()
    body = match.group(1)
    names: set[str] = set()
    for line in body.splitlines():
        if "static" in line:
            member = re.search(r"static\s+(?:const\s+)?[\w<>?,\s\.\[\]]+?\s(\w+)\s*[=(;]", line)
            if member:
                names.add(member.group(1))
    return names


def check_static_usage(class_name: str, names: set[str]) -> None:
    pattern = re.compile(rf"{class_name}\.(\w+)")
    for path in dart_files():
        for used in pattern.findall(read(path)):
            if used.startswith("_"):
                continue
            if used not in names:
                errors.append(
                    f"{path.relative_to(ROOT)}: {class_name}.{used} is not defined"
                )


# ---------------------------------------------------------------------------
# 3. Localization completeness + usage
# ---------------------------------------------------------------------------
def check_strings() -> None:
    source = read(LIB / "core/localization/app_strings.dart")
    abstract = re.search(r"abstract class AppStrings \{(.*?)\n\}", source, re.S)
    if not abstract:
        errors.append("abstract AppStrings not found")
        return
    body = abstract.group(1)
    getters = set(re.findall(r"String get (\w+);", body))
    methods = set(re.findall(r"String (\w+)\([^)]*\);", body))
    interface = getters | methods

    for implementation in ("AppStringsEn", "AppStringsAr"):
        block = re.search(
            rf"class {implementation} extends AppStrings \{{(.*?)\n\}}\n", source, re.S
        )
        if not block:
            errors.append(f"{implementation} not found")
            continue
        impl_body = block.group(1)
        impl_getters = set(re.findall(r"String get (\w+)", impl_body))
        impl_methods = set(re.findall(r"String (\w+)\(", impl_body))
        missing = interface - (impl_getters | impl_methods)
        extra = (impl_getters | impl_methods) - interface - {"hashCode", "runtimeType", "toString", "noSuchMethod"}
        if missing:
            errors.append(f"{implementation}: missing {sorted(missing)}")
        if extra:
            errors.append(f"{implementation}: not in interface {sorted(extra)}")

    usage = re.compile(r"\bstrings\.(\w+)")
    allowed_extra = {"hashCode", "runtimeType", "toString", "noSuchMethod"}
    for path in dart_files():
        for used in usage.findall(read(path)):
            if used not in interface and used not in allowed_extra:
                errors.append(
                    f"{path.relative_to(ROOT)}: strings.{used} is not declared"
                )


# ---------------------------------------------------------------------------
# 4. Focused checks
# ---------------------------------------------------------------------------
def main() -> int:
    check_imports()

    constants = class_statics(read(LIB / "core/constants/app_constants.dart"), "AppConstants")
    colors = class_statics(read(LIB / "core/theme/radar_colors.dart"), "RadarColors")
    theme = class_statics(read(LIB / "core/theme/app_theme.dart"), "AppTheme")
    formatters = class_statics(read(LIB / "core/utils/formatters.dart"), "Formatters")
    pulse = class_statics(read(LIB / "domain/signal/proximity_pulse.dart"), "ProximityPulse")
    stable = class_statics(read(LIB / "core/utils/stable_angle.dart"), "StableAngle")

    check_static_usage("AppConstants", constants)
    check_static_usage("RadarColors", colors)
    check_static_usage("AppTheme", theme)
    check_static_usage("Formatters", formatters)
    check_static_usage("ProximityPulse", pulse)
    check_static_usage("StableAngle", stable)

    check_strings()

    if errors:
        print(f"✗ {len(errors)} issue(s):")
        for issue in errors:
            print("  -", issue)
        return 1
    print("✓ all static checks passed "
          f"({len(dart_files())} dart files, "
          f"{len(constants)} constants, {len(colors)} colours)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
