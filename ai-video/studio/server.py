#!/usr/bin/env python3
"""Local AI video studio — a Higgsfield-style web UI on top of ComfyUI.

Runs a small web app (stdlib only, no extra dependencies) that turns a text
prompt into a video using the free open-weight Wan 2.1 T2V 1.3B model via a
locally running ComfyUI instance.

Usage:
    python3 server.py                 # expects ComfyUI at http://127.0.0.1:8188
    COMFY_URL=http://host:8188 PORT=8189 python3 server.py
"""

import json
import os
import random
import urllib.error
import urllib.parse
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

COMFY_URL = os.environ.get("COMFY_URL", "http://127.0.0.1:8188").rstrip("/")
PORT = int(os.environ.get("PORT", "8189"))
STUDIO_DIR = os.path.dirname(os.path.abspath(__file__))

MODEL_FILES = {
    "diffusion model": "wan2.1_t2v_1.3B_fp16.safetensors",
    "text encoder": "umt5_xxl_fp8_e4m3fn_scaled.safetensors",
    "vae": "wan_2.1_vae.safetensors",
}

FPS = 16


def build_workflow(prompt, negative, width, height, length, steps, seed):
    """Wan 2.1 text-to-video graph in ComfyUI API format."""
    return {
        "1": {"class_type": "UNETLoader",
              "inputs": {"unet_name": MODEL_FILES["diffusion model"],
                         "weight_dtype": "default"}},
        "2": {"class_type": "CLIPLoader",
              "inputs": {"clip_name": MODEL_FILES["text encoder"], "type": "wan"}},
        "3": {"class_type": "VAELoader",
              "inputs": {"vae_name": MODEL_FILES["vae"]}},
        "4": {"class_type": "ModelSamplingSD3",
              "inputs": {"model": ["1", 0], "shift": 8.0}},
        "5": {"class_type": "CLIPTextEncode",
              "inputs": {"clip": ["2", 0], "text": prompt}},
        "6": {"class_type": "CLIPTextEncode",
              "inputs": {"clip": ["2", 0], "text": negative}},
        "7": {"class_type": "EmptyHunyuanLatentVideo",
              "inputs": {"width": width, "height": height,
                         "length": length, "batch_size": 1}},
        "8": {"class_type": "KSampler",
              "inputs": {"model": ["4", 0], "positive": ["5", 0],
                         "negative": ["6", 0], "latent_image": ["7", 0],
                         "seed": seed, "steps": steps, "cfg": 6.0,
                         "sampler_name": "uni_pc", "scheduler": "simple",
                         "denoise": 1.0}},
        "9": {"class_type": "VAEDecode",
              "inputs": {"samples": ["8", 0], "vae": ["3", 0]}},
        "10": {"class_type": "SaveWEBM",
               "inputs": {"images": ["9", 0], "filename_prefix": "studio/video",
                          "codec": "vp9", "fps": float(FPS), "crf": 32.0}},
    }


def comfy_request(path, data=None, raw=False):
    url = f"{COMFY_URL}{path}"
    body = json.dumps(data).encode() if data is not None else None
    req = urllib.request.Request(
        url, data=body,
        headers={"Content-Type": "application/json"} if body else {})
    with urllib.request.urlopen(req, timeout=30) as resp:
        payload = resp.read()
        return payload if raw else json.loads(payload)


def missing_models():
    """Which Wan model files ComfyUI can't see yet."""
    missing = []
    checks = [
        ("diffusion model", "/object_info/UNETLoader",
         lambda info: info["UNETLoader"]["input"]["required"]["unet_name"][0]),
        ("text encoder", "/object_info/CLIPLoader",
         lambda info: info["CLIPLoader"]["input"]["required"]["clip_name"][0]),
        ("vae", "/object_info/VAELoader",
         lambda info: info["VAELoader"]["input"]["required"]["vae_name"][0]),
    ]
    for kind, path, extract in checks:
        available = extract(comfy_request(path))
        if MODEL_FILES[kind] not in available:
            missing.append(MODEL_FILES[kind])
    return missing


def gallery():
    """Finished videos from ComfyUI history, newest first."""
    history = comfy_request("/history?max_items=100")
    items = []
    for prompt_id, entry in history.items():
        for node_output in entry.get("outputs", {}).values():
            for vid in node_output.get("images", []) + node_output.get("video", []):
                name = vid.get("filename", "")
                if not name.endswith((".webm", ".mp4")):
                    continue
                prompt_text = ""
                try:
                    graph = entry["prompt"][2]
                    prompt_text = graph["5"]["inputs"]["text"]
                except (KeyError, IndexError, TypeError):
                    pass
                items.append({
                    "prompt_id": prompt_id,
                    "filename": name,
                    "subfolder": vid.get("subfolder", ""),
                    "prompt": prompt_text,
                })
    items.reverse()
    return items


