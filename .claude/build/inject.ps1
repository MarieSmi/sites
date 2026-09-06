# Вшивает шрифты и превью в prototype.html на место маркера /* __ASSETS__ */.
# Идемпотентен: повторный запуск заменяет ранее вшитый блок.
$d    = Split-Path -Parent $MyInvocation.MyCommand.Path
$html = Join-Path (Split-Path -Parent (Split-Path -Parent $d)) "prototype.html"

$OPEN  = "/* __ASSETS__ */"
$CLOSE = "/* __ASSETS_END__ */"

function B64($path) { [Convert]::ToBase64String([IO.File]::ReadAllBytes($path)) }

$fonts = @(
  @{ family="cbuc-icons";   file="$d\cbuc-icons.woff2" },
  @{ family="cbuc-icons24"; file="$d\cbuc-icons24.woff2" },
  @{ family="Maison Book";  file="$d\maison-book.woff2" },
  @{ family="Maison Demi";  file="$d\maison-demi.woff2" }
)

$shots = @(
  @{ var="--shot-saby";    file="$d\assets\s1_card1.jpg" },
  @{ var="--shot-mili";    file="$d\assets\s1_card2.jpg" },
  @{ var="--shot-shef";    file="$d\assets\s1_card3.jpg" },
  @{ var="--shot-park";    file="$d\assets\s1_card4.jpg" },
  @{ var="--shot-blanc";   file="$d\assets\s1_card5.jpg" },
  @{ var="--shot-billing"; file="$d\assets\s1_card6.jpg" },
  @{ var="--icon-widgets"; file="$d\assets\icon_widgets.png"; mime="image/png" },
  @{ var="--icon-disk";    file="$d\assets\icon_disk.png";    mime="image/png" },

  # screen 2
  @{ var="--shot-page";         file="$d\assets\s2_preview.jpg" },
  @{ var="--report-visitors";   file="$d\assets\s2_visitors.png";     mime="image/png" },
  @{ var="--icon-view-desktop"; file="$d\assets\s2_view_desktop.png"; mime="image/png" },
  @{ var="--icon-view-mobile";  file="$d\assets\s2_view_mobile.png";  mime="image/png" },

  # screen 3
  @{ var="--icon-favicon"; file="$d\assets\s3_favicon.png";   mime="image/png" },
  @{ var="--icon-home";    file="$d\assets\s3_icon_home.png"; mime="image/png" },

  # screen 5 - logos of traffic sources
  @{ var="--logo-yandex-direct"; file="$d\assets\s5_imgYandexDirect1.svg";           mime="image/svg+xml" },
  @{ var="--logo-google-ads";    file="$d\assets\s5_imgGoogleAds1.svg";              mime="image/svg+xml" },
  @{ var="--logo-youtube";       file="$d\assets\s5_imgYoutube1.svg";                mime="image/svg+xml" },
  @{ var="--logo-vk";            file="$d\assets\s5_imgVkontakte21.svg";             mime="image/svg+xml" },
  @{ var="--logo-ok";            file="$d\assets\s5_imgOdnoclassniki1.svg";          mime="image/svg+xml" },
  @{ var="--logo-yandex";        file="$d\assets\s5_imgSurface1.svg";                mime="image/svg+xml" },
  @{ var="--logo-google";        file="$d\assets\s5_imgGoogle1.svg";                 mime="image/svg+xml" },
  @{ var="--logo-tensor";        file="$d\assets\s5_imgImage741.png";                mime="image/png" },
  @{ var="--logo-glavbukh";      file="$d\assets\s5_imgImage744.png";                mime="image/png" },
  @{ var="--logo-sabyget";       file="$d\assets\s5_imgProperty1SabyGetSize16.png";  mime="image/png" },

  # screen 6 - source icons in the visitors registry
  @{ var="--logo-v-yandex";  file="$d\assets\s6_imgYandexDirect1.svg"; mime="image/svg+xml" },
  @{ var="--logo-v-youtube"; file="$d\assets\s6_imgYoutube1.svg";      mime="image/svg+xml" },
  @{ var="--logo-v-site";    file="$d\assets\s6_imgSurface1.svg";      mime="image/svg+xml" },
  @{ var="--logo-v-saby";    file="$d\assets\s6_img.png";              mime="image/png" },

  # screen 7
  @{ var="--logo-r-yandex"; file="$d\assets\s7_imgYandexDirect1.svg"; mime="image/svg+xml" },
  @{ var="--logo-r-ya";     file="$d\assets\s7_imgSurface1.svg";      mime="image/svg+xml" },
  @{ var="--logo-r-google"; file="$d\assets\s7_imgGoogle1.svg";       mime="image/svg+xml" }
)

$sb = New-Object Text.StringBuilder
[void]$sb.AppendLine($OPEN)
foreach ($f in $fonts) {
  [void]$sb.AppendLine("@font-face{font-family:'$($f.family)';font-style:normal;font-weight:400;font-display:block;src:url(data:font/woff2;base64,$(B64 $f.file)) format('woff2');}")
}
[void]$sb.AppendLine(":root{")
foreach ($s in $shots) {
  $mime = if ($s.mime) { $s.mime } else { "image/jpeg" }
  [void]$sb.AppendLine("  $($s.var): url(data:$mime;base64,$(B64 $s.file));")
}
[void]$sb.AppendLine("}")
[void]$sb.Append($CLOSE)

$text = [IO.File]::ReadAllText($html)
$startIdx = $text.IndexOf($OPEN)
if ($startIdx -lt 0) { throw "маркер $OPEN не найден в $html" }
$endIdx = $text.IndexOf($CLOSE)
$tailFrom = if ($endIdx -ge 0) { $endIdx + $CLOSE.Length } else { $startIdx + $OPEN.Length }

$out = $text.Substring(0, $startIdx) + $sb.ToString() + $text.Substring($tailFrom)

# Chart curve: inline the Figma vector in place of the marker (idempotent).
$C_OPEN  = "<!-- __CHART_CURVE__ -->"
$C_CLOSE = "<!-- __CHART_CURVE_END__ -->"
$svg = [IO.File]::ReadAllText("$d\assets\s2_c3deea10-e90a-40de-a94b-443efb3e162f.svg")
$svg = $svg -replace 'style="[^"]*"', '' -replace '\s+overflow="visible"', '' -replace '\s+width="[^"]*"', '' -replace '\s+height="[^"]*"', ''
$svg = $svg -replace '<svg ', '<svg aria-hidden="true" '
$svg = ($svg -split "`r?`n" | Where-Object { $_.Trim() -ne '' }) -join ''

$cs = $out.IndexOf($C_OPEN)
if ($cs -ge 0) {
  $ce = $out.IndexOf($C_CLOSE)
  $cTail = if ($ce -ge 0) { $ce + $C_CLOSE.Length } else { $cs + $C_OPEN.Length }
  $out = $out.Substring(0, $cs) + $C_OPEN + $svg + $C_CLOSE + $out.Substring($cTail)
}

[IO.File]::WriteAllText($html, $out, (New-Object Text.UTF8Encoding $false))
Write-Output ("prototype.html: {0:N0} KB" -f ((Get-Item $html).Length / 1KB))
