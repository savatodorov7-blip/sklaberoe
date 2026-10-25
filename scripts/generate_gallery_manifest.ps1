$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$outputPath = Join-Path $projectRoot "assets\gallery\gallery-manifest.json"
$optimizedRootRelative = "assets\gallery\optimized"
$optimizedRoot = Join-Path $projectRoot $optimizedRootRelative
$cachePath = Join-Path $optimizedRoot "optimization-cache.json"
$supportedExtensions = @(".jpg", ".jpeg", ".png", ".webp")
$jpegExtensions = @(".jpg", ".jpeg")
$thumbnailMaxDimension = 700
$thumbnailQuality = 78
$fullMaxDimension = 1920
$fullQuality = 85
$optimizationSettings = "jpeg-v1-thumb-$thumbnailMaxDimension-q$thumbnailQuality-full-$fullMaxDimension-q$fullQuality"

function ConvertFrom-Utf8Base64 {
    param([string]$Value)

    return [System.Text.Encoding]::UTF8.GetString(
        [System.Convert]::FromBase64String($Value)
    )
}

$albums = @(
    [PSCustomObject]@{
        Id = "kids-athletics"
        Title = (ConvertFrom-Utf8Base64 "0JTQtdGC0YHQutCwINCw0YLQu9C10YLQuNC60LA=")
        Subtitle = (ConvertFrom-Utf8Base64 "0JzQvtC80LXQvdGC0Lgg0L7RgiDRgtGA0LXQvdC40YDQvtCy0LrQuNGC0LU=")
        Folder = "assets\gallery\kids-athletics"
        PreferredCover = "kids-03.jpg"
    },
    [PSCustomObject]@{
        Id = "training-process"
        Title = (ConvertFrom-Utf8Base64 "0KLRgNC10L3QuNGA0L7QstGK0YfQtdC9INC/0YDQvtGG0LXRgQ==")
        Subtitle = (ConvertFrom-Utf8Base64 "0J/QvtC00LPQvtGC0L7QstC60LAg0Lgg0YDQsNC30LLQuNGC0LjQtSDQvdCwINC90LDRiNC40YLQtSDQsNGC0LvQtdGC0Lg=")
        Folder = (ConvertFrom-Utf8Base64 "YXNzZXRzXGdhbGxlcnlc0KLRgNC10L3QuNGA0L7QstGK0YfQtdC9INC/0YDQvtGG0LXRgQ==")
        PreferredCover = "training-01.jpg"
    },
    [PSCustomObject]@{
        Id = "competitions"
        Title = (ConvertFrom-Utf8Base64 "0KHRitGB0YLQtdC30LDQvdC40Y8=")
        Subtitle = (ConvertFrom-Utf8Base64 "0JzQvtC80LXQvdGC0Lgg0L7RgiDRgdGK0YHRgtC10LfQsNGC0LXQu9C90LjRjyDRgdC10LfQvtC9")
        Folder = "assets\gallery\competitions"
        PreferredCover = "competition-09.jpg"
        CoverFirst = $true
    },
    [PSCustomObject]@{
        Id = "kids-day"
        Title = (ConvertFrom-Utf8Base64 "0JrQu9GD0LHQtdC9INC20LjQstC+0YI=")
        Subtitle = (ConvertFrom-Utf8Base64 "0KHRitCx0LjRgtC40Y8g0Lgg0LzQvtC80LXQvdGC0Lgg0L7RgiDQttC40LLQvtGC0LAg0L3QsCDQutC70YPQsdCw")
        Folder = "assets\gallery\club-life"
        PreferredCover = "club-01.jpg"
    }
)

function Get-NaturalSortKey {
    param([string]$Name)

    return [regex]::Replace(
        $Name.ToLowerInvariant(),
        "\d+",
        { param($match) $match.Value.PadLeft(20, "0") }
    )
}

