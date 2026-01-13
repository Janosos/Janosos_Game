from PIL import Image
import sys
import os

def process_enemies(input_path, output_dir, bg_color=(0, 255, 0), tolerance=50):
    print(f"Processing enemies from {input_path}...")
    try:
        img = Image.open(input_path).convert("RGBA")
        width, height = img.size
        
        # Split into two (Dog Left, Cat Right)
        # Assuming equal distribution
        mid_x = width // 2
        
        dog_img = img.crop((0, 0, mid_x, height))
        cat_img = img.crop((mid_x, 0, width, height))
        
        images = [('dog.png', dog_img), ('cat.png', cat_img)]
        
        for name, sub_img in images:
            datas = sub_img.getdata()
            newData = []
            
            r_bg, g_bg, b_bg = bg_color
            
            for item in datas:
                r, g, b, a = item
                # Distance to green
                dist = ((r - r_bg)**2 + (g - g_bg)**2 + (b - b_bg)**2)**0.5
                if dist < tolerance:
                    newData.append((0, 0, 0, 0))
                else:
                    newData.append(item)
            
            sub_img.putdata(newData)
            out_path = os.path.join(output_dir, name)
            sub_img.save(out_path, "PNG")
            print(f"Saved {name} to {out_path}")
            
    except Exception as e:
        print(f"Error processing enemies: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python process_enemies.py <input_sheet> <output_dir>")
        sys.exit(1)
        
    input_file = sys.argv[1]
    output_dir = sys.argv[2]
    
    process_enemies(input_file, output_dir)
