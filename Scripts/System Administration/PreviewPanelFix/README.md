# PreviewPanelFix

Windows Explorer won't show PDF (or other file) previews for files on mapped network drives by default. The reason is that Windows doesn't trust the network path, so the preview handler refuses to render it. This set of scripts fixes that by adding your mapped drive servers to the Local Intranet trusted zone — the same thing you'd do manually through Internet Options.

## How it works

For IP-based servers the script writes to:
```
HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges\RangeN
  *      REG_DWORD  1
  :Range REG_SZ     192.168.x.x
```

For hostname-based servers it writes to:
```
HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\servername
  *  REG_DWORD  1
```

This matches exactly what Internet Options writes when you add a site manually. No admin rights needed since it's all HKCU.

## Usage

Double-click `PreviewPanelFix.bat` — it handles the execution policy bypass automatically.

Dry run to preview changes without writing anything:
```powershell
powershell.exe -ExecutionPolicy Bypass -File "PreviewPanelFix.ps1" -WhatIf
```

After running, open a new Explorer window and try the preview pane on a file from the mapped drive.
If it still doesn't work, sign out and back in to flush the zone cache.

## PDF preview handler requirement

The zone trust alone isn't enough — you also need a PDF viewer that registers a Windows Explorer preview handler. **Microsoft Edge does not do this** even when set as the default PDF app; this is a known limitation. The script will warn you if no working handler is found.

Working options (all free):
- **Adobe Acrobat Reader**
- **Foxit PDF Reader**
- **PDF-XChange Viewer**

## Files

| File | Purpose |
|------|---------|
| `PreviewPanelFix.bat` | Double-click launcher |
| `PreviewPanelFix.ps1` | Main script — detects mapped drives, writes zone entries, checks PDF handler |
| `PreviewPanelFixCleanup.bat` | Double-click launcher for cleanup |
| `PreviewPanelFixCleanup.ps1` | Removes zone entries — see warning below |
| `PreviewPanelFixDiag.ps1` | Diagnostic script — run and paste output if something isn't working |

## Cleanup script

`PreviewPanelFixCleanup.ps1` has two modes:

- **No flag** — removes entries for your **currently mapped drives only**. Manually added sites for other servers are left untouched. Re-run `PreviewPanelFix.bat` afterwards to re-add them cleanly.
- **`-Legacy`** — removes leftover entries from old broken versions of this script (the `<ip>`-named format). You will almost never need this.
