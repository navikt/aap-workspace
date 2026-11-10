#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["markdown", "weasyprint"]
# ///
"""Convert Markdown to PDF with clickable links: uv run md-to-pdf.py report.md."""

import argparse
import html
from pathlib import Path
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("markdown", type=Path, help="Markdown file to convert")
    args = parser.parse_args()

    try:
        import markdown
        from weasyprint import HTML
    except ImportError as error:
        parser.exit(
            1,
            f"Missing PDF dependency: {error}\n"
            "Install in your Python environment: python3 -m pip install markdown weasyprint\n",
        )

    source = args.markdown.resolve(strict=True)
    output = source.with_suffix(".pdf")
    content = markdown.markdown(
        source.read_text(encoding="utf-8"), extensions=["tables", "fenced_code"]
    )
    document = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>{html.escape(source.stem)}</title>
<style>
@page {{ size: A4 landscape; margin: 15mm; }}
body {{ font-family: sans-serif; font-size: 10pt; line-height: 1.4; }}
h1 {{ font-size: 18pt; }}
table {{ width: 100%; border-collapse: collapse; table-layout: fixed; }}
th, td {{ border: 1px solid #ccc; padding: 6px; text-align: left;
          vertical-align: top; overflow-wrap: anywhere; }}
thead {{ display: table-header-group; }}
tr {{ break-inside: avoid; }}
a {{ color: #005b9a; text-decoration: underline; }}
pre {{ white-space: pre-wrap; overflow-wrap: anywhere; }}
</style>
</head>
<body>{content}</body>
</html>"""
    with tempfile.TemporaryDirectory(dir=output.parent) as temporary:
        temporary_pdf = Path(temporary) / output.name
        HTML(string=document, base_url=str(source.parent)).write_pdf(temporary_pdf)
        temporary_pdf.replace(output)
    print(output)


if __name__ == "__main__":
    main()
