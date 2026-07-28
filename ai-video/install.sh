#!/usr/bin/env bash
# Installs ComfyUI (free, open-source AI video generation software) with
# video-focused custom nodes and optional open-weight video models.
#
# Usage:
#   ./install.sh [install-dir]            # default: ./ComfyUI
#   ./install.sh --with-model ltx         # also download the LTX-Video model
#   ./install.sh --with-model wan         # also download Wan 2.1 T2V 1.3B
#
# Requirements: git, python3 (3.10+), ~10 GB disk (more with models).
# Works with or without an NVIDIA GPU (CPU mode is slow but functional).

set -euo pipefail

INSTALL_DIR="./ComfyUI"
MODEL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-model)
      MODEL="${2:?--with-model requires an argument: ltx | wan}"
      shift 2
      ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      INSTALL_DIR="$1"
      shift
      ;;
  esac
done

command -v git >/dev/null || { echo "error: git is required" >&2; exit 1; }
command -v python3 >/dev/null || { echo "error: python3 is required" >&2; exit 1; }

PYVER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
case "$PYVER" in
  3.1[0-9]) ;;
  *) echo "error: Python 3.10+ required (found $PYVER)" >&2; exit 1 ;;
esac

echo "==> Installing ComfyUI into $INSTALL_DIR"

if [[ ! -d "$INSTALL_DIR/.git" ]]; then
  git clone --depth 1 https://github.com/comfyanonymous/ComfyUI "$INSTALL_DIR"
else
  echo "    already cloned, pulling latest"
  git -C "$INSTALL_DIR" pull --ff-only
fi

cd "$INSTALL_DIR"

echo "==> Creating virtual environment"
if [[ ! -d venv ]]; then
  python3 -m venv venv
fi
# shellcheck disable=SC1091
source venv/bin/activate
pip install --upgrade pip --quiet

echo "==> Installing PyTorch"
if command -v nvidia-smi >/dev/null 2>&1; then
  echo "    NVIDIA GPU detected: installing CUDA build"
  pip install torch torchvision torchaudio
else
  echo "    no NVIDIA GPU detected: installing CPU build"
  pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu \
    || { echo "    CPU wheel index unreachable, falling back to PyPI"; pip install torch torchvision torchaudio; }
fi

echo "==> Installing ComfyUI requirements"
pip install -r requirements.txt

echo "==> Installing video custom nodes"
declare -A NODES=(
  [ComfyUI-Manager]=https://github.com/ltdrdata/ComfyUI-Manager
  [ComfyUI-VideoHelperSuite]=https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
)
for name in "${!NODES[@]}"; do
  dir="custom_nodes/$name"
  if [[ ! -d "$dir" ]]; then
    git clone --depth 1 "${NODES[$name]}" "$dir"
  fi
  if [[ -f "$dir/requirements.txt" ]]; then
    pip install -r "$dir/requirements.txt"
  fi
done

if [[ -n "$MODEL" ]]; then
  echo "==> Downloading model: $MODEL"
  case "$MODEL" in
    ltx)
      # LTX-Video 2B distilled — fastest open-weight text-to-video model (~6 GB)
      python3 - <<'EOF'
from urllib.request import urlretrieve
import os
os.makedirs("models/checkpoints", exist_ok=True)
url = "https://huggingface.co/Lightricks/LTX-Video/resolve/main/ltxv-2b-0.9.6-distilled-04-25.safetensors"
dest = "models/checkpoints/ltxv-2b-distilled.safetensors"
if not os.path.exists(dest):
    print(f"downloading {url}")
    urlretrieve(url, dest)
print("done:", dest)
EOF
      ;;
    wan)
      # Wan 2.1 T2V 1.3B — high quality open-weight text-to-video (~5 GB total)
      python3 - <<'EOF'
from urllib.request import urlretrieve
import os
files = {
    "models/diffusion_models/wan2.1_t2v_1.3B_fp16.safetensors":
        "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_t2v_1.3B_fp16.safetensors",
    "models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors":
        "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors",
    "models/vae/wan_2.1_vae.safetensors":
        "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors",
}
for dest, url in files.items():
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    if not os.path.exists(dest):
        print(f"downloading {url}")
        urlretrieve(url, dest)
    print("done:", dest)
EOF
      ;;
    *)
      echo "error: unknown model '$MODEL' (expected: ltx | wan)" >&2
      exit 1
      ;;
  esac
fi

echo
echo "==> Install complete."
echo
echo "To start ComfyUI:"
echo "  cd $INSTALL_DIR"
echo "  source venv/bin/activate"
if command -v nvidia-smi >/dev/null 2>&1; then
  echo "  python main.py"
else
  echo "  python main.py --cpu"
fi
echo
echo "Then open http://127.0.0.1:8188 in your browser."
if [[ -z "$MODEL" ]]; then
  echo
  echo "No model downloaded yet. Re-run with '--with-model ltx' or '--with-model wan',"
  echo "or use the Manager tab inside ComfyUI to fetch models."
fi
