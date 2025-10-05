# ---------------- Kydras8 Ultimate README Generator ----------------
# PowerShell 7 required
# Run from your repo root
# ---------------- CONFIG ----------------
$RepoRoot = "$PWD"                       # Run from repo root
$AssetsFolder = "assets"
$LogoPath = "$RepoRoot\Extras\kydras-systems-logo-2.png"
$OnePagerDoc = "$RepoRoot\Extras\Kydras_Systems_OnePager.docx"
$GitHubUser = "Kydras8"
$GitHubToken = "<YOUR_PERSONAL_ACCESS_TOKEN>"  # Replace with PAT
$Headers = @{ Authorization = "token $GitHubToken" }
$ForceRefresh = $false                   # Set $true to refresh cached data
$HtmlOutput = "$RepoRoot\index.html"

# ---------------- HELPERS ----------------
function Write-Lines($Path, $Lines) {
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    Set-Content -Encoding UTF8 -NoNewline -Path $Path -Value ($Lines -join "`r`n")
}

function Get-CacheFile($repo, $type) { "$RepoRoot\.cache\$repo.$type.json" }

function Load-Cache($repo, $type) {
    $file = Get-CacheFile $repo $type
    if (Test-Path $file -and -not $ForceRefresh) { return Get-Content $file | ConvertFrom-Json }
    return $null
}

function Save-Cache($repo, $type, $data) {
    $file = Get-CacheFile $repo $type
    $dir = Split-Path -Parent $file
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    $data | ConvertTo-Json | Set-Content $file
}

function Get-LatestReleaseTag($repo) {
    $cached = Load-Cache $repo "release"
    if ($cached) { return $cached.tag_name }
    try {
        $resp = Invoke-RestMethod "https://api.github.com/repos/$GitHubUser/$repo/releases/latest" -Headers $Headers -UseBasicParsing -TimeoutSec 5
        Save-Cache $repo "release" $resp
        return $resp.tag_name
    } catch { return "N/A" }
}

function Get-LastReleaseDate($repo) {
    $cached = Load-Cache $repo "release"
    if ($cached) { return [datetime]::Parse($cached.published_at) }
    try {
        $resp = Invoke-RestMethod "https://api.github.com/repos/$GitHubUser/$repo/releases/latest" -Headers $Headers -UseBasicParsing -TimeoutSec 5
        Save-Cache $repo "release" $resp
        return [datetime]::Parse($resp.published_at)
    } catch { return $null }
}

function Get-ContributorsCount($repo) {
    $cached = Load-Cache $repo "contributors"
    if ($cached) { return $cached.Count }
    try {
        $resp = Invoke-RestMethod "https://api.github.com/repos/$GitHubUser/$repo/contributors?per_page=100" -Headers $Headers -UseBasicParsing -TimeoutSec 5
        Save-Cache $repo "contributors" $resp
        return $resp.Count
    } catch { return 0 }
}

function Get-LastCommitDate($repo) {
    $cached = Load-Cache $repo "commit"
    if ($cached) { return [datetime]::Parse($cached[0].commit.committer.date) }
    try {
        $resp = Invoke-RestMethod "https://api.github.com/repos/$GitHubUser/$repo/commits?per_page=1" -Headers $Headers -UseBasicParsing -TimeoutSec 5
        Save-Cache $repo "commit" $resp
        return [datetime]::Parse($resp[0].commit.committer.date)
    } catch { return $null }
}

function Get-RelativeTime($date) {
    if (-not $date) { return "N/A" }
    $diff = (Get-Date) - $date
    if ($diff.TotalDays -ge 365) { "{0} years ago" -f [math]::Floor($diff.TotalDays/365) }
    elseif ($diff.TotalDays -ge 30) { "{0} months ago" -f [math]::Floor($diff.TotalDays/30) }
    elseif ($diff.TotalDays -ge 1) { "{0} days ago" -f [math]::Floor($diff.TotalDays) }
    elseif ($diff.TotalHours -ge 1) { "{0} hours ago" -f [math]::Floor($diff.TotalHours) }
    elseif ($diff.TotalMinutes -ge 1) { "{0} minutes ago" -f [math]::Floor($diff.TotalMinutes) }
    else { "Just now" }
}

