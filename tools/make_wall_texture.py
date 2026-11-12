"""Generates assets/textures/env/WallMotel.png: tileable, aged motel wallpaper (nicotine-yellow
vertical stripes, water stains, grime, grain). Run: python3 tools/make_wall_texture.py"""
import numpy as np
from PIL import Image

N = 256
rng = np.random.default_rng(13)


def tile_noise(cells: int, seed: int) -> np.ndarray:
    """Tileable value noise in 0..1 (bilinear-ish via FFT low-pass of white noise)."""
    r = np.random.default_rng(seed)
    f = np.fft.fft2(r.standard_normal((N, N)))
    fy = np.fft.fftfreq(N)[:, None] * N
    fx = np.fft.fftfreq(N)[None, :] * N
    f *= np.exp(-(fx ** 2 + fy ** 2) / (2.0 * cells ** 2))
    a = np.real(np.fft.ifft2(f))
    return (a - a.min()) / (a.max() - a.min())


x = np.arange(N)[None, :].repeat(N, 0)
# Vertical stripes, 32 px period (tiles): a wide pale band, a narrow dark pinstripe.
phase = (x % 32) / 32.0
stripe = np.where(phase < 0.12, 0.78, 1.0) + np.where((phase > 0.5) & (phase < 0.54), 0.9 - 1.0, 0.0)
stripe = stripe - 0.05 * np.sin(phase * 2 * np.pi)

base = np.array([0.66, 0.56, 0.36])             # aged yellow-beige
low = tile_noise(5, 1)                           # big blotches
mid = tile_noise(18, 2)
grain = rng.standard_normal((N, N)) * 0.025
stain = np.clip((tile_noise(3, 3) - 0.62) * 3.0, 0, 1)      # water stains
drip = np.clip((tile_noise(7, 4) - 0.7) * 3.0, 0, 1)

lum = stripe * (0.88 + 0.2 * low) * (0.96 + 0.08 * mid) + grain
img = base[None, None, :] * lum[:, :, None]
img = img * (1.0 - 0.25 * stain[:, :, None]) + np.array([0.12, 0.08, 0.02]) * stain[:, :, None] * 0.25
img *= 1.0 - 0.25 * drip[:, :, None]
img = np.clip(img, 0, 1)
Image.fromarray((img * 255).astype(np.uint8)).save("assets/textures/env/WallMotel.png")
