param(
    [string]$InstanceName = "abg22",
    [string]$InstancePath = "",
    [string]$ProjectPath = ".",
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

function Say($text) {
    Write-Host "[dashmod] $text"
}

function Fail($text) {
    throw "[dashmod] $text"
}

$projectFullPath = (Resolve-Path -Path $ProjectPath).Path
Set-Location $projectFullPath

if ([string]::IsNullOrWhiteSpace($InstancePath)) {
    $instanceRoot = Join-Path $env:USERPROFILE "curseforge\\minecraft\\Instances"
    $InstancePath = Join-Path $instanceRoot $InstanceName
}

$modsPath = Join-Path $InstancePath "mods"
if (-not (Test-Path $modsPath)) {
    Fail "Mods folder not found: $modsPath`nOpen CurseForge -> your instance -> ... -> Open Folder, then copy that full path and pass -InstancePath."
}

Say "Using instance: $InstancePath"
Say "Using project:  $projectFullPath"

if (-not $SkipBuild) {
    Say "Step 1/2: Building the mod"

    if (-not (Test-Path ".\\gradlew.bat")) {
        Say "gradlew.bat not found. Trying to generate wrapper..."

        $gradleCmd = Get-Command gradle -ErrorAction SilentlyContinue
        if ($null -eq $gradleCmd) {
            Fail "No gradlew.bat and no global 'gradle' command found. Install Gradle OR add wrapper files (gradlew, gradlew.bat, gradle/wrapper/*)."
        }

        & gradle wrapper
    }

    & .\gradlew.bat build
    if ($LASTEXITCODE -ne 0) {
        Fail "Build failed. Scroll up for the real Gradle error."
    }
}

Say "Step 2/2: Copying jar to mods folder"
$libsPath = Join-Path $projectFullPath "build\\libs"
if (-not (Test-Path $libsPath)) {
    Fail "Build output folder not found: $libsPath"
}

$jar = Get-ChildItem -Path $libsPath -Filter "*.jar" |
    Where-Object {
        $_.Name -notmatch "-sources\\.jar$" -and
        $_.Name -notmatch "-dev\\.jar$" -and
        $_.Name -notmatch "-javadoc\\.jar$"
    } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($null -eq $jar) {
    Fail "No runnable jar found in $libsPath"
}

$targetJarPath = Join-Path $modsPath $jar.Name
Copy-Item -Path $jar.FullName -Destination $targetJarPath -Force

Say "Success!"
Say "Copied: $($jar.Name)"
Say "To:     $modsPath"
Say "You can now click Play in CurseForge."
