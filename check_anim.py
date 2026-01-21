from PIL import Image, ImageChops

def check_quadrants():
    src_path = r'C:\Users\Janosos\.gemini\antigravity\brain\b01ad5e7-1266-4037-b01c-f545a0b81f56\uploaded_image_1768980158278.jpg'
    try:
        img = Image.open(src_path)
        q1 = img.crop((0, 0, 512, 512))
        q2 = img.crop((512, 0, 1024, 512))
        q3 = img.crop((0, 512, 512, 1024))
        q4 = img.crop((512, 512, 1024, 1024))
        
        diff12 = ImageChops.difference(q1, q2).getbbox()
        diff13 = ImageChops.difference(q1, q3).getbbox()
        
        print(f"Diff Q1-Q2: {diff12}")
        print(f"Diff Q1-Q3: {diff13}")
        
        if diff12 or diff13:
            print("Image contains distinct frames (Animation detected).")
        else:
            print("Image appears to be identical frames (Static).")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_quadrants()
