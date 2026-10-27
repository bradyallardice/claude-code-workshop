# doctor.ps1 - workshop setup checker (Windows PowerShell 5.1 and PowerShell 7).
#
# Checks every tool the workshop needs and prints PASS / WARN / FAIL with the
# fix for each problem. Read-only: it installs nothing and changes nothing.
#
# Windows blocks .ps1 scripts by default, so run it like this (one line):
#   powershell -ExecutionPolicy Bypass -File $HOME\claude-code-workshop\tools\doctor.ps1
# Add -Quick at the end to skip the slow MCP check.
#
# Screenshot the SUMMARY block at the bottom and send it to the instructor.
# Fix codes (e.g. [F07]) refer to sections in tools\TROUBLESHOOTING.md.

param([switch]$Quick)

$script:NPass = 0
$script:NWarn = 0
$script:NFail = 0
$script:FailCodes = @()

function Pass($msg) { $script:NPass++; Write-Host "  PASS  " -ForegroundColor Green -NoNewline; Write-Host $msg }
function Warn($msg, $fix) {
    $script:NWarn++
    Write-Host "  WARN  " -ForegroundColor Yellow -NoNewline; Write-Host $msg
    Write-Host "        fix: $fix"
}
function Fail($msg, $fix, $code) {
    $script:NFail++
    $script:FailCodes += $code
    Write-Host "  FAIL  " -ForegroundColor Red -NoNewline; Write-Host $msg
    Write-Host "        fix: $fix  [$code]"
}
function Section($title) { Write-Host ""; Write-Host $title -ForegroundColor White }
function Have($name) { return [bool](Get-Command $name -ErrorAction SilentlyContinue) }

Write-Host ("Workshop doctor - {0}  platform: windows  PowerShell {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm"), $PSVersionTable.PSVersion)

# ---------------------------------------------------------------------------
Section "1. Folders"
if ($HOME -match " ") {
    Warn "Your home folder path contains a space: $HOME" "tell the instructor; hooks need quoted paths [F01]"
} else {
    Pass "Home folder path has no spaces"
}

$CourseRepo = $null
$Candidates = @("$HOME\claude-code-workshop", "$HOME\Documents\claude-code-workshop", "$HOME\Desktop\claude-code-workshop")
if ($env:OneDrive) { $Candidates += @("$env:OneDrive\Documents\claude-code-workshop", "$env:OneDrive\Desktop\claude-code-workshop") }
foreach ($c in $Candidates) { if (Test-Path "$c\.git") { $CourseRepo = $c; break } }

if (-not $CourseRepo) {
    Fail "Course repo not found in your home, Documents or Desktop folder" "run the start-of-session command from github.com/bradyallardice/claude-code-workshop" "F02"
} elseif (Have git) {
    $Branch = (git -C "$CourseRepo" branch --show-current 2>$null)
    $Dirty = (git -C "$CourseRepo" status --porcelain 2>$null)
    if ($Branch -ne "student") {
        Warn "Course repo is on branch '$Branch', expected 'student'" "cd $CourseRepo; git checkout student [F02]"
    } elseif ($Dirty) {
        Warn "Course repo has local edits (git pull may refuse)" "work in ~\my_workspace, not the course repo; recovery in [F03]"
    } else {
        Pass "Course repo at $CourseRepo (branch student, clean)"
    }
}
if ($CourseRepo -and ($CourseRepo -match "OneDrive|Dropbox")) {
    Warn "Course repo is inside a cloud-synced folder ($CourseRepo)" "sync clients can lock files during git operations; clone to $HOME instead [F01]"
}

# ---------------------------------------------------------------------------
Section "2. Git and GitHub"
if (Have git) {
    Pass ("git " + ((git --version) -replace "git version ", ""))
    $GitName = (git config --global user.name)
    $GitEmail = (git config --global user.email)
    if (-not $GitName -or -not $GitEmail) {
        Fail "git user.name / user.email not set (first commit will fail)" 'git config --global user.name "Your Name"; git config --global user.email "you@example.com"' "F04"
    } else {
        Pass "git identity: $GitName <$GitEmail>"
    }
    $Helper = (git config --get credential.helper)
    $GhOk = $false
    if (Have gh) { gh auth status *> $null; if ($LASTEXITCODE -eq 0) { $GhOk = $true } }
    if ($GhOk) {
        Pass "GitHub CLI logged in (git push over HTTPS will work)"
    } elseif ($Helper -match "manager") {
        Pass "Git Credential Manager installed (browser login on first push)"
    } else {
        Warn "No GitHub login for git push (Sessions 4 and 5 need it)" "winget install GitHub.cli ; then: gh auth login --web --git-protocol https [F05]"
    }
} else {
    Fail "git not installed" "install Git for Windows from https://git-scm.com/downloads/win (default options)" "F04"
}

