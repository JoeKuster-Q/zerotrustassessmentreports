<#
.SYNOPSIS
    Starts a local HTTP server and opens the Raw Data Viewer in the default browser.

.DESCRIPTION
    The Raw Data Viewer (raw-data-viewer.html) uses the browser fetch() API to load
    local JSON files from the ZeroTrustReport/zt-export/ folder.  Browsers block
    fetch() requests for files loaded via the file:// protocol, so the page must be
    served over HTTP.

    This script starts a minimal HTTP server using .NET's built-in HttpListener class
    (no external software or installation required) and then opens the viewer in your
    default browser.

    The server serves files from the repository root so that all relative paths
    resolve correctly:
        http://localhost:<Port>/src/report/raw-data-viewer.html   ← the viewer
        http://localhost:<Port>/ZeroTrustReport/zt-export/...     ← JSON data

.PARAMETER Port
    TCP port for the local HTTP server.  Defaults to 8080.  If the chosen port is
    already in use the script will exit with an error message.

.EXAMPLE
    .\Open-RawDataViewer.ps1

    Starts the server on port 8080 and opens the viewer in the default browser.

.EXAMPLE
    .\Open-RawDataViewer.ps1 -Port 9090

    Starts the server on port 9090 instead.

.NOTES
    Press Ctrl+C (or close this PowerShell window) to stop the server.
#>

[CmdletBinding()]
param (
    [int] $Port = 8080
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Resolve paths ────────────────────────────────────────────────────────────
# This script lives at: <repo-root>/src/report/Open-RawDataViewer.ps1
# The repo root is therefore two directories up.
$scriptDir = $PSScriptRoot
$repoRoot  = (Get-Item (Join-Path $scriptDir '../..')).FullName

$htmlRelPath = 'src/report/raw-data-viewer.html'
$htmlFullPath = Join-Path $repoRoot $htmlRelPath

if (-not (Test-Path $htmlFullPath)) {
    Write-Error "Cannot find raw-data-viewer.html at: $htmlFullPath"
    exit 1
}

$exportPath = Join-Path $repoRoot 'ZeroTrustReport' 'zt-export'
if (-not (Test-Path $exportPath)) {
    Write-Warning "The export folder was not found at: $exportPath"
    Write-Warning "Run the Zero Trust Assessment first to generate the JSON data, then re-open the viewer."
    Write-Warning "(The viewer will still open and show an empty state until the data is present.)"
}

# ── MIME type helper ─────────────────────────────────────────────────────────
function Get-ContentType {
    param([string] $Extension)
    switch ($Extension.ToLower()) {
        '.html' { 'text/html; charset=utf-8' }
        '.htm'  { 'text/html; charset=utf-8' }
        '.json' { 'application/json; charset=utf-8' }
        '.js'   { 'application/javascript; charset=utf-8' }
        '.css'  { 'text/css; charset=utf-8' }
        '.png'  { 'image/png' }
        '.svg'  { 'image/svg+xml' }
        '.ico'  { 'image/x-icon' }
        default { 'application/octet-stream' }
    }
}

# ── Start HttpListener ────────────────────────────────────────────────────────
$prefix = "http://localhost:$Port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
}
catch [System.Net.HttpListenerException] {
    Write-Error "Cannot start HTTP server on port $Port — the port may already be in use.`nTry running with a different port: .\Open-RawDataViewer.ps1 -Port 9090"
    exit 1
}

$viewerUrl = "${prefix}${htmlRelPath}"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        Zero Trust Assessment — Raw Data Viewer               ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Server  : $prefix" -ForegroundColor White
Write-Host "  Viewer  : $viewerUrl" -ForegroundColor Green
Write-Host "  Data    : $exportPath" -ForegroundColor White
Write-Host ""
Write-Host "  Opening browser…" -ForegroundColor Yellow
Write-Host "  Press Ctrl+C to stop the server." -ForegroundColor Yellow
Write-Host ""

# Open the browser
Start-Process $viewerUrl

# ── Request-handling loop ─────────────────────────────────────────────────────
try {
    while ($listener.IsListening) {
        # GetContext() blocks until a request arrives; wrap in try/catch so that
        # a single bad request doesn't kill the whole server.
        try {
            $context  = $listener.GetContext()
            $request  = $context.Request
            $response = $context.Response

            # Decode and sanitise the URL path to a local file path.
            # Use GetFullPath to canonicalise the path, then verify it stays
            # within the repository root to prevent path-traversal attacks.
            $urlPath  = $request.Url.AbsolutePath.TrimStart('/')
            $filePath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $urlPath))

            if (-not $filePath.StartsWith($repoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
                $response.StatusCode = 403
                $body = [System.Text.Encoding]::UTF8.GetBytes('403 Forbidden')
                $response.ContentType = 'text/plain; charset=utf-8'
                $response.ContentLength64 = $body.Length
                $response.OutputStream.Write($body, 0, $body.Length)
            }
            elseif (Test-Path $filePath -PathType Leaf) {
                $bytes = [System.IO.File]::ReadAllBytes($filePath)
                $ext   = [System.IO.Path]::GetExtension($filePath)

                $response.StatusCode  = 200
                $response.ContentType = Get-ContentType $ext
                $response.ContentLength64 = $bytes.Length
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            }
            else {
                $response.StatusCode = 404
                $body = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $urlPath")
                $response.ContentType = 'text/plain; charset=utf-8'
                $response.ContentLength64 = $body.Length
                $response.OutputStream.Write($body, 0, $body.Length)
            }
        }
        catch [System.Net.HttpListenerException] {
            # Listener was stopped (e.g. Ctrl+C) — exit cleanly
            break
        }
        catch {
            Write-Warning "Request handling error: $_"
        }
        finally {
            try { $context.Response.OutputStream.Close() } catch { }
        }
    }
}
finally {
    $listener.Stop()
    Write-Host ""
    Write-Host "Server stopped." -ForegroundColor Yellow
}
