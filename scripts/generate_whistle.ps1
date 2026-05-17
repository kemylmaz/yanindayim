# Generates a sustained, loud, pea-less rescue whistle WAV for SOS.
# Pattern: continuous 2.8kHz + 3.5kHz two-tone with tremolo + vibrato.
# 4 seconds, designed to loop seamlessly.
# Output: assets/audio/whistle_3khz.wav (mono 16-bit 44.1 kHz)

$ErrorActionPreference = 'Stop'
$outPath = Join-Path $PSScriptRoot "..\assets\audio\whistle_3khz.wav"
$outDir = Split-Path $outPath -Parent
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

# Acil durum / arama-kurtarma düdüğü standartları:
# - Fox 40 Classic: ~3.0 kHz primary
# - Acme Tornado 2000: ~2.7 kHz
# - DIN/SAE rescue whistle: 3-3.5 kHz aralığı
# - AFAD sivil savunma düdük frekansı: 3 kHz civarı
# İnsan kulağının en hassas olduğu bant (2-4 kHz), uzun mesafeden duyulur.
$sampleRate = 44100
$duration = 4.0
$freq1 = 2700.0   # Acme Tornado seviyesi — temel
$freq2 = 3300.0   # Fox 40 üst ses — dikkat çekici
$tremoloHz = 5.5
$tremoloDepth = 0.10
$vibratoHz = 4.5
$vibratoDepth = 6.0
$peak = 0.92

$n = [int]($sampleRate * $duration)
$dataSize = $n * 2

$fs = [System.IO.File]::Create($outPath)
$bw = New-Object System.IO.BinaryWriter($fs)
$bw.Write([byte[]]@(0x52,0x49,0x46,0x46))
$bw.Write([uint32](36 + $dataSize))
$bw.Write([byte[]]@(0x57,0x41,0x56,0x45))
$bw.Write([byte[]]@(0x66,0x6D,0x74,0x20))
$bw.Write([uint32]16)
$bw.Write([uint16]1)
$bw.Write([uint16]1)
$bw.Write([uint32]$sampleRate)
$bw.Write([uint32]($sampleRate * 2))
$bw.Write([uint16]2)
$bw.Write([uint16]16)
$bw.Write([byte[]]@(0x64,0x61,0x74,0x61))
$bw.Write([uint32]$dataSize)

# Loop sınırında sorunsuz devamlılık için: vibrato/tremolo frekansları
# 4 saniyelik segmenti tam katı tamamlasın diye round.
for ($i = 0; $i -lt $n; $i++) {
  $t = $i / $sampleRate
  $vib = $vibratoDepth * [Math]::Sin(2 * [Math]::PI * $vibratoHz * $t)
  $f1 = $freq1 + $vib
  $f2 = $freq2 + $vib * 1.25
  # Dual-chamber pea-less düdük taklit: iki temel + alt ottav harmonik.
  # Sürekli güçlü ton, fazla cırtlaklık olmadan uzak mesafeden duyulur.
  $s = 0.70 * [Math]::Sin(2 * [Math]::PI * $f1 * $t)
  $s += 0.50 * [Math]::Sin(2 * [Math]::PI * $f2 * $t)
  $s += 0.10 * [Math]::Sin(2 * [Math]::PI * ($f1 * 0.5) * $t)   # alt ottav: rezonans
  $trem = 1.0 - $tremoloDepth * (1 - [Math]::Sin(2 * [Math]::PI * $tremoloHz * $t)) / 2
  $v = $s * $trem * $peak / 1.15
  if ($v -gt 1.0) { $v = 1.0 }
  if ($v -lt -1.0) { $v = -1.0 }
  $bw.Write([int16]([int]($v * 32767)))
}

$bw.Close()
$fs.Close()
$fi = Get-Item $outPath
Write-Host "WAV created: $($fi.FullName) - $([Math]::Round($fi.Length / 1024, 1)) KB"
