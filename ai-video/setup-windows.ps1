# Sets up the free Local AI Video Studio (ComfyUI + Wan 2.1) on Windows.
#
# Run from any PowerShell window (no admin needed for most systems):
#   irm https://raw.githubusercontent.com/chrispretoriusbusiness20-hue/louis/claude/free-ai-video-generation-y47dig/ai-video/setup-windows.ps1 | iex
#
# What it does:
#   1. Installs Git and Python via winget if missing
#   2. Clones this repo to %USERPROFILE%\louis
#   3. Installs ComfyUI + video nodes into an isolated virtual environment
#   4. Downloads the free Wan 2.1 video model (~5 GB)
#   5. Launches the studio (Start-Studio.bat)

$ErrorActionPreference = "Stop"
$Branch  = "claude/free-ai-video-generation-y47dig"
$RepoUrl = "https://github.com/chrispretoriusbusiness20-hue/louis"
$Root    = Join-Path $env:USERPROFILE "louis"

function Refresh-Path {
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [Environment]::GetEnvironmentVariable("Path", "User")
}

function Have-RealPython {
    # The Microsoft Store stub 'python.exe' exists on PATH but exits non-zero.
    try {
        $v = & python --version 2>&1
        return ($LASTEXITCODE -eq 0 -and "$v" -match "Python 3\.1[0-9]")
    } catch { return $false }
}

Write-Host "== Local AI Video Studio - Windows setup ==" -ForegroundColor Cyan

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget is not available. Install 'App Installer' from the Microsoft Store, then re-run this script."
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "==> Installing Git..."
    winget install --id Git.Git -e --silent --accept-source-agreements --accept-package-agreements
    Refresh-Path
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "Git installed but is not on PATH yet. Open a NEW PowerShell window and re-run this script."
    }
}

if (-not (Have-RealPython)) {
    Write-Host "==> Installing Python 3.12..."
    winget install --id Python.Python.3.12 -e --silent --accept-source-agreements --accept-package-agreements
    Refresh-Path
    if (-not (Have-RealPython)) {
        throw "Python installed but is not on PATH yet. Open a NEW PowerShell window and re-run this script."
    }
}

if (-not (Test-Path (Join-Path $Root ".git"))) {
    Write-Host "==> Downloading the studio (git clone)..."
    git clone -b $Branch $RepoUrl $Root
} else {
    Write-Host "==> Repo already present, updating..."
    git -C $Root fetch origin $Branch
    git -C $Root checkout $Branch
    git -C $Root pull --ff-only origin $Branch
}

$Ai = Join-Path $Root "ai-video"
Set-Location $Ai

if (-not (Test-Path "ComfyUI\.git")) {
    Write-Host "==> Downloading ComfyUI..."
    git clone --depth 1 https://github.com/comfyanonymous/ComfyUI
}

$Py = Join-Path $Ai "ComfyUI\venv\Scripts\python.exe"
if (-not (Test-Path $Py)) {
    Write-Host "==> Creating virtual environment..."
    python -m venv (Join-Path $Ai "ComfyUI\venv")
}
& $Py -m pip install --upgrade pip --quiet

$HasGpu = [bool](Get-Command nvidia-smi -ErrorAction SilentlyContinue)
Write-Host "==> Installing PyTorch ($(if ($HasGpu) {'NVIDIA GPU detected - CUDA build'} else {'no NVIDIA GPU - CPU build'}))..."
if ($HasGpu) {
    & $Py -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
} else {
    & $Py -m pip install torch torchvision torchaudio
}

Write-Host "==> Installing ComfyUI requirements..."
& $Py -m pip install -r (Join-Path $Ai "ComfyUI\requirements.txt")

$Nodes = @{
    "ComfyUI-Manager"          = "https://github.com/ltdrdata/ComfyUI-Manager"
    "ComfyUI-VideoHelperSuite" = "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
}
foreach ($Name in $Nodes.Keys) {
    $Dir = Join-Path $Ai "ComfyUI\custom_nodes\$Name"
    if (-not (Test-Path $Dir)) {
        Write-Host "==> Installing $Name..."
        git clone --depth 1 $Nodes[$Name] $Dir
    }
    $Req = Join-Path $Dir "requirements.txt"
    if (Test-Path $Req) { & $Py -m pip install -r $Req --quiet }
}

$Base = "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files"
$Models = @(
    @{ Dir = "ComfyUI\models\diffusion_models"; File = "wan2.1_t2v_1.3B_fp16.safetensors";       Url = "$Base/diffusion_models/wan2.1_t2v_1.3B_fp16.safetensors" },
    @{ Dir = "ComfyUI\models\text_encoders";    File = "umt5_xxl_fp8_e4m3fn_scaled.safetensors"; Url = "$Base/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" },
    @{ Dir = "ComfyUI\models\vae";              File = "wan_2.1_vae.safetensors";                Url = "$Base/vae/wan_2.1_vae.safetensors" }
)
foreach ($M in $Models) {
    $DirFull = Join-Path $Ai $M.Dir
    New-Item -ItemType Directory -Force -Path $DirFull | Out-Null
    $Dest = Join-Path $DirFull $M.File
    if (-not (Test-Path $Dest)) {
        Write-Host "==> Downloading model file $($M.File) - this is large, please wait..."
        curl.exe -L --retry 3 --retry-delay 5 -o $Dest $M.Url
        if ($LASTEXITCODE -ne 0) { throw "Download failed for $($M.File). Re-run this script to resume." }
    }
}

Write-Host ""
Write-Host "== Setup complete! ==" -ForegroundColor Green
Write-Host "Launching your studio now. Two server windows will open - keep them open."
Write-Host "Next time, just double-click:  $Ai\Start-Studio.bat"
Start-Process (Join-Path $Ai "Start-Studio.bat")
