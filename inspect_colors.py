from PIL import Image
import os

assets_dir = r"c:\Users\Janosos\Desktop\Janosos Game\assets\images"
files = ["title_retro.png", "bullet.png"]

for f in files:
    path = os.path.join(assets_dir, f)
    try:
        img = Image.open(path)
        img = img.convert("RGBA")
        width, height = img.size
        
        # Check corners and a few adjacent pixels to detect checkerboard
        points = [
            (0, 0), (10, 0), (0, 10), (10, 10), # Top Left area
            (width-1, 0), (width-11, 0), # Top Right area
            (0, height-1), # Bottom Left
        ]
        
        print(f"--- {f} ---")
        for p in points:
            if p[0] < width and p[1] < height:
                pixel = img.getpixel(p)
                print(f"Pixel at {p}: {pixel}")
                
    except Exception as e:
        print(f"Error reading {f}: {e}")