# ---------------- STEP 0: Prepare OnePager Markdown ----------------
$OnePagerMd = "$AssetsFolder\OnePager.md"
if (Get-Command pandoc -ErrorAction SilentlyContinue) {
    try {
        pandoc $OnePagerDoc -t markdown -o $OnePagerMd
        Write-Host "[i] OnePager converted to Markdown."
    } catch { Write-Host "[!] Pandoc conversion failed: $_"; $OnePagerMd = $null }
} else { $OnePagerMd = $null }

# ---------------- STEP 1: Build README ----------------
$Lines = @(
    "<p align='center'><img src='$AssetsFolder/kydras-logo.png' width='480'/></p>",
    "",
    "# Kydras Systems Inc. — Nothing is Off Limits",
    "Build • Secure • Create",
    "",
    "## 🏷️ Badge Legend",
    "| Badge | Meaning |",
    "|---|---|",
    "| ⚙️ CI | CI Workflow |",
    "| 🐍 Python | Python Scripts |",
    "| 💻 Bash | Bash Scripts |",
    "| 🌐 HTML | HTML/Frontend |",
    "| 👥 Contrib | Contributors Count |",
    "| 🏷️ Release | Latest Release |",
    "| 🗓️ LastRelease | Last Release Date |",
    "| ⏱️ Last Commit | Last Commit |",
    "| 📥 Download | Release Download |",
    "| 🚀 Demo | Live Web Demo |",
    "",
    "---",
    "",
    "## Contact & Links",
    "- Website: https://kydras-systems-inc.com",
    "- Email: kyle@kydras-systems-inc.com",
    "- GitHub: https://github.com/$GitHubUser",
    "- Buy Me a Coffee: https://buymeacoffee.com/kydras",
    "- Gumroad: https://gydras.gumroad.com",
    "",
    "---",
    "",
    "## 📊 The Kydras App Suite",
    "| App | Description | Repo & Badges |",
    "|---|---|---|"
)

# ---------------- STEP 2: Define Apps ----------------
$Apps = @(
    @{ Name='Kydras Lab'; Repo='Kydras-Lab'; Desc='Build apps with AI'; Lang='Python'; Demo='https://kydras8.github.io/Kydras-Lab/'; Release=$true },
    @{ Name='Eyes of Kydras'; Repo='Eyes-of-Kydras'; Desc='Network visibility'; Lang='Python'; Demo=''; Release=$true },
    @{ Name='Kydras Intelligence'; Repo='Kydras-Intelligence'; Desc='OSINT platform'; Lang='Python'; Demo=''; Release=$true },
    @{ Name='Kydras Echo'; Repo='KydrasEcho'; Desc='AV transcription'; Lang='Python'; Demo=''; Release=$true },
    @{ Name='Kydras e-Book Studio'; Repo='Kydras-eBook-Studio'; Desc='E-book conversion'; Lang='Python'; Demo=''; Release=$true },
    @{ Name='Kydras Mobile Pentest Kit'; Repo='Kydras-Mobile-Pentest-Kit'; Desc='Field toolkit'; Lang='Bash'; Demo=''; Release=$true },
    @{ Name='Kydras Builder'; Repo='Kydras-Builder'; Desc='Website generator'; Lang='HTML'; Demo='https://kydras8.github.io/Kydras-Builder/'; Release=$true }
)

