from PIL import Image

def clean_image(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    datas = img.getdata()

    new_data = []
    for item in datas:
        # Item is (r, g, b, a)
        # Check if the pixel is BRIGHT (White text)
        # "V4" should be white.
        # Threshold: if sum of RGB < 600 (approx 200 each), consider it background and remove.
        # Or checking if it matches the background colors we saw.
        # Let's use a brightness threshold. White is (255,255,255) sum=765.
        # Gray background was (87,87,87) sum=261.
        # Black background was (1,1,1) sum=3.
        
        if sum(item[:3]) < 400:
            new_data.append((0, 0, 0, 0)) # Transparent
        else:
            new_data.append(item) # Keep original (White)

    img.putdata(new_data)
    img.save(output_path, "PNG")
    print(f"Saved cleaned image to {output_path}")

if __name__ == "__main__":
    clean_image("assets/images/version_v4_retro.png", "assets/images/version_v4_retro_cleaned.png")
