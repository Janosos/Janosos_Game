from PIL import Image

def check_corners(image_path):
    print(f"Checking corners of {image_path}...")
    try:
        img = Image.open(image_path).convert("RGBA")
        width, height = img.size
        
        corners = [
            (0, 0),
            (width-1, 0),
            (0, height-1),
            (width-1, height-1)
        ]
        
        for x, y in corners:
            pixel = img.getpixel((x, y))
            print(f"Pixel at ({x}, {y}): {pixel}")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_corners("assets/images/version_v4_retro.png")
