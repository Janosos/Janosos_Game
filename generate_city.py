from PIL import Image, ImageDraw
import random

def generate_nano_city(path):
    # Canvas Size (HD for downscaling if needed, or pixel art styling)
    # User asked for 'Nano Banana' style? Let's do Vibrant Neon (Cyberpunkish).
    w, h = 640, 360 # Higher res pixel art
    img = Image.new('RGB', (w, h), (10, 5, 20)) # Deep Void Background
    draw = ImageDraw.Draw(img)
    
    # 1. Background Grid (Nano/Tech feel)
    for i in range(0, h, 20):
        # Scanlines
        draw.line([(0, i), (w, i)], fill=(20, 10, 40))
        
    # 2. Large Moon/Planet (Banana Yellow?)
    draw.ellipse([w-150, 50, w-50, 150], fill=(255, 220, 50)) 
    
    # 3. Layered Skyline
    # Back Layer (Purple)
    x = 0
    while x < w:
        bw = random.randint(30, 80)
        bh = random.randint(50, 150)
        draw.rectangle([x, h-bh, x+bw, h], fill=(60, 20, 80))
        x += bw - 10

    # Front Layer (Cyan/Neon Blue highlights)
    x = 0
    while x < w:
        bw = random.randint(40, 100)
        bh = random.randint(80, 250)
        
        # Structure
        draw.rectangle([x, h-bh, x+bw, h], fill=(20, 20, 50))
        
        # Neon Edges
        draw.line([(x, h-bh), (x, h)], fill=(0, 255, 255))
        draw.line([(x+bw, h-bh), (x+bw, h)], fill=(0, 255, 255))
        draw.line([(x, h-bh), (x+bw, h-bh)], fill=(0, 255, 255))
        
        # Windows
        for wy in range(h-bh+10, h-10, 15):
             for wx in range(x+10, x+bw-10, 10):
                 if random.random() > 0.5:
                     draw.rectangle([wx, wy, wx+4, wy+8], fill=(255, 0, 128)) # Neon Pink Windows

        x += bw + random.randint(-10, 20)

    # Save
    img.save(path)
    print(f"Nano City generated at {path}")

if __name__ == "__main__":
    generate_nano_city("assets/images/fixed_city.png")
