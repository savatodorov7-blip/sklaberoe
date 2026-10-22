param(
    [switch]$NoBrowser
)

$ErrorActionPreference = "Stop"
$projectRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$rootPrefix = $projectRoot.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) + [System.IO.Path]::DirectorySeparatorChar
$previewUrl = "http://localhost:8000/"
$listener = $null

function Get-ContentType {
    param([string]$Path)

    switch ([System.IO.Path]::GetExtension($Path).ToLowerInvariant()) {
        ".html" { return "text/html; charset=utf-8" }
        ".htm"  { return "text/html; charset=utf-8" }
        ".css"  { return "text/css; charset=utf-8" }
        ".js"   { return "application/javascript; charset=utf-8" }
        ".json" { return "application/json; charset=utf-8" }
        ".xml"  { return "application/xml; charset=utf-8" }
        ".txt"  { return "text/plain; charset=utf-8" }
        ".svg"  { return "image/svg+xml" }
        ".jpg"  { return "image/jpeg" }
        ".jpeg" { return "image/jpeg" }
        ".png"  { return "image/png" }
        ".webp" { return "image/webp" }
        ".gif"  { return "image/gif" }
        ".ico"  { return "image/x-icon" }
        ".woff" { return "font/woff" }
        ".woff2" { return "font/woff2" }
        default  { return "application/octet-stream" }
    }
}

function Send-Response {
    param(
        [System.IO.Stream]$Stream,
        [int]$StatusCode,
        [string]$StatusText,
        [string]$ContentType,
        [byte[]]$Body,
        [bool]$HeadOnly = $false
    )

    $header = "HTTP/1.1 $StatusCode $StatusText`r`n" +
        "Content-Type: $ContentType`r`n" +
        "Content-Length: $($Body.Length)`r`n" +
        "Cache-Control: no-store`r`n" +
        "Connection: close`r`n`r`n"
    $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
    $Stream.Write($headerBytes, 0, $headerBytes.Length)

    if (-not $HeadOnly -and $Body.Length -gt 0) {
        $Stream.Write($Body, 0, $Body.Length)
    }

    $Stream.Flush()
}

function Send-TextResponse {
    param(
        [System.IO.Stream]$Stream,
        [int]$StatusCode,
        [string]$StatusText,
        [string]$Message,
        [bool]$HeadOnly = $false
    )

    $body = [System.Text.Encoding]::UTF8.GetBytes(
        "<!doctype html><meta charset=`"utf-8`"><title>$StatusCode $StatusText</title><h1>$StatusCode $StatusText</h1><p>$Message</p>"
    )
    Send-Response `
        -Stream $Stream `
        -StatusCode $StatusCode `
        -StatusText $StatusText `
        -ContentType "text/html; charset=utf-8" `
        -Body $body `
        -HeadOnly $HeadOnly
}

try {
    $listener = [System.Net.Sockets.TcpListener]::new(
        [System.Net.IPAddress]::Loopback,
        8000
    )

    try {
        $listener.Start()
    }
    catch {
        throw "Cannot listen on localhost port 8000. $($_.Exception.Message)"
    }

    Write-Host "SUCCESS: Local preview server is running at $previewUrl" -ForegroundColor Green
    Write-Host "Serving: $projectRoot"
    Write-Host "Close this window or press Ctrl+C to stop the server."
    Write-Host ""

    if (-not $NoBrowser) {
        try {
            Start-Process -FilePath $previewUrl
        }
        catch {
            Write-Host "WARNING: The browser could not be opened automatically." -ForegroundColor Yellow
            Write-Host "Open $previewUrl manually."
        }
    }

    while ($true) {
        $client = $listener.AcceptTcpClient()

        try {
            $stream = $client.GetStream()
            $reader = [System.IO.StreamReader]::new(
                $stream,
                [System.Text.Encoding]::ASCII,
                $false,
                1024,
                $true
            )
            $requestLine = $reader.ReadLine()

            if ([string]::IsNullOrWhiteSpace($requestLine)) {
                continue
            }

            while ($null -ne ($headerLine = $reader.ReadLine()) -and $headerLine -ne "") {
                # Read through the request headers.
            }

            if ($requestLine -notmatch "^(GET|HEAD)\s+(\S+)\s+HTTP/\d(?:\.\d)?$") {
                Send-TextResponse `
                    -Stream $stream `
                    -StatusCode 405 `
                    -StatusText "Method Not Allowed" `
                    -Message "Only GET and HEAD requests are supported."
                continue
            }

            $method = $Matches[1]
            $requestTarget = $Matches[2]
            $headOnly = $method -eq "HEAD"

            try {
                $requestUri = [System.Uri]::new("http://localhost$requestTarget")
                $decodedPath = [System.Uri]::UnescapeDataString($requestUri.AbsolutePath)
                $relativePath = $decodedPath.TrimStart([char]"/").Replace(
                    "/",
                    [System.IO.Path]::DirectorySeparatorChar
                )

                if ([string]::IsNullOrWhiteSpace($relativePath)) {
                    $relativePath = "index.html"
                }

                $filePath = [System.IO.Path]::GetFullPath(
                    (Join-Path $projectRoot $relativePath)
                )

                if (
                    -not $filePath.Equals(
                        $projectRoot,
                        [System.StringComparison]::OrdinalIgnoreCase
                    ) -and
                    -not $filePath.StartsWith(
                        $rootPrefix,
                        [System.StringComparison]::OrdinalIgnoreCase
                    )
                ) {
                    Send-TextResponse `
                        -Stream $stream `
                        -StatusCode 403 `
                        -StatusText "Forbidden" `
                        -Message "The requested path is outside the preview directory." `
                        -HeadOnly $headOnly
                    continue
                }

                if (Test-Path -LiteralPath $filePath -PathType Container) {
                    $filePath = Join-Path $filePath "index.html"
                }
            }
            catch {
                Send-TextResponse `
                    -Stream $stream `
                    -StatusCode 400 `
                    -StatusText "Bad Request" `
                    -Message "The requested path is invalid." `
                    -HeadOnly $headOnly
                continue
            }

            if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
                Send-TextResponse `
                    -Stream $stream `
                    -StatusCode 404 `
                    -StatusText "Not Found" `
                    -Message "The requested file was not found." `
                    -HeadOnly $headOnly
                continue
            }

            $body = [System.IO.File]::ReadAllBytes($filePath)
            Send-Response `
                -Stream $stream `
                -StatusCode 200 `
                -StatusText "OK" `
                -ContentType (Get-ContentType $filePath) `
                -Body $body `
                -HeadOnly $headOnly
        }
        catch {
            Write-Host "Request error: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        finally {
            if ($null -ne $reader) {
                $reader.Dispose()
                $reader = $null
            }

            if ($null -ne $client) {
                $client.Close()
            }
        }
    }
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
finally {
    if ($null -ne $listener) {
        $listener.Stop()
    }
}
