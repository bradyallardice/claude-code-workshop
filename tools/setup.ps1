# setup.ps1 - do the pre-course setup in one command (Windows).
#
# Students run this in PowerShell (NOT as Administrator), the same pattern as start_session.ps1:
#   irm https://raw.githubusercontent.com/bradyallardice/claude-code-workshop/student/tools/setup.ps1 | iex
# To also INSTALL the big programs when they are missing (Git, VS Code, Python, R, MiKTeX, Zotero):
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/bradyallardice/claude-code-workshop/student/tools/setup.ps1))) -Full
# To see what it would do without changing anything, add -DryRun (can be combined with -Full).
#
# Safe to run again: every step first checks whether the thing is already there.
#
# Default (light) mode, in order:
#   1. Git and your git name/email          (asks for the name/email if they are not set)
#   2. VS Code extensions: Python, R, Claude Code, LaTeX Workshop   (if VS Code is installed)
#   3. Claude Code command-line tool        (installs it if missing, then updates it)
#   4. The course materials                 (runs the start-of-session command for session 1)
#   5. Python packages, and the Zotero MCP package
#   6. R packages                           (only if R is installed)
#   7. GitHub and Zotero MCPs               (asks you to paste the two keys; Enter skips)
#   8. The course checker (doctor.ps1), a compile test of setup_check.tex, and a summary table
# -Full mode also INSTALLS what is missing among: Git, VS Code, Python 3.12, R, MiKTeX (with Perl,
#   which VS Code's LaTeX build needs on Windows), Zotero. It uses winget, which ships with Windows 10
#   and 11. Windows may show a permission (UAC) window for Git and MiKTeX: click Yes. It takes 20 to 40
#   minutes.
#
# What no script can do for you (printed at the end): sign in to Claude, create the GitHub account,
# create the two keys, enable Zotero's local connection, import the practice library.
#
# Keep this file ASCII-only: Windows PowerShell 5.1 misreads other characters.
# Never use "exit" here: under "irm | iex" it would close the student's PowerShell window.
# Settings for testing (students never need these):
#   WORKSHOP_GITHUB_REPO WORKSHOP_BRANCH WORKSHOP_HOME WORKSHOP_SETUP_SESSION WORKSHOP_NO_TTY WORKSHOP_FULL WORKSHOP_DRYRUN

