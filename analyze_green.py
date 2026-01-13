from PIL import Image
from collections import Counter

def analyze_green(image_path):
    print(f"Analyzing {image_path}...")
    try:
        img = Image.open(image_path).convert("RGBA")
        datas = img.getdata()
        
        green_candidates = []
        for r, g, b, a in datas:
            # Look for pixels that are predominantly green
            if g > r + 50 and g > b + 50 and a > 0:
                green_candidates.append((r, g, b))
                
        if not green_candidates:
            print("No significant green pixels found.")
            return

        counts = Counter(green_candidates)
        most_common = counts.most_common(5)
        print("Most common green tints:")
        for color, count in most_common:
            print(f"RGB{color}: {count} pixels")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    analyze_green("assets/images/character.png")
