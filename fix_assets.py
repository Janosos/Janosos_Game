from PIL import Image
import os

def clean_black_bg(image_path):
    # Logic: Remove pure black and near-black background
    try:
        img = Image.open(image_path)
        img = img.convert("RGBA")
        datas = img.getdata()
        new_data = []

        for item in datas:
            r, g, b, a = item
            if a == 0:
                new_data.append(item)
                continue
            
            # Remove Green/Magenta (standard safety)
            if (r < 50 and g > 200 and b < 50) or (r > 200 and g < 50 and b > 200):
                new_data.append((255, 255, 255, 0))
                continue

            # Remove Black Background
            # Tolerance: r,g,b < 15. This is very safe for bright neon assets.
            if r < 15 and g < 15 and b < 15:
                 new_data.append((255, 255, 255, 0))
            else:
                new_data.append(item)

        img.putdata(new_data)
        img.save(image_path, "PNG")
        print(f"Cleaned Black BG: {image_path}")
    except Exception as e:
        print(f"Error Black BG: {e}")

def clean_generic(image_path):
    # Standard cleaner for other assets
    try:
        img = Image.open(image_path)
        img = img.convert("RGBA")
        datas = img.getdata()
        new_data = []
        for item in datas:
            r, g, b, a = item
            if a == 0:
                new_data.append(item)
                continue
            if (r < 100 and g > 200 and b < 100) or (r > 200 and g < 50 and b > 200):
                 new_data.append((255, 255, 255, 0))
            elif r > 240 and g > 240 and b > 240:
                 new_data.append((255, 255, 255, 0))
            else:
                new_data.append(item)
        img.putdata(new_data)
        img.save(image_path, "PNG")
        print(f"Cleaned Generic: {image_path}")
    except Exception as e:
        print(f"Error Generic: {e}")

assets_dir = r"c:\Users\Janosos\Desktop\Janosos Game\assets\images"

# Dispatcher
files = {
    # Title and Button now use Black BG cleaner
    "title_retro.png": clean_black_bg,
    "start_button_retro.png": clean_black_bg,
    
    # Bullet typically has grey artifacts, black cleaner might work if it was generated on black?
    # No, bullet was existing. Let's stick to generic or the previous grey cleaner if we had kept it.
    # But for now let's assume bullet is fine or use generic. 
    # Use generic for bullet to avoid breaking it if it has dark greys inside.
    "bullet.png": clean_generic, 
    
    "heart_indicator.png": clean_generic,
    "tank_shield_icon.png": clean_generic,
    "ability_button.png": clean_generic
}

for f, cleaner in files.items():
    cleaner(os.path.join(assets_dir, f))
