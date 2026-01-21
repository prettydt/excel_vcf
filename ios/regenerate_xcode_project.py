#!/usr/bin/env python3
"""
Script to regenerate the Xcode project with proper UUIDs.
This replaces the placeholder UUIDs in project.pbxproj with real, unique identifiers.
"""

import uuid
import re
import sys
from pathlib import Path


def generate_xcode_uuid():
    """Generate a 24-character uppercase hex string (Xcode format)."""
    return uuid.uuid4().hex.upper()[:24]


def regenerate_project_file(project_path):
    """
    Regenerate the project.pbxproj file with proper UUIDs.
    
    Args:
        project_path: Path to the project.pbxproj file
    """
    print(f"Reading project file: {project_path}")
    
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Find all placeholder UUIDs (format: A10000001234567890000001, A20000001234567890000002, etc.)
    # These are the artificial UUIDs that need to be replaced
    placeholder_pattern = r'A[0-9A-F]{23}'
    placeholders = set(re.findall(placeholder_pattern, content))
    
    print(f"Found {len(placeholders)} placeholder UUIDs to replace")
    
    # Create a mapping from placeholder UUIDs to real UUIDs
    uuid_mapping = {}
    for placeholder in sorted(placeholders):
        uuid_mapping[placeholder] = generate_xcode_uuid()
    
    # Replace all placeholders with real UUIDs
    new_content = content
    for placeholder, real_uuid in uuid_mapping.items():
        new_content = new_content.replace(placeholder, real_uuid)
    
    # Backup the original file
    backup_path = Path(project_path).with_suffix('.pbxproj.backup')
    print(f"Creating backup: {backup_path}")
    with open(backup_path, 'w') as f:
        f.write(content)
    
    # Write the regenerated file
    print(f"Writing regenerated project file: {project_path}")
    with open(project_path, 'w') as f:
        f.write(new_content)
    
    print("✅ Xcode project regenerated successfully!")
    print(f"   - Replaced {len(uuid_mapping)} UUIDs")
    print(f"   - Backup saved to: {backup_path}")


def main():
    """Main function to regenerate the Xcode project."""
    # Path to the project.pbxproj file
    script_dir = Path(__file__).parent
    project_file = script_dir / "Excel2VCard" / "Excel2VCard.xcodeproj" / "project.pbxproj"
    
    if not project_file.exists():
        print(f"❌ Error: Project file not found at {project_file}")
        sys.exit(1)
    
    print("🔨 Regenerating Xcode project...")
    print(f"   Project: {project_file}")
    print()
    
    regenerate_project_file(project_file)
    
    print()
    print("📝 Next steps:")
    print("   1. Open the project in Xcode: open Excel2VCard/Excel2VCard.xcodeproj")
    print("   2. Set your development team in Signing & Capabilities")
    print("   3. Update the Bundle Identifier if needed")
    print("   4. Build and run the app (⌘R)")


if __name__ == "__main__":
    main()
