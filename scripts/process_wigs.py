#!/usr/bin/env python3
"""
Wig Asset Processor for TAJIRI AR Filters — v2
================================================
Produces clean PNG wig assets with transparent face/body regions.

Key insight from v1: skin color detection destroys brown/blonde hair.
v2 uses POSITION-BASED removal only:
  1. rembg AI removes background
  2. OpenCV detects face bounding box
  3. Face INTERIOR masked as ellipse (keeps hair above/beside)
  4. Body below chin removed (center strip only, preserves side hair)
  5. Feathered edges for natural blending
"""

import os
import sys
import glob
import cv2
import numpy as np
from PIL import Image
from rembg import remove

# --- Configuration ---
BASE_DIR = os.path.dirname(os.path.dirname(__file__))
INPUT_DIR = os.path.join(BASE_DIR, 'assets', 'filter_assets', 'wigs')
OUTPUT_DIR = os.path.join(BASE_DIR, 'assets', 'filter_assets', 'wigs_processed')
PREVIEW_DIR = os.path.join(BASE_DIR, 'assets', 'filter_assets', 'wigs_preview')

OUTPUT_SIZE = (512, 640)

WIG_NAMES = [
    'black_white_wave',
    'honey_brown_straight',
    'chocolate_wave',
    'black_curly',
    'ash_blonde_straight',
    'blonde_wavy',
    'auburn_bob',
    'silver_straight',
    'platinum_blonde',
    'sandy_blonde_wave',
    'jet_black_sleek',
    'caramel_brown',
]


def crop_instagram_ui(img_pil):
    """Crop Instagram UI overlays: status bar, bottom bar, side buttons."""
    w, h = img_pil.size
    top = int(h * 0.08)
    bottom = int(h * 0.22)
    side = int(w * 0.02)
    return img_pil.crop((side, top, w - side, h - bottom))


def detect_face(img_rgba):
    """Detect face using multiple Haar cascades. Returns (x,y,w,h) or None."""
    bgr = cv2.cvtColor(img_rgba[:, :, :3], cv2.COLOR_RGB2BGR)
    gray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)

    for cascade_name in [
        'haarcascade_frontalface_default.xml',
        'haarcascade_frontalface_alt.xml',
        'haarcascade_frontalface_alt2.xml',
    ]:
        cascade = cv2.CascadeClassifier(
            cv2.data.haarcascades + cascade_name)
        faces = cascade.detectMultiScale(gray, 1.05, 3, minSize=(60, 60))
        if len(faces) > 0:
            return tuple(max(faces, key=lambda f: f[2] * f[3]))
    return None


def create_face_body_mask(shape, face_rect):
    """
    Create a mask of pixels to REMOVE using position only (no color).

    Strategy:
    - Tight ellipse over face interior (forehead to chin, cheek to cheek)
    - Trapezoid for neck/body below face (narrower than face width)
    - Leave hair zones completely untouched:
      * Above face top (scalp/crown hair)
      * Left/right of face (framing hair)
      * Far left/right below chin (long hair falling down sides)
    """
    h, w = shape[:2]
    mask = np.zeros((h, w), dtype=np.uint8)

    if face_rect is None:
        # Fallback: remove center-bottom 40% of image as likely body
        body_top = int(h * 0.55)
        body_left = int(w * 0.25)
        body_right = int(w * 0.75)
        mask[body_top:, body_left:body_right] = 255
        return mask

    fx, fy, fw, fh = face_rect

    # --- Face ellipse (interior only, tight fit) ---
    # The ellipse should cover the face features (eyes/nose/mouth)
    # but NOT extend into the hair zone above
    face_cx = fx + fw // 2
    face_cy = fy + fh // 2

    # Slightly smaller than detected face to preserve hair edges
    ellipse_rx = int(fw * 0.45)  # horizontal radius
    ellipse_ry = int(fh * 0.48)  # vertical radius

    # Shift ellipse center slightly DOWN so top edge is below hairline
    ellipse_cy = face_cy + int(fh * 0.05)

    cv2.ellipse(mask, (face_cx, ellipse_cy), (ellipse_rx, ellipse_ry),
                0, 0, 360, 255, -1)

    # --- Neck zone (narrow strip below face) ---
    chin_y = fy + fh
    neck_width = int(fw * 0.45)
    neck_left = face_cx - neck_width
    neck_right = face_cx + neck_width
    neck_bottom = chin_y + int(fh * 0.4)

    # Trapezoid: starts at face width, narrows slightly for neck
    pts_neck = np.array([
        [face_cx - int(fw * 0.4), chin_y],
        [face_cx + int(fw * 0.4), chin_y],
        [face_cx + int(fw * 0.35), neck_bottom],
        [face_cx - int(fw * 0.35), neck_bottom],
    ], dtype=np.int32)
    cv2.fillPoly(mask, [pts_neck], 255)

    # --- Body zone (everything below neck, center portion) ---
    # Keep wide side columns for long hair that falls down
    body_top = neck_bottom
    hair_side_margin = int(fw * 0.6)  # preserve this much on each side
    body_left = max(0, face_cx - int(fw * 0.55))
    body_right = min(w, face_cx + int(fw * 0.55))

    # Body mask: center strip below neck
    mask[body_top:, body_left:body_right] = 255

    # --- Chest/shoulder zone (wider than neck) ---
    shoulder_top = neck_bottom
    shoulder_bottom = min(h, neck_bottom + int(fh * 1.5))
    shoulder_left = max(0, face_cx - int(fw * 0.9))
    shoulder_right = min(w, face_cx + int(fw * 0.9))

    # Gradual widening from neck to shoulders
    for y in range(shoulder_top, shoulder_bottom):
        progress = (y - shoulder_top) / max(1, shoulder_bottom - shoulder_top)
        current_half = int(fw * 0.35 + progress * fw * 0.55)
        left = max(0, face_cx - current_half)
        right = min(w, face_cx + current_half)
        mask[y, left:right] = 255

    return mask


