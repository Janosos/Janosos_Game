from PIL import Image
from collections import deque
import os
import sys

def clean_asset(image_path, threshold=28):
    im = Image.open(image_path).convert('RGBA')
    w, h = im.size
    pixels = im.load()
    
    visited = set()
    queue = deque()
    
    for x in range(w):
        queue.append((x, 0))
        queue.append((x, h - 1))
    for y in range(h):
        queue.append((0, y))
        queue.append((w - 1, y))
        
    while queue:
        x, y = queue.popleft()
        if (x, y) in visited:
            continue
        visited.add((x, y))
        
        r, g, b, a = pixels[x, y]
        if max(r, g, b) <= threshold:
            pixels[x, y] = (0, 0, 0, 0)
            for nx, ny in ((x+1, y), (x-1, y), (x, y+1), (x, y-1)):
                if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited:
                    queue.append((nx, ny))

    bbox = im.getbbox()
    if bbox:
        pad = 8
        left = max(0, bbox[0] - pad)
        top = max(0, bbox[1] - pad)
        right = min(im.width, bbox[2] + pad)
        bottom = min(im.height, bbox[3] + pad)
        im = im.crop((left, top, right, bottom))

    im.save(image_path, 'PNG')
    print(f'Cleaned and transparent: {image_path} ({im.size})')

def clean_all_ui_assets():
    base_dir = os.path.join('assets', 'images')
    targets = {
        'ui_coin_pixel.png': 25,
        'ui_trophy_pixel.png': 25,
        'ui_gamepad_pixel.png': 25,
        'ui_pixel_heart.png': 35,
    }
    for filename, thresh in targets.items():
        path = os.path.join(base_dir, filename)
        if os.path.exists(path):
            clean_asset(path, thresh)

if __name__ == '__main__':
    if len(sys.argv) > 1:
        clean_asset(sys.argv[1])
    else:
        clean_all_ui_assets()
