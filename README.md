# Cookie — daily immutable fortune

This Chrome extension shows a single fortune-cookie style quote per day. The quote sequence is fixed at install time and cannot be changed unless you remove and reinstall the extension.

Install (developer mode):

1. Open Chrome and go to `chrome://extensions`.
2. Enable "Developer mode" (top-right).
3. Click "Load unpacked" and select the `Cookie/` folder.
4. Click the extension icon — it will show today's quote.

Notes:
- The extension stores an `installTime` and a random `seed` in `chrome.storage.local` at install; this makes the quote progression deterministic and immutable across normal usage.
- To reset the daily sequence, remove the extension and load it again (reinstall).
- The extension only uses local storage; no external network calls are made except to load the bundled `quotes.json`.

Packaging for Chrome Web Store

1. Create the distributable zip:

```bash
cd Cookie
./package.sh
```

2. Prepare assets for the Web Store:
- Icons: `icons/icon16.svg`, `icons/icon48.svg`, `icons/icon128.svg` (already present).
- Screenshots: replace the placeholder files in `store/screenshots/` with real PNG/JPG screenshots sized per Web Store requirements.
- Privacy policy: see `store/privacy_policy.md` and provide a public URL if required by the store.

3. Use the generated `cookie-extension.zip` (created at the project root) to upload to the Chrome Web Store developer dashboard. Fill in the listing fields using `store/listing.md` as a draft.

Developer utilities

- `scripts/dedupe_quotes.js` — removes duplicate quotes (exact-text duplicates) from `quotes.json`.
- `scripts/preview_quote.js` — preview which quote would show for a given install timestamp and seed. Example:

```bash
node scripts/preview_quote.js 1660000000000 12345
```

Privacy & data

- Cookie stores only `installTime` and a local `seed` in `chrome.storage.local`.
- No telemetry, analytics, or external servers are contacted.
Privacy & data

- The extension stores only `installTime` and a local `seed` in `chrome.storage.local`.
- No telemetry, analytics, or external servers are contacted.
1. Open the popup and enable the "Allow analytics (opt-in)" toggle.
2. Provide your GA4 `Measurement ID` (G-XXXX) and an API secret.

To disable analytics, turn the toggle off in the popup; stored credentials remain but events will not be sent unless enabled.


Files of interest:

- `manifest.json` — extension manifest and icons
- `background.js` — sets `installInfo` at install/startup
- `popup.html`, `popup.js`, `quotes.json` — popup UI and quote data
