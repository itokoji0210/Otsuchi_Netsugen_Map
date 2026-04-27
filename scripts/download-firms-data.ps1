param(
    [string]$MapKey = $env:FIRMS_MAP_KEY,
    [string]$Area = "141.78,39.30,141.97,39.44",
    [string[]]$Sources = @("VIIRS_SNPP_NRT", "VIIRS_NOAA20_NRT", "VIIRS_NOAA21_NRT", "MODIS_NRT"),
    [int]$DayRange = 10,
    [string]$OutputPath = "data/firms-otsuchi-latest.csv",
    [string]$ArchiveDirectory = "data/archive"
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($MapKey)) {
    throw "FIRMS MAP_KEY is required. Set `$env:FIRMS_MAP_KEY or pass -MapKey."
}

if ($DayRange -lt 1 -or $DayRange -gt 10) {
    throw "DayRange must be between 1 and 10 for the FIRMS area CSV API."
}

$outputDir = Split-Path -Parent $OutputPath
if ($outputDir -and -not (Test-Path -LiteralPath $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

if ($ArchiveDirectory -and -not (Test-Path -LiteralPath $ArchiveDirectory)) {
    New-Item -ItemType Directory -Path $ArchiveDirectory | Out-Null
}

$combined = New-Object System.Collections.Generic.List[string]
$wroteHeader = $false

foreach ($source in $Sources) {
    $url = "https://firms.modaps.eosdis.nasa.gov/api/area/csv/$MapKey/$source/$Area/$DayRange"
    Write-Host "Downloading latest $DayRange day(s) from $source"

    $csv = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
    $lines = $csv -split "`r?`n" | Where-Object { $_.Trim().Length -gt 0 }

    if ($lines.Count -lt 2) {
        continue
    }

    if (-not $wroteHeader) {
        $combined.Add("source,$($lines[0])")
        $wroteHeader = $true
    }

    foreach ($line in $lines[1..($lines.Count - 1)]) {
        $combined.Add("$source,$line")
    }
}

if ($combined.Count -le 1) {
    $combined.Clear()
    $combined.Add("source,latitude,longitude,bright_ti4,scan,track,acq_date,acq_time,satellite,instrument,confidence,version,bright_ti5,frp,daynight,type")
    Write-Warning "No FIRMS rows were downloaded. Saved a header-only CSV so the empty result is explicit."
}

$combined | Set-Content -LiteralPath $OutputPath -Encoding UTF8

if ($ArchiveDirectory) {
    $stamp = Get-Date -Format "yyyy-MM-dd"
    $archivePath = Join-Path $ArchiveDirectory "firms-otsuchi-$stamp.csv"
    $combined | Set-Content -LiteralPath $archivePath -Encoding UTF8
    Write-Host "Archived a copy to $archivePath"
}

Write-Host "Saved $($combined.Count - 1) row(s) to $OutputPath"