# Claude Code on native Windows runs commands through Git Bash.
$GitBash = $env:CLAUDE_CODE_GIT_BASH_PATH
if (-not $GitBash) { $GitBash = "C:\Program Files\Git\bin\bash.exe" }
if (Test-Path $GitBash) {
    Pass "Git Bash found at $GitBash"
} else {
    Fail "Git Bash not found at $GitBash (Claude Code needs it)" 'find bash.exe in your Git install, then: setx CLAUDE_CODE_GIT_BASH_PATH "C:\path\to\Git\bin\bash.exe"' "F06"
}

# ---------------------------------------------------------------------------
Section "3. Claude Code"
$ClaudeVersion = "none"
if (Have claude) {
    $ClaudeVersion = (claude --version 2>$null | Select-Object -First 1)
    Pass "claude $ClaudeVersion"
} else {
    Fail "claude command not found" "irm https://claude.ai/install.ps1 | iex   (normal PowerShell, not Administrator), then reopen PowerShell" "F06"
}

# ---------------------------------------------------------------------------
Section "4. Python"
# Several Pythons on one machine is common, and the first one found is not
# necessarily the one with the packages. Check every interpreter on PATH.
$Probe = Join-Path $env:TEMP "workshop_doctor_probe.py"
@'
import sys, importlib
missing = []
for name in ["pandas", "numpy", "statsmodels", "scipy", "linearmodels", "matplotlib", "seaborn", "sklearn", "openpyxl"]:
    try:
        importlib.import_module(name)
    except Exception:
        missing.append("scikit-learn" if name == "sklearn" else name)
print("%d.%d" % sys.version_info[:2])
print(sys.executable)
print(" ".join(missing))
'@ | Set-Content -Path $Probe -Encoding ASCII

$StoreStub = Get-Command python -ErrorAction SilentlyContinue
if ($StoreStub -and $StoreStub.Source -match "WindowsApps") {
    Warn "'python' points to the Microsoft Store placeholder" "Settings > Apps > Advanced app settings > App execution aliases: turn OFF python.exe and python3.exe [F07]"
}

# Python code goes through a temp file: PowerShell 5.1 mangles quotes in
# arguments passed to native programs.
$Pythons = @()
$Seen = @{}
foreach ($c in @("python", "py", "python3")) {
    $cmd = Get-Command $c -ErrorAction SilentlyContinue
    if (-not $cmd -or $cmd.Source -match "WindowsApps") { continue }
    $Out = @(& $c $Probe 2>$null)
    if ($LASTEXITCODE -ne 0 -or $Out.Count -lt 2) { continue }
    if ($Seen.ContainsKey($Out[1])) { continue }
    $Seen[$Out[1]] = $true
    $Pythons += [pscustomobject]@{ Cmd = $c; Version = $Out[0]; Path = $Out[1]; Missing = $(if ($Out.Count -ge 3) { "$($Out[2])".Trim() } else { "" }) }
}
Remove-Item $Probe -ErrorAction SilentlyContinue

$PyVersion = "none"
if ($Pythons.Count -eq 0) {
    Fail "No working Python found (tried python, py, python3)" "install Python 3.12 from python.org and tick 'Add Python to PATH'" "F07"
} else {
    $Ready = @($Pythons | Where-Object { -not $_.Missing -and [version]$_.Version -ge [version]"3.9" })
    if ($Ready.Count -gt 0) {
        $Best = $Ready[0]
        $PyVersion = $Best.Version
        Pass "Python $($Best.Version) has all packages: use '$($Best.Cmd)' ($($Best.Path))"
        if ([version]$Best.Version -ge [version]"3.15") { Warn "Python $($Best.Version) is very new" "it works now; if a later 'pip install' fails, install Python 3.12 [F07]" }
        foreach ($p in ($Pythons | Where-Object { $_.Path -ne $Best.Path })) {
            $Why = if ($p.Missing) { "missing: $($p.Missing)" } else { "too old for the course" }
            Warn "Another Python on PATH: '$($p.Cmd)' = $($p.Version) ($Why)" "always use '$($Best.Cmd) -m pip install ...'; in VS Code select $($Best.Path) [F08]"
        }
    } else {
        $Best = $Pythons[0]
        $PyVersion = $Best.Version
        if ([version]$Best.Version -lt [version]"3.9") {
            Fail "Python $($Best.Version) is too old" "install Python 3.12 from python.org" "F07"
        } else {
            Fail "Missing packages for $($Best.Path): $($Best.Missing)" "$($Best.Cmd) -m pip install $($Best.Missing)" "F08"
            if ([version]$Best.Version -ge [version]"3.15") { Warn "Python $($Best.Version) is very new; some packages may not install yet" "if pip fails, install Python 3.12 from python.org [F07]" }
        }
    }
}

