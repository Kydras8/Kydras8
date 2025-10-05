# --- Kydras8 Ultimate Profile README Generator (PowerShell 7) ---
$ErrorActionPreference = 'Stop'

# ---------------- CONFIG ----------------
$WK = 'C:\Users\kyler'
$Repo = 'Kydras8'
$LogoPath = 'C:\Corporate Binder\Extras\kydras-systems-logo-2.png'
$GitHubUser = 'Kydras8'
$GitHubToken = "<YOUR_PERSONAL_ACCESS_TOKEN>"  # replace with your PAT
$Headers = @{ Authorization = "token $GitHubToken" }

# ---------------- HELPERS ----------------
function Write-Lines($Path, $Lines) {
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    Set-Content -Encoding UTF8 -NoNewline -Path $Path -Value ($Lines -join "`r`n")
}

function Get-LatestReleaseTag($owner, $repo) {
    try {
        $resp = Invoke-RestMethod "https://api.github.com/repos/$owner/$repo/releases/latest" -Headers $Headers -UseBasicParsing -TimeoutSec 5
        return $resp.tag_name
    } catch { return "N/A" }
}

function Get-ContributorsCount($owner, $repo) {
    try { (Invoke-RestMethod "https://api.github.com/repos/$owner/$repo/contributors?per_page=1" -Headers $Headers -UseBasicParsing | Measure-Object).Count } catch { 0 }
}

function Get-LastCommitDate($owner, $repo) {
    try { [datetime]::Parse((Invoke-RestMethod "https://api.github.com/repos/$owner/$repo/commits?per_page=1" -Headers $Headers -UseBasicParsing)[0].commit.committer.date) } catch { $null }
}

function Get-RelativeTime($date) {
    if (-not $date) { return "N/A" }
    $now=Get-Date
    $diff=$now-$date
    if($diff.TotalDays -ge 365) {"{0} years ago" -f [math]::Floor($diff.TotalDays/365)}
    elseif($diff.TotalDays -ge 30) {"{0} months ago" -f [math]::Floor($diff.TotalDays/30)}
    elseif($diff.TotalDays -ge 1) {"{0} days ago" -f [math]::Floor($diff.TotalDays)}
    elseif($diff.TotalHours -ge 1) {"{0} hours ago" -f [math]::Floor($diff.TotalHours)}
    elseif($diff.TotalMinutes -ge 1) {"{0} minutes ago" -f [math]::Floor($diff.TotalMinutes)}
    else {"Just now"}
}

# ---------------- STEP 1: ENTER REPO ----------------
Set-Location $WK
if (-not (Test-Path $Repo)) { gh repo clone $GitHubUser/$Repo }
Set-Location $Repo

# Abort any ongoing rebase
if (Test-Path ".git/rebase-apply") { git rebase --abort }

# Reset local branch to match remote
git fetch origin
git checkout main
git reset --hard origin/main

# ---------------- STEP 2: ADD LOGO ----------------
New-Item -ItemType Directory -Force assets | Out-Null
Copy-Item $LogoPath 'assets/kydras-logo.png' -Force

# ---------------- STEP 3: BUILD README HEADER ----------------
$Lines = @(
    "<p align='center'>",
    "  <img src='assets/kydras-logo.png' alt='Kydras Systems Inc.' width='480'/>",
    "</p>",
    "",
    "# Kydras Systems Inc. — Nothing is Off Limits",
    "Build • Secure • Create",
    "",
    "## 🏷️ Badge Legend",
    "| Badge | Meaning |",
    "|---|---|",
    "| ⚙️ ![CI](https://img.shields.io/badge/CI-Status-lightgrey?style=flat-square&logo=githubactions) | CI Workflow |",
    "| 🐍 ![Python](https://img.shields.io/badge/Python-S-blue?style=flat-square&logo=python) | Python Scripts |",
    "| 💻 ![Bash](https://img.shields.io/badge/Bash-S-green?style=flat-square&logo=gnu-bash) | Bash Scripts |",
    "| 🌐 ![HTML](https://img.shields.io/badge/HTML-S-orange?style=flat-square&logo=html5) | HTML/Frontend |",
    "| 👥 ![Contrib](https://img.shields.io/badge/Contrib-Numbers-lightgrey?style=flat-square&logo=github) | Contributors Count |",
    "| 🏷️ ![Release](https://img.shields.io/badge/Release-v0.1.0-blue?style=flat-square&logo=github) | Latest Release |",
    "| ⏱️ ![Last Commit](https://img.shields.io/badge/LastCommit-Date-lightgrey?style=flat-square&logo=git) | Last Commit (relative + hover) |",
    "| 📥 ![Download](https://img.shields.io/badge/Download-Latest-blue?style=flat-square&logo=github) | Latest Release Download |",
    "| 🚀 ![Demo](https://img.shields.io/badge/Demo-Live-green?style=flat-square&logo=google-chrome) | Live Web Demo |",
    "",
    "---",
    "",
    "## Contact & Links",
    "- Website: https://kydras-systems-inc.com",
    "- Email: kyle@kydras-systems-inc.com",
    "- GitHub: https://github.com/Kydras8",
    "- Buy Me a Coffee: https://buymeacoffee.com/kydras",
    "- Gumroad: https://gydras.gumroad.com",
    "",
    "---",
    "",
    "## 📊 The Kydras App Suite",
    "| App | Description | Repo & Badges |",
    "|---|---|---|"
)