function Invoke-WorkshopSetup {
    param([switch]$Full, [switch]$DryRun, [switch]$Yes)

    if ($env:WORKSHOP_FULL) { $Full = $true }
    if ($env:WORKSHOP_DRYRUN) { $DryRun = $true }

    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $ProgressPreference = "SilentlyContinue"

    $GithubRepo = if ($env:WORKSHOP_GITHUB_REPO) { $env:WORKSHOP_GITHUB_REPO } else { "bradyallardice/claude-code-workshop" }
    $Branch = if ($env:WORKSHOP_BRANCH) { $env:WORKSHOP_BRANCH } else { "student" }
    $Raw = "https://raw.githubusercontent.com/$GithubRepo/$Branch"
    $SessionToFetch = if ($env:WORKSHOP_SETUP_SESSION) { $env:WORKSHOP_SETUP_SESSION } else { "1" }
    $Base = if ($env:WORKSHOP_HOME) { $env:WORKSHOP_HOME } else { $HOME }
    $Workspace = Join-Path $Base "my_workspace"

    $PipPackages = @("pandas", "numpy", "statsmodels", "scipy", "linearmodels", "matplotlib", "seaborn", "scikit-learn", "openpyxl")
    $ImportName = @{ "scikit-learn" = "sklearn" }
    $VsCodeExtensions = @("ms-python.python", "REditorSupport.r", "anthropic.claude-code", "James-Yu.latex-workshop")
    $RPackages = "'readr', 'dplyr', 'tidyr', 'ggplot2', 'MASS'"   # single quotes: 5.1 mangles embedded double quotes passed to native programs

    # -----------------------------------------------------------------------
    # Output helpers. Every step ends in exactly one Record: OK (already fine), DONE (did it now),
    # MANUAL (you must do it), SKIPPED (declined or nothing to ask), FAIL (tried and it did not work).
    $script:Results = @()
    $script:NFail = 0
    function Say($m) { Write-Host "  $m" }
    function Head($m) { Write-Host ""; Write-Host $m -ForegroundColor White }
    function Have($n) { return [bool](Get-Command $n -ErrorAction SilentlyContinue) }
    function Record($status, $label, $detail) {
        if ($DryRun -and $status -eq "DONE") { $status = "WOULD" }   # a dry run never claims to have done anything
        $script:Results += [pscustomobject]@{ Status = $status; Label = $label }
        $color = switch ($status) { "OK" { "Green" } "DONE" { "Green" } "WOULD" { "Cyan" } "FAIL" { "Red" } default { "Yellow" } }
        if ($status -eq "FAIL") { $script:NFail++ }
        Write-Host ("  {0,-8}" -f $status) -ForegroundColor $color -NoNewline
        Write-Host $label
        if ($detail) { Write-Host "          $detail" }
    }
    # Run a command, or only print it in -DryRun. The caller checks $LASTEXITCODE; failures are not hidden.
    function Invoke-Step([string]$display, [scriptblock]$block) {
        if ($DryRun) { Say "[dry-run] $display"; $global:LASTEXITCODE = 0; return }
        & $block
    }
    function Update-SessionPath {
        # Programs just installed are not on this window's PATH yet: re-read it, and add the usual places.
        $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
        $user = [Environment]::GetEnvironmentVariable("Path", "User")
        $env:Path = "$machine;$user;$HOME\.local\bin"
    }

    $TtyOk = -not $env:WORKSHOP_NO_TTY
    function Ask([string]$prompt) {
        if ($DryRun) { Say "[dry-run] would ask: $prompt"; return $null }
        if (-not $TtyOk) { return $null }
        return (Read-Host "  $prompt")
    }
    function Ask-Secret([string]$prompt) {
        if ($DryRun) { Say "[dry-run] would ask (hidden): $prompt"; return $null }
        if (-not $TtyOk) { return $null }
        $secure = Read-Host "  $prompt" -AsSecureString
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        try { return [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
        finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    }
    function Confirm-Step([string]$question) {
        if ($Yes) { return $true }
        $a = Ask "$question [y/N]"
        return ($a -match '^(y|yes)$')
    }
    function Install-WithWinget([string]$id, [string]$label) {
        # Returns $true if winget reports success. winget may show a Windows permission (UAC) window.
        if (-not (Have winget)) { Say "winget (the Windows package installer) was not found on this computer."; return $false }
        Say "Installing $label with winget (this can take several minutes)..."
        Invoke-Step "winget install --id $id -e --accept-package-agreements --accept-source-agreements" {
            & winget install --id $id -e --accept-package-agreements --accept-source-agreements
        }
        if ($LASTEXITCODE -ne 0) { return $false }
        if (-not $DryRun) { Update-SessionPath }
        return $true
    }

    # -----------------------------------------------------------------------
    if (-not $env:WORKSHOP_TEST_NONWINDOWS) {
        if ($PSVersionTable.PSEdition -eq "Core" -and -not $IsWindows) {
            Write-Host "  This script is for Windows. On a Mac, use tools/setup.sh (see the README on GitHub)."; return
        }
        $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Host "`n  STOPPED This PowerShell window is running as Administrator." -ForegroundColor Red
            Write-Host "  Close it, open a normal PowerShell (Start menu, type PowerShell, press Enter), and run the command again."
            Write-Host "  (Claude Code would be installed into the administrator account instead of yours.)"
            return
        }
    }
    Update-SessionPath

    Write-Host ""
    $mode = if ($Full) { "full" } else { "light" }
    Write-Host "Workshop setup  ($mode mode$(if ($DryRun) { ', DRY RUN: nothing will be changed' }))" -ForegroundColor White
    if (-not $TtyOk) { Say "No terminal for questions: steps that need typing will be listed under MANUAL." }
    if ($Full) { Say "Full mode can take 20 to 40 minutes and Windows may ask permission (UAC): click Yes. Ctrl+C stops it; rerun later." }

    # -----------------------------------------------------------------------
    Head "1. Git"
    # Claude Code on Windows needs Git for Windows (it uses Git Bash inside).
    $GitOk = $false
    if (Have git) {
        $GitOk = $true; Record "OK" ("git " + ((& git --version) -replace "git version ", "")) ""
    } elseif ($Full) {
        if (Install-WithWinget "Git.Git" "Git for Windows") {
            Update-SessionPath
            if ($DryRun -or (Have git)) { $GitOk = $true; Record "DONE" "Git for Windows installed" "Open a NEW PowerShell window afterwards so every program sees it." }
            else { Record "FAIL" "Git installed but is not found yet" "Close this window, open a new PowerShell, and run this command again." }
        } else { Record "FAIL" "Git for Windows did not install" "Download it from https://git-scm.com/downloads/win (default settings), then run this command again." }
    } else {
        Record "MANUAL" "Git is not installed (Claude Code on Windows requires it)" "Download it from https://git-scm.com/downloads/win (default settings), then run this command again."
    }
    if ($GitOk) {
        $gn = (& git config --global user.name 2>$null); $ge = (& git config --global user.email 2>$null)
        if ($gn -and $ge) { Record "OK" "git identity: $gn <$ge>" "" }
        else {
            $name = Ask "Your full name (as you want it on commits):"
            $mail = Ask "The email you used for GitHub (create the account at github.com first if you have none):"
            if ($name -and $mail -and $mail -match '^[^@\s]+@[^@\s]+\.[^@\s]+$') {
                Invoke-Step "git config --global user.name/user.email" {
                    & git config --global user.name $name; & git config --global user.email $mail
                }
                Record "DONE" "git identity: $name <$mail>" ""
            } else {
                Record "MANUAL" "git name/email not set" 'Run: git config --global user.name "Your Name"   and   git config --global user.email "you@example.com"'
            }
        }
    }

    # -----------------------------------------------------------------------
    Head "2. VS Code and its extensions"
    function Find-Code {
        if (Have code) { return "code" }
        $p = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\bin\code.cmd"
        if (Test-Path $p) { return $p }
        return $null
    }
    $CodeBin = Find-Code
    if (-not $CodeBin -and $Full) {
        if (Install-WithWinget "Microsoft.VisualStudioCode" "VS Code") {
            $CodeBin = Find-Code; if ($DryRun) { $CodeBin = "code" }
            Record "DONE" "VS Code installed" ""
        } else { Record "FAIL" "VS Code did not install" "Download it from https://code.visualstudio.com and run this command again." }
    } elseif (-not $CodeBin) {
        Record "MANUAL" "VS Code is not installed" "Download it from https://code.visualstudio.com, open it once, then run this command again."
    } else { Record "OK" "VS Code found" "" }
    if ($CodeBin) {
        $installedExt = @(); if (-not $DryRun) { $installedExt = @(& $CodeBin --list-extensions 2>$null | ForEach-Object { $_.ToLower() }) }
        foreach ($ext in $VsCodeExtensions) {
            if ($installedExt -contains $ext.ToLower()) { Record "OK" "extension $ext" ""; continue }
            Invoke-Step "code --install-extension $ext" { & $CodeBin --install-extension $ext *> $null }
            if ($LASTEXITCODE -eq 0) { Record "DONE" "extension $ext installed" "" }
            else { Record "FAIL" "extension $ext did not install" "In VS Code: Extensions (Ctrl+Shift+X), search for it, Install." }
        }
    }

    # -----------------------------------------------------------------------
    Head "3. Claude Code (command line)"
    if (Have claude) { Record "OK" ("claude " + (& claude --version 2>$null | Select-Object -First 1)) "" }
    else {
        Say "Installing Claude Code..."
        Invoke-Step "irm https://claude.ai/install.ps1 | iex" { Invoke-Expression (Invoke-RestMethod "https://claude.ai/install.ps1") }
        if (-not $DryRun) { Update-SessionPath }
        if ((Have claude) -or $DryRun) { Record "DONE" "Claude Code installed" "" }
        else { Record "FAIL" "Claude Code did not install" "Run: irm https://claude.ai/install.ps1 | iex   then close and reopen PowerShell. (Git for Windows must be installed first.)" }
    }
    if (Have claude) {
        Invoke-Step "claude update" { & claude update *> $null }
        $cv = ((& claude --version 2>$null | Select-Object -First 1) -split " ")[0]
        if ($cv -match '^(\d+)\.(\d+)' -and ([int]$Matches[1] -gt 2 -or ([int]$Matches[1] -eq 2 -and [int]$Matches[2] -ge 1))) {
            Record "OK" "Claude Code version $cv is new enough (2.1 or newer is needed for the MCP commands)" ""
        } else { Record "FAIL" "Claude Code version '$cv' is older than 2.1" "Run: claude update" }
    }
    Record "MANUAL" "Sign in to Claude (needs your Claude Pro or Max account)" "In PowerShell run: claude   then follow the browser prompts and type /exit. Also sign in inside VS Code (Claude Code panel)."

    # -----------------------------------------------------------------------
    Head "4. Course materials"
    # Same command students run every session (it falls back to a zip download if git is missing).
    # NO_OPEN: VS Code is opened by hand at the end.
    if ($DryRun) {
        Say "[dry-run] irm $Raw/tools/start_session.ps1 | iex   (session $SessionToFetch)"
        Record "DONE" "course materials (session $SessionToFetch)" ""
    } else {
        $env:WORKSHOP_NO_OPEN = "1"
        try {
            & ([scriptblock]::Create((Invoke-RestMethod "$Raw/tools/start_session.ps1"))) $SessionToFetch
            # start_session.ps1 reports its own failures by printing and returning, so check the result.
            if (Test-Path (Join-Path $Workspace "session_$SessionToFetch")) {
                Record "DONE" "course materials copied to $Workspace" "Session $SessionToFetch folder and slides are in my_workspace. Run the start-of-session command at the start of every session."
            } else {
                Record "FAIL" "session_$SessionToFetch is not in $Workspace after the start-of-session command" "Read the message above it, and email the screen to the instructor."
            }
        } catch {
            Record "FAIL" "start-of-session command failed: $($_.Exception.Message)" "Copy the screen above and email it to the instructor."
        } finally { Remove-Item Env:\WORKSHOP_NO_OPEN -ErrorAction SilentlyContinue }
    }

    # -----------------------------------------------------------------------
    Head "5. Python and packages"
    # The Microsoft Store 'python' placeholder does not run Python, so ask the py launcher first and
    # confirm any interpreter by actually running it.
    function Find-Python {
        $candidates = @(@("py", "-3.12"), @("py", "-3.11"), @("py", "-3.13"), @("py", "-3.10"), @("py", "-3.9"), @("python3"), @("python"))
        foreach ($c in $candidates) {
            $exe = $c[0]
            if (-not (Have $exe)) { continue }
            $extra = @(); if ($c.Count -gt 1) { $extra = @($c[1]) }
            $out = (& $exe @extra -c "import sys; print('%d.%d|%s' % (sys.version_info[0], sys.version_info[1], sys.executable))" 2>$null)
            if ($LASTEXITCODE -ne 0 -or -not $out) { continue }
            $parts = "$out".Trim() -split "\|"
            if ($parts.Count -lt 2) { continue }
            $v = [version]$parts[0]
            if ($v -ge [version]"3.9") { return @{ Exe = $parts[1]; Version = $parts[0] } }
        }
        return $null
    }
    $Py = Find-Python
    if (-not $Py -and $Full) {
        if (Install-WithWinget "Python.Python.3.12" "Python 3.12") {
            $Py = Find-Python
            if ($Py -or $DryRun) { Record "DONE" "Python installed" "" } else { Record "FAIL" "Python installed but is not found yet" "Close this window, open a new PowerShell, and run this command again." }
            if ($DryRun) { $Py = @{ Exe = "python"; Version = "3.12" } }
        } else { Record "FAIL" "Python did not install" "Download Python 3.12 from https://www.python.org/downloads/ and tick 'Add Python to PATH'." }
    } elseif (-not $Py) {
        Record "MANUAL" "No Python 3.9 or newer found" "Install Python 3.12 from https://www.python.org/downloads/ (tick 'Add Python to PATH'), or run this command with -Full."
    } else { Record "OK" "Python $($Py.Version) ($($Py.Exe))" "" }

    if ($Py) {
        $PyExe = $Py.Exe
        $missing = @()
        foreach ($pkg in $PipPackages) {
            $mod = if ($ImportName.ContainsKey($pkg)) { $ImportName[$pkg] } else { $pkg }
            if ($DryRun) { $missing += $pkg; continue }
            & $PyExe -c "import $mod" *> $null
            if ($LASTEXITCODE -ne 0) { $missing += $pkg }
        }
        if (-not $DryRun) { & $PyExe -m pip show zotero-mcp-server *> $null; if ($LASTEXITCODE -ne 0) { $missing += "zotero-mcp-server" } }
        else { $missing += "zotero-mcp-server" }
        if ($missing.Count -eq 0) { Record "OK" "all Python packages already installed" "" }
        else {
            Say ("Installing Python packages (a few minutes): " + ($missing -join " "))
            Invoke-Step "$PyExe -m pip install $($missing -join ' ')" { & $PyExe -m pip install --disable-pip-version-check @missing }
            if ($LASTEXITCODE -eq 0) { Record "DONE" ("Python packages installed: " + ($missing -join " ")) "" }
            else { Record "FAIL" ("pip install failed for: " + ($missing -join " ")) "Read the error above. Fix is usually: py -m pip install $($missing -join ' ')" }
        }
    }

    # -----------------------------------------------------------------------
    Head "6. R (optional: only if you will use the R exercises)"
    if (-not (Have Rscript) -and $Full) {
        if (Install-WithWinget "RProject.R" "R") { Record "DONE" "R installed" "Open a NEW PowerShell window afterwards so Rscript is found." }
        else { Record "FAIL" "R did not install" "Download it from https://cran.r-project.org" }
    }
    if (Have Rscript) {
        Invoke-Step "Rscript -e install.packages(c($RPackages))" {
            $code = "lib <- Sys.getenv('R_LIBS_USER'); dir.create(lib, recursive=TRUE, showWarnings=FALSE); .libPaths(lib); need <- setdiff(c($RPackages), rownames(installed.packages())); if (length(need)) install.packages(need, lib=lib, repos='https://cloud.r-project.org')"
            & Rscript -e $code
        }
        if ($LASTEXITCODE -eq 0) { Record "OK" "R and its packages (readr, dplyr, tidyr, ggplot2, MASS)" "" }
        else { Record "FAIL" "R packages did not install" "Open R and run: install.packages(c($RPackages))" }
    } elseif (-not $Full) {
        Record "SKIPPED" "R not installed" "Only needed for R exercises. https://cran.r-project.org, or run this command with -Full."
    }
    Record "MANUAL" "Stata users only: install two packages inside Stata" "ssc install estout   and   ssc install outreg2   (needs your own Stata licence)"

    # -----------------------------------------------------------------------
    Head "7. LaTeX (needed for Session 3)"
    if (Have pdflatex) { Record "OK" "pdflatex found" "" }
    elseif ($Full) {
        # MiKTeX is the small distribution; VS Code's latexmk build needs Perl on Windows, so add Strawberry Perl.
        $texOk = Install-WithWinget "MiKTeX.MiKTeX" "MiKTeX (LaTeX)"
        if ($texOk -and -not (Have perl)) { $null = Install-WithWinget "StrawberryPerl.StrawberryPerl" "Strawberry Perl (needed by latexmk)" }
        if ($texOk) {
            Invoke-Step "initexmf --set-config-value=[MPM]AutoInstall=1" { & initexmf --set-config-value="[MPM]AutoInstall=1" *> $null }
            Record "DONE" "MiKTeX and Perl installed" "Open a NEW PowerShell window afterwards so pdflatex and perl are found."
        } else { Record "FAIL" "MiKTeX did not install" "Download it from https://miktex.org/download and Perl from https://strawberryperl.com" }
    } else {
        Record "MANUAL" "No LaTeX installed" "Install MiKTeX from https://miktex.org/download (smaller than TeX Live) and Strawberry Perl from https://strawberryperl.com, the day before, or run this command with -Full."
    }
    $testTex = Join-Path $Workspace "session_1\setup_check.tex"
    if ((Have latexmk) -and (Test-Path $testTex) -and -not $DryRun) {
        Push-Location (Split-Path $testTex)
        & latexmk -pdf -interaction=nonstopmode -halt-on-error setup_check.tex *> $null
        $ok = ($LASTEXITCODE -eq 0); Pop-Location
        if ($ok) { Record "OK" "setup_check.tex compiled to a PDF (LaTeX works)" "" }
        else { Record "FAIL" "setup_check.tex did not compile" "See the LaTeX entries in tools\TROUBLESHOOTING.md (usually Perl missing, or a LaTeX package missing)." }
    }

    # -----------------------------------------------------------------------
    Head "8. Zotero (needed for Session 4)"
    $zoteroPaths = @("$env:ProgramFiles\Zotero\zotero.exe", "${env:ProgramFiles(x86)}\Zotero\zotero.exe", "$env:LOCALAPPDATA\Zotero\zotero.exe")
    if ($zoteroPaths | Where-Object { $_ -and (Test-Path $_) }) { Record "OK" "Zotero app found" "" }
    elseif ($Full) {
        if (Install-WithWinget "DigitalScholar.Zotero" "Zotero") { Record "DONE" "Zotero app installed" "" }
        else { Record "FAIL" "Zotero did not install" "Download it from https://www.zotero.org/download/" }
    } else { Record "MANUAL" "Zotero app not installed" "Download it from https://www.zotero.org/download/ (or run this command with -Full)." }
    Record "MANUAL" "Zotero: sign in, then Edit > Settings > Advanced > tick 'Allow other applications on this computer to communicate with Zotero'" ""
    Record "MANUAL" "Zotero: File > Import the practice library" "Choose $HOME\claude-code-workshop\session_4\docs\claude_code_zotero\claude_code_zotero.rdf (keep the files folder next to it; tick 'Copy files to the Zotero storage folder')."

    # -----------------------------------------------------------------------
    Head "9. GitHub and Zotero MCPs (Session 4)"
    if (-not (Have claude)) {
        Record "MANUAL" "MCPs skipped: Claude Code is not installed yet" "Rerun this command once it is."
    } else {
        & claude mcp get github *> $null
        if ($LASTEXITCODE -eq 0 -and -not $DryRun) { Record "OK" "GitHub MCP already configured" "" }
        else {
            Say "GitHub token: create one at https://github.com/settings/tokens?type=beta (name claude-code-workshop, 90 days,"
            Say "  Repository permissions: Read and write on Contents, Issues, Pull requests). Treat it like a password."
            $token = Ask-Secret "Paste the token here (nothing is shown; press Enter to skip):"
            if ($token) {
                & claude mcp add --scope user --transport http github https://api.githubcopilot.com/mcp/ -H "Authorization: Bearer $token" *> $null
                if ($LASTEXITCODE -eq 0) { Record "DONE" "GitHub MCP added (user scope)" "" }
                else { Record "FAIL" "claude mcp add github failed" "Run it by hand using the command in Step 8b of the setup guide." }
                $token = $null
            } else { Record "MANUAL" "GitHub MCP not set up (no token entered)" "Needed for Session 4. Step 8 of the setup guide, or rerun this command with a token ready." }
        }
        & claude mcp get zotero *> $null
        if ($LASTEXITCODE -eq 0 -and -not $DryRun) { Record "OK" "Zotero MCP already configured" "" }
        else {
            Say "Zotero keys: your Library ID and a key from https://www.zotero.org/settings/keys (name claude-code-workshop, allow library access)."
            $libId = Ask "Zotero Library ID (a number; press Enter to skip):"
            if ($libId) {
                $zkey = Ask-Secret "Zotero API key (nothing is shown):"
                if ($zkey) {
                    & claude mcp add --scope user zotero -e ZOTERO_LOCAL=true -e "ZOTERO_LIBRARY_ID=$libId" -e "ZOTERO_API_KEY=$zkey" -e ZOTERO_LIBRARY_TYPE=user -- zotero-mcp serve *> $null
                    if ($LASTEXITCODE -eq 0) { Record "DONE" "Zotero MCP added (user scope)" "" }
                    else { Record "FAIL" "claude mcp add zotero failed" "Run it by hand using the command in Step 9e of the setup guide." }
                    $zkey = $null
                } else { Record "MANUAL" "Zotero MCP not set up (no key entered)" "Needed for Session 4. Step 9 of the setup guide." }
            } else { Record "MANUAL" "Zotero MCP not set up (no Library ID entered)" "Needed for Session 4. Step 9 of the setup guide." }
        }
    }
    Record "MANUAL" "Email the instructor your GitHub username (not your email address)" "So you can be added to the Session 4 class repository."

    # -----------------------------------------------------------------------
    Head "10. Checker"
    $doctor = $null
    foreach ($cand in @((Join-Path $Base "claude-code-workshop"), (Join-Path $Base "Documents\claude-code-workshop"), (Join-Path $Base "Desktop\claude-code-workshop"), (Join-Path $Base "claude-code-workshop-zip"))) {
        $p = Join-Path $cand "tools\doctor.ps1"
        if (Test-Path $p) { $doctor = $p; break }
    }
    if ($DryRun) { Say "[dry-run] would run doctor.ps1 from the course repo" }
    elseif ($doctor) { & powershell -NoProfile -ExecutionPolicy Bypass -File $doctor -Quick }
    else { Record "FAIL" "doctor.ps1 not found: the course materials were not downloaded" "Rerun this command; if it fails again, email the screen to the instructor." }

    # -----------------------------------------------------------------------
    Write-Host ""
    Write-Host "================ SETUP SUMMARY ================" -ForegroundColor White
    foreach ($r in $script:Results) {
        $color = switch ($r.Status) { "OK" { "Green" } "DONE" { "Green" } "WOULD" { "Cyan" } "FAIL" { "Red" } default { "Yellow" } }
        Write-Host ("  {0,-8} " -f $r.Status) -ForegroundColor $color -NoNewline
        Write-Host $r.Label
    }
    Write-Host ""
    if ($script:NFail -gt 0) { Write-Host "  $($script:NFail) step(s) FAILED. Screenshot this summary and the red lines above, and email them to the instructor." }
    else { Write-Host "  No failures. Anything marked MANUAL needs you (details are printed above)." }
    Write-Host "  Open VS Code on $Workspace and start Claude Code there."
    Write-Host "  Run the start-of-session command (github.com/$GithubRepo) at the start of every session."
    Write-Host "==============================================="
}

# Works for both "irm ... | iex" (no arguments) and the scriptblock form (-Full, -DryRun, -Yes).
Invoke-WorkshopSetup -Full:($args -contains '-Full') -DryRun:($args -contains '-DryRun') -Yes:($args -contains '-Yes')
