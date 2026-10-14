#!/usr/bin/env python3
"""
Generate the iOS AppIcon.appiconset from web/logo.png. Run from anywhere; paths are relative to the repository.

For iOS 17.0+, only a single 1024x1024 icon is required.
Xcode automatically generates all other sizes.
"""

from PIL import Image
import os
import json

# For iOS 17.0+, only need single 1024x1024 icon
# Xcode handles all resizing automatically
ICON_SIZES = [
    # Single universal icon (iOS 17.0+)
    ("1024x1024", 1, 1024, ["universal"]),
]

def generate_icons(source_image_path, output_dir):
    """Generate all required icon sizes from source image"""
    from PIL import ImageFilter, ImageEnhance

    # Open the source image
    print(f"Opening source image: {source_image_path}")
    img = Image.open(source_image_path)

    # Convert to RGBA if needed
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    print(f"Source image size: {img.size}")
    print(f"Source image mode: {img.mode}")

    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Clean up old icon files (keep Contents.json if it exists)
    print("Cleaning up old icon files...")
    if os.path.exists(output_dir):
        for file in os.listdir(output_dir):
            if file.endswith('.png') and file.startswith('icon_'):
                old_file_path = os.path.join(output_dir, file)
                os.remove(old_file_path)
                print(f"Removed old file: {file}")

    # Generate each icon size
    # Track unique files to avoid regenerating duplicates
    generated_files = []
    seen_files = set()
    
    for size_name, scale, pixel_size, idioms in ICON_SIZES:
        filename = f"icon_{size_name}@{scale}x.png"
        filepath = os.path.join(output_dir, filename)

        # Only generate file if we haven't seen this exact size/scale combination
        if filename not in seen_files:
            # Resize image with high-quality resampling
            resized = img.resize((pixel_size, pixel_size), Image.Resampling.LANCZOS)

            # Apply sharpening for smaller sizes to improve clarity
            if pixel_size <= 64:
                # More sharpening for very small icons
                resized = resized.filter(ImageFilter.UnsharpMask(radius=1, percent=150, threshold=3))
            elif pixel_size <= 256:
                # Moderate sharpening for medium icons
                resized = resized.filter(ImageFilter.UnsharpMask(radius=0.5, percent=100, threshold=2))

            # Slightly enhance contrast for better visibility
            if pixel_size <= 128:
                enhancer = ImageEnhance.Contrast(resized)
                resized = enhancer.enhance(1.1)

            # Save the resized image with Xcode-compatible settings
            # Ensure we save as standard PNG that Xcode can read
            # Use compress_level=6 (standard) for better Xcode compatibility
            resized.save(filepath, 'PNG', compress_level=6)
            print(f"Generated: {filename} ({pixel_size}x{pixel_size})")
            seen_files.add(filename)

        # Add entry for each idiom that uses this icon
        for idiom in idioms:
            entry = {
                "size": size_name,
                "filename": filename,
                "idiom": idiom
            }
            # Only add scale for non-universal idioms
            if idiom != "universal":
                entry["scale"] = f"{scale}x"
            generated_files.append(entry)

    return generated_files

def update_contents_json(output_dir, generated_files):
    """Update Contents.json with the generated icon filenames"""

    contents = {
        "images": [],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }

    # Create entries (for iOS 17+, just one universal icon)
    image_entries = []
    for file_info in generated_files:
        image_entry = {
            "filename": file_info["filename"],
            "idiom": file_info["idiom"],
            "platform": "ios",
            "size": file_info["size"]
        }
        # Note: No scale field for universal idiom
        image_entries.append(image_entry)

    contents["images"] = image_entries

    # Write Contents.json with standard formatting
    contents_path = os.path.join(output_dir, "Contents.json")
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2, ensure_ascii=False)
        f.write('\n')  # Add trailing newline

    print(f"\nUpdated: {contents_path}")

def main():
    # Paths
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    source_logo = os.path.join(repo_root, "web", "logo.png")
    output_dir = os.path.join(repo_root, "ZetaReps", "Assets.xcassets", "AppIcon.appiconset")

    # Check if source file exists
    if not os.path.exists(source_logo):
        print(f"Error: Source logo not found at {source_logo}")
        print(f"Please create a logo.png file (1024x1024 recommended) at:")
        print(f"  {source_logo}")
        return 1
    print("Generating iOS App Icons for ZetaReps")
    # Generate icons
    generated_files = generate_icons(source_logo, output_dir)

    # Update Contents.json
    update_contents_json(output_dir, generated_files)
    print("App icons generated successfully!")
    # Count unique files (not entries, since same file can be used for multiple idioms)
    unique_files = len(set(f["filename"] for f in generated_files))
    print(f"\nGenerated {unique_files} icon file(s) in:")
    print(f"  {output_dir}")
    print("\niOS 17.0+ Single Icon Approach:")
    print("  • 1024x1024 universal icon")
    print("  • Xcode automatically generates all required sizes")
    print("  • Supports iPhone and iPad")
    return 0

if __name__ == "__main__":
    exit(main())
