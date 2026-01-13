from PIL import Image
import sys
import os

def clean_image(image_path, output_path, bg_color=None, tolerance=30):
    print(f"Processing {image_path}...")
    try:
        img = Image.open(image_path).convert("RGBA")
        datas = img.getdata()
        
        newData = []
        
        # Chroma Key Mode: If no specific bg_color is strict, or if we want aggressive green removal
        # We'll use a heuristic: if Green is significantly dominant
        use_chroma_key = True
        
        for item in datas:
            r, g, b, a = item
            
            is_transparent = False
            
            if bg_color:
                # Distance based (strict)
                r_bg, g_bg, b_bg = bg_color[:3]
                dist = ((r - r_bg)**2 + (g - g_bg)**2 + (b - b_bg)**2)**0.5
                if dist < tolerance:
                    is_transparent = True
            
            # Additional Green Chroma Key Check (Aggressive)
            # Check if pixel is "Greenish"
            # Green needs to be higher than Red and Blue, and dominant
            if not is_transparent and use_chroma_key:
                 # If Green is brighter than Red+20 and Blue+20 (avoiding dark blacks/greys)
                 # And Green is a significant portion of the brightness
                 if g > r + 20 and g > b + 20:
                     # It's green! Make it transparent
                     is_transparent = True
            
            if is_transparent:
                newData.append((0, 0, 0, 0))
            else:
                newData.append(item)
                
        img.putdata(newData)
        img.save(output_path, "PNG")
        print(f"Saved to {output_path}")
        
    except Exception as e:
        print(f"Error processing {image_path}: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python clean_assets.py <input_file> <output_file> [r,g,b]")
        sys.exit(1)
        
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    bg = None
    if len(sys.argv) > 3:
        try:
            bg_str = sys.argv[3].split(',')
            bg = (int(bg_str[0]), int(bg_str[1]), int(bg_str[2]), 255)
        except:
            pass
            
    clean_image(input_file, output_file, bg)