# ---------------------------------------------------------------------------
Section "5. VS Code"
if (Have code) { Pass "'code' command available" } else {
    Fail "'code' command not on PATH ('code .' will fail)" "reinstall VS Code with 'Add to PATH' ticked, then reopen PowerShell" "F09"
}

# ---------------------------------------------------------------------------
Section "6. LaTeX"
if (Have pdflatex) {
    Pass "pdflatex found"
    $IsMiktex = ((pdflatex --version 2>$null | Select-Object -First 1) -match "MiKTeX")
    if (Have latexmk) {
        latexmk -v *> $null
        if ($LASTEXITCODE -eq 0) { Pass "latexmk works" } else {
            Warn "latexmk is installed but does not run (MiKTeX needs Perl for it)" "install Strawberry Perl (strawberryperl.com), or use the pdflatex recipe in LaTeX Workshop [F10]"
        }
    } else {
        Warn "latexmk not found (LaTeX Workshop's default recipe uses it)" "use the 'pdflatex -> bibtex -> pdflatex x2' recipe in LaTeX Workshop [F10]"
    }
    if (Have kpsewhich) {
        $MissingSty = @()
        foreach ($sty in @("booktabs", "setspace", "natbib", "makecell", "microtype", "caption", "geometry", "hyperref", "amsmath", "graphicx")) {
            $found = (kpsewhich "$sty.sty" 2>$null)
            if (-not $found) { $MissingSty += $sty }
        }
        if ($MissingSty.Count -eq 0) { Pass "LaTeX packages used by the course papers are installed" }
        elseif ($IsMiktex) { Warn ("Not yet installed: " + ($MissingSty -join " ")) "MiKTeX Console > Settings > 'Always install missing packages on-the-fly' [F11]" }
        else { Warn ("Missing LaTeX packages: " + ($MissingSty -join " ")) ("tlmgr install " + ($MissingSty -join " ") + " [F11]") }
    }
} else {
    Fail "pdflatex not found" "install TeX Live or MiKTeX, then restart the computer" "F10"
}

# ---------------------------------------------------------------------------
Section "7. R (optional)"
if (Have Rscript) { Pass "R found" } else { Write-Host "  ----  R not found (fine unless you use R)" }

# ---------------------------------------------------------------------------
Section "8. Zotero and MCP servers (Session 4)"
if (Have zotero-mcp) { Pass "zotero-mcp command found" } else {
    Warn "zotero-mcp not on PATH" "py -m pip install zotero-mcp-server, then see [F12] if still not found"
}
try {
    $Ping = Invoke-WebRequest -Uri "http://127.0.0.1:23119/connector/ping" -UseBasicParsing -TimeoutSec 2
    if ($Ping.Content -match "Zotero is running") {
        try {
            $Api = Invoke-WebRequest -Uri "http://127.0.0.1:23119/api/users/0/items?limit=1" -UseBasicParsing -TimeoutSec 2
            Pass "Zotero desktop running, local API enabled"
        } catch {
            Warn "Zotero running but local API is off" "Zotero Edit > Settings > Advanced > tick 'Allow other applications on this computer to communicate with Zotero' [F13]"
        }
    }
} catch {
    Warn "Zotero desktop app is not running" "open Zotero before using the Zotero MCP [F13]"
}

if (-not $Quick -and (Have claude)) {
    Write-Host "  ....  checking MCP servers (takes up to ~20 s; use -Quick to skip)"
    Push-Location $HOME
    $McpOut = (claude mcp list 2>&1 | Out-String)
    Pop-Location
    foreach ($server in @("github", "zotero")) {
        $line = ($McpOut -split "`n" | Where-Object { $_ -match "^$server" } | Select-Object -First 1)
        if (-not $line) {
            Warn "MCP server '$server' not registered for your user" "re-run the 'claude mcp add --scope user ...' command from the setup guide [F14]"
        } elseif ($line -match "Connected" -and $line -notmatch "Failed") {
            Pass "MCP server '$server' connected"
        } else {
            Warn "MCP server '$server' registered but not connected: $line" "see [F14]"
        }
    }
}

# ---------------------------------------------------------------------------
Section "9. Node.js (optional; needed only for the claude-ignore demo)"
if (Have npm) { Pass "npm found" } else { Write-Host "  ----  npm not found (install Node.js LTS if you want to try the claude-ignore demo)" }

# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "==================== SUMMARY ===================="
Write-Host ("  platform: windows   claude: {0}   python: {1}" -f $ClaudeVersion, $PyVersion)
Write-Host ("  PASS {0}   WARN {1}   FAIL {2}" -f $script:NPass, $script:NWarn, $script:NFail)
if ($script:NFail -eq 0) {
    Write-Host "  READY - screenshot this block and send it to the instructor." -ForegroundColor Green
} else {
    Write-Host ("  NOT READY - fix codes: {0} (see tools\TROUBLESHOOTING.md)" -f ($script:FailCodes -join " ")) -ForegroundColor Red
}
Write-Host "================================================="
