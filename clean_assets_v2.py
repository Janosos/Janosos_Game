from PIL import Image
import os

def clean_asset_v2(filename):
    base_path = r'c:\Users\Janosos\Desktop\Janosos Game\assets\images'
    path = os.path.join(base_path, filename)
    
    if not os.path.exists(path):
        print(f"File not found: {filename}")
        return

    try:
        img = Image.open(path).convert('RGBA')
        width, height = img.size
        pixels = img.load()
        
        print(f"Cleaning V2 (Aggressive Saturation Filter) for {filename}...")
        
        for y in range(height):
            for x in range(width):
                r, g, b, a = pixels[x, y]
                if a == 0: continue
                
                # Heuristic: These assets are Electric (Yellow/Blue) -> HIGH SATURATION.
                # Background is Grey Checkerboard -> LOW SATURATION.
                # White Core -> LOW SATURATION but HIGH BRIGHTNESS.
                
                brightness = (r + g + b) // 3
                saturation = max(r, g, b) - min(r, g, b)
                
                # Rule:
                # If it has color (Sat > 30), KEEP IT.
                # If it is super bright (Bright > 150), KEEP IT (White Text).
                # Reduced threshold to 150 to catch anti-aliased white edges, 
                # but might catch light grey background. 
                # User asked for "Pure White". 
                # Let's keep 200 to be safe against grey bg.
                
                if saturation < 30:
                    if brightness < 200:
                        # It's a grey pixel (dark or light), but not pure white core.
                        # Kill it.
                         pixels[x, y] = (0, 0, 0, 0)

        img.save(path)
        print(f"Saved cleaned V2 {filename}")
        
    except Exception as e:
        print(f"Error cleaning {filename}: {e}")

if __name__ == "__main__":
    assets = ['version_v5_retro.png'] 
    for a in assets:
        clean_asset_v2(a)