class Handler(BaseHTTPRequestHandler):

    def send_json(self, obj, status=200):
        body = json.dumps(obj).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        route = parsed.path
        try:
            if route == "/":
                with open(os.path.join(STUDIO_DIR, "index.html"), "rb") as f:
                    body = f.read()
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
            elif route == "/api/status":
                try:
                    missing = missing_models()
                    self.send_json({"comfy": True, "missing_models": missing})
                except (urllib.error.URLError, OSError):
                    self.send_json({"comfy": False, "missing_models": []})
            elif route.startswith("/api/job/"):
                prompt_id = route.rsplit("/", 1)[1]
                hist = comfy_request(f"/history/{prompt_id}")
                if prompt_id in hist:
                    entry = hist[prompt_id]
                    status = entry.get("status", {})
                    if status.get("status_str") == "error":
                        messages = [m for m in status.get("messages", [])
                                    if m[0] == "execution_error"]
                        detail = (messages[0][1].get("exception_message", "")
                                  if messages else "generation failed")
                        self.send_json({"state": "error", "error": detail})
                        return
                    videos = []
                    for out in entry.get("outputs", {}).values():
                        for vid in out.get("images", []) + out.get("video", []):
                            if vid.get("filename", "").endswith((".webm", ".mp4")):
                                videos.append(vid)
                    self.send_json({"state": "done", "videos": videos})
                else:
                    queue = comfy_request("/queue")
                    running = any(item[1] == prompt_id
                                  for item in queue.get("queue_running", []))
                    position = next(
                        (i for i, item in enumerate(queue.get("queue_pending", []))
                         if item[1] == prompt_id), None)
                    self.send_json({"state": "running" if running else "queued",
                                    "position": position})
            elif route == "/api/gallery":
                self.send_json(gallery())
            elif route == "/api/video":
                qs = urllib.parse.parse_qs(parsed.query)
                view = urllib.parse.urlencode({
                    "filename": qs.get("filename", [""])[0],
                    "subfolder": qs.get("subfolder", [""])[0],
                    "type": "output"})
                data = comfy_request(f"/view?{view}", raw=True)
                self.send_response(200)
                self.send_header("Content-Type", "video/webm")
                self.send_header("Content-Length", str(len(data)))
                self.end_headers()
                self.wfile.write(data)
            else:
                self.send_json({"error": "not found"}, 404)
        except (urllib.error.URLError, OSError) as exc:
            self.send_json({"error": f"ComfyUI unreachable at {COMFY_URL}: {exc}"},
                           502)

    def do_POST(self):
        if self.path != "/api/generate":
            self.send_json({"error": "not found"}, 404)
            return
        length = int(self.headers.get("Content-Length", 0))
        req = json.loads(self.rfile.read(length) or b"{}")
        prompt = (req.get("prompt") or "").strip()
        if not prompt:
            self.send_json({"error": "prompt is required"}, 400)
            return
        seconds = min(max(float(req.get("seconds", 3)), 1), 8)
        frames = int(seconds * FPS) // 4 * 4 + 1  # latent needs 4n+1 frames
        workflow = build_workflow(
            prompt=prompt,
            negative=req.get("negative")
            or "blurry, low quality, distorted, deformed, watermark, static image",
            width=int(req.get("width", 832)),
            height=int(req.get("height", 480)),
            length=frames,
            steps=min(max(int(req.get("steps", 30)), 4), 60),
            seed=int(req.get("seed") or random.randint(0, 2**48)),
        )
        try:
            resp = comfy_request("/prompt", {"prompt": workflow})
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode(errors="replace")[:2000]
            self.send_json({"error": f"ComfyUI rejected the job: {detail}"}, 502)
            return
        except (urllib.error.URLError, OSError) as exc:
            self.send_json({"error": f"ComfyUI unreachable at {COMFY_URL}: {exc}"},
                           502)
            return
        self.send_json({"prompt_id": resp["prompt_id"]})

    def log_message(self, fmt, *args):
        pass  # keep the console quiet


def main():
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"Local AI video studio running at http://127.0.0.1:{PORT}")
    print(f"Talking to ComfyUI at {COMFY_URL}")
    server.serve_forever()


if __name__ == "__main__":
    main()
