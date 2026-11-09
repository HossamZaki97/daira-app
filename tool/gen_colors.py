"""Regenerate lib/design/colors.dart from design/identity-v2/design-tokens.json.
Run from the project root: python tool/gen_colors.py"""
import json

t = json.load(open('design/identity-v2/design-tokens.json', encoding='utf-8'))
L = dict(t['color']['light']); L.update(t['color']['status']['light'])
D = dict(t['color']['dark']); D.update(t['color']['status']['dark'])
keys = list(L)


def col(h):
    h = h.lstrip('#')
    return f"Color(0xFF{h.upper()})" if len(h) == 6 else f"Color(0x{h[6:8].upper()}{h[:6].upper()})"


out = ["// Generated from design/identity-v2/design-tokens.json — edit the JSON, then regenerate.",
       "import 'package:flutter/material.dart';", "",
       "/// Color roles of the Daira identity (C1: night navy + amber).",
       "/// Accent is only for the one primary action and round progress; status never uses accent.",
       "@immutable", "class DairaColors extends ThemeExtension<DairaColors> {", "  const DairaColors({"]
out += [f"    required this.{k}," for k in keys] + ["  });", ""]
out += [f"  final Color {k};" for k in keys]
out += ["", "  static const light = DairaColors("] + [f"    {k}: {col(L[k])}," for k in keys] + ["  );", ""]
out += ["  static const dark = DairaColors("] + [f"    {k}: {col(D[k])}," for k in keys] + ["  );", ""]
out += ["  @override", "  DairaColors copyWith() => this;", "", "  @override",
        "  DairaColors lerp(covariant ThemeExtension<DairaColors>? other, double t) {",
        "    if (other is! DairaColors) return this;", "    return DairaColors("]
out += [f"      {k}: Color.lerp({k}, other.{k}, t)!," for k in keys] + ["    );", "  }", "}", ""]
open('lib/design/colors.dart', 'w', encoding='utf-8', newline='\n').write("\n".join(out))