# ---------------- STEP 4: DEFINE APPS ----------------
$Apps = @(
    @{ Name='Kydras Lab'; Repo='Kydras-Lab'; Desc='Build apps with AI'; Lang='Python'; Demo='https://kydras8.github.io/Kydras-Lab/'; Release=$true },
    @{ Name='Eyes of Kydras'; Repo='Eyes-of-Kydras'; Desc='Network visibility'; Lang='Python'; Demo=''; Release=$true },
    @{ Name='Kydras Intelligence'; Repo='Kydras-Intelligence'; Desc='OSINT platform'; Lang='Python'; Demo=''; Release=$true },
    @{ Name='Kydras Echo'; Repo='KydrasEcho'; Desc='AV transcription'; Lang='Python'; Demo=''; Release=$true },
    @{ Name='Kydras e-Book Studio'; Repo='Kydras-eBook-Studio'; Desc='E-book conversion'; Lang='Python'; Demo=''; Release=$true },
    @{ Name='Kydras Mobile Pentest Kit'; Repo='Kydras-Mobile-Pentest-Kit'; Desc='Field toolkit'; Lang='Bash'; Demo=''; Release=$true },
    @{ Name='Kydras Builder'; Repo='Kydras-Builder'; Desc='Website generator'; Lang='HTML'; Demo='https://kydras8.github.io/Kydras-Builder/'; Release=$true }
)

# ---------------- STEP 5: APP SECTIONS WITH COLLAPSIBLE GIFS AND RELEASES ----------------
foreach ($app in $Apps) {
    Write-Host "[*] Generating section for $($app.Name)..."

    $repo = $app.Repo
    $latestTag = if ($app.Release) { Get-LatestReleaseTag $GitHubUser $repo } else { 'N/A' }
    $contributors = Get-ContributorsCount $GitHubUser $repo
    $commitDate = Get-LastCommitDate $GitHubUser $repo
    $relativeCommit = Get-RelativeTime $commitDate
    $commitIso = if ($commitDate) { $commitDate.ToString("yyyy-MM-ddTHH:mm:ssZ") } else { "N/A" }

    switch ($app.Lang) {
        'Python' { $color='blue'; $icon='python'; $emoji='🐍' }
        'Bash'   { $color='green'; $icon='gnu-bash'; $emoji='💻' }
        'HTML'   { $color='orange'; $icon='html5'; $emoji='🌐' }
        default  { $color='lightgrey'; $icon=''; $emoji='' }
    }

    $langBadge = "$emoji ![${($app.Lang)}](https://img.shields.io/badge/${($app.Lang)}-S-$color?style=flat-square&logo=$icon&logoColor=white&label=${($app.Lang)})"
    $ciBadge = "⚙️ ![CI](https://img.shields.io/github/actions/workflow/status/$GitHubUser/$repo/ci.yml?style=flat-square&logo=githubactions&label=CI)"
    $contribBadge = "👥 ![Contrib](https://img.shields.io/badge/Contrib-$contributors-lightgrey?style=flat-square&logo=github&label=Contrib)"
    $versionBadge = "🏷️ ![Release](https://img.shields.io/badge/Release-$latestTag-blue?style=flat-square&logo=github&label=Release&tooltip=Release:$latestTag)"
    $lastUpdatedBadge = "⏱️ ![Last Commit](https://img.shields.io/badge/LastCommit-$relativeCommit-lightgrey?style=flat-square&logo=git&label=Last%20Commit&tooltip=Last%20commit:$commitIso)"
    $downloadBadge = if ($app.Release) { "📥 [Download](https://github.com/$GitHubUser/$repo/releases/latest)" } else { "" }
    $demoBadge = if ($app.Demo) { "🚀 [Demo]($($app.Demo))" } else { "" }

    # Collapsible section
    $Lines += @(
        "<details>",
        "<summary>📦 $($app.Name) — $($app.Desc)</summary>",
        "",
        "| Badge | Status |",
        "|---|---|",
        "| Repo | [Link](https://github.com/$GitHubUser/$repo) $ciBadge $langBadge $contribBadge $versionBadge $lastUpdatedBadge $downloadBadge $demoBadge |",
        ""
    )

    # GIF preview
    $gifPath = "assets/$repo_demo.gif"
    if (Test-Path $gifPath) {
        $Lines += "<img src='$gifPath' alt='$($app.Name) demo' width='480'/>"
    }

    # Release notes preview with auth + timeout + caching
    if ($app.Release) {
        try {
            $resp = Invoke-RestMethod "https://api.github.com/repos/$GitHubUser/$repo/releases/latest" -Headers $Headers -UseBasicParsing -TimeoutSec 5
            if ($resp -and $resp.body) {
                $latestRelease = $resp.body
                $releaseLines = ($latestRelease -split "`n")
                if ($releaseLines.Count -gt 3) { $releaseLines = $releaseLines[0..2] }
                $Lines += "### Latest Release Notes"
                $Lines += "```text"
                $Lines += $releaseLines
                $Lines += "```"
            }
        } catch {
            Write-Host "[i] No release info or request timed out for $repo"
        }
    }

    $Lines += "</details>"
    $Lines += ""
    Start-Sleep -Milliseconds 300  # Avoid hitting API rate limits
}

