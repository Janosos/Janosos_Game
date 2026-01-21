from PIL import Image
import os

def clean_asset(filename):
    base_path = r'c:\Users\Janosos\Desktop\Janosos Game\assets\images'
    path = os.path.join(base_path, filename)
    
    if not os.path.exists(path):
        print(f"File not found: {filename}")
        return

    try:
        img = Image.open(path).convert('RGBA')
        width, height = img.size
        pixels = img.load()
        
        print(f"Cleaning {filename} ({width}x{height})...")

        # Flood Fill from corners
        visited = set()
        queue = []
        
        # Check all 4 corners
        corners = [(0, 0), (width-1, 0), (0, height-1), (width-1, height-1)]
        
        for cx, cy in corners:
            queue.append((cx, cy))
            
        # Tolerance for checkerboard (White/Grey)
        # Usually checkerboard is distinct from the colorful asset
        
        while queue:
            x, y = queue.pop(0)
            if (x, y) in visited: continue
            if x < 0 or x >= width or y < 0 or y >= height: continue
            
            visited.add((x, y))
            r, g, b, a = pixels[x, y]
            
            # Identify Background
            # Checkerboard is usually greyscale (r~g~b) and > 100 brightness
            # Aura is BLUE/CYAN (High B/G)
            # Linktning is YELLOW (High R/G)
            # Orb is YELLOW
            
            brightness = (r + g + b) // 3
            saturation = max(r, g, b) - min(r, g, b)
            
            is_bg = False
            
            # Simple Checkerboard rule: Low Saturation (< 30) AND Brightness > 50
            if saturation < 30 and brightness > 50:
                is_bg = True
                
            if is_bg:
                pixels[x, y] = (0, 0, 0, 0)
                
                # Add neighbors
                queue.append((x+1, y))
                queue.append((x-1, y))
                queue.append((x, y+1))
                queue.append((x, y-1))

        img.save(path)
        print(f"Saved cleaned {filename}")
        
    except Exception as e:
        print(f"Error cleaning {filename}: {e}")

if __name__ == "__main__":
    assets = ['lightning_icon.png', 'orb.png', 'aura.png']
    for a in assets:
        clean_asset(a)
