Privacy Policy — Cookie Extension

Last updated: 2026-08-31

1) Summary
Cookie is a local Chrome extension that displays one quote per day. It does not collect personal data and does not send analytics or tracking data to external servers.

2) Data Stored Locally
Cookie stores the following values in `chrome.storage.local`:
- `installTime`: installation timestamp
- `seed`: random value used to select the daily quote sequence
- `autoOpen`: user preference to auto-open the daily popup
- `lastShownDate`: date key to avoid repeated same-day popup/notification

These values are used only for extension functionality and remain on the user's device.

3) Data Transmission
Cookie does not transmit personal data or usage analytics to remote services.

4) Third-Party Services
None. Cookie does not use external analytics, ads, or remote storage.

5) Permissions Used
- `storage`: save local extension preferences/state
- `alarms`: schedule daily checks (startup/midnight behavior)
- `notifications`: show daily notification fallback when popup cannot auto-open

6) Data Retention and Deletion
Local extension data remains until the user:
- uninstalls the extension, or
- clears extension/browser storage manually.

Reinstalling creates a new `installTime` and `seed`.

7) Children’s Privacy
Cookie is not designed to collect personal data from children or any users.

8) Changes to This Policy
This policy may be updated when extension behavior changes. The "Last updated" date will reflect revisions.

9) Contact
For privacy questions, contact: carlosluquetrad@gmail.com
