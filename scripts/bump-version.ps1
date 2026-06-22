<#
.SYNOPSIS
    Bumps the project version in backend/pom.xml and frontend/package.json together,
    updates CHANGELOG.md, and optionally cuts a release branch with an annotated tag.

.PARAMETER Bump
    Force a specific bump type: MAJOR, MINOR, or PATCH.
    If omitted, auto-detects from git log since the last tag using Conventional Commits.

.PARAMETER Apply
    Write the version bump to files (dry-run by default).

.PARAMETER CutRelease
    Implies -Apply. Creates release/x.y.z from the current HEAD, commits the version
    bump files, creates an annotated tag, and pushes both to origin.
    Prints the gh CLI command to enable branch protection.

.PARAMETER Force
    Continue even if pom.xml and package.json versions do not match.

.EXAMPLE
    .\scripts\bump-version.ps1                        # dry-run -- show recommended bump
    .\scripts\bump-version.ps1 -Bump MINOR            # dry-run with override
    .\scripts\bump-version.ps1 -Bump MINOR -Apply     # write version bump to files
    .\scripts\bump-version.ps1 -CutRelease            # bump + release branch + tag
#>
[CmdletBinding()]
param(
    [ValidateSet('MAJOR', 'MINOR', 'PATCH')]
    [string]$Bump,
    [switch]$Apply,
    [switch]$CutRelease,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ROOT        = Split-Path -Parent $PSScriptRoot
$pomPath     = Join-Path $ROOT 'backend\pom.xml'
$pkgPath     = Join-Path $ROOT 'frontend\package.json'
$clPath      = Join-Path $ROOT 'CHANGELOG.md'
$utf8NoBom   = New-Object System.Text.UTF8Encoding $false

# -- Read pom.xml version (skip <parent> block) --------------------------------
$pomLines       = [string[]](Get-Content $pomPath -Encoding utf8)
$pomVersion     = $null
$pomVersionLine = -1
$inParent       = $false

for ($i = 0; $i -lt $pomLines.Count; $i++) {
    if ($pomLines[$i] -match '<parent>')  { $inParent = $true  }
    if ($pomLines[$i] -match '</parent>') { $inParent = $false }
    if (-not $inParent -and $pomLines[$i] -match '<version>(\d+\.\d+\.\d+(?:-[^<]+)?)</version>') {
        $pomVersion     = $Matches[1]
        $pomVersionLine = $i
        break
    }
}

if (-not $pomVersion) {
    Write-Error 'Could not find project <version> in backend/pom.xml'
    exit 1
}

# -- Read package.json version -------------------------------------------------
$pkgRaw     = Get-Content $pkgPath -Raw -Encoding utf8
$pkgVersion = (ConvertFrom-Json $pkgRaw).version

if ($pomVersion -ne $pkgVersion) {
    if (-not $Force) {
        Write-Error "Version mismatch: pom.xml=$pomVersion  package.json=$pkgVersion`nFix manually or use -Force."
        exit 1
    }
    Write-Warning "Version mismatch (pom=$pomVersion pkg=$pkgVersion) -- continuing with -Force."
}

$currentVersion = $pomVersion

# -- Commits since last tag ----------------------------------------------------
$lastTag   = (git describe --tags --abbrev=0 2>$null)
$commitLog = @()

if ($lastTag) {
    $raw = git log "$lastTag..HEAD" --oneline 2>$null
} else {
    $raw = git log --oneline 2>$null
}
if ($raw) { $commitLog = @($raw -split "`n" | Where-Object { $_ -ne '' }) }

# -- Auto-detect bump type from Conventional Commits ---------------------------
$bumpReason = 'No feat:/fix:/perf: commits since last tag'

if (-not $Bump) {
    $detected = 'NONE'

    foreach ($line in $commitLog) {
        if ($line -match '!(\s|:)|BREAKING[_ ]CHANGE') { $detected = 'MAJOR'; $bumpReason = $line.Trim(); break }
    }
    if ($detected -eq 'NONE') {
        foreach ($line in $commitLog) {
            if ($line -match '^[a-f0-9]+ feat[:(]') { $detected = 'MINOR'; $bumpReason = $line.Trim(); break }
        }
    }
    if ($detected -eq 'NONE') {
        foreach ($line in $commitLog) {
            if ($line -match '^[a-f0-9]+ (fix|perf)[:(]') { $detected = 'PATCH'; $bumpReason = $line.Trim(); break }
        }
    }

    if ($detected -eq 'NONE') {
        Write-Host ''
        Write-Host "- Current version:    $currentVersion"
        Write-Host "- Latest tag:         $(if ($lastTag) { $lastTag } else { '(none)' })"
        Write-Host "- Commits since tag:  $($commitLog.Count)"
        Write-Host '- Recommended bump:   NONE'
        Write-Host "- Reason:             $bumpReason"
        Write-Host ''
        Write-Host 'No version bump needed. Use -Bump MAJOR|MINOR|PATCH to override.' -ForegroundColor Yellow
        exit 0
    }

    $Bump = $detected
}

# -- Compute new version -------------------------------------------------------
$parts = $currentVersion -split '\.'
[int]$major = $parts[0]
[int]$minor = $parts[1]
[int]$patch = ($parts[2] -replace '-.*', '')

switch ($Bump) {
    'MAJOR' { $major++; $minor = 0; $patch = 0 }
    'MINOR' { $minor++;             $patch = 0 }
    'PATCH' {                       $patch++   }
}

$newVersion = "$major.$minor.$patch"

# -- Print release prep table --------------------------------------------------
Write-Host ''
Write-Host "- Current version:    $currentVersion"
Write-Host "- Latest tag:         $(if ($lastTag) { $lastTag } else { '(none)' })"
Write-Host "- Commits since tag:  $($commitLog.Count)"
Write-Host "- Recommended bump:   $Bump"
Write-Host "- Reason:             $bumpReason"
Write-Host "- Proposed version:   $newVersion"
Write-Host '- Files to change:    backend/pom.xml, frontend/package.json, CHANGELOG.md'
Write-Host ''

if (-not $Apply -and -not $CutRelease) {
    Write-Host '(Dry-run. Use -Apply to write changes, -CutRelease to also cut a release branch + tag.)' -ForegroundColor Cyan
    exit 0
}

# -- Update pom.xml ------------------------------------------------------------
$pomLines[$pomVersionLine] = $pomLines[$pomVersionLine] -replace `
    '<version>[^<]+</version>', "<version>$newVersion</version>"
[System.IO.File]::WriteAllLines($pomPath, $pomLines, $utf8NoBom)
Write-Host "  Updated backend/pom.xml: $currentVersion -> $newVersion"

# -- Update package.json -------------------------------------------------------
$newPkgRaw = $pkgRaw -replace '"version":\s*"[^"]+"', "`"version`": `"$newVersion`""
[System.IO.File]::WriteAllText($pkgPath, $newPkgRaw, $utf8NoBom)
Write-Host "  Updated frontend/package.json: $currentVersion -> $newVersion"

# -- Update CHANGELOG.md -------------------------------------------------------
$today    = Get-Date -Format 'yyyy-MM-dd'
$clLines  = [string[]](Get-Content $clPath -Encoding utf8)
$urIdx    = -1
$nextIdx  = -1

for ($i = 0; $i -lt $clLines.Count; $i++) {
    if ($clLines[$i] -match '^\#\# \[Unreleased\]')  { $urIdx = $i }
    if ($urIdx -ge 0 -and $i -gt $urIdx -and $clLines[$i] -match '^\#\# \[') { $nextIdx = $i; break }
}

if ($urIdx -lt 0) {
    Write-Warning 'No ## [Unreleased] section found in CHANGELOG.md -- skipping CHANGELOG update.'
} else {
    $urContent = @()
    $endIdx = if ($nextIdx -gt 0) { $nextIdx - 1 } else { $clLines.Count - 1 }
    for ($i = $urIdx + 1; $i -le $endIdx; $i++) { $urContent += $clLines[$i] }

    # Trim trailing blank / '---' lines. Use an integer index (never re-read .Count on a value that
    # may have unwrapped to a scalar) and force array context — required under Set-StrictMode Latest.
    $urContent = @($urContent)
    $trimEnd = $urContent.Count
    while ($trimEnd -gt 0 -and ($urContent[$trimEnd - 1] -match '^\s*$' -or $urContent[$trimEnd - 1] -match '^---\s*$')) {
        $trimEnd--
    }
    $urContent = if ($trimEnd -gt 0) { @($urContent[0..($trimEnd - 1)]) } else { @() }

    $newLines = @()
    for ($i = 0; $i -le $urIdx; $i++) { $newLines += $clLines[$i] }
    $newLines += ''
    $newLines += '---'
    $newLines += ''
    $newLines += "## [$newVersion] - $today"
    foreach ($l in @($urContent)) { if ($null -ne $l) { $newLines += $l } }
    $newLines += ''
    $newLines += '---'
    $newLines += ''
    if ($nextIdx -gt 0) {
        for ($i = $nextIdx; $i -lt $clLines.Count; $i++) { $newLines += $clLines[$i] }
    }

    [System.IO.File]::WriteAllLines($clPath, $newLines, $utf8NoBom)
    Write-Host "  Updated CHANGELOG.md: added section [$newVersion] - $today"
}

Write-Host ''
Write-Host "Version bump complete: $currentVersion -> $newVersion" -ForegroundColor Green

if (-not $CutRelease) {
    Write-Host ''
    Write-Host 'Next steps:'
    Write-Host "  git add backend/pom.xml frontend/package.json CHANGELOG.md"
    Write-Host "  git commit -m `"chore: release v$newVersion`""
    Write-Host '  Use -CutRelease to create release branch + tag automatically.'
    exit 0
}

# -- Cut release branch --------------------------------------------------------
$releaseBranch = "release/$newVersion"

$existingBranch = git branch --list $releaseBranch
if ($existingBranch) {
    Write-Error "Branch '$releaseBranch' already exists. Delete it first or choose a different version."
    exit 1
}

$currentBranch = git branch --show-current
if ($currentBranch -ne 'master' -and $currentBranch -ne 'main') {
    Write-Warning "Not on master -- currently on '$currentBranch'. Release branch will be cut from here."
}

Write-Host ''
Write-Host "Cutting $releaseBranch..." -ForegroundColor Green

Push-Location $ROOT
try {
    git checkout -b $releaseBranch
    git add backend/pom.xml frontend/package.json CHANGELOG.md
    git commit -m "chore: release v$newVersion"
    git tag -a "v$newVersion" -m "Release v$newVersion"
    git push origin $releaseBranch
    git push origin "v$newVersion"
} finally {
    Pop-Location
}

Write-Host ''
Write-Host "Branch $releaseBranch pushed." -ForegroundColor Green
Write-Host "Tag v$newVersion pushed." -ForegroundColor Green

# -- Print branch protection command -------------------------------------------
$remoteUrl = git remote get-url origin 2>$null
$ownerRepo = ''
if ($remoteUrl -match 'github\.com[:/](.+?/.+?)(?:\.git)?$') { $ownerRepo = $Matches[1] }

Write-Host ''
Write-Host 'Protect the release branch (run once, requires GH_TOKEN in .env):' -ForegroundColor Yellow
Write-Host ''

if ($ownerRepo) {
    $ghEndpoint = 'repos/' + $ownerRepo + '/branches/' + $releaseBranch + '/protection'
    Write-Host "  Endpoint : PUT $ghEndpoint"
    Write-Host '  Command  : gh api -X PUT <endpoint> --input - (pipe the JSON body)'
    Write-Host '  JSON body: see ai/skills/git-branching-release-strategy.md'
} else {
    Write-Host "  Endpoint : PUT repos/OWNER/REPO/branches/$releaseBranch/protection"
    Write-Host '  JSON body: see ai/skills/git-branching-release-strategy.md'
}
