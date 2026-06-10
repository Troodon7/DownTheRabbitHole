# PreviewPanelFix

Ever open Windows Explorer on a network share and the preview panel just stares at you blankly for PDFs? This is why — Windows doesn't trust the file path because the network server isn't in your Local Intranet zone, so the PDF handler refuses to render it.

This fixes that. It scans all your mapped drives, pulls the server name (or IP) out of each UNC path, and writes the right registry entries under `HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains` so Windows treats those locations as Local Intranet. No admin rights needed since it's all HKCU.

## Usage

Double-click `PreviewPanelFix.bat` — it handles the execution policy bypass and calls the script automatically.

Dry run to see what would change before touching anything:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "PreviewPanelFix.ps1" -WhatIf
```

Changes take effect for new Explorer windows immediately. If previews still aren't showing after running it, sign out and back in to flush the zone cache.

## Files

- **PreviewPanelFix.bat** — double-click launcher, passes `-WhatIf` through
- **PreviewPanelFix.ps1** — main script; reads mapped drives from 4 sources, writes to ZoneMap\Domains, auto-cleans any bad Ranges entries from older runs
- **PreviewPanelFixCleanup.bat** — double-click launcher for the cleanup script
- **PreviewPanelFixCleanup.ps1** — removes bad ZoneMap\Ranges entries that show as `:Range:` with a square character in the Local Intranet Sites UI
- **PreviewPanelFixDiag.ps1** — diagnostic script; run this and paste the output if the fix script isn't detecting your drives