function Get-PublicImagePath {
    param(
        [string]$Folder,
        [string]$FileName
    )

    $publicFolder = $Folder.Replace("\", "/")
    return "./$publicFolder/$FileName"
}

function Get-FileSha256 {
    param([string]$Path)

    $stream = $null
    $sha256 = $null

    try {
        $stream = [System.IO.File]::OpenRead($Path)
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        return [System.BitConverter]::ToString(
            $sha256.ComputeHash($stream)
        ).Replace("-", "")
    }
    finally {
        if ($null -ne $sha256) { $sha256.Dispose() }
        if ($null -ne $stream) { $stream.Dispose() }
    }
}

function Set-CorrectImageOrientation {
    param([System.Drawing.Image]$Image)

    try {
        $orientation = [System.BitConverter]::ToUInt16(
            $Image.GetPropertyItem(0x0112).Value,
            0
        )
    }
    catch {
        return
    }

    $rotateFlip = switch ($orientation) {
        2 { [System.Drawing.RotateFlipType]::RotateNoneFlipX }
        3 { [System.Drawing.RotateFlipType]::Rotate180FlipNone }
        4 { [System.Drawing.RotateFlipType]::Rotate180FlipX }
        5 { [System.Drawing.RotateFlipType]::Rotate90FlipX }
        6 { [System.Drawing.RotateFlipType]::Rotate90FlipNone }
        7 { [System.Drawing.RotateFlipType]::Rotate270FlipX }
        8 { [System.Drawing.RotateFlipType]::Rotate270FlipNone }
        default { [System.Drawing.RotateFlipType]::RotateNoneFlipNone }
    }

    if ($rotateFlip -ne [System.Drawing.RotateFlipType]::RotateNoneFlipNone) {
        $Image.RotateFlip($rotateFlip)
    }
}

function Save-OptimizedJpeg {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [int]$MaxDimension,
        [long]$Quality
    )

    $destinationFolder = Split-Path -Parent $DestinationPath
    [System.IO.Directory]::CreateDirectory($destinationFolder) | Out-Null
    $temporaryPath = Join-Path $destinationFolder (".{0}.tmp" -f [guid]::NewGuid().ToString("N"))
    $sourceImage = $null
    $bitmap = $null
    $graphics = $null
    $imageAttributes = $null
    $encoderParameters = $null
    $qualityParameter = $null
    $outputStream = $null

    try {
        $sourceImage = [System.Drawing.Image]::FromFile($SourcePath)
        Set-CorrectImageOrientation -Image $sourceImage

        $scale = [Math]::Min(
            1.0,
            $MaxDimension / [double][Math]::Max($sourceImage.Width, $sourceImage.Height)
        )
        $targetWidth = [Math]::Max(1, [int][Math]::Round($sourceImage.Width * $scale))
        $targetHeight = [Math]::Max(1, [int][Math]::Round($sourceImage.Height * $scale))

        $bitmap = [System.Drawing.Bitmap]::new(
            $targetWidth,
            $targetHeight,
            [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
        )
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

        $imageAttributes = [System.Drawing.Imaging.ImageAttributes]::new()
        $imageAttributes.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
        $destinationRectangle = [System.Drawing.Rectangle]::new(
            0,
            0,
            $targetWidth,
            $targetHeight
        )
        $graphics.DrawImage(
            $sourceImage,
            $destinationRectangle,
            0,
            0,
            $sourceImage.Width,
            $sourceImage.Height,
            [System.Drawing.GraphicsUnit]::Pixel,
            $imageAttributes
        )

        $jpegEncoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
            Where-Object { $_.MimeType -eq "image/jpeg" } |
            Select-Object -First 1
        if ($null -eq $jpegEncoder) {
            throw "Windows JPEG encoder is unavailable."
        }

        $encoderParameters = [System.Drawing.Imaging.EncoderParameters]::new(1)
        $qualityParameter = [System.Drawing.Imaging.EncoderParameter]::new(
            [System.Drawing.Imaging.Encoder]::Quality,
            $Quality
        )
        $encoderParameters.Param[0] = $qualityParameter
        $outputStream = [System.IO.File]::Open(
            $temporaryPath,
            [System.IO.FileMode]::CreateNew,
            [System.IO.FileAccess]::Write,
            [System.IO.FileShare]::None
        )
        $bitmap.Save($outputStream, $jpegEncoder, $encoderParameters)
        $outputStream.Dispose()
        $outputStream = $null

        Move-Item -LiteralPath $temporaryPath -Destination $DestinationPath -Force
    }
    finally {
        if ($null -ne $outputStream) { $outputStream.Dispose() }
        if ($null -ne $qualityParameter) { $qualityParameter.Dispose() }
        if ($null -ne $encoderParameters) { $encoderParameters.Dispose() }
        if ($null -ne $imageAttributes) { $imageAttributes.Dispose() }
        if ($null -ne $graphics) { $graphics.Dispose() }
        if ($null -ne $bitmap) { $bitmap.Dispose() }
        if ($null -ne $sourceImage) { $sourceImage.Dispose() }
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

function Write-Utf8Json {
    param(
        [object]$Value,
        [string]$Path,
        [int]$Depth = 6
    )

    $json = $Value | ConvertTo-Json -Depth $Depth
    $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText(
        $Path,
        $json + [Environment]::NewLine,
        $utf8WithoutBom
    )
}

try {
    [System.IO.Directory]::CreateDirectory($optimizedRoot) | Out-Null

    $cachedEntries = @{}
    if (Test-Path -LiteralPath $cachePath -PathType Leaf) {
        try {
            $cacheDocument = Get-Content -LiteralPath $cachePath -Raw -Encoding UTF8 |
                ConvertFrom-Json
            if ($cacheDocument.settings -eq $optimizationSettings) {
                foreach ($entry in @($cacheDocument.entries)) {
                    $cachedEntries[$entry.source] = $entry
                }
            }
        }
        catch {
            Write-Warning "Optimization cache is invalid and will be rebuilt."
            $cachedEntries = @{}
        }
    }

    $manifestAlbums = @()
    $newCacheEntries = @()
    $generatedCount = 0
    $reusedCount = 0
    $fallbackCount = 0

    foreach ($album in $albums) {
        $folderPath = Join-Path $projectRoot $album.Folder

        if (-not (Test-Path -LiteralPath $folderPath -PathType Container)) {
            throw "Gallery folder does not exist: $folderPath"
        }

        $imageFiles = @(
            Get-ChildItem -LiteralPath $folderPath -File |
                Where-Object { $supportedExtensions -contains $_.Extension.ToLowerInvariant() } |
                Sort-Object `
                    @{ Expression = { Get-NaturalSortKey $_.Name } },
                    @{ Expression = { $_.Name.ToLowerInvariant() } }
        )

        if ($imageFiles.Count -eq 0) {
            throw "Gallery folder contains no supported images: $folderPath"
        }

        $coverFile = $imageFiles |
            Where-Object { $_.Name -ceq $album.PreferredCover } |
            Select-Object -First 1

        if ($null -eq $coverFile) {
            $coverFile = $imageFiles[0]
        }

        $orderedImageFiles = $imageFiles

        if ($album.CoverFirst) {
            $orderedImageFiles = @($coverFile) + @(
                $imageFiles | Where-Object { $_.FullName -ne $coverFile.FullName }
            )
        }

        $baseNameCounts = @{}
        foreach ($imageFile in $imageFiles) {
            $baseNameKey = $imageFile.BaseName.ToLowerInvariant()
            $baseNameCounts[$baseNameKey] = 1 + [int]$baseNameCounts[$baseNameKey]
        }

        $thumbnailFolderRelative = "$optimizedRootRelative\$($album.Id)\thumbnails"
        $fullFolderRelative = "$optimizedRootRelative\$($album.Id)\full"
        $thumbnailFolderPath = Join-Path $projectRoot $thumbnailFolderRelative
        $fullFolderPath = Join-Path $projectRoot $fullFolderRelative
        $imageRecords = @()

        foreach ($imageFile in $orderedImageFiles) {
            $originalPublicPath = Get-PublicImagePath `
                -Folder $album.Folder `
                -FileName $imageFile.Name
            $thumbnailPublicPath = $originalPublicPath
            $fullPublicPath = $originalPublicPath
            $extension = $imageFile.Extension.ToLowerInvariant()

            if ($jpegExtensions -contains $extension) {
                $outputBaseName = $imageFile.BaseName
                if ($baseNameCounts[$imageFile.BaseName.ToLowerInvariant()] -gt 1) {
                    $outputBaseName = "{0}-{1}" -f `
                        $imageFile.BaseName,
                        $extension.TrimStart(".")
                }
                $outputFileName = "$outputBaseName.jpg"
                $thumbnailPath = Join-Path $thumbnailFolderPath $outputFileName
                $fullPath = Join-Path $fullFolderPath $outputFileName
                $sourceHash = Get-FileSha256 -Path $imageFile.FullName
                $cacheKey = "$($album.Id)/$($imageFile.Name)"
                $cachedEntry = $cachedEntries[$cacheKey]
                $canReuse =
                    $null -ne $cachedEntry -and
                    $cachedEntry.sha256 -eq $sourceHash -and
                    (Test-Path -LiteralPath $thumbnailPath -PathType Leaf) -and
                    (Test-Path -LiteralPath $fullPath -PathType Leaf)

                try {
                    if (-not $canReuse) {
                        Save-OptimizedJpeg `
                            -SourcePath $imageFile.FullName `
                            -DestinationPath $thumbnailPath `
                            -MaxDimension $thumbnailMaxDimension `
                            -Quality $thumbnailQuality
                        Save-OptimizedJpeg `
                            -SourcePath $imageFile.FullName `
                            -DestinationPath $fullPath `
                            -MaxDimension $fullMaxDimension `
                            -Quality $fullQuality
                        $generatedCount++
                    }
                    else {
                        $reusedCount++
                    }

                    $thumbnailPublicPath = Get-PublicImagePath `
                        -Folder $thumbnailFolderRelative `
                        -FileName $outputFileName
                    $fullPublicPath = Get-PublicImagePath `
                        -Folder $fullFolderRelative `
                        -FileName $outputFileName
                    $newCacheEntries += [PSCustomObject][ordered]@{
                        source = $cacheKey
                        sha256 = $sourceHash
                        thumbnail = $thumbnailPublicPath
                        full = $fullPublicPath
                    }
                }
                catch {
                    $fallbackCount++
                    Write-Warning (
                        "Could not optimize {0}; using the original. {1}" -f `
                            $imageFile.FullName,
                            $_.Exception.Message
                    )
                }
            }
            else {
                $fallbackCount++
            }

            $imageRecords += [PSCustomObject][ordered]@{
                name = $imageFile.Name
                original = $originalPublicPath
                thumbnail = $thumbnailPublicPath
                full = $fullPublicPath
            }
        }

        $coverRecord = $imageRecords |
            Where-Object { $_.name -ceq $coverFile.Name } |
            Select-Object -First 1

        $manifestAlbums += [PSCustomObject][ordered]@{
            id = $album.Id
            title = $album.Title
            subtitle = $album.Subtitle
            cover = $coverRecord.original
            coverThumbnail = $coverRecord.thumbnail
            images = @($imageRecords | ForEach-Object { $_.original })
            thumbnails = @($imageRecords | ForEach-Object { $_.thumbnail })
            fullImages = @($imageRecords | ForEach-Object { $_.full })
        }
    }

    $manifest = [ordered]@{
        version = 2
        albums = $manifestAlbums
    }
    Write-Utf8Json -Value $manifest -Path $outputPath -Depth 6

    $cacheDocument = [ordered]@{
        version = 1
        settings = $optimizationSettings
        entries = $newCacheEntries
    }
    Write-Utf8Json -Value $cacheDocument -Path $cachePath -Depth 5

    $counts = $manifestAlbums |
        ForEach-Object { "$($_.id)=$($_.images.Count)" }
    Write-Host "Generated $outputPath ($($counts -join ', '))"
    Write-Host (
        "Gallery optimization: generated={0}, reused={1}, original fallbacks={2}" -f `
            $generatedCount,
            $reusedCount,
            $fallbackCount
    )
    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
