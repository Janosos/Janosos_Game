from PIL import Image
import sys

def check_dims(path):
    try:
        img = Image.open(path)
        print(f"Image: {path}")
        print(f"Dimensions: {img.width}x{img.height}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_dims(sys.argv[1])
