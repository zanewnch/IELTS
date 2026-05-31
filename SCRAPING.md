# IELTS Bro Scraping Notes

This project includes a small Playwright-based scraper for personal IELTS study indexing.

## Boundaries

- Use the scraper only for personal study and local notes.
- Do not redistribute IELTS Bro content, audio, explanations, paid materials, or copied question banks.
- Do not bypass login, payment, rate limits, or access controls.
- Keep delays enabled when collecting more than a few records.
- Prefer storing source links, metadata, and your own study notes instead of republishing full third-party materials.

## Setup

```powershell
python -m pip install -r requirements.txt
python -m playwright install chromium
```

If your machine uses `python3` instead of `python`, use:

```powershell
python3 -m pip install -r requirements.txt
python3 -m playwright install chromium
```

## Examples

Fetch a small sample from the public question-bank page:

```powershell
python scripts/scrape_ieltsbro.py --limit-per-list 5
```

Or:

```powershell
python3 scripts/scrape_ieltsbro.py --limit-per-list 5
```

On Windows PowerShell, you can also use the wrapper, which tries `python` first and then `python3`:

```powershell
.\scripts\run_scrape_ieltsbro.ps1 --limit-per-list 5
```

Fetch all currently visible oral topic lists:

```powershell
python scripts/scrape_ieltsbro.py --all --delay 1.5
```

Run with a visible browser window:

```powershell
python scripts/scrape_ieltsbro.py --headed --limit-per-list 3
```

The default output path is:

```text
data/external/ieltsbro/oral_topics.json
```

## Current Scope

The script currently collects public oral-topic list data exposed by the question-bank page, including Part 1 and Part 2/3 topic list entries. It does not crawl paid pages, user-only pages, media files, or hidden content.