# ---------------- STEP 3: App Sections ----------------
foreach ($app in $Apps) {
    Write-Host "[*] Generating section for $($app.Name)..."

    $repo = $app.Repo
    $latestTag = if ($app.Release) { Get-LatestReleaseTag $repo } else { 'N/A' }
    $lastReleaseDate = if ($app.Release) { Get-LastReleaseDate $repo } else { $null }
    $contributors = Get-ContributorsCount $repo
    $commitDate = Get-LastCommitDate $repo
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
    $lastReleaseBadge = if ($lastReleaseDate) { "🗓️ ![LastRelease](https://img.shields.io/badge/LastRelease-$(Get-RelativeTime $lastReleaseDate)-lightgrey?style=flat-square&logo=github&label=LastRelease&tooltip=Last release:$($lastReleaseDate.ToString('yyyy-MM-dd')))" } else { "" }
    $lastUpdatedBadge = "⏱️ ![Last Commit](https://img.shields.io/badge/LastCommit-$relativeCommit-lightgrey?style=flat-square&logo=git&label=Last%20Commit&tooltip=Last%20commit:$commitIso)"
    $downloadBadge = if ($app.Release) { "📥 [Download](https://github.com/$GitHubUser/$repo/releases/latest)" } else { "" }
    $demoBadge = if ($app.Demo) { "🚀 [Demo]($($app.Demo))" } else { "" }

    # Collapsible app section
    $Lines += @(
        "<details>",
        "<summary>📦 $($app.Name) — $($app.Desc)</summary>",
        "",
        "| Badge | Status |",
        "|---|---|",
        "| Repo | [Link](https://github.com/$GitHubUser/$repo) $ciBadge $langBadge $contribBadge $versionBadge $lastReleaseBadge $lastUpdatedBadge $downloadBadge $demoBadge |",
        ""
    )

    # GIF preview
    $gifPath = "$AssetsFolder/$repo_demo.gif"
    if (Test-Path $gifPath) { $Lines += "<img src='$gifPath' alt='$($app.Name) demo' width='480'/>" }

    # Embed OnePager Markdown
    if ($OnePagerMd -and (Test-Path $OnePagerMd)) {
        $Lines += "<details>"
        $Lines += "<summary>📄 OnePager Overview</summary>"
        $Lines += ""
        $Lines += Get-Content $OnePagerMd -Raw -ErrorAction SilentlyContinue
        $Lines += "</details>"
        $Lines += ""
    }

    Start-Sleep -Milliseconds 250  # Safe API pacing
}

# ---------------- STEP 4: Footer ----------------
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

# ---------------- STEP 5: Write README ----------------
Write-Lines "README.md" $Lines

# ---------------- STEP 6: Commit & Push ----------------
git add README.md "$AssetsFolder/kydras-logo.png"
git commit -m "[Kydras] README + badges + OnePager + hover tooltips + collapsible GIFs"
git push -u origin main

# ---------------- STEP 7: Optional GitHub Pages ----------------
if (Get-Command pandoc -ErrorAction SilentlyContinue) {
    Write-Host "[i] Pandoc found, converting README.md → index.html..."
    try {
        pandoc README.md -s -o $HtmlOutput `
            --css "https://cdnjs.cloudflare.com/ajax/libs/github-markdown-css/5.2.0/github-markdown-light.min.css" `
            --metadata title="Kydras Systems Inc. Dashboard"
        Write-Host "[✓] README.md converted → index.html"
    } catch { Write-Host "[!] Pandoc conversion failed: $_" }

    # Deploy to gh-pages
    if (-not (git rev-parse --is-inside-work-tree 2>$null)) {
        Write-Host "[!] Not inside a Git repository. Skipping Pages deployment."
    } else {
        git checkout --orphan gh-pages 2>$null
        git rm -rf . 2>$null
        git commit --allow-empty -m "Init gh-pages branch" 2>$null
        git push origin gh-pages 2>$null
        git checkout gh-pages
        Copy-Item README.md -Destination README.md -Force
        Copy-Item index.html -Destination index.html -Force
        if (Test-Path $AssetsFolder) { Copy-Item "$AssetsFolder\*" -Destination $AssetsFolder -Recurse -Force }
        git add README.md index.html "$AssetsFolder/*"
        git commit -m "[Kydras] Updated Pages dashboard (cached releases, badges, GIFs, OnePager)" 2>$null
        git push -u origin gh-pages 2>$null
        git checkout main
        Write-Host "[✓] GitHub Pages updated: https://$GitHubUser.github.io/$Repo/"
    }
} else {
    Write-Host "[!] Pandoc not installed. Pages deployment skipped."
}

