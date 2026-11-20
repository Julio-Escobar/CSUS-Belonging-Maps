<#
.SYNOPSIS
    Builds the Android/iOS launcher-icon sources from the Belonging Maps logo.

.DESCRIPTION
    `flutter_launcher_icons` only resizes the images it is given, so the icon
    sources must already be square and already carry their own padding.
    This tool produces the two sources that `pubspec.yaml` points at, from
    `assets/belonging_maps_no_text.png`:

      assets/icon/app_icon.png
          Opaque #2F5F3E canvas. Used for the iOS icons and for the splash
          screen artwork (`flutter_native_splash`). The logo is kept inside
          76% of the canvas, clear of the iOS rounded-square icon mask.

      assets/icon/app_icon_foreground.png
          Transparent canvas. Used as the Android adaptive-icon foreground,
          where `adaptive_icon_background` supplies the green. The logo is
          kept inside the launcher's safe zone so no mask can clip it.

    Two adaptive-foreground fits are available:

      -ForegroundFit SafeZone  (default)
          Inscribes the logo's bounding box inside Android's 66dp/108dp
          (~61%) safe-zone circle, so every launcher mask keeps it intact.

      -ForegroundFit Fill
          Scales the logo to -ForegroundScale of the canvas' longest side.
          Bolder, but the corners of the artwork can be clipped by round or
          squircle masks. Use -ForegroundScale to tune (0.61 - 0.72 works
          well for this logo).

    The logo is cropped to its visible pixels first, so transparent margins
    in the source file never affect the result.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File tool/make_app_icons.ps1

    Rebuild both sources with the default safe-zone adaptive icon.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File tool/make_app_icons.ps1 -ForegroundFit Fill -ForegroundScale 0.70

    Bolder adaptive icon that fills more of the launcher canvas.

.NOTES
    Run from anywhere; paths are resolved relative to this script.
    After changing an icon source, regenerate the platform icons with:
        dart run flutter_launcher_icons
        dart run flutter_native_splash:create

    Known `flutter_launcher_icons` 0.13.1 bug: its iOS step rewrites every
    project.pbxproj line containing "ASSETCATALOG", which corrupts
    `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES` into
    `= AppIcon`. After running it, restore that setting with:
        git diff -- mobile/belonging_maps_app/ios/Runner.xcodeproj/project.pbxproj
#>
[CmdletBinding()]
param(
    # Logo to build the icons from.
    [string] $SourcePath,

    # Square canvas size written for both sources.
    [int] $CanvasSize = 1024,

    # Fraction of the canvas the logo may occupy (longest side) on the
    # opaque icon used by iOS and the splash screen.
    [ValidateRange(0.1, 1.0)]
    [double] $IconScale = 0.76,

    # How the Android adaptive foreground is fitted to the canvas.
    [ValidateSet('SafeZone', 'Fill')]
    [string] $ForegroundFit = 'SafeZone',

    # Fraction of the canvas the logo may occupy (longest side) for the
    # adaptive foreground; only used with -ForegroundFit Fill.
    [ValidateRange(0.61, 0.85)]
    [double] $ForegroundScale = 0.70,

    # Adaptive-icon background colour; the app's brand green.
    [string] $BackgroundColor = '#2F5F3E',

    # Alpha values at or below this are treated as empty when cropping.
    [ValidateRange(0, 254)]
    [int] $AlphaThreshold = 8
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

# Android's adaptive icons are a 108dp canvas whose 66dp diameter central
# circle is guaranteed to stay visible under every launcher mask.
$AndroidSafeZoneFraction = 66.0 / 108.0

$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $SourcePath) {
    $SourcePath = Join-Path $projectRoot 'assets\belonging_maps_no_text.png'
}
$iconOutputPath = Join-Path $projectRoot 'assets\icon\app_icon.png'
$foregroundOutputPath = Join-Path $projectRoot 'assets\icon\app_icon_foreground.png'


function Get-ArtworkBounds {
    param(
        [System.Drawing.Bitmap] $Bitmap,
        [int] $Threshold,

        # When set, pixels this close to the colour are treated as empty too,
        # which is how the visible logo is measured on an opaque canvas.
        [System.Drawing.Color] $Background = [System.Drawing.Color]::Empty,
        [int] $Tolerance = 24
    )

    $width = $Bitmap.Width
    $height = $Bitmap.Height
    $hasBackground = $Background -ne [System.Drawing.Color]::Empty
    $backgroundRed = $Background.R
    $backgroundGreen = $Background.G
    $backgroundBlue = $Background.B

    $lockArea = New-Object System.Drawing.Rectangle 0, 0, $width, $height
    $data = $Bitmap.LockBits(
        $lockArea,
        [System.Drawing.Imaging.ImageLockMode]::ReadOnly,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )

    try {
        $stride = $data.Stride
        $buffer = New-Object byte[] ($stride * $height)
        [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $buffer, 0, $buffer.Length)

        $minX = $width
        $minY = $height
        $maxX = -1
        $maxY = -1

        # 32bppArgb is stored as BGRA, so alpha lives at offset +3.
        for ($y = 0; $y -lt $height; $y++) {
            $rowStart = $y * $stride
            $index = $rowStart
            for ($x = 0; $x -lt $width; $x++) {
                $visible = $buffer[$index + 3] -gt $Threshold
                if ($visible -and $hasBackground) {
                    $delta = [math]::Abs($buffer[$index] - $backgroundBlue) +
                        [math]::Abs($buffer[$index + 1] - $backgroundGreen) +
                        [math]::Abs($buffer[$index + 2] - $backgroundRed)
                    $visible = $delta -gt $Tolerance
                }

                if ($visible) {
                    if ($x -lt $minX) { $minX = $x }
                    if ($x -gt $maxX) { $maxX = $x }
                    if ($y -lt $minY) { $minY = $y }
                    if ($y -gt $maxY) { $maxY = $y }
                }

                $index += 4
            }
        }
    }
    finally {
        $Bitmap.UnlockBits($data)
    }

    if ($maxX -lt 0) {
        throw "No visible pixels found above alpha threshold $Threshold."
    }

    return [System.Drawing.Rectangle]::FromLTRB($minX, $minY, $maxX + 1, $maxY + 1)
}

