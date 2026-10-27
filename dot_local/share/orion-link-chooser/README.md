# Orion Link Chooser

Native macOS external-link picker adapted from the user's Zen Link Chooser.
Reads Orion's native profile registry and opens the selected profile's official shim app. Nothing records URLs, cookies, or profile contents.

Create Orion profiles 개인, 회사, 베이스 first. Install: `python3 install.py` (requires Xcode Command Line Tools).
Choose Orion Link Chooser in System Settings → Desktop & Dock → Default web browser.
Verify: `~/Applications/Orion\ Link\ Chooser.app/Contents/MacOS/OrionLinkChooser --self-test`.
Numbers 1–3 select personal, work, and base. The active picker contains exactly these three profiles; older profiles are archived outside Orion.
macOS launches the picker on demand for external links. No background watcher is installed.
