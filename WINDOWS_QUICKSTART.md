# Windows 11 Quick Start (CurseForge)

This is the easiest way to install the mod into your CurseForge instance.

## 1) Open Terminal in this project folder
Use PowerShell or Windows Terminal in the folder that has:
- `install_to_curseforge.ps1`
- `install_to_curseforge.bat`

## 2) Run one command
### Option A (double-click friendly)
```bat
install_to_curseforge.bat
```

### Option B (PowerShell)
```powershell
.\install_to_curseforge.ps1
```

By default, the script uses your instance path from the screenshot:
`C:\Users\Fedor Belovolov\curseforge\minecraft\Instances\abg22`

## 3) Play
After the script says `Done. Copied: ...jar`, open CurseForge and click **Play** on `abg22`.

---

## If your instance name changes
Run with a custom path:

```powershell
.\install_to_curseforge.ps1 -InstancePath "C:\Users\Fedor Belovolov\curseforge\minecraft\Instances\YOUR_INSTANCE_NAME"
```

## If you already built and only want to copy
```powershell
.\install_to_curseforge.ps1 -SkipBuild
```