def apply_mask_feathered(img_rgba, remove_mask, feather_px=9):
    """Apply removal mask with Gaussian feathering for soft edges."""
    result = img_rgba.copy()

    # Feather the mask edges
    blurred = cv2.GaussianBlur(
        remove_mask.astype(np.float32),
        (feather_px * 2 + 1, feather_px * 2 + 1),
        feather_px
    )
    if blurred.max() > 0:
        blurred = blurred / blurred.max()

    # Reduce alpha in masked regions
    alpha = result[:, :, 3].astype(np.float32)
    alpha *= (1.0 - blurred)
    result[:, :, 3] = alpha.clip(0, 255).astype(np.uint8)

    return result


def crop_to_content(img_rgba, padding=10):
    """Crop to bounding box of visible pixels."""
    alpha = img_rgba[:, :, 3]
    rows = np.any(alpha > 10, axis=1)
    cols = np.any(alpha > 10, axis=0)
    if not np.any(rows) or not np.any(cols):
        return img_rgba
    r0, r1 = np.where(rows)[0][[0, -1]]
    c0, c1 = np.where(cols)[0][[0, -1]]
    h, w = img_rgba.shape[:2]
    return img_rgba[
        max(0, r0 - padding):min(h, r1 + padding),
        max(0, c0 - padding):min(w, c1 + padding)
    ]


def resize_centered(img_rgba, target=(512, 640)):
    """Resize maintaining aspect ratio, centered on transparent canvas."""
    tw, th = target
    h, w = img_rgba.shape[:2]
    scale = min(tw / w, th / h)
    nw, nh = int(w * scale), int(h * scale)

    resized = cv2.resize(img_rgba, (nw, nh), interpolation=cv2.INTER_AREA)
    canvas = np.zeros((th, tw, 4), dtype=np.uint8)
    x0, y0 = (tw - nw) // 2, (th - nh) // 2
    canvas[y0:y0 + nh, x0:x0 + nw] = resized
    return canvas


def process_wig(input_path, name, out_dir, preview_dir):
    """Full pipeline for one wig image."""
    print(f"\n  [{name}] Loading {os.path.basename(input_path)}...")

    # Load & crop Instagram UI
    img = Image.open(input_path).convert('RGB')
    img = crop_instagram_ui(img)

    # rembg background removal
    print(f"  [{name}] Removing background...")
    img_nobg = remove(img)
    img_np = np.array(img_nobg)

    # Save no-bg intermediate
    Image.fromarray(img_np).save(
        os.path.join(preview_dir, f"{name}_1_nobg.png"))

    # Detect face
    face = detect_face(img_np)
    if face:
        print(f"  [{name}] Face at x={face[0]} y={face[1]} "
              f"w={face[2]} h={face[3]}")
    else:
        print(f"  [{name}] No face detected — using position heuristic")

    # Create position-based removal mask
    remove_mask = create_face_body_mask(img_np.shape, face)

    # Only apply to currently-opaque pixels
    remove_mask = cv2.bitwise_and(remove_mask, img_np[:, :, 3])

    # Save mask preview
    cv2.imwrite(os.path.join(preview_dir, f"{name}_2_mask.png"), remove_mask)

    # Apply with feathering
    result = apply_mask_feathered(img_np, remove_mask, feather_px=11)

    # Save masked intermediate
    Image.fromarray(result).save(
        os.path.join(preview_dir, f"{name}_3_result.png"))

    # Crop & resize
    result = crop_to_content(result, padding=8)
    result = resize_centered(result, OUTPUT_SIZE)

    # Save final
    out_path = os.path.join(out_dir, f"wig_{name}.png")
    Image.fromarray(result).save(out_path, 'PNG')
    print(f"  [{name}] Saved → {os.path.basename(out_path)} "
          f"({result.shape[1]}x{result.shape[0]})")
    return out_path


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    os.makedirs(PREVIEW_DIR, exist_ok=True)

    inputs = sorted(
        glob.glob(os.path.join(INPUT_DIR, '*.jpeg')) +
        glob.glob(os.path.join(INPUT_DIR, '*.jpg')) +
        glob.glob(os.path.join(INPUT_DIR, '*.png'))
    )
    # Deduplicate
    inputs = list(dict.fromkeys(inputs))

    print(f"Found {len(inputs)} wig images")

    # Extend names if needed
    while len(WIG_NAMES) < len(inputs):
        WIG_NAMES.append(f'style_{len(WIG_NAMES) + 1}')

    ok, fail = 0, 0
    for i, path in enumerate(inputs):
        try:
            process_wig(path, WIG_NAMES[i], OUTPUT_DIR, PREVIEW_DIR)
            ok += 1
        except Exception as e:
            print(f"  [{WIG_NAMES[i]}] ERROR: {e}")
            fail += 1

    print(f"\nDone: {ok} OK, {fail} failed")
    print(f"Output: {OUTPUT_DIR}")


if __name__ == '__main__':
    main()
