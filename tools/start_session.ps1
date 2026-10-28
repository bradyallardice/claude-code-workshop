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
#   3. Brings today's folders in ~\my_workspace up to date:
#        - a folder you do not have yet is copied in;
#        - a file you have NOT edited is replaced by the instructor's newer version;
#        - a file you HAVE edited is never touched: the newer version is saved beside it
#          as <name>.new, and you decide what to keep;
#        - files you created, and files you deleted, are left alone.
#      (A small record of what was delivered last time is kept in ~\my_workspace\.workshop\.)
#   4. Copies today's slides into ~\my_workspace\slides\ (always the newest version).
#   5. Opens ~\my_workspace in VS Code.
# Work only in ~\my_workspace. The course repo is a disposable mirror that this script resets.
# If git does not work at all, it downloads a zip of the materials instead.
#
# Keep this file ASCII-only: Windows PowerShell 5.1 misreads other characters.
# Settings for testing (students never need these):
#   WORKSHOP_SESSION WORKSHOP_GITHUB_REPO WORKSHOP_REPO_URL WORKSHOP_BRANCH WORKSHOP_HOME WORKSHOP_ZIP_URL WORKSHOP_NO_OPEN

function Start-WorkshopSession {
    param([string]$Session)

    # PowerShell 5.1: GitHub needs TLS 1.2, and the progress bar makes downloads crawl.
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $ProgressPreference = "SilentlyContinue"

    # ---- Where the public student repo lives. This is the one place in this script to change
    # ---- if the repo is renamed or moved (admin/publishing.md lists the other files).
    $GithubRepo = if ($env:WORKSHOP_GITHUB_REPO) { $env:WORKSHOP_GITHUB_REPO } else { "bradyallardice/claude-code-workshop" }
    $Branch = if ($env:WORKSHOP_BRANCH) { $env:WORKSHOP_BRANCH } else { "student" }
    $RepoUrl = if ($env:WORKSHOP_REPO_URL) { $env:WORKSHOP_REPO_URL } else { "https://github.com/$GithubRepo.git" }
    $ZipUrl = if ($env:WORKSHOP_ZIP_URL) { $env:WORKSHOP_ZIP_URL } else { "https://github.com/$GithubRepo/archive/refs/heads/$Branch.zip" }
    $ManifestUrl = if ($env:WORKSHOP_MANIFEST_URL) { $env:WORKSHOP_MANIFEST_URL } else { "https://raw.githubusercontent.com/$GithubRepo/$Branch/tools/sessions.txt" }
    $Base = if ($env:WORKSHOP_HOME) { $env:WORKSHOP_HOME } else { $HOME }
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

    # Delivery records use git's blob hash of the bytes on disk (same value as
    # `git hash-object --no-filters`), computed here with .NET so no git call and no
    # character-encoding problem with file names is involved. The same records are
    # written by start_session.sh, so either script can update what the other delivered.
    function LongPath($p) {
        $full = [IO.Path]::GetFullPath($p)
        if ($full.StartsWith("\\?\")) { return $full }
        if ($full.StartsWith("\\")) { return "\\?\UNC\" + $full.Substring(2) }
        return "\\?\" + $full
    }
    function Get-BlobHash($p) {
        $bytes = [IO.File]::ReadAllBytes((LongPath $p))
        $header = [Text.Encoding]::ASCII.GetBytes("blob " + $bytes.Length + [char]0)
        $all = New-Object byte[] ($header.Length + $bytes.Length)
        [Array]::Copy($header, 0, $all, 0, $header.Length)
        [Array]::Copy($bytes, 0, $all, $header.Length, $bytes.Length)
        $sha = [Security.Cryptography.SHA1]::Create()
        try { return ([BitConverter]::ToString($sha.ComputeHash($all))).Replace("-", "").ToLower() }
        finally { $sha.Dispose() }
    }
    $StateDir = Join-Path $Workspace ".workshop"
    $Utf8NoBom = New-Object Text.UTF8Encoding $false
    $script:NewFiles = @()

    # Copy a new folder, or update an existing one without touching the student's work.
    function Update-Folder($folder) {
        $Src = Join-Path $Repo $folder
        $Dest = Join-Path $Workspace $folder
        $Mf = Join-Path $StateDir ($folder + ".manifest")
        New-Item -ItemType Directory -Force $StateDir | Out-Null

        # What the instructor published now: relative path (forward slashes) -> hash
        $RepoRoot = (Resolve-Path $Repo).Path.TrimEnd("\")
        $Up = [ordered]@{}
        foreach ($f in (Get-ChildItem -LiteralPath $Src -Recurse -File -Force | Where-Object { $_.Name -ne ".DS_Store" } | Sort-Object FullName)) {
            $rel = $f.FullName.Substring($RepoRoot.Length + 1).Replace("\", "/")
            $Up[$rel] = Get-BlobHash $f.FullName
        }

        if (-not (Test-Path $Dest)) {
            # robocopy handles long paths; exit codes 0-7 mean success, 8+ mean failure.
            robocopy $Src $Dest /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
            if ($LASTEXITCODE -ge 8) { Write-Host "`n  STOPPED Copy of $folder failed. Ask the instructor for help." -ForegroundColor Red; return $false }
            $global:LASTEXITCODE = 0
            $lines = @("#method=git") + @($Up.Keys | ForEach-Object { $Up[$_] + "`t" + $_ })
            [IO.File]::WriteAllLines($Mf, $lines, $Utf8NoBom)
            Ok "Copied $folder into $Workspace"
            return $true
        }

        # What was delivered last time
        $Old = @{}
        if (Test-Path $Mf) {
            $mlines = [IO.File]::ReadAllLines($Mf)
            if ($mlines.Count -gt 0 -and $mlines[0] -eq "#method=git") {
                for ($i = 1; $i -lt $mlines.Count; $i++) {
                    $tab = $mlines[$i].IndexOf("`t")
                    if ($tab -gt 0) { $Old[$mlines[$i].Substring($tab + 1)] = $mlines[$i].Substring(0, $tab) }
                }
            }
        }

        # Decide file by file. old = hash delivered last time, ws = hash in the student's folder
        # now, u = hash of the version published now.
        #   not in your folder, delivered before             -> you deleted it: stays deleted
        #   not in your folder, never delivered              -> new from the instructor: add it
        #   same as published                                -> nothing to do
        #   unchanged since delivered, newer one published   -> replace it
        #   anything else (you edited it, or no record)      -> keep yours, save the new one as .new
        # For the last case the record is set to the version just offered, so a student who adopts
        # it (copies the .new over their file) gets silent updates from then on.
        $NewMf = @("#method=git")
        $nAdd = 0; $nUpd = 0; $nNew = 0; $nGone = 0
        foreach ($rel in $Up.Keys) {
            $u = $Up[$rel]
            $wsPath = Join-Path $Workspace ($rel.Replace("/", "\"))
            $srcPath = Join-Path $Repo ($rel.Replace("/", "\"))
            $exists = [IO.File]::Exists((LongPath $wsPath))
            if (-not $exists) {
                if ($Old.ContainsKey($rel)) { $nGone++; $NewMf += ($Old[$rel] + "`t" + $rel) }
                else {
                    [IO.Directory]::CreateDirectory((LongPath (Split-Path $wsPath -Parent))) | Out-Null
                    [IO.File]::Copy((LongPath $srcPath), (LongPath $wsPath), $true)
                    $nAdd++; $NewMf += ($u + "`t" + $rel)
                }
                continue
            }
            $w = Get-BlobHash $wsPath
            if ($w -eq $u) { $NewMf += ($u + "`t" + $rel) }
            elseif ($Old.ContainsKey($rel) -and $Old[$rel] -eq $w) {
                [IO.File]::Copy((LongPath $srcPath), (LongPath $wsPath), $true)
                $nUpd++; $NewMf += ($u + "`t" + $rel)
            } else {
                [IO.File]::Copy((LongPath $srcPath), (LongPath ($wsPath + ".new")), $true)
                $nNew++; $script:NewFiles += ($wsPath + ".new"); $NewMf += ($u + "`t" + $rel)
            }
        }
        [IO.File]::WriteAllLines($Mf, $NewMf, $Utf8NoBom)
        Ok "${folder}: $nUpd updated, $nAdd added, $nNew of your edited files have a newer version (saved as <name>.new)"
        if ($nGone -gt 0) { Say "($nGone files you deleted were not restored)" }
        return $true
    }

    foreach ($folder in $Folders) {
        if (Test-Path (Join-Path $Repo $folder)) {
            if (-not (Update-Folder $folder)) { return }
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
    Write-Host "  (Do not edit inside the course repo; it is reset every time you run this.)"
    if ($script:NewFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "  The instructor changed files you had already edited. Yours were NOT touched."
        Write-Host "  The newer versions are next to them, ending in .new:"
        foreach ($nf in $script:NewFiles) { Write-Host "    $nf" }
        Write-Host "  Ask Claude Code to compare each pair and tell you what changed."
        Write-Host ""
    }
    if ($Opened) { Write-Host "  VS Code is opening that folder. Start Claude Code there." }
    else { Write-Host "  Open VS Code, then File > Open Folder > $Workspace" }
    Write-Host "  ======================================="
    Write-Host ""
}

# Works for both "irm ... | iex" (no arguments: asks) and the scriptblock form (argument given).
Start-WorkshopSession @args
