# start_session.ps1 - get the current course materials and today's folders, in one step.
#
# Students run this in PowerShell (the same pattern as the Claude Code installer):
#   irm https://raw.githubusercontent.com/bradyallardice/claude-code-workshop/student/tools/start_session.ps1 | iex
# It asks for the session number. To skip the question, run instead:
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/bradyallardice/claude-code-workshop/student/tools/start_session.ps1))) 2
#
# What it does, in order:
#   1. Finds the course repo (~\claude-code-workshop, Documents, Desktop, OneDrive),
#      or downloads it if missing.
#   2. Backs up anything you changed inside the course repo (git stash + a backup
#      branch), then moves the repo to exactly the version the instructor published.
#      It fetches only the latest snapshot, so there is nothing to merge or conflict.
#   3. Copies today's folders into ~\my_workspace. A folder you already have there
#      is NEVER overwritten.
#   4. Copies today's slides into ~\my_workspace\slides\ (always the newest version).
#   5. Opens ~\my_workspace in VS Code.
# If git does not work at all, it downloads a zip of the materials instead.
#
# Keep this file ASCII-only: Windows PowerShell 5.1 misreads other characters.
# Settings for testing (students never need these):
#   WORKSHOP_SESSION WORKSHOP_REPO_URL WORKSHOP_BRANCH WORKSHOP_HOME WORKSHOP_ZIP_URL WORKSHOP_NO_OPEN

