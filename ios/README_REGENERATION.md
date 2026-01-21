# iOS Xcode Project Regeneration

This directory contains tools for regenerating the Excel2VCard iOS Xcode project.

## regenerate_xcode_project.py

**Purpose**: Regenerates the Xcode project file with proper unique UUIDs.

### What it does

The script replaces placeholder UUIDs in `project.pbxproj` with real, unique identifiers. This is necessary when:

1. The project was created from a template with placeholder UUIDs
2. Xcode reports project file corruption
3. UUID conflicts occur during collaboration
4. You need to ensure all project objects have unique identifiers

### Usage

```bash
cd ios
python3 regenerate_xcode_project.py
```

### Output

The script will:
1. Read the current `Excel2VCard.xcodeproj/project.pbxproj` file
2. Identify all placeholder UUIDs (format: A10000001234567890000001)
3. Generate real UUIDs to replace each placeholder
4. Create a backup at `project.pbxproj.backup`
5. Write the regenerated project file

### Example Output

```
🔨 Regenerating Xcode project...
   Project: .../Excel2VCard.xcodeproj/project.pbxproj

Reading project file: .../project.pbxproj
Found 29 placeholder UUIDs to replace
Creating backup: .../project.pbxproj.backup
Writing regenerated project file: .../project.pbxproj
✅ Xcode project regenerated successfully!
   - Replaced 29 UUIDs
   - Backup saved to: .../project.pbxproj.backup

📝 Next steps:
   1. Open the project in Xcode: open Excel2VCard/Excel2VCard.xcodeproj
   2. Set your development team in Signing & Capabilities
   3. Update the Bundle Identifier if needed
   4. Build and run the app (⌘R)
```

### Requirements

- Python 3.6+
- No external dependencies required (uses only standard library)

### Safety

- The script creates a backup of the original file before making changes
- The backup is excluded from version control via `.gitignore`
- If anything goes wrong, you can restore from the backup:
  ```bash
  cd ios/Excel2VCard/Excel2VCard.xcodeproj
  cp project.pbxproj.backup project.pbxproj
  ```

### Technical Details

**UUID Format**: Xcode uses 24-character uppercase hexadecimal strings as unique identifiers for all objects in the project.

**Placeholder Pattern**: The original project used a predictable pattern like `A10000001234567890000001`, which are not truly unique and could cause conflicts.

**Real UUIDs**: The script generates random 24-character hex strings using Python's `uuid.uuid4()` function, ensuring uniqueness.

## Files in this directory

- `regenerate_xcode_project.py` - Main regeneration script
- `Excel2VCard/` - iOS app Xcode project directory
- `Samples/` - Sample CSV files for testing
- `README_iOS.md` - Complete iOS app documentation

## After Regeneration

After running the script, you should:

1. **Open in Xcode**: `open Excel2VCard/Excel2VCard.xcodeproj`
2. **Resolve Packages**: Xcode should automatically download CoreXLSX
3. **Configure Signing**: Set your development team and Bundle ID
4. **Build**: ⌘B to verify the project builds successfully
5. **Run**: ⌘R to test on simulator or device

## Troubleshooting

**Issue**: Script reports "Project file not found"
- **Solution**: Ensure you're running from the `ios/` directory

**Issue**: Xcode still shows errors after regeneration
- **Solution**: Try cleaning the build folder (⌘⇧K) and derived data

**Issue**: Want to restore the original file
- **Solution**: Copy the backup file back: `cp project.pbxproj.backup project.pbxproj`

## Version History

- **v1.0** (2026-01): Initial version - regenerates project with proper UUIDs
