#!/bin/bash
# Interactive setup script for automatic file addition
# This helps configure the automatic file addition system

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "🔧 Automatic File Addition Setup"
echo "================================="
echo ""
echo "This script helps you set up automatic addition of Swift files to the Xcode project."
echo ""
echo "Available options:"
echo "  1. Xcode Build Phase (Recommended) - Runs before each build"
echo "  2. File Watcher - Watches for new files in real-time"
echo "  3. Git Post-Commit Hook - Runs after each commit (already active)"
echo "  4. All of the above"
echo ""

read -p "Select option (1-4): " choice

case $choice in
    1)
        echo ""
        echo "📝 Xcode Build Phase Setup"
        echo "=========================="
        echo ""
        echo "To add the build phase:"
        echo "  1. Open Plena.xcodeproj in Xcode"
        echo "  2. Select the 'Plena' target"
        echo "  3. Go to 'Build Phases' tab"
        echo "  4. Click '+' and select 'New Run Script Phase'"
        echo "  5. Drag it to the TOP (before Sources phase)"
        echo "  6. Paste this in the script box:"
        echo ""
        echo "     \${SRCROOT}/scripts/add_files_build_phase.sh"
        echo ""
        echo "  7. Name it: 'Ensure Files in Project'"
        echo "  8. Uncheck 'For install builds only'"
        echo ""
        echo "✅ Script is ready at: scripts/add_files_build_phase.sh"
        ;;
    2)
        echo ""
        echo "📝 File Watcher Setup"
        echo "===================="
        echo ""

        # Check if fswatch is installed
        if ! command -v fswatch &> /dev/null; then
            echo "❌ fswatch is not installed"
            echo ""
            read -p "Install fswatch with Homebrew? (y/n) " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                if command -v brew &> /dev/null; then
                    brew install fswatch
                    echo "✅ fswatch installed"
                else
                    echo "❌ Homebrew not found. Install fswatch manually:"
                    echo "   Visit: https://github.com/emcrisostomo/fswatch"
                    exit 1
                fi
            else
                echo "⚠️  File watcher requires fswatch. Install it manually."
                exit 1
            fi
        else
            echo "✅ fswatch is installed"
        fi

        echo ""
        echo "To start the file watcher:"
        echo "  ./scripts/watch_for_new_files.sh &"
        echo ""
        echo "To run in background on startup, add to ~/.zshrc:"
        echo "  nohup $PROJECT_ROOT/scripts/watch_for_new_files.sh > /dev/null 2>&1 &"
        echo ""
        read -p "Start the file watcher now? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            nohup "$SCRIPT_DIR/watch_for_new_files.sh" > /dev/null 2>&1 &
            echo "✅ File watcher started in background (PID: $!)"
        fi
        ;;
    3)
        echo ""
        echo "📝 Git Post-Commit Hook"
        echo "======================"
        echo ""
        if [ -f ".git/hooks/post-commit" ]; then
            echo "✅ Post-commit hook is already configured"
            echo "   Location: .git/hooks/post-commit"
        else
            echo "❌ Post-commit hook not found"
            echo "   Creating it now..."
            cp "$SCRIPT_DIR/../.git/hooks/post-commit" .git/hooks/post-commit 2>/dev/null || {
                echo "   Creating from template..."
                cat > .git/hooks/post-commit << 'EOF'
#!/bin/bash
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
cd "$PROJECT_ROOT"
SCRIPT_DIR="$PROJECT_ROOT/scripts"
if [ -f "$SCRIPT_DIR/add_missing_files_to_project.py" ]; then
    python3 "$SCRIPT_DIR/add_missing_files_to_project.py" > /dev/null 2>&1
fi
exit 0
EOF
                chmod +x .git/hooks/post-commit
            }
            echo "✅ Post-commit hook created"
        fi
        ;;
    4)
        echo ""
        echo "📝 Setting up all options..."
        echo ""

        # Build phase instructions
        echo "1️⃣  Xcode Build Phase:"
        echo "   Follow the instructions in Option 1 above"
        echo ""

        # File watcher
        if command -v fswatch &> /dev/null; then
            echo "2️⃣  File Watcher:"
            read -p "   Start file watcher now? (y/n) " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                nohup "$SCRIPT_DIR/watch_for_new_files.sh" > /dev/null 2>&1 &
                echo "   ✅ File watcher started (PID: $!)"
            fi
        else
            echo "2️⃣  File Watcher:"
            echo "   ⚠️  fswatch not installed. Install with: brew install fswatch"
        fi
        echo ""

        # Post-commit hook
        echo "3️⃣  Git Post-Commit Hook:"
        if [ -f ".git/hooks/post-commit" ]; then
            echo "   ✅ Already configured"
        else
            echo "   ✅ Will be created on next commit"
        fi
        echo ""
        echo "✅ Setup complete!"
        ;;
    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac

echo ""
echo "📚 For more details, see: docs/development/AUTOMATIC_FILE_ADDITION_SETUP.md"



