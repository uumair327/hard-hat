#!/bin/bash

echo "🔧 Generating Injectable code..."

# Clean previous builds
flutter packages pub run build_runner clean

# Generate code
flutter packages pub run build_runner build --delete-conflicting-outputs

echo "✅ Injectable code generation completed!"
echo ""
echo "📝 Generated files:"
echo "  - lib/core/di/injection.config.dart"
echo ""
echo "🚀 You can now run the app with the new injectable setup!"