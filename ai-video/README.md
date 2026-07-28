# Free AI Video Generation — ComfyUI Setup + Local Studio

This directory installs [ComfyUI](https://github.com/comfyanonymous/ComfyUI),
the leading free and open-source AI video generation software, together with
video-focused custom nodes and (optionally) free open-weight video models.
Everything runs locally on your own machine — no subscription, no credits,
no watermarks.

## Quick start (Windows — fully automatic)

Open **PowerShell** (Start menu → type "PowerShell") and paste this one line:

```powershell
irm https://raw.githubusercontent.com/chrispretoriusbusiness20-hue/louis/claude/free-ai-video-generation-y47dig/ai-video/setup-windows.ps1 | iex
```

It installs Git and Python if needed, sets up ComfyUI and the studio in
`C:\Users\<you>\louis`, downloads the free Wan 2.1 model (~5 GB), and opens
the studio in your browser when done. From then on, just double-click
**`louis\ai-video\Start-Studio.bat`** to launch everything.

## Quick start (Linux / macOS)

```bash
cd ai-video
./install.sh                     # install ComfyUI into ./ComfyUI
./install.sh --with-model ltx    # ...and download the LTX-Video model (~6 GB)
```

Then start it:

```bash
cd ComfyUI
source venv/bin/activate
python main.py        # add --cpu if you have no NVIDIA GPU
```

Open **http://127.0.0.1:8188** in your browser. In the ComfyUI interface go to
**Workflow → Browse Templates → Video** to load a ready-made text-to-video or
image-to-video workflow, type a prompt, and click **Queue**.

## Local Studio — your own Higgsfield-style app

`studio/` is a lightweight web app (no extra dependencies) that gives you a
clean prompt-to-video interface on top of ComfyUI: type a prompt, pick a
motion/style preset, choose size and duration, hit **Generate**, and watch
your gallery fill up. It uses the free open-weight **Wan 2.1 T2V 1.3B** model.

```bash
# one-time: install ComfyUI and the Wan model
./install.sh --with-model wan

# terminal 1 — start the engine
cd ComfyUI && source venv/bin/activate && python main.py   # add --cpu if no NVIDIA GPU

# terminal 2 — start the studio
python3 studio/server.py
```

Then open **http://127.0.0.1:8189**. The studio talks to ComfyUI on port 8188
(override with `COMFY_URL=... PORT=... python3 studio/server.py`). If ComfyUI
isn't running or model files are missing, the studio tells you exactly what to
do.

## What gets installed

| Component | Purpose |
|---|---|
| ComfyUI | Node-based UI and engine for image/video generation |
| ComfyUI-Manager | In-app installer for models and extra nodes |
| VideoHelperSuite | Video combine/export nodes (MP4, GIF, WebM) |
| PyTorch | CUDA build if an NVIDIA GPU is detected, otherwise CPU build |

## Free video models (open weights)

| Model | Flag | Size | Notes |
|---|---|---|---|
| LTX-Video 2B (distilled) | `--with-model ltx` | ~6 GB | Fastest; near-real-time on a good GPU |
| Wan 2.1 T2V 1.3B | `--with-model wan` | ~5 GB | Excellent quality for its size; runs in ~8 GB VRAM |

Both are free to download and use. More models (Hunyuan Video, Mochi,
AnimateDiff, Stable Video Diffusion) can be installed from the **Manager**
tab inside ComfyUI.

## Hardware requirements

- **NVIDIA GPU with 8 GB+ VRAM** — recommended. Both bundled models fit in
  8 GB; generation takes seconds to a few minutes per clip.
- **CPU only** — works (`python main.py --cpu`) but is very slow: expect many
  minutes to hours per clip. Fine for trying the software, not for production.
- **Disk**: ~10 GB for the software, plus 5–6 GB per model.
- **OS**: Linux, macOS, or Windows (run `install.sh` from Git Bash or WSL on
  Windows).

## Troubleshooting

- **Out of VRAM**: launch with `python main.py --lowvram`.
- **Model not showing in a workflow node**: confirm the file landed in the
  right `ComfyUI/models/...` subfolder, then press **R** to refresh the UI.
- **Slow first run**: models are loaded into memory on first use; later runs
  are faster.
