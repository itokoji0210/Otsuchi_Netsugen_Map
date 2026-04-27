param(
    [ValidateSet("daily", "social", "pr", "official", "all")]
    [string]$Mode = "daily",
    [switch]$Open
)

$packPath = Join-Path $PSScriptRoot "news_tip_search_pack.md"
$reader = New-Object System.IO.StreamReader($packPath, [System.Text.Encoding]::UTF8)
$lines = @()
try {
    while (($line = $reader.ReadLine()) -ne $null) {
        $lines += $line
    }
} finally {
    $reader.Close()
}

$sectionMap = @{
    daily = @("recent_core")
    social = @("social_signal")
    pr = @("pr_release", "near_future_event")
    official = @("official_confirmation")
    all = @("recent_core", "social_signal", "pr_release", "official_confirmation", "near_future_event")
}

$currentSection = ""
$queries = @()

foreach ($line in $lines) {
    if ($line -match "^###\s+(.+)$") {
        $currentSection = $Matches[1].Trim()
        continue
    }

    if ($sectionMap[$Mode] -contains $currentSection -and $line -match '^-\s+`(.+)`') {
        $queries += $Matches[1]
    }
}

foreach ($query in $queries) {
    $encoded = [uri]::EscapeDataString($query)
    $url = "https://www.google.com/search?q=$encoded&tbs=qdr:d"
    Write-Output $url
    if ($Open) {
        Start-Process -FilePath $url -WindowStyle Hidden
    }
}
