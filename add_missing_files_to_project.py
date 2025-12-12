#!/usr/bin/env python3
"""
Script to automatically add missing Swift files to Xcode project.
This script modifies project.pbxproj to include Swift files that exist but aren't in the project.

Usage:
    python3 add_missing_files_to_project.py [--dry-run] [--verbose]
"""

import re
import os
import sys
import uuid
import subprocess
from pathlib import Path
from typing import List, Tuple, Dict

PROJECT_FILE = Path("Plena.xcodeproj/project.pbxproj")
PROJECT_DIRS = ["Plena", "Plena Watch App", "PlenaShared", "Tests"]


def generate_id() -> str:
    """Generate a unique 24-character hex ID for Xcode project files."""
    return ''.join([f'{b:02X}' for b in uuid.uuid4().bytes[:12]])


def find_swift_files() -> List[Path]:
    """Find all Swift files in project directories."""
    swift_files = []
    for dir_name in PROJECT_DIRS:
        dir_path = Path(dir_name)
        if dir_path.exists():
            for swift_file in dir_path.rglob("*.swift"):
                swift_files.append(swift_file)
    return sorted(swift_files)


def get_files_in_project(project_content: str) -> set:
    """Extract all Swift file references from project.pbxproj."""
    # Find all file references (PBXFileReference section)
    file_ref_pattern = r'(\w{24})\s+/\*\s+([^*]+)\s+\*/\s+=\s+{isa = PBXFileReference[^}]+path = ([^;]+);'
    files_in_project = set()

    for match in re.finditer(file_ref_pattern, project_content):
        filename = match.group(3).strip()
        files_in_project.add(filename)

    return files_in_project


def determine_group_and_target(file_path: Path) -> Tuple[str, str]:
    """Determine which group and target a file belongs to."""
    parts = file_path.parts

    if "Tests" in parts:
        return "Tests", "iOS"  # Tests might need special handling
    elif "Plena Watch App" in parts:
        if "Views" in parts:
            return "Views", "Watch"
        return "Watch", "Watch"
    elif "Plena" in parts:
        if "Views" in parts:
            if "Components" in parts:
                return "Components", "iOS"
            return "Views", "iOS"
        return "Plena", "iOS"
    elif "PlenaShared" in parts:
        if "Models" in parts:
            return "Models", "iOS"
        elif "Services" in parts:
            return "Services", "iOS"
        elif "ViewModels" in parts:
            return "ViewModels", "iOS"
        return "PlenaShared", "iOS"

    return "Unknown", "iOS"


def add_file_to_project(file_path: Path, project_content: str, dry_run: bool = False) -> str:
    """Add a Swift file to the Xcode project."""
    filename = file_path.name
    file_id = generate_id()
    build_file_id = generate_id()

    # Determine group and target
    group_name, target = determine_group_and_target(file_path)

    print(f"  📝 Would add: {file_path} (Group: {group_name}, Target: {target})")

    if dry_run:
        return project_content

    # This is complex - we'd need to:
    # 1. Add PBXBuildFile entry
    # 2. Add PBXFileReference entry
    # 3. Add to appropriate group
    # 4. Add to build phases

    # For now, just return the content unchanged
    # A full implementation would require parsing and modifying the project file structure
    return project_content


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Add missing Swift files to Xcode project")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be added without making changes")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    args = parser.parse_args()

    if not PROJECT_FILE.exists():
        print(f"❌ Error: Project file not found: {PROJECT_FILE}")
        sys.exit(1)

    print("🔍 Scanning for missing Swift files...")

    # Read project file
    with open(PROJECT_FILE, 'r') as f:
        project_content = f.read()

    # Find all Swift files
    swift_files = find_swift_files()
    files_in_project = get_files_in_project(project_content)

    # Find missing files
    missing_files = []
    for swift_file in swift_files:
        if swift_file.name not in files_in_project:
            missing_files.append(swift_file)

    if not missing_files:
        print("✅ All Swift files are in the Xcode project!")
        return

    print(f"\n❌ Found {len(missing_files)} missing file(s):")
    for file_path in missing_files:
        print(f"   - {file_path}")

    print("\n⚠️  Automatic addition to project.pbxproj is complex and error-prone.")
    print("   Please add these files manually in Xcode:")
    print("   1. Right-click the appropriate group in Project Navigator")
    print("   2. Select 'Add Files to Plena...'")
    print("   3. Select the missing files")
    print("   4. Ensure 'Copy items if needed' is unchecked")
    print("   5. Ensure correct target membership is selected")

    sys.exit(1)


if __name__ == "__main__":
    main()
