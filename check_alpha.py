from PIL import Image
import sys

def check_content(path):
    try:
        img = Image.open(path).convert("RGBA")
        datas = img.getdata()
        
        non_transparent = 0
        total = 0
        for item in datas:
            if item[3] > 0: # Alpha > 0
                non_transparent += 1
            total += 1
            
        print(f"File: {path}")
        print(f"Total Pixels: {total}")
        print(f"Visible Pixels: {non_transparent}")
        print(f"Visibility Ratio: {non_transparent/total:.4f}")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_content(sys.argv[1])
