#!/usr/bin/env python3
"""Merge Localization/translations.json into the String Catalog (state: needs_review)."""
import json
import pathlib
import sys

LANGUAGES = ["es", "fr", "de", "it", "pt-BR", "ja", "zh-Hans", "ko"]
root = pathlib.Path(__file__).resolve().parent.parent
translations = json.loads((root / "Localization/translations.json").read_text(encoding="utf-8"))
catalog_path = root / "MicDrop/Resources/Localizable.xcstrings"
catalog = json.loads(catalog_path.read_text(encoding="utf-8"))

incomplete = [key for key, langs in translations.items() if sorted(langs) != sorted(LANGUAGES)]
if incomplete:
    sys.exit(f"Missing languages for: {incomplete}")

strings = catalog.setdefault("strings", {})
for key, langs in translations.items():
    localizations = strings.setdefault(key, {}).setdefault("localizations", {})
    for lang, value in langs.items():
        localizations[lang] = {"stringUnit": {"state": "needs_review", "value": value}}

catalog_path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"Merged {len(translations)} strings × {len(LANGUAGES)} languages")
