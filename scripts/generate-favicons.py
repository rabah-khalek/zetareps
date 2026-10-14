#!/usr/bin/env python3
"""
Generate the website favicons from web/logo.png into web/. Run from anywhere; paths are relative to the repository.
Creates favicon.ico and various PNG sizes for different devices.
"""

from PIL import Image
import os

def generate_favicons(source_logo, output_dir):
    """Generate all favicon sizes from source logo"""

    # Open the source image
    print(f"Opening source logo: {source_logo}")
    img = Image.open(source_logo)

    # Convert to RGBA if needed
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    print(f"Source image size: {img.size}")
    print(f"Source image mode: {img.mode}")

    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)

    # Define favicon sizes
    # Format: (filename, size)
    favicon_sizes = [
        ('favicon-16x16.png', 16),
        ('favicon-32x32.png', 32),
        ('apple-touch-icon.png', 180),  # Apple touch icon
    ]

    print("\nGenerating favicon files...")

    # Generate PNG favicons
    for filename, size in favicon_sizes:
        filepath = os.path.join(output_dir, filename)
        resized = img.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(filepath, 'PNG')
        print(f"  {filename} ({size}x{size})")

    # Generate favicon.ico with multiple sizes (16x16, 32x32, 48x48)
    ico_sizes = [(16, 16), (32, 32), (48, 48)]
    ico_images = []
    for size in ico_sizes:
        resized = img.resize(size, Image.Resampling.LANCZOS)
        ico_images.append(resized)

    ico_path = os.path.join(output_dir, 'favicon.ico')
    ico_images[0].save(ico_path, format='ICO', sizes=ico_sizes)
    print(f"  favicon.ico (multi-size: 16x16, 32x32, 48x48)")

    # Generate site.webmanifest
    manifest = {
        "name": "ZetaReps",
        "short_name": "ZetaReps",
        "icons": [
            {
                "src": "/apple-touch-icon.png",
                "sizes": "180x180",
                "type": "image/png"
            }
        ],
        "theme_color": "#EE220C",
        "background_color": "#000000",
        "display": "standalone"
    }

    import json
    manifest_path = os.path.join(output_dir, 'site.webmanifest')
    with open(manifest_path, 'w') as f:
        json.dump(manifest, f, indent=2)
    print(f"  site.webmanifest")
    print("Favicons generated successfully!")
    print(f"\nGenerated files in {output_dir}:")
    print("  • favicon.ico (multi-size)")
    print("  • favicon-16x16.png")
    print("  • favicon-32x32.png")
    print("  • apple-touch-icon.png (180x180)")
    print("  • site.webmanifest")
def main():
    # Paths
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    source_logo = os.path.join(repo_root, "web", "logo.png")
    output_dir = os.path.join(repo_root, "web")

    # Check if source file exists
    if not os.path.exists(source_logo):
        print(f"Error: Source logo not found at {source_logo}")
        print(f"Please create a logo.png file (1024x1024 recommended)")
        return 1
    print("Generating Favicons for ZetaReps Website")
    print()

    # Generate favicons
    generate_favicons(source_logo, output_dir)

    return 0

if __name__ == "__main__":
    exit(main())
