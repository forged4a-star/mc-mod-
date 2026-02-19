# Windows 11 - 1 click install for CurseForge

If "it is not working", use this exact flow.

## Fastest way
1. Open this project folder.
2. Double click `install_to_curseforge.bat`.
3. Wait for `Success!`.
4. Open CurseForge and click **Play**.

---

## If you want to run in PowerShell
```powershell
.\install_to_curseforge.ps1
```

That auto-uses:
- instance name: `abg22`
- instance root: `%USERPROFILE%\curseforge\minecraft\Instances`

So it targets:
`C:\Users\<YourName>\curseforge\minecraft\Instances\abg22\mods`

---

## If your instance has a different name
```powershell
.\install_to_curseforge.ps1 -InstanceName "YOUR_INSTANCE_NAME"
```

## If auto path still fails
1. In CurseForge: open your instance -> `...` -> **Open Folder**.
2. Copy that path from Explorer.
3. Run:
```powershell
.\install_to_curseforge.ps1 -InstancePath "PASTE_FULL_INSTANCE_PATH_HERE"
```

## If you already built and only need copy
```powershell
.\install_to_curseforge.ps1 -SkipBuild
```

---

## Common error fixes
- **"gradlew.bat not found"**
  - In project folder run: `gradle wrapper`
- **Build failed**
  - Make sure Java 21 is installed.
- **Mods folder not found**
  - Use `-InstancePath` with the exact path from CurseForge "Open Folder".
