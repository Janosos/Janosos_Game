from PIL import Image

def process_sprite_v11():
    src_path = r'C:\Users\Janosos\.gemini\antigravity\brain\b01ad5e7-1266-4037-b01c-f545a0b81f56\uploaded_image_1768982068575.jpg'
    dest_path = r'c:\Users\Janosos\Desktop\Janosos Game\assets\images\nanic_clean.png'

    try:
        img = Image.open(src_path)
        
        quad_coords = [
            (0, 0, 512, 512),
            (512, 0, 1024, 512),
            (0, 512, 512, 1024),
            (512, 512, 1024, 1024)
        ]
        
        frames = []
        max_h = 0
        max_w = 0 
        
        print("Processing V11 - HIGH RESOLUTION (Full Detail)...")
        
        for idx, crop_box in enumerate(quad_coords):
            frame = img.crop(crop_box).convert('RGBA')
            width, height = frame.size
            pixels = frame.load()
            
            # 1. Base Cleanup (Flood Fill) - Safe Background Removal
            visited = set()
            queue = []
            for x in range(0, width, 5): 
                queue.append((x, 0))
                queue.append((x, height-1))
            for y in range(0, height, 5):
                queue.append((0, y))
                queue.append((width-1, y))
                
            for start_node in queue:
                if start_node in visited: continue
                q_curr = [start_node]
                while q_curr:
                    x, y = q_curr.pop(0)
                    if (x,y) in visited: continue
                    if x<0 or x>=width or y<0 or y>=height: continue
                    visited.add((x,y))
                    
                    r, g, b, a = pixels[x,y]
                    brightness = (r+g+b)//3
                    saturation = max(r,g,b) - min(r,g,b)
                    
                    # High tolerance for background
                    if brightness > 120 and saturation < 40:
                        pixels[x,y] = (0,0,0,0)
                        q_curr.append((x+1, y))
                        q_curr.append((x-1, y))
                        q_curr.append((x, y+1))
                        q_curr.append((x, y-1))

            # 2. Island Cleanup (Remove floating noise)
            visited_island = set()
            components = []
            for y in range(height):
                for x in range(width):
                    if pixels[x,y][3] == 0: continue
                    if (x,y) in visited_island: continue
                    comp = []
                    q_island = [(x,y)]
                    visited_island.add((x,y))
                    while q_island:
                        cx, cy = q_island.pop(0)
                        comp.append((cx,cy))
                        for nx, ny in [(cx+1, cy), (cx-1, cy), (cx, cy+1), (cx, cy-1)]:
                            if 0 <= nx < width and 0 <= ny < height:
                                if (nx,ny) not in visited_island and pixels[nx,ny][3] != 0:
                                    visited_island.add((nx,ny))
                                    q_island.append((nx,ny))
                    components.append(comp)
            
            if components:
                components.sort(key=len, reverse=True)
                # Keep biggest
                for i in range(1, len(components)):
                    if len(components[i]) < 500: # Increase threshold for high res noise
                        for dx, dy in components[i]:
                            pixels[dx, dy] = (0,0,0,0)

            # 3. CONTOUR CLEANUP - Halo Erosion (High Res)
            # More gentle on High Res? Or same?
            # Let's target Bright+LowSat pixels at the edge.
            
            pixels_to_kill = []
            for y in range(height):
                for x in range(width):
                    if pixels[x,y][3] == 0: continue
                    
                    # Is Edge?
                    is_edge = False
                    for nx, ny in [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]:
                        if 0 <= nx < width and 0 <= ny < height:
                            if pixels[nx,ny][3] == 0:
                                is_edge = True
                                break
                    
                    if is_edge:
                        r, g, b, a = pixels[x,y]
                        brightness = (r+g+b)//3
                        saturation = max(r,g,b) - min(r,g,b)
                        
                        # Grey Edge
                        if brightness > 100 and saturation < 30:
                             pixels_to_kill.append((x,y))
            
            for kx, ky in pixels_to_kill:
                 pixels[kx, ky] = (0,0,0,0)

            # Recalculate BBox (High Res)
            bbox = frame.getbbox()
            if bbox:
                frames.append(frame.crop(bbox))
                w, h = frame.crop(bbox).size
                max_w = max(max_w, w)
                max_h = max(max_h, h)
                print(f"Frame {idx} High Res Content: {w}x{h}")
            else:
                frames.append(None)

        if not frames or max_h == 0:
            return

        # V11 CHANGE: NO DOWNSCALING
        # Create sheet to fit MAX High Res content (+ margin)
        
        # Add a tiny margin?
        cell_w = max_w + 4
        cell_h = max_h + 4
        
        # Ensure even numbers just in case
        if cell_w % 2 != 0: cell_w += 1
        if cell_h % 2 != 0: cell_h += 1
        
        sheet_w = cell_w * 2
        sheet_h = cell_h * 2
        
        sheet = Image.new('RGBA', (sheet_w, sheet_h), (0, 0, 0, 0))
        
        dest_positions = [(0, 0), (cell_w, 0), (0, cell_h), (cell_w, cell_h)]
        
        for i, frame in enumerate(frames):
            if frame:
                # Center-Bottom alignment in cell
                cell_x, cell_y = dest_positions[i]
                
                fw, fh = frame.size
                
                # Center X
                paste_x = cell_x + (cell_w - fw) // 2
                
                # Bottom Y (flush or -2 padding)
                paste_y = cell_y + (cell_h - fh) - 2
                
                sheet.paste(frame, (paste_x, paste_y))

        sheet.save(dest_path)
        print(f"Successfully processed nanic_clean.png (V11 - High Res {sheet_w}x{sheet_h}).")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    process_sprite_v11()