function Get-ScaledSize {
    param(
        [int] $Width,
        [int] $Height,
        [double] $Scale
    )

    $scaledWidth = [int][math]::Round($Width * $Scale)
    $scaledHeight = [int][math]::Round($Height * $Scale)
    if ($scaledWidth -lt 1 -or $scaledHeight -lt 1) {
        throw "Scale $Scale collapses the artwork to $scaledWidth x $scaledHeight."
    }

    return New-Object psobject -Property @{
        Width  = $scaledWidth
        Height = $scaledHeight
    }
}

# Scales the logo so its bounding box fits inside a circle of the given
# diameter, i.e. the diagonal of the scaled artwork equals the diameter.
function Get-CircleFitSize {
    param(
        [int] $Width,
        [int] $Height,
        [double] $Diameter
    )

    $diagonal = [math]::Sqrt(($Width * $Width) + ($Height * $Height))
    return Get-ScaledSize -Width $Width -Height $Height -Scale ($Diameter / $diagonal)
}

function New-IconCanvas {
    param(
        [System.Drawing.Bitmap] $Art,
        [int] $Size,
        [int] $TargetWidth,
        [int] $TargetHeight,
        [string] $FillColor
    )

    $canvas = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)

    try {
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

        if ($FillColor) {
            $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml($FillColor))
            $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
        }
        else {
            # Copying straight (rather than blending) onto a transparent
            # canvas keeps the logo's anti-aliased edges from darkening.
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        }

        $destX = [int][math]::Round(($Size - $TargetWidth) / 2)
        $destY = [int][math]::Round(($Size - $TargetHeight) / 2)
        $destRect = New-Object System.Drawing.Rectangle $destX, $destY, $TargetWidth, $TargetHeight
        $graphics.DrawImage($Art, $destRect)
    }
    finally {
        $graphics.Dispose()
    }

    return $canvas
}

function Save-IconPng {
    param(
        [System.Drawing.Bitmap] $Bitmap,
        [string] $Path
    )

    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}



# Re-reads a written PNG and reports what actually landed on disk, so the
# result can be checked without opening the image.
function Write-IconReport {
    param(
        [string] $Path,

        # Colour expected behind the logo, or Empty when the file must be
        # transparent outside the artwork.
        [System.Drawing.Color] $Background = [System.Drawing.Color]::Empty,
        [string] $Label,
        [int] $Threshold
    )

    $bitmap = [System.Drawing.Bitmap]::FromFile($Path)
    try {
        $bounds = Get-ArtworkBounds -Bitmap $bitmap -Threshold $Threshold -Background $Background
        $corner = $bitmap.GetPixel(0, 0)

        # Average colour of the semi-transparent edge pixels; catches the
        # dark halo that non-premultiplied downscaling can introduce.
        $edgeRed = 0.0
        $edgeGreen = 0.0
        $edgeBlue = 0.0
        $edgeCount = 0
        for ($y = 0; $y -lt $bitmap.Height; $y += 2) {
            for ($x = 0; $x -lt $bitmap.Width; $x += 2) {
                $pixel = $bitmap.GetPixel($x, $y)
                if ($pixel.A -gt 32 -and $pixel.A -lt 224) {
                    $edgeRed += $pixel.R
                    $edgeGreen += $pixel.G
                    $edgeBlue += $pixel.B
                    $edgeCount++
                }
            }
        }

        $percentWidth = [math]::Round(100.0 * $bounds.Width / $bitmap.Width, 1)
        $percentHeight = [math]::Round(100.0 * $bounds.Height / $bitmap.Height, 1)

        Write-Host "  $Label"
        Write-Host "    artwork bounds : $($bounds.Width)x$($bounds.Height) at ($($bounds.X),$($bounds.Y)) = $percentWidth% x $percentHeight% of canvas"
        Write-Host "    corner pixel   : R$($corner.R) G$($corner.G) B$($corner.B) A$($corner.A)"

        if ($edgeCount -gt 0) {
            $edgeColour = "R$([math]::Round($edgeRed / $edgeCount)) G$([math]::Round($edgeGreen / $edgeCount)) B$([math]::Round($edgeBlue / $edgeCount))"
            Write-Host "    edge pixels    : $edgeCount sampled, average $edgeColour"
        }
        else {
            Write-Host "    edge pixels    : none (no anti-aliased edges detected)"
        }

        if ($Background -ne [System.Drawing.Color]::Empty) {
            $isBackground = (
                $corner.R -eq $Background.R -and
                $corner.G -eq $Background.G -and
                $corner.B -eq $Background.B -and
                $corner.A -eq 255
            )
            $backgroundText = 'matches requested colour'
            if (-not $isBackground) { $backgroundText = 'DOES NOT match requested colour' }
            Write-Host "    background     : $backgroundText"
        }
        else {
            $backgroundText = "NOT transparent (alpha $($corner.A))"
            if ($corner.A -eq 0) { $backgroundText = 'transparent as requested' }
            Write-Host "    background     : $backgroundText"
        }

        $insideCanvas = (
            $bounds.X -gt 0 -and $bounds.Y -gt 0 -and
            $bounds.Right -lt $bitmap.Width -and $bounds.Bottom -lt $bitmap.Height
        )
        $clippingText = 'ARTWORK TOUCHES CANVAS EDGE'
        if ($insideCanvas) { $clippingText = 'artwork fully inside canvas' }
        Write-Host "    clipping       : $clippingText"
    }
    finally {
        $bitmap.Dispose()
    }
}

