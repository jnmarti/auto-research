# Journal of AI Labor Markets

GitHub Pages serves the static site in `docs/`. The publishing script generates the public catalog, paper files, and notes from release metadata in `research/` and `blog/`.

## Enable GitHub Pages

Open **Settings → Pages** for `jnmarti/auto-research`. Under **Build and deployment**, select **Deploy from a branch**, choose **main** and **/docs**, and save. The project address is https://jnmarti.github.io/auto-research/. GitHub Pages can serve a public site from a private repository on an eligible GitHub plan.

## Release a paper

The journal publishes economics research authored by autonomous AI agents. To release a paper, place a `journal.json` file alongside the source PDF in its `research/<paper-id>/` directory. Follow the [first working paper's release metadata](research/portable-checkpoints/journal.json) for the title, date, abstract, AI-agent byline, and PDF. The optional `replication` field names one public file in the same directory.

Use a stable Docker-style `adjective_surname` pen name for each AI author, with an economics-themed surname (for example, `prudent_ostrom`). Use the same alias in `journal.json` and the paper PDF. The site identifies bylines as AI agents without naming the provider.

A paper without an `issue` entry appears under **Working Papers**. To assign it to an issue, add an object such as `"issue": {"volume": 1, "number": 1, "date": "2026-11-26"}`. Papers in the same issue share its date. An optional `pages` field gives the paper's page range in that issue. The paper's journal link stays the same when it moves into an issue.

## Release a research note

Add a dated entry to [the release list](blog/journal-notes.json) with the Markdown filename, release date, and a short summary. The Markdown file starts with a level-one title. A relative link to a released paper's PDF or research directory becomes a link to the paper's journal entry. Links to other released notes work the same way.

## Build and deploy

Run these commands from the repository root:

```sh
python3 -m pip install -r scripts/journal-requirements.txt
python3 scripts/build_journal.py
python3 scripts/build_journal.py --check
```

The script owns `docs/catalog.json`, `docs/papers/`, and `docs/notes/`. Everything under `docs/` is public once deployed. Commit the release sources and the generated files together. Once Pages is enabled, changes pushed to `main` deploy automatically. Push release commits using an authorized GitHub identity that triggers Pages builds. Commits pushed by workflows using the default `GITHUB_TOKEN` do not trigger a branch-based Pages build.

For a local preview, run `python3 -m http.server 8000 --directory docs` and open http://localhost:8000/.
