# Generates 3 kHz intermittent whistle WAV for the SOS feature.
# Pattern: 3 seconds tone (with 800-sample fade in/out), 2 seconds silence, 2 cycles.
# Output: assets/audio/whistle_3khz.wav (~860 KB, mono 16-bit 44.1 kHz)

$ErrorActionPreference = 'Stop'
$outPath = Join-Path $PSScriptRoot "..\assets\audio\whistle_3khz.wav"
$outDir = Split-Path $outPath -Parent
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

$sampleRate = 44100
$frequency = 3000.0
$burstDuration = 3.0
$silenceDuration = 2.0
$totalCycles = 2
$amplitude = 0.85
$fadeSamples = 800

$samplesPerBurst = [int]($sampleRate * $burstDuration)
$samplesPerSilence = [int]($sampleRate * $silenceDuration)
$totalSamples = ($samplesPerBurst + $samplesPerSilence) * $totalCycles
$dataSize = $totalSamples * 2

$fs = [System.IO.File]::Create($outPath)
$bw = New-Object System.IO.BinaryWriter($fs)
$bw.Write([byte[]]@(0x52,0x49,0x46,0x46))  # RIFF
$bw.Write([uint32](36 + $dataSize))
$bw.Write([byte[]]@(0x57,0x41,0x56,0x45))  # WAVE
$bw.Write([byte[]]@(0x66,0x6D,0x74,0x20))  # fmt
$bw.Write([uint32]16)
$bw.Write([uint16]1)
$bw.Write([uint16]1)
$bw.Write([uint32]$sampleRate)
$bw.Write([uint32]($sampleRate * 2))
$bw.Write([uint16]2)
$bw.Write([uint16]16)
$bw.Write([byte[]]@(0x64,0x61,0x74,0x61))  # data
$bw.Write([uint32]$dataSize)

for ($c = 0; $c -lt $totalCycles; $c++) {
  for ($i = 0; $i -lt $samplesPerBurst; $i++) {
    $t = $i / $sampleRate
    $env = $amplitude
    if ($i -lt $fadeSamples) { $env = $env * ($i / $fadeSamples) }
    if ($i -gt ($samplesPerBurst - $fadeSamples)) { $env = $env * (($samplesPerBurst - $i) / $fadeSamples) }
    $val = [Math]::Sin(2 * [Math]::PI * $frequency * $t) * 32767 * $env
    $bw.Write([int16]$val)
  }
  for ($i = 0; $i -lt $samplesPerSilence; $i++) { $bw.Write([int16]0) }
}

$bw.Close()
$fs.Close()
$fi = Get-Item $outPath
Write-Host "WAV created: $($fi.FullName) - $([Math]::Round($fi.Length / 1024, 1)) KB"