# ---------------- STEP 6: FOOTER ----------------
$Lines += @(
    "",
    "---",
    "",
    "## 🛡️ Vision & Ethos",
    "- Secure by design — red team roots, hacker-grade quality",
    "- AI everywhere — intelligent automation across workflows",
    "- Creative unleashed — music, books, content, all powered by AI",
    "",
    "> We engineer tools for operators who need to **see deeper**, **act faster**, and **build smarter**.",
    "",
    "<details>",
    "<summary>🖥️ Hacker Vibe (expand)</summary>",
    "```",
    "   ██ ▄█▀   ▓██   ██▓ ▓█████▄  ██▀███   ▄▄▄       ██████ ",
    "   ██▄█▒     ▒██  ██▒ ▒██▀ ██▌▓██ ▒ ██▒▒████▄   ▒██    ▒ ",
    "  ▓███▄░      ▒██ ██░ ░██   █▌▓██ ░▄█ ▒▒██  ▀█▄ ░ ▓██▄   ",
    "  ▓██ █▄      ░ ▐██▓░ ░▓█▄   ▌▒██▀▀█▄  ░██▄▄▄▄██  ▒   ██▒",
    "  ▒██▒ █▄     ░ ██▒▓░ ░▒████▓ ░██▓ ▒██▒ ▓█   ▓██▒██████▒▒",
    "  ▒ ▒▒ ▓▒      ██▒▒▒   ▒▒▓  ▒ ░ ▒▓ ░▒▓░ ▒▒   ▓▒█▒ ▒▓▒ ▒ ░",
    "  ░ ░▒ ▒░    ▓██ ░▒░   ░ ▒  ▒   ░▒ ░ ▒░  ▒   ▒▒ ░ ░▒  ░ ░",
    "  ░ ░░ ░     ▒ ▒ ░░    ░ ░  ░   ░░   ░   ░   ▒  ░  ░  ░  ",
    "  ░  ░       ░ ░         ░       ░           ░  ░     ░  ",
    "              ░ ░       ░                               ",
    "```",
    "</details>",
    "",
    "### ⚖️ Legal",
    "For authorized security testing and education only. Comply with all applicable laws."
)

# ---------------- STEP 7: WRITE README ----------------
Write-Lines "README.md" $Lines

# ---------------- STEP 8: COMMIT & PUSH ----------------
git add README.md assets/kydras-logo.png
git commit -m "[Kydras] README + dynamic badges + hover tooltips + collapsible GIFs"
git push -u origin main