function Start-WorkshopSession {
    param([string]$Session)

    # PowerShell 5.1: GitHub needs TLS 1.2, and the progress bar makes downloads crawl.
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $ProgressPreference = "SilentlyContinue"

    $RepoUrl = if ($env:WORKSHOP_REPO_URL) { $env:WORKSHOP_REPO_URL } else { "https://github.com/bradyallardice/claude-code-workshop.git" }
    $Branch = if ($env:WORKSHOP_BRANCH) { $env:WORKSHOP_BRANCH } else { "student" }
    $Base = if ($env:WORKSHOP_HOME) { $env:WORKSHOP_HOME } else { $HOME }
    $ZipUrl = if ($env:WORKSHOP_ZIP_URL) { $env:WORKSHOP_ZIP_URL } else { "https://github.com/bradyallardice/claude-code-workshop/archive/refs/heads/$Branch.zip" }
    $ManifestUrl = if ($env:WORKSHOP_MANIFEST_URL) { $env:WORKSHOP_MANIFEST_URL } else { "https://raw.githubusercontent.com/bradyallardice/claude-code-workshop/$Branch/tools/sessions.txt" }
    $Workspace = Join-Path $Base "my_workspace"
    $Stamp = Get-Date -Format "yyyyMMdd-HHmmss"

    function Ok($m) { Write-Host "  OK    " -ForegroundColor Green -NoNewline; Write-Host $m }
    function Note($m) { Write-Host "  NOTE  " -ForegroundColor Yellow -NoNewline; Write-Host $m }
    function Say($m) { Write-Host "  $m" }
    function Have($n) { return [bool](Get-Command $n -ErrorAction SilentlyContinue) }
    # git stash and backup branches need an identity; supply one so a missing
    # git config never blocks the update.
    # core.longpaths: some course files have paths near Windows' 260-character limit.
    function G { & git -c user.name=workshop -c user.email=workshop@localhost -c advice.detachedHead=false -c core.longpaths=true @args }

    if (-not $Session) { $Session = $env:WORKSHOP_SESSION }
    if (-not $Session) { $Session = Read-Host "Which session is today? (number)" }
    $Session = "$Session".Trim()
    if ($Session -notmatch '^\d{1,2}$') {
        Write-Host "`n  STOPPED Session must be a number, e.g. 2." -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "Starting session $Session"

    # -----------------------------------------------------------------------
    # 1-2. Get the published version of the course repo
    $Candidates = @((Join-Path $Base "claude-code-workshop"), (Join-Path $Base "Documents\claude-code-workshop"), (Join-Path $Base "Desktop\claude-code-workshop"))
    if ($env:OneDrive -and -not $env:WORKSHOP_HOME) {
        $Candidates += @((Join-Path $env:OneDrive "Documents\claude-code-workshop"), (Join-Path $env:OneDrive "Desktop\claude-code-workshop"))
    }
    $Repo = $null
    foreach ($c in $Candidates) { if (Test-Path (Join-Path $c ".git")) { $Repo = $c; break } }

    # Fresh shallow clone; also used to replace a copy that cannot be updated.
    function Clone-Fresh($Dest) {
        # Out-Host keeps git's output out of the function's return value.
        G clone -q --depth 1 --branch $Branch --single-branch $RepoUrl $Dest | Out-Host
        if ($LASTEXITCODE -ne 0) { return $false }
        git -C $Dest config core.longpaths true | Out-Host
        return $true
    }

    $UseZip = $false
    if (-not (Have git)) {
        Note "git not found; downloading a zip of the materials instead"
        $UseZip = $true
    } elseif (-not $Repo) {
        $Repo = Join-Path $Base "claude-code-workshop"
        if (Test-Path $Repo) {
            Move-Item $Repo "$Repo.old-$Stamp"
            Note "Moved a non-git folder out of the way: $Repo.old-$Stamp"
        }
        Say "Downloading the course materials (first time on this computer)..."
        if (Clone-Fresh $Repo) { Ok "Downloaded to $Repo" } else {
            Note "git clone failed; trying the zip download instead"
            $UseZip = $true
        }
    } else {
        # Update in place: back up edits, keep local commits on a branch, switch.
        # If any step fails (no network, or a copy damaged e.g. by Windows'
        # path-length limit), fall back to a fresh copy.
        $Updated = $false
        Push-Location $Repo
        try {
            # A pull that stopped half way leaves a merge or rebase open; close it first.
            if (Test-Path ".git\MERGE_HEAD") { G merge --abort; Note "Closed an unfinished merge from an earlier git pull" }
            if ((Test-Path ".git\rebase-merge") -or (Test-Path ".git\rebase-apply")) { G rebase --abort; Note "Closed an unfinished rebase" }
            Remove-Item ".git\index.lock" -ErrorAction SilentlyContinue
            git config core.longpaths true

            Say "Fetching the latest version..."
            G fetch -q --depth 1 $RepoUrl $Branch
            if ($LASTEXITCODE -eq 0) {
                $Updated = $true
                $Dirty = (git status --porcelain)
                if ($Dirty) {
                    G stash push -q -u -m "start_session backup $Stamp"
                    if ($LASTEXITCODE -eq 0) { Note "You had changed files inside the course repo. Saved them: git stash list (in $Repo)" }
                    else { $Updated = $false }
                }
                if ($Updated) {
                    $Head = (git rev-parse -q --verify HEAD)
                    $Fetched = (git rev-parse FETCH_HEAD)
                    if ($Head -and ($Head -ne $Fetched)) { G branch -q -f "backup-$Stamp" HEAD }
                    G checkout -q -B $Branch FETCH_HEAD
                    if ($LASTEXITCODE -ne 0) { $Updated = $false }
                }
            }
        } finally { Pop-Location }

        if ($Updated) {
            Ok "Course repo updated: $Repo"
        } else {
            # Clone fresh beside the old copy first, and only then swap, so nothing
            # moves if the network is the problem. The old copy is kept.
            Say "Your copy could not be updated in place; downloading a fresh copy..."
            $New = "$Repo.new-$Stamp"
            if (Clone-Fresh $New) {
                try {
                    Move-Item $Repo "$Repo.old-$Stamp" -ErrorAction Stop
                    Move-Item $New $Repo -ErrorAction Stop
                    Note "Kept your previous copy, untouched, as $Repo.old-$Stamp"
                } catch {
                    $Repo = $New
                    Note "Your previous copy is in use (open in VS Code?), so the fresh copy is at $Repo"
                }
                Ok "Fresh copy: $Repo"
            } else {
                Remove-Item $New -Recurse -Force -ErrorAction SilentlyContinue
                Note "Download failed (network?); trying the zip download instead"
                $UseZip = $true
            }
        }
    }

    if ($UseZip) {
        # Unpack beside the destination (same drive), so the final move is a rename,
        # not a file-by-file copy that can fail part way.
        $Tmp = Join-Path $Base "workshop-download-$Stamp"
        New-Item -ItemType Directory -Force $Tmp | Out-Null
        $Zip = Join-Path $Tmp "materials.zip"
        try { Invoke-WebRequest -Uri $ZipUrl -OutFile $Zip -UseBasicParsing }
        catch { Write-Host "`n  STOPPED Download failed. Check the Wi-Fi, then run the command again." -ForegroundColor Red; return }
        # Windows 10+ ships tar.exe, which unpacks zips much faster than Expand-Archive.
        $TarExe = Join-Path $env:SystemRoot "System32\tar.exe"
        if (Test-Path $TarExe) { & $TarExe -xf $Zip -C $Tmp } else { Expand-Archive -Path $Zip -DestinationPath $Tmp -Force }
        Remove-Item $Zip -ErrorAction SilentlyContinue
        $Extracted = Get-ChildItem $Tmp -Directory | Select-Object -First 1
        if (-not $Extracted) { Write-Host "`n  STOPPED The download unpacked to nothing." -ForegroundColor Red; return }
        $Repo = Join-Path $Base "claude-code-workshop-zip"
        if (Test-Path $Repo) { Move-Item $Repo "$Repo.old-$Stamp" }
        Move-Item $Extracted.FullName $Repo
        Remove-Item $Tmp -Recurse -Force -ErrorAction SilentlyContinue
        Ok "Materials unpacked to $Repo (zip copy; fix git later with the troubleshooting sheet)"
    }

    if (Test-Path (Join-Path $Repo ".git")) {
        $Version = (git -C $Repo log -1 "--format=%cd  (%h)" "--date=format:%a %d %b %H:%M")
    } else {
        $Version = "zip download " + (Get-Date -Format "ddd dd MMM HH:mm")
    }

    # -----------------------------------------------------------------------
    # 3-4. Copy today's folders and slides into the workspace
    $Folders = @()
    $Slides = $null
    $Manifest = Join-Path $Repo "tools\sessions.txt"
    $ManifestLines = @()
    if (Test-Path $Manifest) { $ManifestLines = @(Get-Content $Manifest) }
    else {
        # The copy may be incomplete (e.g. a zip unpacked with errors): fetch just the list.
        try { $ManifestLines = @(((Invoke-WebRequest -Uri $ManifestUrl -UseBasicParsing).Content) -split "`r?`n") } catch { }
    }
    if ($ManifestLines.Count -gt 0) {
        foreach ($line in $ManifestLines) {
            if ($line -match '^\s*#' -or $line -notmatch '\|') { continue }
            $parts = $line.Split("|")
            if ($parts[0].Trim() -eq $Session) {
                $Folders = @($parts[1].Trim() -split '\s+' | Where-Object { $_ })
                if ($parts.Count -ge 3) { $Slides = $parts[2].Trim() }
                break
            }
        }
    }
    if ($Folders.Count -eq 0) {
        if ($ManifestLines.Count -eq 0) { Note "No session list found (tools\sessions.txt); guessing session_$Session" }
        $Folders = @("session_$Session")
        $Slides = "slides/session${Session}_slides.pdf"
    }
    Say ("Today's folders: " + ($Folders -join ", "))

    New-Item -ItemType Directory -Force $Workspace | Out-Null
    foreach ($folder in $Folders) {
        $Dest = Join-Path $Workspace $folder
        $Src = Join-Path $Repo $folder
        if (Test-Path $Dest) {
            Ok "Kept your existing $Dest (not overwritten)"
        } elseif (Test-Path $Src) {
            # robocopy handles long paths; exit codes 0-7 mean success, 8+ mean failure.
            robocopy $Src $Dest /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
            if ($LASTEXITCODE -ge 8) { Write-Host "`n  STOPPED Copy of $folder failed. Raise your red sticky note." -ForegroundColor Red; return }
            $global:LASTEXITCODE = 0
            Ok "Copied $folder into $Workspace"
        } else {
            Note "$folder is not in the published materials yet; tell the instructor"
        }
    }
    $SlidesSrc = if ($Slides) { Join-Path $Repo ($Slides -replace "/", "\") } else { $null }
    if ($SlidesSrc -and (Test-Path $SlidesSrc)) {
        $SlidesDir = Join-Path $Workspace "slides"
        New-Item -ItemType Directory -Force $SlidesDir | Out-Null
        Copy-Item -Force $SlidesSrc $SlidesDir
        Ok ("Slides: " + (Join-Path $SlidesDir (Split-Path $SlidesSrc -Leaf)))
    } else {
        Note "Slides for session $Session are not published yet"
    }

    # -----------------------------------------------------------------------
    # 5. Open the workspace (the parent folder, so paths like session_1/data/... work)
    $Opened = $false
    if (-not $env:WORKSHOP_NO_OPEN -and (Have code)) { code $Workspace; $Opened = $true }

    Write-Host ""
    Write-Host "  ================ READY ================"
    Write-Host "  Materials version: $Version"
    Write-Host "  Work in:           $Workspace"
    if ($Opened) { Write-Host "  VS Code is opening that folder. Start Claude Code there." }
    else { Write-Host "  Open VS Code, then File > Open Folder > $Workspace" }
    Write-Host "  ======================================="
    Write-Host ""
}

# Works for both "irm ... | iex" (no arguments: asks) and the scriptblock form (argument given).
Start-WorkshopSession @args
