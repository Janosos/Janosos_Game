from PIL import Image
import sys

def remove_black_background(input_path, output_path):
    img = Image.open(input_path)
    img = img.convert("RGBA")
    datas = img.getdata()

    new_data = []
    for item in datas:
        # Check for Magenta (approximate to handle slight compression artifacts)
        # Magenta is ~ (255, 0, 255)
        if item[0] > 200 and item[1] < 50 and item[2] > 200:
            new_data.append((0, 0, 0, 0)) # Transparent
        else:
            new_data.append(item)

    img.putdata(new_data)
    img.save(output_path, "PNG")
    print(f"Saved transparent image to {output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python remove_bg.py <input> <output>")
    else:
        remove_black_background(sys.argv[1], sys.argv[2])
