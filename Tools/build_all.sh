#!/bin/bash
rm -rf build_ios.log build_mac.log build_watch.log

echo "Building iOS..."
xcodebuild clean build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO > build_ios.log 2>&1

echo "Building macOS Catalyst..."
xcodebuild clean build -project ZhiYu.xcodeproj -scheme ZhiYuMac -destination 'platform=macOS,variant=Mac Catalyst' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO > build_mac.log 2>&1

echo "Building watchOS..."
xcodebuild clean build -project ZhiYu.xcodeproj -scheme ZhiYuWatch -destination 'generic/platform=watchOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO > build_watch.log 2>&1

echo "iOS Warns/Errors:"
grep -i "warning:" build_ios.log | wc -l
grep -i "error:" build_ios.log | wc -l

echo "Mac Warns/Errors:"
grep -i "warning:" build_mac.log | wc -l
grep -i "error:" build_mac.log | wc -l

echo "Watch Warns/Errors:"
grep -i "warning:" build_watch.log | wc -l
grep -i "error:" build_watch.log | wc -l

