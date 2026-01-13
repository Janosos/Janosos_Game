from PIL import Image
import os

def make_transparent(image_path):
    try:
        img = Image.open(image_path)
        img = img.convert("RGBA")
        datas = img.getdata()

        new_data = []
        # Green screen removal
        # Typical green screen is (0, 255, 0) or similar. 
        # Let's count corners to find bg or just target green.
        # User said "green background".
        
        # Let's check for "greenish" pixels or exact green? 
        # Often pixel art uses specific palette index. 
        # Let's sample top-left.
        bg_color = img.getpixel((0, 0))
        # print(f"BG Color: {bg_color}")

        for item in datas:
            # Distance from background color
            dist = abs(item[0] - bg_color[0]) + abs(item[1] - bg_color[1]) + abs(item[2] - bg_color[2])
            is_bg = dist < 20 # Tolerance

            # Green Screen (Bright Green)
            # R < 100, G > 200, B < 100
            is_green = (item[0] < 100 and item[1] > 200 and item[2] < 100)
            
            # White/Light check for button cleanup (optional, careful with lightning bolt)
            # Only if it's NOT the button icon (which is white). 
            # If we assume black background for the new button, we strictly remove black.
            
            if is_bg or is_green:
                new_data.append((255, 255, 255, 0))
            else:
                new_data.append(item)

        img.putdata(new_data)
        img.save(image_path, "PNG")
        print(f"Processed {image_path}")
    except Exception as e:
        print(f"Failed to process {image_path}: {e}")

assets_dir = r"c:\Users\Janosos\Desktop\Janosos Game\assets\images"
files = ["heart_indicator.png", "tank_shield_icon.png", "ability_button.png", "title_retro.png", "start_button_retro.png", "bullet.png"]

for f in files:
    make_transparent(os.path.join(assets_dir, f))
