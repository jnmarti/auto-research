#!/usr/bin/env python3
"""Generate the public journal catalog and release files for GitHub Pages."""

import argparse
import json
import re
import sys
from datetime import date
from html import escape
from pathlib import Path
from urllib.parse import unquote, urlsplit

from markdown_it import MarkdownIt


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
SLUG = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*")
FILE_NAME = re.compile(r"[a-zA-Z0-9][a-zA-Z0-9._-]*")


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def release_file(directory, name):
    if not FILE_NAME.fullmatch(name):
        raise ValueError(f"Expected a file name in {directory}: {name}")
    path = directory / name
    if path.is_symlink() or not path.is_file():
        raise ValueError(f"Missing release file or unsupported symlink: {path}")
    return path


def render_note(source, summary, published, links):
    markdown = MarkdownIt("commonmark", {"html": False})
    tokens = markdown.parse(source.read_text(encoding="utf-8"))
    if len(tokens) < 3 or tokens[0].type != "heading_open" or tokens[0].tag != "h1":
        raise ValueError(f"Start the note with a level-one heading: {source}")
    title = tokens[1].content
    for token in tokens[3:]:
        for child in token.children or []:
            if child.type not in {"link_open", "image"}:
                continue
            attr = "href" if child.type == "link_open" else "src"
            value = child.attrGet(attr)
            target = urlsplit(value)
            if target.scheme in {"https", "http"} and target.netloc:
                continue
            if target.scheme or target.netloc or not target.path or target.path.startswith("/"):
                raise ValueError(f"Unsupported link in {source.name}: {value}")
            public = links.get((source.parent / unquote(target.path)).resolve())
            if not public or (child.type == "image" and public.startswith("../#")):
                raise ValueError(f"Link points outside the public release in {source.name}: {value}")
            child.attrSet(attr, public)
    body = markdown.renderer.render(tokens[3:], markdown.options, {})
    display_date = f"{published:%B} {published.day}, {published.year}"
    return title, f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="{escape(summary)}">
  <title>{escape(title)} | Journal of AI Labor Markets</title>
  <link rel="icon" href="../assets/journal-cover.webp" type="image/webp">
  <link rel="stylesheet" href="../journal.css">
</head>
<body>
  <header class="frame note-masthead">
    <a href="../">Journal of AI Labor Markets</a>
  </header>
  <main class="frame">
    <article class="secondary-page note-page">
      <a href="../#notes">Research Notes</a>
      <h1>{escape(title)}</h1>
      <p class="note-date"><time datetime="{published.isoformat()}">{display_date}</time></p>
      <div class="note-body">
{body}      </div>
    </article>
  </main>
</body>
</html>
"""


def build():
    outputs = {}
    public_links = {}
    issues = {}
    working_papers = []

    for manifest in sorted((ROOT / "research").glob("*/journal.json")):
        directory = manifest.parent
        slug = directory.name
        if directory.is_symlink() or manifest.is_symlink() or not SLUG.fullmatch(slug):
            raise ValueError(f"Invalid paper release directory: {directory}")
        paper = read_json(manifest)
        article = {key: paper[key] for key in ("title", "agents", "abstract")}
        if not all(isinstance(article[key], str) and article[key].strip() for key in ("title", "abstract")):
            raise ValueError(f"Expected a title and abstract in {manifest}")
        agents = article["agents"]
        if not isinstance(agents, list) or not agents or not all(isinstance(agent, str) and agent.strip() for agent in agents):
            raise ValueError(f"Expected AI-agent bylines in {manifest}")

        article.update(id=slug, date=date.fromisoformat(paper["date"]).isoformat())
        pdf = release_file(directory, paper["pdf"])
        if pdf.suffix.lower() != ".pdf" or not pdf.read_bytes().startswith(b"%PDF-"):
            raise ValueError(f"Expected a PDF: {pdf}")
        for field, source in (("pdf", pdf), ("replication", paper.get("replication"))):
            if not source:
                continue
            path = source if isinstance(source, Path) else release_file(directory, source)
            target = Path("papers") / slug / path.name
            article[field] = target.as_posix()
            outputs[target] = path.read_bytes()
            public_links[path.resolve()] = f"../#paper-{slug}" if field == "pdf" else f"../{target.as_posix()}"
        public_links[(directory / "README.md").resolve()] = f"../#paper-{slug}"
        public_links[directory.resolve()] = f"../#paper-{slug}"

        if "issue" not in paper:
            working_papers.append(article)
            continue
        issue = paper["issue"]
        volume, number = (issue[key] for key in ("volume", "number"))
        if any(type(value) is not int or value < 1 for value in (volume, number)):
            raise ValueError(f"Expected positive issue and volume numbers in {manifest}")
        issue_date = date.fromisoformat(issue["date"]).isoformat()
        record = issues.setdefault((volume, number), dict(volume=volume, number=number, date=issue_date, articles=[]))
        if record["date"] != issue_date:
            raise ValueError(f"Inconsistent date for volume {volume}, issue {number}")
        if "pages" in paper:
            article["pages"] = paper["pages"]
        record["articles"].append(article)

    note_sources = []
    notes_manifest = ROOT / "blog" / "journal-notes.json"
    if notes_manifest.is_symlink():
        raise ValueError(f"Unsupported symlink: {notes_manifest}")
    for note in read_json(notes_manifest):
        source = release_file(notes_manifest.parent, note["source"])
        if source.suffix != ".md" or not SLUG.fullmatch(source.stem) or source.resolve() in public_links:
            raise ValueError(f"Invalid or duplicate note source: {source}")
        public_links[source.resolve()] = f"./{source.stem}.html"
        note_sources.append((source, note))

    notes = []
    for source, note in note_sources:
        published = date.fromisoformat(note["date"])
        title, html = render_note(source, note["summary"], published, public_links)
        path = Path("notes") / f"{source.stem}.html"
        outputs[path] = html.encode("utf-8")
        notes.append(dict(title=title, date=published.isoformat(), summary=note["summary"], url=path.as_posix()))

    catalog = {
        "issues": [issues[key] for key in sorted(issues, reverse=True)],
        "workingPapers": sorted(working_papers, key=lambda paper: paper["date"], reverse=True),
        "notes": sorted(notes, key=lambda note: note["date"], reverse=True),
    }
    outputs[Path("catalog.json")] = (json.dumps(catalog, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    return outputs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Check that the committed site matches its release sources.")
    args = parser.parse_args()
    outputs = build()
    generated = {
        path.relative_to(DOCS)
        for directory in (DOCS / "papers", DOCS / "notes")
        for path in directory.rglob("*")
        if path.is_file() or path.is_symlink()
    }
    obsolete = generated - outputs.keys()
    changed = {
        path for path, content in outputs.items()
        if not (DOCS / path).is_file() or (DOCS / path).read_bytes() != content
    }
    if args.check:
        for path in sorted(changed | obsolete):
            print(f"Out of date: docs/{path}", file=sys.stderr)
        return int(bool(changed or obsolete))

    for path in sorted(changed):
        output = DOCS / path
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_bytes(outputs[path])
    for path in sorted(obsolete):
        (DOCS / path).unlink()
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (KeyError, OSError, TypeError, ValueError) as error:
        sys.exit(str(error))
