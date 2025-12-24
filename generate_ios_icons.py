#!/usr/bin/env python3
"""
App Icon Generator for iOS
Generates all required iOS app icon sizes from a single source image.

Usage:
    python generate_ios_icons.py source_icon.png

Requirements:
    pip install Pillow
"""

import os
import sys
from PIL import Image

# iOS App Icon sizes (width, height, filename)
ICON_SIZES = [
    (20, 20, "Icon-App-20x20@1x.png"),
    (40, 40, "Icon-App-20x20@2x.png"),
    (60, 60, "Icon-App-20x20@3x.png"),
    (29, 29, "Icon-App-29x29@1x.png"),
    (58, 58, "Icon-App-29x29@2x.png"),
    (87, 87, "Icon-App-29x29@3x.png"),
    (40, 40, "Icon-App-40x40@1x.png"),
    (80, 80, "Icon-App-40x40@2x.png"),
    (120, 120, "Icon-App-40x40@3x.png"),
    (50, 50, "Icon-App-50x50@1x.png"),
    (100, 100, "Icon-App-50x50@2x.png"),
    (57, 57, "Icon-App-57x57@1x.png"),
    (114, 114, "Icon-App-57x57@2x.png"),
    (120, 120, "Icon-App-60x60@2x.png"),
    (180, 180, "Icon-App-60x60@3x.png"),
    (72, 72, "Icon-App-72x72@1x.png"),
    (144, 144, "Icon-App-72x72@2x.png"),
    (76, 76, "Icon-App-76x76@1x.png"),
    (152, 152, "Icon-App-76x76@2x.png"),
    (167, 167, "Icon-App-83.5x83.5@2x.png"),
    (1024, 1024, "Icon-App-1024x1024@1x.png"),
]

def generate_icons(source_path, output_dir):
    """Generate all iOS app icons from source image."""
    try:
        # Open source image
        source_img = Image.open(source_path)
        print(f"Source image: {source_path}")
        print(f"Source size: {source_img.size}")
        
        # Convert to RGBA if needed
        if source_img.mode != 'RGBA':
            source_img = source_img.convert('RGBA')
        
        # Generate each size
        for width, height, filename in ICON_SIZES:
            # Resize image
            resized = source_img.resize((width, height), Image.Resampling.LANCZOS)
            
            # Save
            output_path = os.path.join(output_dir, filename)
            resized.save(output_path, 'PNG')
            print(f"✓ Generated {filename} ({width}x{height})")
        
        print(f"\n✅ Successfully generated {len(ICON_SIZES)} icons!")
        
    except FileNotFoundError:
        print(f"❌ Error: Source image not found: {source_path}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

def main():
    if len(sys.argv) < 2:
        print("Usage: python generate_ios_icons.py <source_icon.png>")
        print("\nExample:")
        print("  python generate_ios_icons.py app_icon_1024.png")
        sys.exit(1)
    
    source_path = sys.argv[1]
    output_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    generate_icons(source_path, output_dir)

if __name__ == "__main__":
    main()