if (-not (Test-Path -LiteralPath $SourcePath)) {
    throw "Logo not found: $SourcePath"
}

$background = [System.Drawing.ColorTranslator]::FromHtml($BackgroundColor)

Write-Host "Belonging Maps launcher icons"
Write-Host "  logo    : $SourcePath"
Write-Host "  canvas  : ${CanvasSize}x${CanvasSize}"
Write-Host "  green   : $BackgroundColor (R$($background.R) G$($background.G) B$($background.B))"

$source = [System.Drawing.Bitmap]::FromFile($SourcePath)
$art = $null
try {
    $bounds = Get-ArtworkBounds -Bitmap $source -Threshold $AlphaThreshold
    $art = $source.Clone(
        $bounds,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
}
finally {
    $source.Dispose()
}

$created = @()
try {
    Write-Host "  cropped : $($bounds.Width)x$($bounds.Height) from ($($bounds.X),$($bounds.Y))"

    # --- opaque icon: iOS icons + splash artwork -------------------------
    $iconSize = Get-ScaledSize -Width $art.Width -Height $art.Height -Scale (
        ($IconScale * $CanvasSize) / [math]::Max($art.Width, $art.Height)
    )
    $icon = New-IconCanvas -Art $art -Size $CanvasSize `
        -TargetWidth $iconSize.Width -TargetHeight $iconSize.Height `
        -FillColor $BackgroundColor
    try {
        Save-IconPng -Bitmap $icon -Path $iconOutputPath
        $created += $iconOutputPath
    }
    finally {
        $icon.Dispose()
    }
    Write-Host "  icon    : logo drawn at $($iconSize.Width)x$($iconSize.Height)"

    # --- transparent adaptive foreground --------------------------------
    $safeZoneDiameter = $AndroidSafeZoneFraction * $CanvasSize
    if ($ForegroundFit -eq 'SafeZone') {
        $foregroundSize = Get-CircleFitSize -Width $art.Width -Height $art.Height `
            -Diameter $safeZoneDiameter
        Write-Host "  fit     : SafeZone (logo inscribed in the $([math]::Round($safeZoneDiameter))px safe circle)"
    }
    else {
        $foregroundSize = Get-ScaledSize -Width $art.Width -Height $art.Height -Scale (
            ($ForegroundScale * $CanvasSize) / [math]::Max($art.Width, $art.Height)
        )
        Write-Host "  fit     : Fill at $ForegroundScale of the canvas"
    }

    $foreground = New-IconCanvas -Art $art -Size $CanvasSize `
        -TargetWidth $foregroundSize.Width -TargetHeight $foregroundSize.Height `
        -FillColor ''
    try {
        Save-IconPng -Bitmap $foreground -Path $foregroundOutputPath
        $created += $foregroundOutputPath
    }
    finally {
        $foreground.Dispose()
    }
    Write-Host "  fg      : logo drawn at $($foregroundSize.Width)x$($foregroundSize.Height)"
}
finally {
    if ($art) { $art.Dispose() }
}

Write-Host ''
Write-Host 'Verifying written files'
Write-IconReport -Path $iconOutputPath -Background $background `
    -Label 'app_icon.png (iOS icons, splash)' -Threshold $AlphaThreshold
Write-IconReport -Path $foregroundOutputPath -Background ([System.Drawing.Color]::Empty) `
    -Label 'app_icon_foreground.png (Android adaptive foreground)' -Threshold $AlphaThreshold

Write-Host ''
Write-Host 'Next: dart run flutter_launcher_icons; dart run flutter_native_splash:create'
Write-Host "Wrote $($created.Count) file(s)."
