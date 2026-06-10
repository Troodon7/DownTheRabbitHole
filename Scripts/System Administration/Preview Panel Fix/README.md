# Preview Panel Fix

Ever open Windows Explorer on a network share and the preview panel just stares at you blankly for PDFs? This is why — Windows doesn't trust the file path because the network server isn't in your Local Intranet zone, so the PDF handler refuses to render it.

This fixes that. It scans all your mapped drives, pulls the server name (or IP) out of each UNC path, and writes the right registry entries under `HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap` so Windows treats those locations as Local Intranet. No admin rights needed since it's all HKCU.

## Usage

Just double-click `Preview Panel Fix.bat` — it handles the execution policy bypass and calls the script automatically.

If you want to see what it would change before it touches anything:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "Preview Panel Fix.ps1" -WhatIf
```

Changes take effect for new Explorer windows immediately. If previews still aren't showing after running it, sign out and back in to flush the zone cache.

## Files

- **Preview Panel Fix.bat** — double-click launcher, passes arguments through so `-WhatIf` works
- **Preview Panel Fix.ps1** — the actual script; handles both hostnames and IPs (they go into different registry paths)
