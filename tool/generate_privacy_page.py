"""Builds docs/index.html from lib/features/legal/privacy_policy_content.dart.

Run from the project root after changing the in-app policy:
    python3 tool/generate_privacy_page.py
"""

import html
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'lib/features/legal/privacy_policy_content.dart'
TARGET = ROOT / 'docs/index.html'

STRING = re.compile(r"'((?:[^'\\]|\\.)*)'")


def dart_string(raw):
    return raw.replace("\\'", "'").replace('\\n', '\n').replace('\\\\', '\\')


def parse_language(source, name):
    start = source.index(f'static const {name} = PrivacyPolicyText(')
    end = source.index('\n  );', start)
    block = source[start:end]
    title = dart_string(re.search(r"title: '((?:[^'\\]|\\.)*)'", block).group(1))
    effective = dart_string(re.search(r"effective: '((?:[^'\\]|\\.)*)'", block).group(1))
    sections = []
    for match in re.finditer(r'PolicySection\((.*?)\n      \),', block, re.S):
        parts = [dart_string(s) for s in STRING.findall(match.group(1))]
        sections.append((parts[0], ''.join(parts[1:])))
    return title, effective, sections


def render_body(text):
    out = []
    bullets = []
    for line in text.split('\n'):
        if line.startswith('• '):
            bullets.append(f'<li>{html.escape(line[2:])}</li>')
            continue
        if bullets:
            out.append('<ul>' + ''.join(bullets) + '</ul>')
            bullets = []
        if line.strip():
            out.append(f'<p>{html.escape(line)}</p>')
    if bullets:
        out.append('<ul>' + ''.join(bullets) + '</ul>')
    return '\n'.join(out)


def render_language(source, name, code, direction, label):
    title, effective, sections = parse_language(source, name)
    body = '\n'.join(
        f'<h2>{html.escape(t)}</h2>\n{render_body(b)}' for t, b in sections
    )
    return (
        f'<section id="{code}" lang="{code}" dir="{direction}" aria-label="{label}">\n'
        f'<h1>{html.escape(title)}</h1>\n<p class="date">{html.escape(effective)}</p>\n'
        f'{body}\n</section>'
    )


def main():
    source = SOURCE.read_text(encoding='utf-8')
    languages = [
        ('kurdish', 'ckb', 'rtl', 'کوردی'),
        ('arabic', 'ar', 'rtl', 'العربية'),
        ('english', 'en', 'ltr', 'English'),
    ]
    nav = ' · '.join(f'<a href="#{code}">{label}</a>' for _, code, _, label in languages)
    sections = '\n<hr>\n'.join(render_language(source, *lang) for lang in languages)
    page = f"""<!doctype html>
<html lang="ckb">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>ZankoSwap Privacy Policy &amp; Terms</title>
<style>
:root {{ --bg: #ffffff; --text: #1f2937; --muted: #6b7280; --accent: #6d28d9; --rule: #e5e7eb; }}
@media (prefers-color-scheme: dark) {{
  :root {{ --bg: #0f1020; --text: #e5e7eb; --muted: #9ca3af; --accent: #a78bfa; --rule: #2a2b45; }}
}}
body {{ margin: 0; background: var(--bg); color: var(--text);
  font: 16px/1.7 system-ui, -apple-system, "Segoe UI", Tahoma, sans-serif; }}
main {{ max-width: 760px; margin: 0 auto; padding: 24px 16px 64px; }}
nav {{ text-align: center; font-weight: 600; margin-bottom: 24px; }}
a {{ color: var(--accent); }}
h1 {{ font-size: 1.6rem; margin: 8px 0 0; }}
h2 {{ font-size: 1.15rem; margin: 28px 0 6px; }}
.date {{ color: var(--muted); margin-top: 4px; }}
hr {{ border: 0; border-top: 1px solid var(--rule); margin: 48px 0; }}
ul {{ padding-inline-start: 22px; }}
</style>
</head>
<body>
<main>
<nav>{nav}</nav>
{sections}
</main>
</body>
</html>
"""
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    TARGET.write_text(page, encoding='utf-8')
    print(f'Wrote {TARGET.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
