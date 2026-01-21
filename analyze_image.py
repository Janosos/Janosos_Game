from PIL import Image

src_path = r'C:\Users\Janosos\.gemini\antigravity\brain\b01ad5e7-1266-4037-b01c-f545a0b81f56\uploaded_image_1768980158278.jpg'

try:
    img = Image.open(src_path)
    print(f"Size: {img.size}")
    print(f"Mode: {img.mode}")
    
    # Check corners
    tl = img.getpixel((0,0))
    tr = img.getpixel((img.width-1, 0))
    print(f"TopLeft Color: {tl}")
    print(f"TopRight Color: {tr}")
    
    # Analyze a small patch to see if it varies (checkerboard?)
    patch = img.crop((0,0, 50, 50))
    colors = patch.getcolors()
    if len(colors) > 5:
        print("Background seems noisy or checkered (many colors in 50x50 patch).")
    else:
        print("Background seems solid.")
        
except Exception as e:
    print(f"Error: {e}")
