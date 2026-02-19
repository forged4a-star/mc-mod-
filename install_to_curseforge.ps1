param(
    [string]$InstancePath = "C:\Users\Fedor Belovolov\curseforge\minecraft\Instances\abg22",
    [string]$ProjectPath = ".",
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

function Say($text) {
    Write-Host "[dashmod] $text"
}

$projectFullPath = (Resolve-Path -Path $ProjectPath).Path
Set-Location $projectFullPath

$modsPath = Join-Path $InstancePath "mods"
if (-not (Test-Path $modsPath)) {
    throw "Mods folder not found: $modsPath"
}

if (-not $SkipBuild) {
    Say "Building mod in: $projectFullPath"

    if (-not (Test-Path ".\\gradlew.bat")) {
        Say "gradlew.bat not found. Trying to generate wrapper with local Gradle..."
        gradle wrapper
    }

    .\gradlew.bat build
}

$libsPath = Join-Path $projectFullPath "build\\libs"
if (-not (Test-Path $libsPath)) {
    throw "Build output folder not found: $libsPath"
}

$jar = Get-ChildItem -Path $libsPath -Filter "*.jar" |
    Where-Object { $_.Name -notmatch "-sources\\.jar$" } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($null -eq $jar) {
    throw "No runnable jar found in $libsPath"
}

$targetJarPath = Join-Path $modsPath $jar.Name
Copy-Item -Path $jar.FullName -Destination $targetJarPath -Force

Say "Done. Copied: $($jar.Name)"
Say "To: $modsPath"
Say "Now launch CurseForge and press Play on instance 'abg22'."
