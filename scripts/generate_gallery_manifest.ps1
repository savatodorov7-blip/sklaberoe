$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$outputPath = Join-Path $projectRoot "assets\gallery\gallery-manifest.json"
$supportedExtensions = @(".jpg", ".jpeg", ".png", ".webp")

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
        PreferredCover = "competition-01.jpg"
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

try {
    $manifestAlbums = @()

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

        $imagePaths = @(
            $imageFiles | ForEach-Object {
                Get-PublicImagePath -Folder $album.Folder -FileName $_.Name
            }
        )

        $manifestAlbums += [PSCustomObject][ordered]@{
            id = $album.Id
            title = $album.Title
            subtitle = $album.Subtitle
            cover = Get-PublicImagePath -Folder $album.Folder -FileName $coverFile.Name
            images = $imagePaths
        }
    }

    $manifest = [ordered]@{
        version = 1
        albums = $manifestAlbums
    }

    $json = $manifest | ConvertTo-Json -Depth 5
    $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText(
        $outputPath,
        $json + [Environment]::NewLine,
        $utf8WithoutBom
    )

    $counts = $manifestAlbums |
        ForEach-Object { "$($_.id)=$($_.images.Count)" }
    Write-Host "Generated $outputPath ($($counts -join ', '))"
    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
